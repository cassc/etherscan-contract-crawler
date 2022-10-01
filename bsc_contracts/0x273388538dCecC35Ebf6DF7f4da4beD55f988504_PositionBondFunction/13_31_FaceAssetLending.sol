pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BondMath} from "../../lib/BondMath.sol";
import {BondTransfer} from "../../lib/BondTransfer.sol";

abstract contract FaceAssetLending {
    using SafeERC20 for IERC20;

    event FaceValueClaimed(address user, uint256 amount);
    event FaceValueDeposited(uint256 amount);
    event FaceValueRepaid(
        uint256 amount,
        uint256 bondAmount,
        uint256 faceValue
    );

    uint256 public totalSoldAmountClaimed;

    address private _faceAsset;
    uint256 private _faceValue;
    uint256 private _issuePrice;

    // 0 is Token, 1 is PosiNFT, 2 is Ether
    uint256 private faceAssetType;

    function initFaceAssetLending(
        uint256 faceAssetTypeType_,
        address faceAsset_,
        uint256 faceValue_,
        uint256 issuePrice_) internal {
        require(
            faceAssetTypeType_ == 0,
            "!supported"
        );

        faceAssetType = faceAssetTypeType_;
        _faceAsset = faceAsset_;
        _faceValue = faceValue_;
        _issuePrice = issuePrice_;

    }

    function _transferIn(uint256 amount) internal virtual {
        if (faceAssetType == 0) {
            if (amount > 0) {
                IERC20(_faceAsset).safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount
                );
            }

        } else {
            require(msg.value >= amount, "!amount");
        }
    }

    function getFaceAssetType() public view virtual returns (uint256) {
        return faceAssetType;
    }

    function faceAsset() public view virtual returns (address) {
        return _faceAsset;
    }

    function faceValue() public view virtual returns (uint256) {
        return _faceValue;
    }

    function _calculateFaceValueOut(uint256 bondAmount)
        internal
        view
        virtual
        returns (uint256)
    {
        return BondMath.calculateFaceValue(bondAmount, faceValue());
    }

    function _balanceOf() internal view virtual returns (uint256) {
        return IERC20(_faceAsset).balanceOf(address(this));
    }

    /// @dev Calculate the face value and transfer in
    /// inherit contract must implement
    /// @param totalSupply The bond amount
    function _transferRepaymentFaceValue(uint256 totalSupply) internal virtual {
        uint256 calculatedFaceValue = BondMath.calculateFaceValue(
            totalSupply,
            faceValue()
        );
        _transferIn(calculatedFaceValue);
        if (faceAssetType == 0) {
            // issuer needs cover any losses due to transfer token from issuer -> contract
            // if the transaction reverted with the following reason
            // issuer needs manually transfer the token to cover losses before repay the face value
            require(
                IERC20(_faceAsset).balanceOf(address(this)) >=
                    calculatedFaceValue,
                "need to cover deflection fees"
            );
        }

        emit FaceValueRepaid(calculatedFaceValue, totalSupply, _faceValue);
    }

    /// @dev Calculate the face value and transfer in
    /// inherit contract must implement
    /// @param bondAmount The bond amount
    function _transferFaceValueOut(uint256 bondAmount) internal virtual {
        uint256 calculatedFaceValue = BondMath.calculateFaceValue(
            bondAmount,
            faceValue()
        );
        _transferOut(calculatedFaceValue, msg.sender);
        emit FaceValueClaimed(msg.sender, calculatedFaceValue);
    }

    function _transferOut(uint256 amount, address to) internal {
        BondTransfer._transferOutToken(_faceAsset, amount, to);
    }

    function _amountLending(uint256 _bondAmount)
        internal
        view
        returns (uint256)
    {
        return ((_bondAmount * _issuePrice)) / 10**18;
    }

    function getIssuePrice() public view returns (uint256) {
        return _issuePrice;
    }

    function getBalanceFaceAmount() internal view returns (uint256) {
        return IERC20(_faceAsset).balanceOf(address(this));
    }
}