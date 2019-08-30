/**
 *Submitted for verification at Etherscan.io on 2017-10-22
*/

pragma solidity ^0.4.17;

contract ENS {
    function owner(bytes32 node) public constant returns(address);
    function resolver(bytes32 node) public constant returns(address);
    function ttl(bytes32 node) public constant returns(uint64);
    function setOwner(bytes32 node, address newOwner) public;
    function setSubnodeOwner(bytes32 node, bytes32 label, address newOwner) public;
    function setResolver(bytes32 node, address newResolver) public;
    function setTTL(bytes32 node, uint64 newTtl) public;

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);
}

contract DNSSEC {
    function rrset(uint16 class, uint16 dnstype, bytes name) public constant returns(uint32 inception, uint32 expiration, uint64 inserted, bytes rrs);
}

library BytesUtils {
    struct slice {
        uint len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * @dev Copies memory from one slice to another.
     *
     * Not safe to use if `src` and `dest` overlap.
     *
     * @param dest The destination slice.
     * @param destoff Offset into the destination slice.
     * @param src The source slice.
     * @param srcoff Offset into the source slice.
     * @param len Number of bytes to copy.
     */
    function memcpy(slice memory dest, uint destoff, slice memory src, uint srcoff, uint len) internal pure {
        require(destoff + len <= dest.len);
        require(srcoff + len <= src.len);
        memcpy(dest._ptr + destoff, src._ptr + srcoff, len);
    }

    /*
     * @dev Returns a slice containing the entire byte string.
     * @param self The byte string to make a slice from.
     * @return A newly allocated slice
     */
    function toSlice(bytes memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(self.length, ptr);
    }

    /*
     * @dev Allocates backing memory for a new slice of the specified length.
     * @param len The length of the slice to create.
     * @return A newly allocated slice
     */
    function newSlice(uint len) internal pure returns (slice memory) {
        bytes memory data = new bytes(len);
        uint ptr;
        assembly {
            ptr := add(data, 0x20)
        }
        return slice(len, ptr);
    }

    /*
     * @dev Initializes a slice from a byte string.
     * @param self The slice to iInitialize.
     * @param data The byte string to initialize from.
     * @return The initialized slice.
     */
    function fromBytes(slice self, bytes data) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(data, 0x20)
        }
        self._ptr = ptr;
        self.len = data.length;
        return self;
    }

    /*
     * @dev Makes 'self' a duplicate of 'other'.
     * @param self The slice to copy to.
     * @param other The slice to copy from
     * @return self
     */
    function copyFrom(slice self, slice other) internal pure returns (slice) {
        self._ptr = other._ptr;
        self.len = other.len;
        return self;
    }

    /*
     * @dev Copies a slice to a new byte string.
     * @param self The slice to copy.
     * @return A newly allocated byte string containing the slice's text.
     */
    function toBytes(slice self) internal pure returns (bytes) {
        var ret = new bytes(self.len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self.len);
        return ret;
    }

    /*
     * @dev Copies a slice to a new byte string
     * @param self The slice to copy
     * @param start The start position to copy, inclusive
     * @param end The end position to copy, exclusive
     * @return A newly allocated byte string.
     */
    function toBytes(slice self, uint start, uint end) internal pure returns (bytes memory ret) {
        require(start <= end && end <= self.len);
        ret = new bytes(end - start);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr + start, end - start);
    }


    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice self, slice other) internal pure returns (int) {
        uint shortest = self.len;
        if (other.len < self.len)
            shortest = other.len;

        var selfptr = self._ptr;
        var otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                var diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self.len) - int(other.len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice self, slice other) internal pure returns (bool) {
        return keccak(self) == keccak(other);
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice self) internal pure returns (bytes32 ret) {
        assembly {
            ret := sha3(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns the keccak-256 hash of part of the slice.
     * @param self The slice to hash.
     * @param start The start index, inclusive.
     * @param end The end index, exclusive.
     * @return The hash of the slice.
     */
    function keccak(slice self, uint start, uint end) internal pure returns (bytes32 ret) {
        assembly {
            ret := sha3(add(mload(add(self, 32)), start), sub(end, start))
        }
    }

    /*
     * @dev Reslices the current slice
     * @param self The slice to reslice.
     * @param start The start index, inclusive.
     * @param end The end index, exclusive.
     * @return The modified slice.
     */
    function s(slice self, uint start, uint end) internal pure returns (slice) {
        assert(start >= 0 && end <= self.len && start <= end);

        self._ptr += uint(start);
        self.len = end - start;
        return self;
    }

    /*
     * @dev Returns true iff the slice is a suffix of the provided byte string.
     * @param self The slice to test.
     * @param data The byte string to test against.
     */
    function suffixOf(slice self, uint off, bytes data) internal pure returns (bool ret) {
        var suffixlen = self.len - off;
        require(suffixlen <= data.length);
        var suffixOffset = 32 + (data.length - suffixlen);
        assembly {
          let suffixhash := keccak256(add(data, suffixOffset), suffixlen)
          let ourhash := keccak256(add(mload(add(self, 32)), off), suffixlen)
          ret := eq(suffixhash, ourhash)
        }
    }

    /*
     * @dev Returns the specified byte from the slice.
     * @param self The slice.
     * @param idx The index into the slice.
     * @return The specified 8 bits of slice, interpreted as a byte.
     */
    function byteAt(slice self, uint idx) internal pure returns (byte ret) {
        var ptr = self._ptr;
        assembly {
            ret := and(mload(add(sub(ptr, 31), idx)), 0xFF)
        }
    }

    /*
     * @dev Returns the 8-bit number at the specified index of self.
     * @param self The slice.
     * @param idx The index into the slice
     * @return The specified 8 bits of slice, interpreted as an integer.
     */
    function uint8At(slice self, uint idx) internal pure returns (uint8 ret) {
        var ptr = self._ptr;
        assembly {
            ret := and(mload(add(sub(ptr, 31), idx)), 0xFF)
        }
    }

    /*
     * @dev Returns the 16-bit number at the specified index of self.
     * @param self The slice.
     * @param idx The index into the slice
     * @return The specified 16 bits of slice, interpreted as an integer.
     */
    function uint16At(slice self, uint idx) internal pure returns (uint16 ret) {
        var ptr = self._ptr;
        assembly {
            ret := and(mload(add(sub(ptr, 30), idx)), 0xFFFF)
        }
    }

    /*
     * @dev Returns the 32-bit number at the specified index of self.
     * @param self The slice.
     * @param idx The index into the slice
     * @return The specified 32 bits of slice, interpreted as an integer.
     */
    function uint32At(slice self, uint idx) internal pure returns (uint32 ret) {
        var ptr = self._ptr;
        assembly {
            ret := and(mload(add(sub(ptr, 28), idx)), 0xFFFFFFFF)
        }
    }

    /*
     * @dev Returns the bytes32 at the specified index of self.
     * @param self The slice.
     * @param idx The index into the slice
     * @return The specified 32 bytes of slice.
     */
    function bytes32At(slice self, uint idx) internal pure returns (bytes32 ret) {
        var ptr = self._ptr + idx;
        assembly { ret := mload(ptr) }
    }

    /*
     * @dev Writes a word to the specified index of self.
     * @param self The slice.
     * @param idx The index into the slice.
     * @param data The word to write.
     */
    function writeBytes32(slice self, uint idx, bytes32 data) internal pure {
        var ptr = self._ptr + idx;
        assembly { mstore(ptr, data) }
    }

    /**
     * @dev Writes a byte string to the specified index of self.
     * @param self The slice.
     * @param idx The index into the slice.
     * @param data The bytes to write.
     */
    function writeBytes(slice self, uint idx, bytes data) internal pure {
        uint ptr;
        assembly { ptr := add(data, 32) }
        memcpy(self._ptr + idx, ptr, data.length);
    }
}

library RRUtils {
    using BytesUtils for *;

    function dnsNameAt(BytesUtils.slice self, uint startIdx, BytesUtils.slice memory target) internal pure returns (BytesUtils.slice) {
        target._ptr = self._ptr + startIdx;

        var idx = startIdx;
        while(true) {
            assert(idx < self.len);
            var labelLen = self.uint8At(idx);
            idx += labelLen + 1;
            if(labelLen == 0) break;
        }
        target.len = idx - startIdx;
        return target;
    }

    function nextRR(BytesUtils.slice memory self, BytesUtils.slice memory name, BytesUtils.slice memory rdata) internal pure returns (uint16 dnstype, uint16 class, uint32 ttl) {
        // Compute the offset from self to the start of the next record
        uint off;
        if(rdata._ptr < self._ptr || rdata._ptr > self._ptr + self.len) {
            off = 0;
        } else {
            off = (rdata._ptr + rdata.len) - self._ptr;
        }

        if(off >= self.len) {
            return (0, 0, 0);
        }

        // Parse the name
        dnsNameAt(self, off, name); off += name.len;

        // Read type, class, and ttl
        dnstype = self.uint16At(off); off += 2;
        class = self.uint16At(off); off += 2;
        ttl = self.uint32At(off); off += 4;

        // Read the rdata
        rdata.len = self.uint16At(off); off += 2;
        rdata._ptr = self._ptr + off;
    }

    function countLabels(BytesUtils.slice memory self, uint off) internal pure returns(uint ret) {
        while(true) {
            assert(off < self.len);
            var labelLen = self.uint8At(off);
            if(labelLen == 0) return;
            off += labelLen + 1;
            ret += 1;
        }
    }
}

/**
 * @dev An ENS registrar that allows the owner of a DNS name to claim the
 *      corresponding name in ENS.
 */
contract DNSRegistrar {
    using BytesUtils for *;
    using RRUtils for *;

    uint16 constant CLASS_INET = 1;
    uint16 constant TYPE_TXT = 16;

    DNSSEC public oracle;
    ENS public ens;
    bytes public rootDomain;
    bytes32 public rootNode;

    function DNSRegistrar(DNSSEC _dnssec, ENS _ens, bytes _rootDomain, bytes32 _rootNode) public {
        oracle = _dnssec;
        ens = _ens;
        rootDomain = _rootDomain;
        rootNode = _rootNode;
    }

    function claim(bytes name) public {
        var nameslice = name.toSlice();

        var labelHash = getLabelHash(nameslice);
        require(labelHash != 0);

        var addr = getOwnerAddress(nameslice);
        // Anyone can set the address to 0, but only the owner can claim a name.
        require(addr == 0 || addr == msg.sender);

        ens.setSubnodeOwner(rootNode, labelHash, addr);
    }

    function getLabelHash(BytesUtils.slice memory name) internal constant returns(bytes32) {
        var len = name.uint8At(0);
        // Check this name is a direct subdomain of the one we're responsible for
        if(name.keccak(len + 1, name.len) != keccak256(rootDomain)) {
            return 0;
        }
        return name.keccak(1, len + 1);
    }

    function getOwnerAddress(BytesUtils.slice memory name) internal constant returns(address) {
        // Add "_ens." to the front of the name.
        var subname = BytesUtils.newSlice(name.len + 5);
        subname.writeBytes(0, "\x04_ens");
        subname.memcpy(5, name, 0, name.len);

        // Query the oracle for TXT records
        var rrs = getTXT(subname);

        BytesUtils.slice memory rrname;
        BytesUtils.slice memory rdata;
        for(var (dnstype,,) = rrs.nextRR(rrname, rdata); dnstype != 0; (dnstype,,) = rrs.nextRR(name, rdata)) {
            var addr = parseRR(rdata);
            if(addr != 0) return addr;
        }

        return 0;
    }

    function getTXT(BytesUtils.slice memory name) internal constant returns(BytesUtils.slice memory) {
        uint len;
        uint ptr;
        oracle.rrset(CLASS_INET, TYPE_TXT, name.toBytes());
        assembly {
            // Fetch the pointer to the RR data
            returndatacopy(0, 0x60, 0x20)
            ptr := mload(0)
            // Fetch the RR data length
            returndatacopy(0, ptr, 0x20)
            len := mload(0)
        }
        // Allocate space for the RR data
        var ret = BytesUtils.newSlice(len);
        assembly {
            // Fetch the RR data
            returndatacopy(mload(add(ret, 0x20)), add(ptr, 0x20), len)
        }
        return ret;
    }

    function parseRR(BytesUtils.slice memory rdata) internal pure returns(address) {
        BytesUtils.slice memory segment;

        uint idx = 0;
        var len = rdata.uint8At(idx);
        while(len + idx <= rdata.len) {
            segment._ptr = rdata._ptr + idx + 1;
            segment.len = len;
            var addr = parseString(segment);
            if(addr != 0) return addr;
        }

        return 0;
    }

    function parseString(BytesUtils.slice memory str) internal pure returns(address) {
        // TODO: More robust parsing that handles whitespace and multiple key/value pairs
        if(str.uint32At(0) != 0x613d3078) return 0; // 0x613d3078 == 'a=0x'
        str.s(4, str.len);
        return hexToAddress(str);
    }

    function hexToAddress(BytesUtils.slice memory str) internal pure returns(address) {
        if(str.len < 40) return 0;
        uint ret = 0;
        for(uint i = 0; i < 40; i++) {
            ret <<= 4;
            var x = str.uint8At(i);
            if(x >= 48 && x < 58) {
                ret |= x - 48;
            } else if(x >= 65 && x < 71) {
                ret |= x - 55;
            } else if(x >= 97 && x < 103) {
                ret |= x - 87;
            } else {
                return 0;
            }
        }
        return address(ret);
    }
}