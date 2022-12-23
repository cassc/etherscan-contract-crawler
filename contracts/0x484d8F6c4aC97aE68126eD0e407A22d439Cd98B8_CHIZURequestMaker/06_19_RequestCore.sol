// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "../interfaces/ILazyMintable.sol";
import "../interfaces/ICurrencyManager.sol";

import "../Constants.sol";
import "hardhat/console.sol";

abstract contract RequestCore is Initializable, ERC1155Holder {
    using AddressUpgradeable for address;

    address internal core;
    address internal currencyManager;

    struct OrderInfo {
        // salt
        uint256 creatorSalt;
        uint256 requesterSalt;
        //user
        address creatorAccount;
        address requesterAccount;
        //terms info
        address collectionAddress;
        uint256 policy;
    }

    struct LazyNFTInfo {
        address collectionAddress;
        uint256 policy;
        // ipfs hash
        string uri;
        // lazy mint hash
        bytes32 hashValue;
    }

    struct NFTInfo {
        // The address of colletion for NFT
        address collectionAddress;
        // The tokenId to exchanger
        uint256 tokenId;
        // The amount of token
        uint256 amount;
    }

    struct CurrencyInfo {
        // The address of currency
        address currencyAddress;
        // The price to pay
        uint256 price;
    }

    struct UserValidate {
        bytes32 creatorHash;
        bytes32 requesterHash;
        bytes creatorSignature;
        bytes requesterSignature;
    }

    struct NodeValidate {
        address nodeAddress;
        bytes32 hashValue;
        bytes signature;
        uint256 expiredAt;
    }

    struct RequestInfo {
        // default : 0, refunded:1, accepted : 2, finished: 3
        uint8 status;
        // end time
        uint40 endTime;
        // currency erc721 erc1155
        uint8 escrowType;
        // creator Address
        address creatorAccount;
        // requester Address
        address requesterAccount;
        // currency or collection address
        address contractAddress;
        // currency price or tokenId
        uint256 value;
        // amount if erc721 or erc1155, erc721 => amount:0
        uint256 amount;
    }

    /**
     * @dev The function that initialize core addresas and currency manager address
     */
    function _initializeCore(address _core, address _currencyManager)
        internal
        onlyInitializing
    {
        core = _core;
        currencyManager = _currencyManager;
    }

    /**
     * @dev The function that get initialze information
     */
    function getInitializeInfo() external view returns (address, address) {
        return (core, currencyManager);
    }

    /**
     * @dev The internal function that escrow currency
     */
    function _escrowCurrency(
        address requesterAddress,
        CurrencyInfo memory currencyInfo
    ) internal returns (bool success, string memory message) {
        uint256 requesterBalance = ICurrencyManager(currencyManager).balanceOf(
            currencyInfo.currencyAddress,
            requesterAddress
        );

        if (currencyInfo.price > requesterBalance) {
            return (false, "RequestCore : price is larger than balance");
        }

        ICurrencyManager(currencyManager).chizuTransferCurrencyFrom(
            currencyInfo.currencyAddress,
            requesterAddress,
            address(this),
            currencyInfo.price
        );
        success = true;
    }

    /**
     * @dev The internal function that escrow NFT
     */
    function _escrowNFT(address requesterAddress, NFTInfo memory nftInfo)
        internal
        returns (bool success, string memory message)
    {
        (success, message) = _transferNftFrom(
            nftInfo.collectionAddress,
            nftInfo.tokenId,
            nftInfo.amount,
            requesterAddress,
            address(this)
        );
    }

    /**
     * @dev The internal function that exchange the lazy NFT for currency
     */
    function _exchanageNFTAndCurrency(
        RequestInfo memory requestInfo,
        LazyNFTInfo memory lazyNFTInfo,
        uint256 expiredAt
    ) internal returns (uint256 tokenId) {
        uint256 protocolFee = (requestInfo.value * 2) / 100;

        ICurrencyManager(currencyManager).chizuReduceCurrencyFrom(
            requestInfo.contractAddress,
            address(this),
            protocolFee
        );

        ICurrencyManager(currencyManager).chizuTransferCurrencyFrom(
            requestInfo.contractAddress,
            address(this),
            requestInfo.creatorAccount,
            requestInfo.value - protocolFee
        );

        tokenId = ILazyMintable(lazyNFTInfo.collectionAddress).chizuMintFor(
            requestInfo.creatorAccount,
            requestInfo.requesterAccount,
            lazyNFTInfo.policy,
            lazyNFTInfo.uri,
            lazyNFTInfo.hashValue,
            expiredAt
        );
    }

    /**
     * @dev The internal function that exchange the lazy NFT for NFT
     */
    function _exchanageNFTS(
        RequestInfo memory requestInfo,
        LazyNFTInfo memory lazyNFTInfo,
        uint256 expiredAt
    ) internal returns (uint256 tokenId) {
        (bool success, string memory message) = _transferNftFrom(
            requestInfo.contractAddress,
            requestInfo.value,
            requestInfo.amount,
            address(this),
            requestInfo.creatorAccount
        );
        require(success, message);

        tokenId = ILazyMintable(lazyNFTInfo.collectionAddress).chizuMintFor(
            requestInfo.creatorAccount,
            requestInfo.requesterAccount,
            lazyNFTInfo.policy,
            lazyNFTInfo.uri,
            lazyNFTInfo.hashValue,
            expiredAt
        );
    }

    /**
     * @dev The internal function that refund the currency
     */
    function _refundCurrency(RequestInfo memory requestInfo) internal {
        ICurrencyManager(currencyManager).chizuTransferCurrencyFrom(
            requestInfo.contractAddress,
            address(this),
            requestInfo.requesterAccount,
            requestInfo.value
        );
    }

    /**
     * @dev The internal function that refund the NFT
     */
    function _refundNFT(RequestInfo memory requestInfo)
        internal
        returns (bool success, string memory message)
    {
        (success, message) = _transferNftFrom(
            requestInfo.contractAddress,
            requestInfo.value,
            requestInfo.amount,
            address(this),
            requestInfo.requesterAccount
        );
        success = true;
    }

    /**
     * ===================================
     * Util function
     * ===================================
     */

    /**
     * @dev  It's internal function to transfer the nft
     */
    function _transferNftFrom(
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        address fromAddress,
        address toAddress
    ) internal returns (bool success, string memory message) {
        if (amount == ERC721_RESERVED_AMOUNT) {
            /**
             * ======================================
             * Case 1 : ERC721
             * ======================================
             * @dev amount can not be zero
             * Therefore, if amount == 0, assume it as ERC721
             */
            if (fromAddress != IERC721(contractAddress).ownerOf(tokenId)) {
                return (false, "RequestCore : is not owner");
            }
            IERC721(contractAddress).transferFrom(
                fromAddress,
                toAddress,
                tokenId
            );
        } else {
            /**
             * ======================================
             * Case 2 : ERC1155
             * ======================================
             */
            if (
                amount >
                IERC1155(contractAddress).balanceOf(fromAddress, tokenId)
            ) {
                return (false, "RequesteCore : is larger than balance");
            }

            IERC1155(contractAddress).safeTransferFrom(
                fromAddress,
                toAddress,
                tokenId,
                amount,
                new bytes(0)
            );
        }
        success = true;
    }

    uint256[1000] private __gap;
}