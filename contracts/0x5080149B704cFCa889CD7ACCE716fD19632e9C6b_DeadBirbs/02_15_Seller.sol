// SPDX-License-Identifier: MIT
// Creator: deadbirbs.xyz

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
contract Seller is Ownable {
    using ECDSA for bytes32;

    struct SaleConfig {
        /**
         @dev dates are in unix timestamp format, example: 1650230067
         *    one of the usable converters: https://www.epochconverter.com/
         */
        string saleName;          // name of sale
        uint256 startDate;        // start of the sale 0 means it hasn't been started yet
        uint256 duration;         // sale duration in seconds 0 means open ended
        uint256 price;            // price of one item
        uint256 quantityLimit;    // how many tokens can be minted part of one transaction
        address signer;           // address that is used to sign the saleKeys
        bool isPublicSale;        // if it's true the signer will not be checked
        bool checkUsedKeys;       // if it's false saleKeys not stored after mint, making it cheaper
        bool exists;              // @dev to be able to delete sales
    }

    // /** 
    //  @dev Default sale definitions with disabled sale configs
    //         0: allowlist
    //         1: waitlist
    //         2: public
    //  */
    // SaleConfig[] private saleConfigs = [
    //     SaleConfig(0, 0, 0, 0, address(0), false, false, false),
    //     SaleConfig(0, 0, 0, 0, address(0), false, false, false),
    //     SaleConfig(0, 0, 0, 0, address(0), false, false, false)];

    SaleConfig private allowlistConfig = SaleConfig("allowlistMint",0, 0, 0, 0, address(0), false, false, false);
    SaleConfig private waitlistConfig = SaleConfig("waitlistMint",0, 0, 0, 0, address(0), false, false, false);
    SaleConfig private publicConfig = SaleConfig("publicMint",0, 0, 0, 0, address(0), false, false, false);

    /**
     @dev Record of already-used signatures, used when every saleKey can be used only once
          All sale keys are stored in the same so different key should be used to allowlist and waitlist
     */
    mapping(bytes => bool) public usedKeys;

    /**
     @dev provide setup and remove functions for the sales
     */
    function setAllowlistSale(uint256 startDate, uint256 duration, uint256 price, uint256 quantityLimit, address signer, bool checkUsedKeys) public onlyOwner {
        allowlistConfig = SaleConfig("allowlistMint", startDate, duration, price, quantityLimit, signer, false, checkUsedKeys, true);
    }
    function removeAllowlistSale() external onlyOwner {
        allowlistConfig.exists = false;
    }

    function setWaitlistSale(uint256 startDate, uint256 duration, uint256 price, uint256 quantityLimit, address signer, bool checkUsedKeys) public onlyOwner {
       waitlistConfig = SaleConfig("waitlistMint",startDate, duration, price, quantityLimit, signer, false, checkUsedKeys, true);
    }
    function removeWaitlistSale() external onlyOwner {
        waitlistConfig.exists = false;
    }

    function setPublicSale(uint256 startDate, uint256 duration, uint256 price, uint256 quantityLimit) public onlyOwner {
        publicConfig = SaleConfig("publicMint",startDate, duration, price, quantityLimit, address(0), true, false, true);
    }
    function removePublicSale() external onlyOwner {
        publicConfig.exists = false;
    }

    /**
     @dev returns the current sale setups
     */
    function getSalesConfig() public view returns (SaleConfig[3] memory) {
        return [allowlistConfig, waitlistConfig, publicConfig];
    }

    /**
     @dev returns true if the current date is between the sale start and start + duration
     *      - start date is 0 means the sale is inactive -> returns false
     *      - duration is 0 means it is an open ended sale no need to check end date
     */
    function verifySaleDate(SaleConfig memory sale) internal virtual view {
        require(sale.exists, "invalid saleId");
        require(sale.startDate != 0 && block.timestamp >= sale.startDate, "sale has not been started yet");
        require(sale.duration == 0 || block.timestamp < sale.startDate + sale.duration, "sale has been ended");
    }

    /**
     @dev returns true if the provided mintKey is valid 
     *      - address in the key matches with the sender's address
     *      - it is signed with the stored signer address
     *      - returns true when the sale is a public sale
     */
    function verifyMintKey(bytes memory mintKey, SaleConfig memory sale) internal virtual {
        require(sale.isPublicSale || 
                (!usedKeys[mintKey] && checkSignature(sale.signer, msg.sender, mintKey)),
                "address with this key is not eligible to mint or saleKey has been already used");

        if (sale.checkUsedKeys) {
            usedKeys[mintKey] = true;
        }
    }

    /**
     @dev verifies if the requested quantity is available for the sender 
     *      - quantity should be less than the limit in the saleConfig
     *      - price should be at least the salePrice * quantity
     */
    function verifyQuantity(uint256 quantity, SaleConfig memory sale) internal virtual view {
        require(quantity <= sale.quantityLimit, "sale limit is exceeded for this transaction");
        require(quantity * sale.price <= msg.value, "not enough value was sent to complete the purchase");
    }

    /**
     @dev verifyAllowlist and verifyWaitlist runs the previous checks in one place to simplify the usage:
     *      - verifySaleDate
     *      - verifySaleKey
     *      - verifyQuantity & price
     */
    function verifyAllowlist(uint256 quantity, bytes memory mintKey) internal virtual {
        verifySaleDate(allowlistConfig);
        verifyMintKey(mintKey, allowlistConfig);
        verifyQuantity(quantity, allowlistConfig);
    }
    function verifyWaitlist(uint256 quantity, bytes memory mintKey) internal virtual {
        verifySaleDate(waitlistConfig);
        verifyMintKey(mintKey, waitlistConfig);
        verifyQuantity(quantity, waitlistConfig);
    }

    /**
     @dev verifyPublicSale runs the previous checks without the mintKey verification:
     *      - verifySaleDate
     *      - verifyQuantity & price
     */
    function verifyPublicSale(uint256 quantity) internal virtual view {
        verifySaleDate(publicConfig);
        verifyQuantity(quantity, publicConfig);
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
}