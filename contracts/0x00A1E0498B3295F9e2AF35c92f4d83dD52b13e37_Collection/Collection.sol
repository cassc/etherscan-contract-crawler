/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
// File: contracts/external/Strings.sol

// OpenZeppelin Contracts v4.3.2 (utils/Strings.sol)


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// File: contracts/Ownable.sol

// Copyright 2017 Loopring Technology Limited.


/// @title Ownable
/// @author Brecht Devos - <[email protected]>
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        virtual
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

// File: contracts/Claimable.sol

// Copyright 2017 Loopring Technology Limited.



/// @title Claimable
/// @author Brecht Devos - <[email protected]>
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable
{
    address public pendingOwner;

    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        override
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/IPriceOracle.sol



/**
 * @title ICollection
 */
abstract contract IPriceOracle {
    function getPrice(
        address baseTokenAddress,
        uint128 baseAmount,
        uint32 secondsAgo,
        uint256 defaultPrice
    ) public view virtual returns (uint256 price);
}

// File: ../contracts/Collection.sol



//import "./ICollection.sol";




/**
 * @title Collection
 *
 * Devs: currently `is ICollection*` is commented out because I haven't found a good way
 * to share the interface contract between different solidity versions. The Collection
 * contracts are compiled with solidity 0.7 because of the dependency on the uniswap
 * oracle lib, and the main NFT contracts are compiled with solidity 0.8 because it
 * uses the latest openzeppelin versions of the contract. The interface is used by
 * both set of contracts which currently makes the compilation fail when used by both
 * sets of contracts.
 */
contract Collection is Claimable
{
    using Strings for uint;

    uint32 public CURRENT_PRICE_SECONDS_AGO = 5 minutes;
    uint32 public PREVIOUS_PRICE_SECONDS_AGO = 5 hours;
    IPriceOracle public priceOracle;
    uint32  immutable public /*override*/ collectionID;
    uint128 immutable public baseAmount;
    uint    public initPrice;
    address immutable public baseTokenAddress;
    string public baseTokenURI;

    int[] public priceLevels;
    int[] public relativeLevels;

    constructor(
        uint32                  _collectionID,
        string  memory          _baseTokenURI,
        IPriceOracle            _priceOracle,
        address                 _baseTokenAddress,
        uint128                 _baseAmount,
        uint                    _initPrice,
        int[]   memory          _priceLevels,
        int[]   memory          _relativeLevels
        )
    {
        collectionID = _collectionID;
        baseTokenURI = _baseTokenURI;
        priceOracle = _priceOracle;
        baseTokenAddress = _baseTokenAddress;
        baseAmount = _baseAmount;
        initPrice = _initPrice;
        priceLevels = _priceLevels;
        relativeLevels = _relativeLevels;
    }

    function setParams(uint _initPrice, uint32 _currentPriceSecondsAgo, uint32 _previousPriceSecondsAgo) external onlyOwner {
        initPrice = _initPrice;
        PREVIOUS_PRICE_SECONDS_AGO = _previousPriceSecondsAgo;
        CURRENT_PRICE_SECONDS_AGO = _currentPriceSecondsAgo;
    }

    function setPriceOracle(IPriceOracle _priceOracle) external onlyOwner {
        priceOracle = _priceOracle;
    }


    function tokenURI(uint256 tokenId)
        //override
        public
        view
        returns (string memory)
    {
        // Data format:
        // -  4 bytes: collection ID
        // - 16 bytes: base price
        // - 12 bytes: id
        require(uint32((tokenId >> 224) & 0xFFFFFFFF) == collectionID, "inconsistent collection id");
        
        uint basePrice = initPrice;

        uint currentPrice = getPrice(CURRENT_PRICE_SECONDS_AGO, basePrice);
        uint previousPrice = getPrice(PREVIOUS_PRICE_SECONDS_AGO, currentPrice);

        uint baseLevel = getBaseLevel(currentPrice, basePrice);
        uint relativeLevel = getRelativeLevel(currentPrice, previousPrice);

        return string(
            abi.encodePacked(
                baseTokenURI,
                "/",
                tokenId.toString(),
                "/",
                baseLevel.toString(),
                "_",
                relativeLevel.toString(),
                "/metadata.json"
            )
        );
    }

    function getPrice(uint32 secondsAgo, uint defaultPrice)
        public
        view
        returns (uint price)
    {
        // Currently returns the AVERAGE price over the passed in duration.
        // Can be changed but I think this should work well.
        return priceOracle.getPrice(baseTokenAddress, baseAmount, secondsAgo, defaultPrice);
    }

    function getRelativeLevel(uint currentPrice, uint previousPrice)
        public
        view
        returns (uint level)
    {
        int change = int(currentPrice) - int(previousPrice);
        uint basePrice = (currentPrice >= previousPrice) ? previousPrice : currentPrice;
        if (basePrice != 0) {
            change = (change * 100) / int(basePrice);
        }
        return getRangeLevel(relativeLevels, change);
    }

    function getBaseLevel(uint currentPrice, uint basePrice)
        public
        view
        returns (uint level)
    {
        int change = int(currentPrice) - int(basePrice);
        return getRangeLevel(priceLevels, change);
    }

    function getRangeLevel(int[] memory levels, int value)
        public
        pure
        returns (uint level)
    {
        for (uint i = 0; i < levels.length; i++) {
            if (value < levels[i]) {
                return i;
            }
        }
        return levels.length;
    }

    

}