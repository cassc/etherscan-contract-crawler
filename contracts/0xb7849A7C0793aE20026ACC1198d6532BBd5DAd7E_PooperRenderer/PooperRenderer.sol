/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.13;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    error SSTORE2_DEPLOYMENT_FAILED();
    error SSTORE2_READ_OUT_OF_BOUNDS();

    // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.
    uint256 internal constant DATA_OFFSET = 1;

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Note: The assembly block below does not expand the memory.
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, 1)

            /**
             * ------------------------------------------------------------------------------------+
             *   Opcode  | Opcode + Arguments  | Description       | Stack View                    |
             * ------------------------------------------------------------------------------------|
             *   0x61    | 0x61XXXX            | PUSH2 codeSize    | codeSize                      |
             *   0x80    | 0x80                | DUP1              | codeSize codeSize             |
             *   0x60    | 0x600A              | PUSH1 10          | 10 codeSize codeSize          |
             *   0x3D    | 0x3D                | RETURNDATASIZE    | 0 10 codeSize codeSize        |
             *   0x39    | 0x39                | CODECOPY          | codeSize                      |
             *   0x3D    | 0x3D                | RETURNDATASZIE    | 0 codeSize                    |
             *   0xF3    | 0xF3                | RETURN            |                               |
             *   0x00    | 0x00                | STOP              |                               |
             * ------------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called. Also PUSH2 is
             * used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                data,
                or(
                    0x61000080600a3d393df300,
                    shl(64, dataSize) // shift `dataSize` so that it lines up with the 0000 after PUSH2
                )
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 21), add(dataSize, 10))

            // Restore original length of the variable size `data`
            mstore(data, originalDataLength)
        }

        if (pointer == address(0)) {
            revert SSTORE2_DEPLOYMENT_FAILED();
        }
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        if (pointer.code.length < end) {
            revert SSTORE2_READ_OUT_OF_BOUNDS();
        }

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 63 (32 + 31) to size and running the result through the logic
            // above ensures the memory pointer remains word-aligned, following
            // the Solidity convention.
            mstore(0x40, add(data, and(add(size, 63), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <[email protected]>.
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding)
        internal
        pure
        returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            for { let dataLength := mload(data) } dataLength {} {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(ptr, mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr(6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(input, 0x3F)))

                    ptr := add(ptr, 4) // Advance 4 bytes.

                    if iszero(lt(ptr, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))

                let r := mod(dataLength, 3)

                if iszero(noPadding) {
                    // Offset `ptr` and pad with '='. We can simply write over the end.
                    mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                    mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
                    // Write the length of the string.
                    mstore(result, encodedLength)
                    break
                }
                // Write the length of the string.
                mstore(result, sub(encodedLength, add(iszero(iszero(r)), eq(r, 1))))
                break
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe)
        internal
        pure
        returns (string memory result)
    {
        result = encode(data, fileSafe, false);
    }

    /// @dev Encodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let end := add(data, dataLength)
                let decodedLength := mul(shr(2, dataLength), 3)

                for {} 1 {} {
                    // If padded.
                    if iszero(and(dataLength, 3)) {
                        let t := xor(mload(end), 0x3d3d)
                        // forgefmt: disable-next-item
                        decodedLength := sub(
                            decodedLength,
                            add(iszero(byte(30, t)), iszero(byte(31, t)))
                        )
                        break
                    }
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                    break
                }
                result := mload(0x40)

                // Write the length of the string.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    // forgefmt: disable-next-item
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)

                    if iszero(lt(data, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 32 + 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(add(result, decodedLength), 63), not(31)))

                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IRenderer {
    function renderAttributes(uint256 tokenId) external view returns(string memory);
    function renderSVG(uint256 tokenId) external view returns(string memory);
}

contract ImageScripterSSTORE2 {

    mapping(bytes32 => address) internal _imageScriptPtr;

    // hub stuff
    mapping(bytes32 => address) _id2ElementsPtr; // this is powerful. use this.

    mapping(bytes32 => address) _id2StringPtr; // this is powerful. use this.

    mapping(bytes32 => address) _id2StylePtr; // this is powerful. use this.
    // hub stuff
}

struct Element {
    bytes32 name; // for attributes tie {id <--> name}
    bool groupingOrPath; // grouping means d decodes to Elements[] iterate
    bytes d; 
    // data or 
    //   - array of ids bytes32[]: id -> ptr(Elements) // during construction
    //   or 
    //   - array of ptrs address[]: ptr -> Elements
}

struct Elements {
    bytes32 id; 
    bytes32[] fills; // vary
    Element[] elements; // vary
    string class; // may be longer thant 32
}

struct ImageScript {
    //<style>

    address motionPtr; // ptr -> string

    address[] styleIterPtrs; // M: ptr -> Elements  //M: ptr -> string[]
    //</style>

    address[] elementIterPtrs; // M: ptr -> Elements
}

    
// for efficiency
struct ElementssFormatted {
    bytes32[] ids;
    bytes[] compressedBE; // compressed byte Elements
}

library Compression {

    struct Segment {
        uint256 start;
        uint256 end;
    }

    uint256 constant FLAG_IS_NOT_COMPRESSED = 0x1;
    uint256 constant FLAG_IS_COMPRESSED = 0x2;

    uint256 constant FLAG_ZERO_MASK = 0x0f;
    uint256 constant FLAG_ZERO = 0x03;
    uint256 constant FLAG_NONZERO = 0x04;

    uint256 constant FLAG_LENGTH_MASK = 0xf0;
    uint256 constant FLAG_LENGTH_UINT8 = 0x10;
    uint256 constant FLAG_LENGTH_UINT16 = 0x20;
    uint256 constant FLAG_LENGTH_UINT32 = 0x30;
    uint256 constant FLAG_LENGTH_UINT64 = 0x40;

    // just compresses all zeros 
    function compressZeros(bytes memory input) internal view returns(bytes memory ret) {
        uint256 inputLength = input.length;
        ret = new bytes(inputLength*3); // overdo it
        uint256 retIdx;

        uint256 idx;

        // first find consecutive zeros
        
        uint256 _byte;
        bool inZeroSegment;
        Segment[] memory zeroSegments = new Segment[](inputLength);

        // collect all zero segments
        for (uint256 i; i < inputLength; ++i) {
            _byte = uint256(uint8(input[i]));

            if (_byte == 0) {
                if (!inZeroSegment) { // start of zero segment
                    zeroSegments[idx].start = i;
                    inZeroSegment = true;
                }
            } else {
                if (inZeroSegment) { // is end of zero segment
                    zeroSegments[idx].end = i;
                    inZeroSegment = false;
                    ++idx;
                }
            }
        }
        
        assembly {
            mstore(zeroSegments, idx)
        }

        // we now know all the zero segments
        Segment memory zs;
        uint256 start;
        uint256 end;
        uint256 length;

        for (uint256 i; i < idx; ++i) {
            zs = zeroSegments[i]; 
            end = zs.start;
            ret[retIdx] = bytes1(uint8(FLAG_NONZERO));
            length = end-start;

            retIdx = _setLength(ret, retIdx, length);
            for (uint256 j = start; j < end; ++j) {
                ret[retIdx++] = input[j];
            }
            start = zs.end;

            // zeros
            ret[retIdx] = bytes1(uint8(FLAG_ZERO));
            length = zs.end-zs.start;
            retIdx = _setLength(ret, retIdx, length);
        }
        
        ret[retIdx] = bytes1(uint8(FLAG_NONZERO));
        length = inputLength-zs.end;
        retIdx = _setLength(ret, retIdx, length);
        for (uint256 i = zs.end; i < inputLength; ++i) {
            ret[retIdx++] = input[i];
        }
        if (retIdx < input.length) { // compression was favorable
            ret[retIdx++] = bytes1(uint8(FLAG_IS_COMPRESSED));
            assembly {
                mstore(ret, retIdx)
            }
        } else { // compression was NOT an improvement
            ret = new bytes(inputLength+1);
            assembly {
                mstore(ret, 0)
            }
            _append(ret, input);
            assembly {
                mstore(ret, add(inputLength, 1))
            }
            ret[inputLength] = bytes1(uint8(FLAG_IS_NOT_COMPRESSED));
        }
    } 

    function decompressZeros(bytes memory input) internal pure returns(bytes memory ret) {
        // assumes input is output of `compressZeros`
        uint256 inputLength = input.length;
        require(inputLength > 0, "invalid input len.");
        uint256 isCompressed = uint256(uint8(input[inputLength-1]));
        assembly {
            mstore(input, sub(mload(input), 1))
        }
        if (isCompressed == FLAG_IS_NOT_COMPRESSED) return input;
        --inputLength;

        uint256 totalLength;
        uint256 length;
        uint256 idx;
        uint256 flag;
        
        while (idx < inputLength) {
            flag = uint256(uint8(input[idx])) & FLAG_ZERO_MASK;
            (length, idx) = _getLength(input, idx);
            if (length == 0) {
                continue;
            }
            totalLength += length; 
            if (flag == FLAG_NONZERO){
                idx += length;
            }
        }
        idx = 0;
        ret = new bytes(totalLength);
        uint256 retIdx;
        while (idx < inputLength) {
            flag = uint256(uint8(input[idx])) & FLAG_ZERO_MASK;
            (length, idx) = _getLength(input, idx);
            if (length == 0) {
                continue;
            }
            if (flag == FLAG_ZERO) {
                retIdx += length;
                continue;
            } else if (flag == FLAG_NONZERO){
                for (uint256 i; i < length; ++i) {
                    ret[retIdx++] = input[i+idx]; 
                }
                idx += length; 
            } else {
                revert("should not happen :(");
            }
        }
    }
    
    function _setLength(bytes memory arr, uint256 arrIdx, uint256 length) private pure returns(uint256) {
        uint256 bound;
        if (length < type(uint8).max) {
            arr[arrIdx++] |= bytes1(uint8(FLAG_LENGTH_UINT8));
            bound = 1;
        } else if (length < type(uint16).max) {
            arr[arrIdx++] |= bytes1(uint8(FLAG_LENGTH_UINT16));
            bound = 2;
        } else if (length < type(uint32).max) { 
            arr[arrIdx++] |= bytes1(uint8(FLAG_LENGTH_UINT32));
            bound = 4;
        } else if (length < type(uint64).max) { 
            arr[arrIdx++] |= bytes1(uint8(FLAG_LENGTH_UINT64));
            bound = 8;
        } else {
            revert("_setLength:unsupportedLength");
        }
        for (uint256 i; i < bound; ++i) {
            arr[arrIdx++] = bytes1(uint8(length >> (8*i)));
        }
        return arrIdx;
    }

    function _getLength(bytes memory arr, uint256 arrIdx) private pure returns(uint256, uint256) {
        uint256 flagLength = uint256(uint8(arr[arrIdx++])) & FLAG_LENGTH_MASK; 
        uint256 bound;
        if (flagLength == FLAG_LENGTH_UINT8) {
            bound = 1;
        } else if (flagLength == FLAG_LENGTH_UINT16) {
            bound = 2;
        } else if (flagLength == FLAG_LENGTH_UINT32) { 
            bound = 4;
        } else if (flagLength == FLAG_LENGTH_UINT64) { 
            bound = 8;
        } else {
            revert("_getLength:unsupportedLength");
        }
        uint256 length;
        for (uint256 i; i < bound; ++i) {
            length |= uint256(uint8(arr[arrIdx++])) << (8*i);
        }
        return (length, arrIdx);
    }
    
    // cheaper than bytes concat :)
    function _append(bytes memory dst, bytes memory src) private view {
      
        assembly {
            // resize

            let priorLength := mload(dst)
            
            mstore(dst, add(priorLength, mload(src)))
        
            // copy    

            pop(
                staticcall(
                  gas(), 4, 
                  add(src, 32), // src data start
                  mload(src), // src length 
                  add(dst, add(32, priorLength)), // dst write ptr
                  mload(dst)
                ) 
            )
        }
    }
}

contract PooperRenderer is IRenderer, ImageScripterSSTORE2, Ownable {

    mapping(address => bool) internal _hasCallerRole;
    mapping(address => bytes32) internal _contractLink;

    constructor() {
        _hasCallerRole[owner()] = true;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner(), "not owner.");
    }

    function _onlyHasCallerRole() private view {
        require(_hasCallerRole[msg.sender], "msg.sender !_hasCallerRole.");
    }

    function _onlyLinkedContract() private view {
        require(bytes(abi.encodePacked(_contractLink[msg.sender])).length > 0, "caller not linked.");
    }

    function grantCallerRole(address account) external {
        _onlyOwner();
        _grantCallerRole(account);
    }

    function _grantCallerRole(address account) private {
        _hasCallerRole[account] = true;
    }

    function linkContract(address contract_, bytes32 imageScriptPtrName) external {
        _onlyOwner();
        _linkContract(contract_, imageScriptPtrName);
    }
    
    function _linkContract(address contract_, bytes32 imageScriptPtrName) private {
        _contractLink[contract_] = imageScriptPtrName;
    }

    string constant SVG_HEADER = ""
"    <svg version=\"1.1\""
"     baseProfile=\"full\""
"     viewBox=\"0 0 100 100\""
"     xmlns=\"http://www.w3.org/2000/svg\""
"     >"
     "";

    string constant SVG_FOOTER = "</svg>";

    function _getSeed(uint256 tokenId) private view returns(uint256) {
        address caller = msg.sender;
        return uint256(keccak256(abi.encodePacked(tokenId, caller)));
    }

    function getMaxDistinctTokens() external returns(uint256) {
        _onlyHasCallerRole();
        _onlyLinkedContract();
        address caller = msg.sender;
        return _getMaxDistinctTokens(_contractLink[msg.sender]);
    }

    function getMaxDistinctTokens(bytes32 name) external returns(uint256) {
        _onlyOwner();
        return _getMaxDistinctTokens(name); 
    }

    function _getMaxDistinctTokens(bytes32 name) private returns(uint256 tally) {
        ImageScript memory script = abi.decode(_read(_imageScriptPtr[name]), (ImageScript));
        uint256 elementIterPtrsLength = script.styleIterPtrs.length;
        Elements memory elements;
        tally = 1;
        for (uint256 i; i < elementIterPtrsLength; ++i) {
            elements = abi.decode(_read(script.styleIterPtrs[i]), (Elements));
            tally *= _getMaxDistinctTokens(elements);
        }
        elementIterPtrsLength = script.elementIterPtrs.length;
        for (uint256 i; i < elementIterPtrsLength; ++i) {
            elements = abi.decode(_read(script.elementIterPtrs[i]), (Elements));
            tally *= _getMaxDistinctTokens(elements);
        }
    }

    function _getMaxDistinctTokens(Elements memory e) private returns(uint256 tally) {
        Element memory element;
        uint256 elementsLength = e.elements.length;
        tally = elementsLength; // this is the most crucial line in this count
        for (uint256 i; i < elementsLength; ++i) {
            element = e.elements[i];
            tally *= (e.fills.length > 0) ? e.fills.length : 1;

            tally *= (element.groupingOrPath) ? _getMaxDistinctTokens(element) : 1;
        }
    }

    function _getMaxDistinctTokens(Element memory e) private returns(uint256) {
        if (e.groupingOrPath) {
            address[] memory toGroupPtrs = abi.decode(e.d, (address[]));
            
            uint256 toGroupPtrsLength = toGroupPtrs.length;
            Elements memory elts;
            uint256 tally = 1;
            for (uint256 i; i < toGroupPtrsLength; ++i) {
                elts = abi.decode(_read(toGroupPtrs[i]), (Elements));
                tally *= _getMaxDistinctTokens(elts);
            }
            return tally;
        }
        revert("_getMaxDistinctTokens: only for groupings.");
    }

    function renderAttributes(uint256 tokenId) external view returns(string memory) {
        _onlyHasCallerRole();
        _onlyLinkedContract();
        
        ImageScript memory script = abi.decode(_read(_imageScriptPtr[_contractLink[msg.sender]]), (ImageScript));

        uint256 seed = _getSeed(tokenId);
        return _getAttributes(script, seed); // "csv", so whomever ingests may need to ignore last comma
    }

    // encoding is done by caller
    function renderSVG(uint256 tokenId) external view returns(string memory) {
        _onlyHasCallerRole();
        _onlyLinkedContract();
        return string(_renderSVG(tokenId)); 
    }

    function _renderSVG(uint256 tokenId) private view returns(bytes memory) {

        ImageScript memory script = abi.decode(_read(_imageScriptPtr[_contractLink[msg.sender]]), (ImageScript));

        uint256 seed = _getSeed(tokenId);

        return abi.encodePacked(
            SVG_HEADER,
            _getStyles(script, seed),
            _getPaths(script, seed),
            SVG_FOOTER 
        );
    }

    function _getStyles(ImageScript memory script, uint256 seed) private view returns(string memory) {
        require(script.motionPtr != address(0), "motionPtr not set.");
        string memory style;
        uint256 styleIterPtrsLength = script.styleIterPtrs.length;
        Elements memory e;
        Element[] memory elts;
        for (uint256 i; i < styleIterPtrsLength; ++i) {
            e = abi.decode(_read(script.styleIterPtrs[i]), (Elements));
            elts = e.elements;
            style = string(abi.encodePacked(style, _choose(elts, seed, e.id, "element").d));
        }
        return string(abi.encodePacked("<style>",
                      _read(script.motionPtr),
                      style, 
                      "</style>"));    
    }

    function _getPaths(ImageScript memory script, uint256 seed) private view returns(string memory ret) {
        uint256 elementIterPtrsLength = script.elementIterPtrs.length;
        for (uint256 i; i < elementIterPtrsLength; ++i) {
            Elements memory elements = abi.decode(_read(script.elementIterPtrs[i]), (Elements));
            ret = string(abi.encodePacked(ret, _toString(elements, seed)));
        }
    }

    function _toString(Elements memory e, uint256 seed) private view returns(string memory ret) {
      
        Element memory element = _choose(e.elements, seed, e.id, "element");
        bool groupingOrPath = element.groupingOrPath;
        (string memory prefix, 
         string memory prePostfix, 
         string memory postfix) = (groupingOrPath) ? ("<g ", ">", "</g>") : ("<path ", "", "/>"); 
        return string(abi.encodePacked(
            prefix,
            "id=\"", _toString(e.id), 
            "\" class=\"", e.class,
            "\" fill=\"", _toString(_choose(e.fills, seed, e.id, "fill")), "\" ",
            prePostfix,
            _toString(element, seed),
            postfix
        ));
    }

    // can this be more efficient??
    function _toString(bytes32 b) private pure returns(string memory ret) {
        if (b == 0x0) return "";
        ret = string(abi.encodePacked(b)); 
        unchecked{
        for (uint256 i = 1; i < 32; ++i) {
            if (bytes(ret)[i] == 0x0) {
                assembly {
                    mstore(ret, i)
                } 
                break;
            }
        } 
        }//uc
    }

    function _toString(Element memory e, uint256 seed) private view returns(string memory) {
        if (e.groupingOrPath) {
            address[] memory toGroupPtrs = abi.decode(e.d, (address[]));
            
            string memory ret;
            uint256 toGroupPtrsLength = toGroupPtrs.length;
            Elements memory elts;
            for (uint256 i; i < toGroupPtrsLength; ++i) {
                elts = abi.decode(_read(toGroupPtrs[i]), (Elements));
                ret = string(abi.encodePacked(ret, _toString(elts, seed))); 
            }
            return ret;
        }
        return string(abi.encodePacked("d=\"", e.d, "\" "));
    }

    // opensea compatibility
    // note: using _toString() for bytes32 elements is CRUCIAL for decoding in the browser
    function _traitTypeString(bytes32 traitType, bytes32 value) private pure returns(string memory) {
        return string(abi.encodePacked(
          "{\"trait_type\": \"", 
          _toString(traitType), 
          "\", \"value\": \"", 
          _toString(value),"\"}"
        )); 
    }
    
    function _traitTypeString(string memory traitType, bytes32 value) private pure returns(string memory) {
        return string(abi.encodePacked(
            "{\"trait_type\":\"", traitType, 
            "\",\"value\":\"", _toString(value), "\"}"
        )); 
    }

    function _toAttributeString(Elements memory e, uint256 seed) private view returns(string memory ret) {
        Element memory element = _choose(e.elements, seed, e.id, "element");
        if (element.name != 0x0)
            ret = string(abi.encodePacked(_traitTypeString(e.id, element.name), ","));
        if (e.fills.length > 1) 
            ret = string(abi.encodePacked(
                            ret,
                            _traitTypeString(
                            string(abi.encodePacked(_toString(e.id), "-fill")), 
                            _choose(e.fills, seed, e.id, "fill")), 
                            ","));

        bool groupingOrPath = element.groupingOrPath;
        if (groupingOrPath) 
            ret = string(abi.encodePacked(ret, _toAttributeString(element, seed)));

    }

    function _toAttributeString(Element memory e, uint256 seed) private view returns(string memory ret) {
        if (e.groupingOrPath) {
            address[] memory toGroupPtrs = abi.decode(e.d, (address[]));
            
            uint256 toGroupPtrsLength = toGroupPtrs.length;
            Elements memory elts;
            for (uint256 i; i < toGroupPtrsLength; ++i) {
                elts = abi.decode(_read(toGroupPtrs[i]), (Elements));
                ret = string(abi.encodePacked(ret, _toAttributeString(elts, seed))); 
            }
            return ret;
        }
        revert("_toAttributeString: only for groupings.");
    }

    function _getAttributes(ImageScript memory script, uint256 seed) private view returns(string memory ret) {
        uint256 elementIterPtrsLength = script.styleIterPtrs.length;
        Elements memory elements;
        for (uint256 i; i < elementIterPtrsLength; ++i) {
            elements = abi.decode(_read(script.styleIterPtrs[i]), (Elements));
            ret = string(abi.encodePacked(ret, _toAttributeString(elements, seed)));
        }
        elementIterPtrsLength = script.elementIterPtrs.length;
        for (uint256 i; i < elementIterPtrsLength; ++i) {
            elements = abi.decode(_read(script.elementIterPtrs[i]), (Elements));
            ret = string(abi.encodePacked(ret, _toAttributeString(elements, seed)));
        }
    }

    function _choose(Element[] memory e, uint256 seed, bytes32 id, string memory name) private pure returns(Element memory) {
        seed = uint256(keccak256(abi.encode(seed, id, name))); // not packed :)
        return e[seed % e.length]; // e should NEVER have length 0
    }

    function _choose(bytes32[] memory e, uint256 seed, bytes32 id, string memory name) private pure returns(bytes32) {
        if (e.length == 0) return ""; // this is used for "fill" and things that can be "null"
        seed = uint256(keccak256(abi.encode(seed, id, name))); // not packed :)
        return e[seed % e.length];
    }

    // hub stuff

    function _setImageScript(bytes memory compressedImageScript, bytes32 name) private {
        _imageScriptPtr[name] = SSTORE2.write(compressedImageScript);
    }

    // motion
    function setMotion(bytes calldata compressedBStyle, bytes32 id) external {
        _onlyOwner();
        _id2StringPtr[id] = SSTORE2.write(compressedBStyle);
    }

    function getStringPtr(bytes32 id) external view returns(address) {
        _onlyOwner();
        return _getStringPtr(id);
    }

    function _getStringPtr(bytes32 id) private view returns(address) {
        return _id2StringPtr[id];
    }

    // style
    function formatStyle(Elements[] memory eltss, bytes32[] memory ids) external returns(bytes memory) {
        _onlyOwner();
        uint256 length = eltss.length;
        require(length == ids.length, "wrong lens.");
        bytes[] memory preRet = new bytes[](length);
        for (uint256 i; i < length; ++i) {
            preRet[i] = abi.encode(ids[i], Compression.compressZeros(abi.encode(eltss[i])));
        }
        return abi.encode(preRet);
    }
    
    function setStyle(bytes calldata formatted) external {
        _onlyOwner();
        bytes[] memory bArr = abi.decode(formatted, (bytes[]));
        uint256 length = bArr.length;
        bytes32 id;
        bytes memory compressedBStyle;
        for (uint256 i; i < length; ++i) {
            (id, compressedBStyle) = abi.decode(bArr[i], (bytes32, bytes)); 
            _setStyle(compressedBStyle, id);
        }
    }

    function _setStyle(bytes memory compressedBStyle, bytes32 id) private {
        _id2StylePtr[id] = SSTORE2.write(compressedBStyle);
    }

    function getStylePtr(bytes32 id) external view returns(address) {
        _onlyOwner();
        return _getStylePtr(id);
    }
    
    function _getStylePtr(bytes32 id) private view returns(address) {
        return _id2StylePtr[id];
    }

    // elements
    function formatElementss(bytes calldata bbE) external view returns(ElementssFormatted memory ret) {
        _onlyOwner();
        bytes[] memory bE = abi.decode(bbE, (bytes[]));
        return _formatElementss(bE);
    }

    function _formatElementss(bytes[] memory bE) private view returns(ElementssFormatted memory ret) {
        // using bytes for ease on js layer
        uint256 len = bE.length;
        bytes32[] memory ids = new bytes32[](len); 
        Elements memory e;
        bytes[] memory compressedBEltss = new bytes[](len);
        for (uint256 i; i < len; ++i) {
            e = abi.decode(bE[i], (Elements));
            require(e.id != 0x0, "elements need id!!");
            ids[i] = e.id;
            compressedBEltss[i] = Compression.compressZeros(abi.encode(_format(e)));
        }
        ret.ids = ids;
        ret.compressedBE = compressedBEltss;
    }

    function _format(Elements memory e) private view returns(Elements memory ret) {
        Element[] memory elts = e.elements; 
        uint256 eltsLength = elts.length;
        Element[] memory retElts = new Element[](eltsLength); 
        for (uint256 i; i < eltsLength; ++i) {
            retElts[i] = _format(elts[i]);
        }
        ret.id = e.id;
        ret.fills = e.fills;
        ret.elements = retElts;
        ret.class = e.class;
    }

    function _format(Element memory e) private view returns(Element memory ret) {
        bytes memory retData;
        if (e.groupingOrPath) {
            bytes32[] memory ids = abi.decode(e.d, (bytes32[])); 
            uint256 idsLength = ids.length;
            address[] memory retPtrs = new address[](idsLength);
            for (uint256 i; i < idsLength; ++i) {
                retPtrs[i] = _getElementsPtr(ids[i]);
            }
            retData = abi.encode(retPtrs);
        } else {
            retData = e.d;
        }
        ret.name = e.name;
        ret.groupingOrPath = e.groupingOrPath;
        ret.d = retData;
    }

    function setElementss(ElementssFormatted calldata ef) external {
        _onlyOwner();
        // note this is unchecked where the mapping can be overwritten
        uint256 eLength = ef.ids.length;
        bytes[] memory compressedBE = ef.compressedBE;
        unchecked{
        for (uint256 i; i < eLength; ++i) {
            _id2ElementsPtr[ef.ids[i]] = SSTORE2.write(compressedBE[i]);
        }
        }//uc
    }

    function getElementsPtr(bytes32 id) external view returns(address) {
        _onlyOwner();
        return _getElementsPtr(id);
    } 
    
    function _getElementsPtr(bytes32 id) private view returns(address) {
        return _id2ElementsPtr[id];
    } 

    // callStatic!!
    function buildImageScript(bytes32 motion, bytes32[] memory styles, bytes32[] memory ids) external view returns(bytes memory) {
        _onlyOwner();
        ImageScript memory _is;
        _is.motionPtr = _getStringPtr(motion);
        
        _is.styleIterPtrs = new address[](styles.length);
        for (uint256 i; i < styles.length; ++i) {
            _is.styleIterPtrs[i] = _getStylePtr(styles[i]); 
        }
        _is.elementIterPtrs = new address[](ids.length);
        for (uint256 i; i < ids.length; ++i) {
            _is.elementIterPtrs[i] = _getElementsPtr(ids[i]); 
        }
        return Compression.compressZeros(abi.encode(_is));
    }

    function setImageScript(bytes memory compressedImageScript/*ImageScript memory _is*/, bytes32 name, address caller) external {
        _onlyOwner();
        _setImageScript(compressedImageScript, name);
        _linkContract(caller, name);
        _grantCallerRole(caller);
    }

    // read and decompress
    function _read(address ptr) private view returns(bytes memory) {
            return Compression.decompressZeros(SSTORE2.read(ptr));
    }
}