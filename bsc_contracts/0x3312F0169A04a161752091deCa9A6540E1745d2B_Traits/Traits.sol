/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File contracts/IMosaicRewardNft.sol

// -License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IMosaicRewardNft {
    event TokenTraitsUpdated(uint256 tokenId, uint8 traitId);

    function getMintedTraitsByAddress(address to) 
        external 
        view 
        returns(uint8[] memory);

    function getMintedTraitsByUUID(bytes16 uuid)
        external
        view
        returns(uint8[] memory);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (uint8);

    // function getTokens(address to) 
    //     external 
    //     view 
    //     returns(uint256[] memory);

    function setExclusiveId(uint8 faceId)
        external;
}


// File contracts/ITraits.sol

pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getTraits() external view returns (uint8[] memory);
    function getTrait(uint8 traitId) external view returns (Trait memory);
    struct Trait {
        uint8 id;
        string name;
        string imageUri;
        string[] traitTypes;
        string[] traitValues;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// -License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]

// -License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

// -License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File contracts/Traits.sol

// -License-Identifier: MIT LICENSE

pragma solidity 0.8.9;




contract Traits is Ownable, ITraits {
    using Strings for uint256;

    // storage of each traits
    mapping(uint8 => Trait) public traits;
    // store ids of traits
    uint8[] public traitIds;

    // mapping from number to string
    string[] numToString;

    IMosaicRewardNft public nft;

    constructor() {
        for (uint256 i = 0; i <= 100; i++) {
            numToString.push(i.toString());
        }
    }

    function addNumbers(uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            numToString.push((numToString.length).toString());
        }
    }

    /** ADMIN */

    function setNftContract(address _m) external onlyOwner {
        nft = IMosaicRewardNft(_m);
    }

    function uploadTrait(
        uint8 id,
        string memory name,
        string memory imageUri,
        string[] calldata traitTypes,
        string[] calldata traitValues
    ) external onlyOwner {
        Trait memory t;
        t.id = id;
        t.name = name;
        t.imageUri = imageUri;
        t.traitTypes = traitTypes;
        t.traitValues = traitValues;
        traits[id] = t;
        traitIds.push(id);
    }

    function updateTrait(
        uint8 id,
        string memory imageUri
    ) external onlyOwner {
        traits[id].imageUri = imageUri;
    }

    function attributeForTypeAndValue(
        string memory traitType,
        string memory value
    ) internal pure returns (string memory) {
        return attributeForTypeAndValue(traitType, value, true, false);
    }

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     *  traitType the trait type to reference as the metadata key
     *  value the token's trait associated with the key
     *  a JSON dictionary for the single attribute
     */
    function attributeForTypeAndValue(
        string memory traitType,
        string memory value,
        bool isString,
        bool displayAsNumber
    ) internal pure returns (string memory)  {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    displayAsNumber ? '","display_type":"number' : '',
                    isString ? '","value":"' : '","value":',
                    value,
                    isString ? '"},' : '},'
                )
            );
    }

    /**
     * generates an array composed of all the individual traits and values
     * @param tokenId the ID of the token to compose the metadata for
     * @return a JSON array of all of the attributes for given token ID
     */
    function compileAttributes(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        uint8 traitId = nft.getTokenTraits(tokenId);
        Trait memory trait = traits[traitId];
        string memory result;
        for(uint i = 0; i < trait.traitTypes.length; i++){
            result = string(abi.encodePacked(result,attributeForTypeAndValue(trait.traitTypes[i], trait.traitValues[i])));
        }
        
        return
            string(
                abi.encodePacked(
                    "[",
                    result,
                    "]"
                )
            );
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint8 traitId = nft.getTokenTraits(tokenId);
        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                "Mosaic Wallet Reward NFT #",
                tokenId.toString(),
                '", "description": "Mosaic Wallet rewards NFT, https://mosaicalpha.com", "image": "',
                // base64(bytes(drawSVG(tokenId))),
                traits[traitId].imageUri,
                '", "attributes":',
                compileAttributes(tokenId),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    /**
     * Get the uploaded trait ids
     * @return a uint8 array contains the available trait ids
     */
    function getTraits()
        external
        view
        returns(uint8[] memory)
    {
        return traitIds;
    }

    /**
     * get the uploaded trait data by uique id
     * @return a Trait object that contains metadata values
     */
    function getTrait(uint8 traitId) 
        external 
        view 
        returns (Trait memory)
    {
        return traits[traitId];
    }

    /** BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}