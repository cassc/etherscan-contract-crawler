// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {GenArtAccess} from "../access/GenArtAccess.sol";
import {GenArtCurated} from "../app/GenArtCurated.sol";
import {IGenArtMintAllocator} from "../interface/IGenArtMintAllocator.sol";
import {IGenArtInterfaceV4} from "../interface/IGenArtInterfaceV4.sol";
import {IGenArtERC721} from "../interface/IGenArtERC721.sol";
import {IGenArtPaymentSplitterV5} from "../interface/IGenArtPaymentSplitterV5.sol";
import {GenArtMinterBase} from "./GenArtMinterBase.sol";

/**
 * @dev GEN.ART Minter Flash loan
 * Admin for collections deployed on {GenArtCurated}
 */

struct PublicSaleParams {
    uint256 startTime;
    uint256 price;
    address mintAllocContract;
    uint16 maxPerTransaction;
}

contract GenArtMinterPublic is GenArtMinterBase {
    uint256 DOMINATOR = 1000;
    address public loyaltyPool;
    uint256 public loyaltyRewardBps = 125;

    mapping(address => PublicSaleParams) public saleParams;

    constructor(
        address genartInterface_,
        address genartCurated_,
        address loyaltyPool_
    ) GenArtMinterBase(genartInterface_, genartCurated_) {
        loyaltyPool = loyaltyPool_;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param data encoded data
     */
    function setPricing(
        address collection,
        bytes memory data
    ) external override onlyAdmin returns (uint256) {
        PublicSaleParams memory params = abi.decode(data, (PublicSaleParams));
        _setPricing(collection, params);
        return params.price;
    }

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param startTime start time for minting
     * @param price price per token
     * @param mintAllocContract contract address of {GenArtMintAllocator}
     * @param maxPerTransaction max mints per transaction
     */
    function setPricing(
        address collection,
        uint256 startTime,
        uint256 price,
        address mintAllocContract,
        uint16 maxPerTransaction
    ) external onlyAdmin {
        _setPricing(
            collection,
            PublicSaleParams(
                startTime,
                price,
                mintAllocContract,
                maxPerTransaction
            )
        );
    }

    /**
     * @dev Internal helper method to set pricing for collection
     * @param collection contract address of the collection
     * @param params mint params
     */
    function _setPricing(
        address collection,
        PublicSaleParams memory params
    ) internal {
        super._setMintParams(
            collection,
            params.startTime,
            params.mintAllocContract
        );
        saleParams[collection] = params;
    }

    /**
     * @dev Get price for collection
     * @param collection contract address of the collection
     */
    function getPrice(
        address collection
    ) public view virtual override returns (uint256) {
        return saleParams[collection].price;
    }

    /**
     * @dev Helper function to check for mint price and start date
     */
    function _checkMint(address collection, uint256 amount) internal view {
        require(
            msg.value == getPrice(collection) * amount,
            "wrong amount sent"
        );
        (, , , , , uint256 maxSupply, uint256 totalSupply) = IGenArtERC721(
            collection
        ).getInfo();
        require(
            totalSupply + amount <= maxSupply,
            "not enough mints available"
        );
        require(
            amount <= saleParams[collection].maxPerTransaction,
            "mint amount exceeds max per transaction"
        );
        require(
            mintParams[collection].startTime != 0,
            "public mint not started yet"
        );
        require(
            mintParams[collection].startTime <= block.timestamp,
            "mint not started yet"
        );
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param "" any uint256
     */
    function mintOne(address collection, uint256) external payable override {
        _checkMint(collection, 1);
        IGenArtMintAllocator(mintParams[collection].mintAllocContract).update(
            collection,
            0,
            1
        );
        IGenArtERC721(collection).mint(msg.sender, 0);
        _splitPayment(collection);
    }

    /**
     * @dev Mint many tokens
     */
    function mint(
        address collection,
        uint256 amount
    ) external payable override {
        _checkMint(collection, amount);
        IGenArtMintAllocator(mintParams[collection].mintAllocContract).update(
            collection,
            0,
            amount
        );
        for (uint256 i; i < amount; i++) {
            IGenArtERC721(collection).mint(msg.sender, 0);
        }
        _splitPayment(collection);
    }

    /**
     * @dev Internal function to forward funds to a {GenArtPaymentSplitter}
     */
    function _splitPayment(address collection) internal {
        uint256 value = msg.value;
        address paymentSplitter = GenArtCurated(genArtCurated)
            .store()
            .getPaymentSplitterForCollection(collection);

        uint256 loyalties = (value * loyaltyRewardBps) / DOMINATOR;
        payable(loyaltyPool).transfer(loyalties);
        IGenArtPaymentSplitterV5(paymentSplitter).splitPayment{
            value: value - loyalties
        }(value);
    }

    /**
     * @dev Set the loyalty reward bps per mint {e.g 125}
     */
    function setLoyaltyRewardBps(uint256 bps) external onlyAdmin {
        loyaltyRewardBps = bps;
    }

    /**
     * @dev Set the payout address for the flash lending fees
     */
    function setLoyaltyPool(address loyaltyPool_) external onlyAdmin {
        loyaltyPool = loyaltyPool_;
    }

    /**
     * @dev Widthdraw contract balance
     */
    function withdraw() external onlyAdmin {
        payable(owner()).transfer(address(this).balance);
    }
}