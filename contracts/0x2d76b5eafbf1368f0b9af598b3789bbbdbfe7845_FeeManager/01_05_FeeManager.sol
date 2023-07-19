// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";

/**
 * @author Jonatã Oliveira
 * @title FeeManager
 * @notice It handles the logic to manage platform fees.
 */
contract FeeManager is IFeeManager, Ownable {
    using SafeMath for uint256;

    struct CustomFee {
        uint16 fee;
        bool enabled;
    }

    uint16 private constant _DIVIDER = 10000;
    mapping(address => CustomFee) private customFees;
    uint16 public defaultFee = 200; // 2%
    uint16 private royaltyPercentage = 10000; // 100%
    address private feeReceiver;
    bool private royaltiesEnabled;

    /**
     * @notice Constructor
     * @param _defaultFee default platform fee
     * @param _feeReceiver address to receive fees
     */
    constructor(uint16 _defaultFee, address _feeReceiver) {
        defaultFee = _defaultFee;
        feeReceiver = _feeReceiver;
    }

    /**
     * @notice Add a custom fee to target collection
     * @param collection address of the collection (ERC-721 or ERC-1155)
     * @param fee fee percentage
     */
    function setCollectionFee(address collection, uint16 fee) external override onlyOwner {
        customFees[collection].fee = fee;
        customFees[collection].enabled = true;
    }

    /**
     * @notice Remove the custom fee from collection
     * @param collection address of the collection (ERC-721 or ERC-1155)
     */
    function removeCollectionFee(address collection) external override onlyOwner {
        customFees[collection].fee = 0;
        customFees[collection].enabled = false;
    }

    /**
     * @notice Change the default fee
     * @param fee fee percentage
     */
    function setDefaultFee(uint16 fee) external override onlyOwner {
        defaultFee = fee;
    }

    /**
     * @notice Get royalties enabled
     */
    function getRoyaltiesEnabled() external view override returns (bool) {
        return royaltiesEnabled;
    }

    /**
     * @notice Enable/Disable royalties
     * @param enabled boolean
     */
    function setRoyaltiesEnabled(bool enabled) external override onlyOwner {
        royaltiesEnabled = enabled;
    }

    /**
     * @notice Change the royalties percentage to pay
     * @param percentage percentage
     */
    function setRoyaltyPercentage(uint16 percentage) external override onlyOwner {
        royaltyPercentage = percentage;
    }

    /**
     * @notice Change the fee receiver address
     * @param receiver address to receive fees
     */
    function setFeeReceiver(address receiver) external override onlyOwner {
        require(receiver != address(0), "Invalid address");
        feeReceiver = receiver;
    }

    /**
     * @notice Returns the fee receiver address
     */
    function getReceiver() public view override returns (address) {
        return feeReceiver;
    }

    /**
     * @notice Returns the royalty percentage
     */
    function getRoyaltyPercentage() public view override returns (uint16) {
        return royaltyPercentage;
    }

    /**
     * @notice Returns the collection fee
     * @param collection address of the collection
     */
    function getFee(address collection) public view override returns (uint16) {
        CustomFee memory custom = customFees[collection];
        if (custom.enabled) {
            return custom.fee;
        }
        return defaultFee;
    }

    /**
     * @notice Returns the percentage divider
     */
    function divider() public pure override returns (uint16) {
        return _DIVIDER;
    }

    /**
     * @notice Returns the calculated fee amount
     * @param collection address of the collection
     * @param amount amount to calc
     */
    function getFeeAmount(address collection, uint256 amount) external view override returns (uint256) {
        return amount.mul(getFee(collection)).div(_DIVIDER);
    }
}