/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

// SPDX-License-Identifier: MIT
// Author: tycoon.eth, thanks to @geraldb & @samwilsn on Github for inspiration!
// Also, thanks to jeremy.eth and @dumbnamenumbers for the review & feedback
// Version: v0.1.4
// Note: The MIT license is for the source code only. Images registered through
// this contract retain all of their owner's rights. This contract
// is a non-profit "library" project and intended to archive & preserve punk
// images, so that they can become widely accessible for decentralized
// applications, including marketplaces, wallets, galleries, etc.
pragma solidity ^0.8.19;
/**

 ███████████                        █████
░░███░░░░░███                      ░░███
 ░███    ░███ █████ ████ ████████   ░███ █████
 ░██████████ ░░███ ░███ ░░███░░███  ░███░░███
 ░███░░░░░░   ░███ ░███  ░███ ░███  ░██████░
 ░███         ░███ ░███  ░███ ░███  ░███░░███
 █████        ░░████████ ████ █████ ████ █████
░░░░░          ░░░░░░░░ ░░░░ ░░░░░ ░░░░ ░░░░░



 ███████████  ████                    █████
░░███░░░░░███░░███                   ░░███
 ░███    ░███ ░███   ██████   ██████  ░███ █████  █████
 ░██████████  ░███  ███░░███ ███░░███ ░███░░███  ███░░
 ░███░░░░░███ ░███ ░███ ░███░███ ░░░  ░██████░  ░░█████
 ░███    ░███ ░███ ░███ ░███░███  ███ ░███░░███  ░░░░███
 ███████████  █████░░██████ ░░██████  ████ █████ ██████
░░░░░░░░░░░  ░░░░░  ░░░░░░   ░░░░░░  ░░░░ ░░░░░ ░░░░░░

            A Registry of 24x24 png images

This contract:

1. Uses the punblocks.sol for storage, contains functions for rendering
the punk blocks.

*/

//import "hardhat/console.sol";


contract RenderBlocks {
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    // Layer defines all possible layers. The order of layering is configured
    //    separately.
    enum Layer {
        Base,      //0 Base is the face. Determines if m or f version will be used to render the remaining layers
        Mouth,     //1 (Hot Lipstick, Smile, Buck Teeth, ...)
        Cheeks,    //2 (Rosy Cheeks)
        Blemish,   //3 (Mole, Spots)
        Eyes,      //4 (Clown Eyes Green, Green Eye Shadow, ...)
        Neck,      //5 (Choker, Silver Chain, Gold Chain)
        Beard,     //6 (Big Beard, Front Beard, Goat, ...)
        Ears,      //7 (Earring)
        HeadTop1,  //8 (Purple Hair, Shaved Head, Beanie, Fedora,Hoodie)
        HeadTop2,  //9 eg. sometimes an additional hat over hair
        Eyewear,   //10 (VR, 3D Glass, Eye Mask, Regular Shades, Welding Glasses, ...)
        MouthProp, //11 (Medical Mask, Cigarette, ...)
        Nose       //12 (Clown Nose)
    }
    struct Block {
        Layer layer; // 13 possible layers
        bytes blockL;// male version of this attribute
        bytes blockS;// female version of this attribute
    }
    mapping (uint32 => mapping(Layer => uint16)) public orderConfig; // layer => seq
    uint32 public nextConfigId;
    uint256 constant private bit2byte  =  0xFFFF00;     // bit mask 2
    uint256 constant private bit3byte  =  0xFFFF000000; // bit mask 3
    IPunkBlocks public pb;                              // 0xe91Eb909203c8C8cAd61f86fc44EDeE9023bdA4D

    /**
    * _pb address of the underlying PunkBlocks storage contract
    */
    constructor(address _pb) {
        // Initial blocks that were sourced from https://github.com/cryptopunksnotdead/punks.js/blob/master/yeoldepunks/yeoldepunks-24x24.png
        pb = IPunkBlocks(_pb);
        // default config
        mapping(Layer => uint16) storage c = orderConfig[0];
        uint8[13] memory order =  [uint8(0),2,3,1,5,6,7,8,9,4,11,10,12];
        for (uint8 i = 0; i < 13; i++) {
            c[Layer(i)] = order[i];
        }
        nextConfigId++;
    }

    /**
    * @dev getBlocks returns a sequential list of blocks in a single call
    * @param _fromID is which id to begin from
    * @param _count how many items to retrieve.
    * @return Block[] list of blocks, uint256 next id
    */
    function getBlocks(
        uint _fromID,
        uint _count) external view returns(IPunkBlocks.PBlock[] memory, uint32) {
        return pb.getBlocks(_fromID, _count);
    }

    /**
    * registerOrderConfig
    */
    function registerOrderConfig(
        Layer[] calldata _order
    ) external {
        mapping(Layer => uint16) storage c = orderConfig[nextConfigId];
        for (uint16 i = 0; i < _order.length; i++) {
            require(c[Layer(i)] == 0, "storage must be empty");
            c[Layer(i)] = uint16(_order[i]);
        }
        nextConfigId++;
    }

    /**
    * _unpackInfo extracts block information
    */
    function _unpackInfo(uint256 _info) pure internal returns(Layer, uint16, uint16) {
        Layer layer = Layer(uint8(_info));
        uint16 l = uint16((_info & bit2byte) >> 8);
        uint16 s = uint16((_info & bit3byte) >> 24);
        return (layer, l, s);
    }

    /**
    * get info about a block
    */
    function info(bytes32 _id) view public returns(IPunkBlocks.Layer, uint16, uint16) {
        return pb.info(_id);
    }

    /**
    * @dev registerBlock allows anybody to add a new block to the contract.
    *   Either _dataL or _dataF, or both, must contain a byte stream of a png file.
    *   It's best if the png is using an 'index palette' and the lowest bit depth possible,
    *   while keeping the highest compression setting.
    * @param _dataL png data for the larger male version, 24x24
    * @param _dataS png data for the smaller female version, 24x24
    * @param _layer 0 to 12, corresponding to the Layer enum type.
    * @param _name the name of the trait, Camel Case. e.g. "Luxurious Beard"
    */
    function registerBlock(
        bytes calldata _dataL,
        bytes calldata _dataS,
        uint8 _layer,
        string memory _name) external {
        pb.registerBlock(_dataL, _dataS, _layer, _name);
    }

    /**
    * @dev svgFromNames returns the svg data as a string
    * @param _attributeNames a list of attribute names, eg "Male 1", "Goat"
    *   must have at least 1 layer 0 attribute (eg. Male, Female, Alien, Ape, Zombie)
    *   e.g. ["Male 1","Goat"]
    *   Where "Male 1" is a layer 0 attribute, that decides what version of
    *   image to use for the higher
    *   layers (dataMale or dataFemale)
    * @param _size the width and height of generated svg, eg. 24
    * @param _orderID which order config to use when rendering, 0 is the default
    */
    function svgFromNames(
        string[] memory _attributeNames,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        uint32 _orderID) external view returns (string memory){
        bool isLarge;
        bytes32[] memory layerKeys = new bytes32[](13);
        for (uint16 i = 0; i < _attributeNames.length; i++) {
            bytes32 hash = keccak256(
                abi.encodePacked(_attributeNames[i]));
            uint256 fo = pb.blocksInfo(hash);
            if (fo == 0) {
                break;
            }
            (Layer l, uint16 sL,) = _unpackInfo(fo);
            layerKeys[uint256(orderConfig[_orderID][l])] = hash;
            if (l == Layer.Base) {
                // base later
                if (sL > 0) {
                    isLarge = true;
                }
            }
        }
        return _svg(layerKeys, _x, _y, _size, isLarge);
    }

    /**
    * @dev svgFromKeys returns the svg data as a string
    * @param _attributeKeys a list of attribute names that have been hashed,
    *    eg keccak256("Male 1"), keccak256("Goat")
    *    must have at least 1 layer 0 attribute (eg. keccak256("Male 1")) which
    *    decides what version of image to use for the higher layers
    *    (dataMale or dataFemale)
    *    e.g. ["0x9039da071f773e85254cbd0f99efa70230c4c11d63fce84323db9eca8e8ef283",
    *    "0xd5de5c20969a9e22f93842ca4d65bac0c0387225cee45a944a14f03f9221fd4a"]
    * @param _size the width and height of generated svg, eg. 24
    * @param _orderID which order config to use when rendering, 0 is the default
    */
    function svgFromKeys(
        bytes32[] memory _attributeKeys,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        uint32 _orderID) external view returns (string memory) {
        bool isLarge;
        bytes32[] memory layerKeys = new bytes32[](13);
        for (uint16 i = 0; i < _attributeKeys.length; i++) {
            uint256 fo = pb.blocksInfo(_attributeKeys[i]);
            if (fo == 0) {
                break;
            }
            (Layer l, uint16 sL,) = _unpackInfo(fo);
            layerKeys[uint256(orderConfig[_orderID][l])] = _attributeKeys[i];
            if (l == Layer.Base) {
                // base later
                if (sL > 0) {
                    isLarge = true;
                }
            }
        }
        return _svg(layerKeys, _x, _y, _size, isLarge);
    }

    /**
    * @dev svgFromIDs returns the svg data as a string
    *   e.g. [9,55,99]
    *   One of the elements must be must be a layer 0 block.
    *   This element decides what version of image to use for the higher layers
    *   (dataMale or dataFemale)
    * @param _ids uint256 ids of an attribute, by it's index of creation
    * @param _size the width and height of generated svg, eg. 24
    * @param _orderID which order config to use when rendering, 0 is the default
    */
    function svgFromIDs(
        uint32[] calldata _ids,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        uint32 _orderID) external view returns (string memory) {
        bool isLarge;
        bytes32[] memory layerKeys = new bytes32[](13);
        for (uint16 i = 0; i < _ids.length; i++) {
            bytes32 hash = pb.index(_ids[i]);
            uint256 fo = pb.blocksInfo(hash);
            if (fo == 0) {
                break;
            }
            (Layer l, uint16 sL,) = _unpackInfo(fo);
            layerKeys[uint256(orderConfig[_orderID][l])] = hash;
            if (l == Layer.Base) {
                // base later
                if (sL > 0) {
                    isLarge = true;
                }
            }
        }
        return _svg(layerKeys, _x, _y, _size, isLarge);
    }

    /**
    * @dev svgFromPunkID returns the svg data as a string given a punk id
    * @param _tokenID uint256 IDs a punk id, 0-9999
    * @param _size the width and height of generated svg, eg. 24
    * @param _orderID which order config to use when rendering, 0 is the default
    */
    function svgFromPunkID(
        uint256 _tokenID,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        uint32 _orderID
    ) external view returns (string memory) {
        // Get the attributes first, using https://github.com/0xTycoon/punks-token-uri
        IAttrParser p = IAttrParser(0xD8E916C3016bE144eb2907778cf972C4b01645fC);
        string[8] memory _attributeNames = p.parseAttributes(_tokenID);
        bool isLarge;
        bytes32[] memory layerKeys = new bytes32[](13);
        for (uint16 i = 0; i < 8; i++) {
            if (bytes(_attributeNames[i]).length == 0) {
                break;
            }
            bytes32 hash = keccak256(
                abi.encodePacked(_attributeNames[i]));
            uint256 fo = pb.blocksInfo(hash);
            if (fo == 0) {
                break;
            }
            (Layer l, uint16 sL,) = _unpackInfo(fo);
            layerKeys[uint256(orderConfig[_orderID][l])] = hash;
            if (l == Layer.Base) {
                // base later
                if (sL > 0) {
                    isLarge = true;
                }
            }
        }
        return _svg(layerKeys, _x, _y, _size, isLarge);
    }


    bytes constant header1 = '<svg class="punkblock" width="';
    bytes constant header2 = '" height="';
    bytes constant header3 = '" x="';
    bytes constant header4 = '" y="';
    bytes constant header5 = '" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" > <style> .pix {image-rendering:pixelated;-ms-interpolation-mode: nearest-neighbor;image-rendering: -moz-crisp-edges;} </style>';
    bytes constant end = '</svg>';
    bytes constant imgStart = '<foreignObject x="0" y="0" width="24" height="24"> <img xmlns="http://www.w3.org/1999/xhtml"  width="100%" class="pix" src="data:image/png;base64,';
    bytes constant imgEnd = '"/></foreignObject>';
    /**
    * @dev _svg build the svg, layer by layer.
    * @return string of the svg image
    */
    function _svg(
        bytes32[] memory _keys,
        uint16 _x,
        uint16 _y,
        uint16 _size,
        bool isLarge
    ) internal view returns (string memory) {
        bytes memory s = bytes(toString(_size));
        DynamicBufferLib.DynamicBuffer memory result;
        result.append(header1, s, header2);
        result.append(s, header3, bytes(toString(_x)));
        result.append(header4, bytes(toString(_y)), header5);
        for (uint256 i = 0; i < 13; i++) {
            if (_keys[i] == 0x0) {
                continue;
            }
            (, uint16 s1, uint16 s2) = info(_keys[i]);
            if (isLarge) {
                if (s1 == 0) {
                    continue; // no data
                }
                result.append(imgStart, bytes(Base64.encode(pb.blockL(_keys[i]))), imgEnd);
            } else {
                if (s2 == 0) {
                    continue; // no data
                }
                result.append(imgStart, bytes(Base64.encode(pb.blockS(_keys[i]))), imgEnd);
            }
        }
        result.append(end);
        return string(result.data);
    }

    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by openzeppelin's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15
        // this version removes the decimals counting
        uint8 count;
        if (value == 0) {
            return "0";
        }
        uint256 digits = 31;
        // bytes and strings are big endian, so working on the buffer from right to left
        // this means we won't need to reverse the string later
        bytes memory buffer = new bytes(32);
        while (value != 0) {
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
            digits -= 1;
            count++;
        }
        uint256 temp;
        assembly {
            temp := mload(add(buffer, 32))
            temp := shl(mul(sub(32,count),8), temp)
            mstore(add(buffer, 32), temp)
            mstore(buffer, count)
        }
        return string(buffer);
    }

    function nextId() view external returns (uint32) {
        return pb.nextId();
    }

}
// IAttrParser implemented by 0x4e776fCbb241a0e0Ea2904d642baa4c7E171a1E9
interface IAttrParser {
    function parseAttributes(uint256 _tokenId) external view returns (string[8] memory);
}

library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
        // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

        // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

        // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
            // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

            // To write each character, shift the 3 bytes (18 bits) chunk
            // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
            // and apply logical AND with 0x3F which is the number of
            // the previous character in the ASCII table prior to the Base64 Table
            // The result is then added to the table to get the character to write,
            // and finally write it in the result pointer but with a left shift
            // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

        // When data `bytes` is not exactly 3 bytes long
        // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }
        return result;
    }
}

/**
* DynamicBufferLib adapted from
* https://github.com/Vectorized/solady/blob/main/src/utils/DynamicBufferLib.sol
*/
library DynamicBufferLib {
    /// @dev Type to represent a dynamic buffer in memory.
    /// You can directly assign to `data`, and the `append` function will
    /// take care of the memory allocation.
    struct DynamicBuffer {
        bytes data;
    }

    /// @dev Appends `data` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(DynamicBuffer memory buffer, bytes memory data)
    internal
    pure
    returns (DynamicBuffer memory)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                let w := not(31)
                let bufferData := mload(buffer)
                let bufferDataLength := mload(bufferData)
                let newBufferDataLength := add(mload(data), bufferDataLength)
            // Some random prime number to multiply `capacity`, so that
            // we know that the `capacity` is for a dynamic buffer.
            // Selected to be larger than any memory pointer realistically.
                let prime := 1621250193422201
                let capacity := mload(add(bufferData, w))

            // Extract `capacity`, and set it to 0, if it is not a multiple of `prime`.
                capacity := mul(div(capacity, prime), iszero(mod(capacity, prime)))

            // Expand / Reallocate memory if required.
            // Note that we need to allocate an exta word for the length, and
            // and another extra word as a safety word (giving a total of 0x40 bytes).
            // Without the safety word, the data at the next free memory word can be overwritten,
            // because the backwards copying can exceed the buffer space used for storage.
                for {} iszero(lt(newBufferDataLength, capacity)) {} {
                // Approximately double the memory with a heuristic,
                // ensuring more than enough space for the combined data,
                // rounding up to the next multiple of 32.
                    let newCapacity :=
                    and(add(capacity, add(or(capacity, newBufferDataLength), 32)), w)

                // If next word after current buffer is not eligible for use.
                    if iszero(eq(mload(0x40), add(bufferData, add(0x40, capacity)))) {
                    // Set the `newBufferData` to point to the word after capacity.
                        let newBufferData := add(mload(0x40), 0x20)
                    // Reallocate the memory.
                        mstore(0x40, add(newBufferData, add(0x40, newCapacity)))
                    // Store the `newBufferData`.
                        mstore(buffer, newBufferData)
                    // Copy `bufferData` one word at a time, backwards.
                        for { let o := and(add(bufferDataLength, 32), w) } 1 {} {
                            mstore(add(newBufferData, o), mload(add(bufferData, o)))
                            o := add(o, w) // `sub(o, 0x20)`.
                            if iszero(o) { break }
                        }
                    // Store the `capacity` multiplied by `prime` in the word before the `length`.
                        mstore(add(newBufferData, w), mul(prime, newCapacity))
                    // Assign `newBufferData` to `bufferData`.
                        bufferData := newBufferData
                        break
                    }
                // Expand the memory.
                    mstore(0x40, add(bufferData, add(0x40, newCapacity)))
                // Store the `capacity` multiplied by `prime` in the word before the `length`.
                    mstore(add(bufferData, w), mul(prime, newCapacity))
                    break
                }
            // Initalize `output` to the next empty position in `bufferData`.
                let output := add(bufferData, bufferDataLength)
            // Copy `data` one word at a time, backwards.
                for { let o := and(add(mload(data), 32), w) } 1 {} {
                    mstore(add(output, o), mload(add(data, o)))
                    o := add(o, w) // `sub(o, 0x20)`.
                    if iszero(o) { break }
                }
            // Zeroize the word after the buffer.
                mstore(add(add(bufferData, 0x20), newBufferDataLength), 0)
            // Store the `newBufferDataLength`.
                mstore(bufferData, newBufferDataLength)
            }
        }
        return buffer;
    }
    /*
        /// @dev Appends `data0`, `data1` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(DynamicBuffer memory buffer, bytes memory data0, bytes memory data1)
    internal
    pure
    returns (DynamicBuffer memory)
    {
        return append(append(buffer, data0), data1);
    }
*/
    /// @dev Appends `data0`, `data1`, `data2` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2
    ) internal pure returns (DynamicBuffer memory) {
        return append(append(append(buffer, data0), data1), data2);
    }
    /*

        /// @dev Appends `data0`, `data1`, `data2`, `data3` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3
    ) internal pure returns (DynamicBuffer memory) {
        return append(append(append(append(buffer, data0), data1), data2), data3);
    }

    /// @dev Appends `data0`, `data1`, `data2`, `data3`, `data4` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4
    ) internal pure returns (DynamicBuffer memory) {
        append(append(append(append(buffer, data0), data1), data2), data3);
        return append(buffer, data4);
    }

    /// @dev Appends `data0`, `data1`, `data2`, `data3`, `data4`, `data5` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4,
        bytes memory data5
    ) internal pure returns (DynamicBuffer memory) {
        append(append(append(append(buffer, data0), data1), data2), data3);
        return append(append(buffer, data4), data5);
    }

    /// @dev Appends `data0`, `data1`, `data2`, `data3`, `data4`, `data5`, `data6` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
    function append(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4,
        bytes memory data5,
        bytes memory data6
    ) internal pure returns (DynamicBuffer memory) {
        append(append(append(append(buffer, data0), data1), data2), data3);
        return append(append(append(buffer, data4), data5), data6);
    }
    */
}

interface IPunkBlocks {
    enum Layer {
        Base,      //0 Base is the face. Determines if m or f version will be used to render the remaining layers
        Mouth,     //1 (Hot Lipstick, Smile, Buck Teeth, ...)
        Cheeks,    //2 (Rosy Cheeks)
        Blemish,   //3 (Mole, Spots)
        Eyes,      //4 (Clown Eyes Green, Green Eye Shadow, ...)
        Neck,      //5 (Choker, Silver Chain, Gold Chain)
        Beard,     //6 (Big Beard, Front Beard, Goat, ...)
        Ears,      //7 (Earring)
        HeadTop1,  //8 (Purple Hair, Shaved Head, Beanie, Fedora,Hoodie)
        HeadTop2,  //9 eg. sometimes an additional hat over hair
        Eyewear,   //10 (VR, 3D Glass, Eye Mask, Regular Shades, Welding Glasses, ...)
        MouthProp, //11 (Medical Mask, Cigarette, ...)
        Nose       //12 (Clown Nose)
    }
    struct PBlock {
        uint8 Layer; // 13 possible layers
        bytes blockL;// male version of this attribute
        bytes blockS;// female version of this attribute
    }
    function blockS(bytes32) view external returns(bytes memory);
    function blockL(bytes32) view external returns(bytes memory);
    function info(bytes32 _id) view external returns(Layer, uint16, uint16);
    function getBlocks(
        uint _fromID,
        uint _count) external view returns(PBlock[] memory, uint32);
    function registerBlock(
        bytes calldata _dataL,
        bytes calldata _dataS,
        uint8 _layer,
        string memory _name) external;
    function blocksInfo(bytes32) external view returns(uint256);
    function index(uint32) external view returns(bytes32);
    function nextId() external view returns(uint32);
}