// SPDX-License-Identifier: MIT
// Creator: https://degen.beauty

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 @title AllowlistSale contract
 @dev AllowlistSale can manage multiple pre-defined sales with:
 *        - fixed or open ended time intervals
 *        - fixed price
 *        - quantity limit per transaction
 *        - allowlists with signature verification (we choose this method since it's more cost
 *          efficient with lists larger than 127 members than merkle trees)
 *        - public sales without signature verification
 *    This contracts aims to handle the needed verifications and also to provide a flexible dynamic
 *    configuration option.
 */
contract AllowlistSale {
    using ECDSA for bytes32;

    struct SaleConfig {
        /**
         @dev dates are in unix timestamp format, example: 1650230067
         *    one of the usable converters: https://www.epochconverter.com/
         */
        uint256 startDate;        // start of the sale 0 means it hasn't been started yet
        uint256 endDate;          // end of the sale 0 means it is open ended
        uint256 price;            // price of one item
        uint256 maxSgnUsage;      // defines how many times a siganture can be used
        uint256 quantityLimit;    // how many tokens can be minted part of one transaction
        address signer;           // address that is used to sign the saleKeys
        bool isPublicSale;        // if it's true the signer will not be checked
        bool checkUsedKeys;       // if it's false saleKeys not stored after mint, making it cheaper
        bool exists;              // @dev to be able to delete sales
    }

    /**
     @dev contains the added saleConfigs by sale ids
     */
    mapping(uint256 => SaleConfig) public saleConfig;

    /**
     @dev Record of already-used signatures, used when every saleKey can be used only once
     */
    mapping(bytes => uint256) public usedKeys;

    /**
     @dev adds a new sale with the id and config to the available sales
     */
    function _addSale(uint256 id, SaleConfig memory config) internal virtual {
        saleConfig[id] = config;
    }

    /**
     @dev deletes the saleConfig for the given id
     */
    function _removeSale(uint256 id) internal virtual {
        saleConfig[id].exists = false;
    }

    /**
     @dev returns true if the current date is between the sale start and end date
     *      - start date is 0 means the sale is inactive -> returns false
     *      - end date is 0 means it is an open ended sale no need to check end date
     */
    function verifySaleDate(uint256 saleId) internal virtual view {
        SaleConfig memory sale = saleConfig[saleId];
        require(sale.exists, "invalid saleId");
        require(sale.startDate != 0 && block.timestamp > sale.startDate, "sale has not been started yet");
        require(sale.endDate == 0 || block.timestamp < sale.endDate, "sale has been ended");
    }

    /**
     @dev returns true if the provided saleKey is valid 
     *      - address in the key matches with the sender's address
     *      - it is signed with the stored signer address
     *      - returns true when the sale is a public sale
     */
    function verifySaleKey(bytes memory saleKey, uint256 saleId) internal virtual {
        SaleConfig memory sale = saleConfig[saleId];
        require(sale.isPublicSale || 
                (usedKeys[saleKey] < sale.maxSgnUsage && checkSignature(sale.signer, msg.sender, saleKey)),
                "address with this key is not eligible to mint or saleKey has been already used");

        if (saleConfig[saleId].checkUsedKeys) {
            usedKeys[saleKey] += 1;
        }
    }

    /**
     @dev verifies if the requested quantity is available for the sender 
     *      - quantity should be less than the limit in the saleConfig
     *      - price should be at least the salePrice * quantity
     */
    function verifyQuantity(uint256 quantity, uint256 saleId) internal virtual view {
        require(quantity <= saleConfig[saleId].quantityLimit, "sale limit is exceeded for this transaction");
        require(quantity * saleConfig[saleId].price <= msg.value, "not enough value was sent to complete the purchase");
    }

    /**
     @dev verify runs the previous checks in one place to simplify the usage:
     *      - verifySaleDate
     *      - verifySaleKey
     *      - verifyQuantity & price
     */
    function verify(uint256 quantity, bytes memory saleKey, uint256 saleId) internal virtual {
        verifySaleDate(saleId);
        verifySaleKey(saleKey, saleId);
        verifyQuantity(quantity, saleId);
    }

    /**
     @dev verifyPublicSale runs the previous checks without the saleKey verification:
     *      - verifySaleDate
     *      - verifyQuantity & price
     */
    function verifyPublicSale(uint256 quantity, uint256 saleId) internal virtual view {
        verifySaleDate(saleId);
        verifyQuantity(quantity, saleId);
    }

    /**
     @dev verifies the sent signature against the signer and sender address
     */
    function checkSignature(address signer, address sender, bytes memory signature) private pure returns (bool) {
        return signer == 
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(uint256(uint160(sender))) // creates the 0x000000000000000000000000<sender> expected format
                )
            ).recover(signature);
    }

    /**
     @notice returns the sale config for a given saleId
     */
    function getSale(uint256 saleId) public view returns (SaleConfig memory) {
        require(saleConfig[saleId].exists, "invalid saleId");
        return saleConfig[saleId];
    }
}