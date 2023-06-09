// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Refundable.sol";

contract BatchTransfer is Refundable {
    using SafeERC20 for IERC20;

    event SetVIP(address indexed vip, uint256 discount);

    uint256 private _baseFee;
    uint256 private _unitFee;
    uint256 private _refBonus;
    mapping(address => uint256) private _vips;

    constructor(
        address owner_,
        uint256 baseFee,
        uint256 unitFee,
        uint256 refBonus
    ) Refundable(owner_) {
        _baseFee = baseFee;
        _unitFee = unitFee;
        require(refBonus <= 100, "Invalid bonus value");
        _vips[owner_] = 100;
    }

    function setFees_mix_(uint256 baseFee, uint256 unitFee) external onlyOwner {
        _baseFee = baseFee;
        _unitFee = unitFee;
    }

    function setRefBonus_mix_(uint256 refBonus) external onlyOwner {
        require(refBonus <= 100, "Invalid bonus");
        _refBonus = refBonus;
    }

    function setVip_mix_(address vip, uint256 discount) external onlyOwner {
        require(discount <= 100, "Invalid discount");
        _vips[vip] = discount;
        emit SetVIP(vip, discount);
    }

    function getFees() public view returns (uint256, uint256) {
        return (_baseFee, _unitFee);
    }

    function getRefBonus() public view returns (uint256) {
        return _refBonus;
    }

    function getVip(address vip) public view returns (uint256) {
        return _vips[vip];
    }

    function calcFee(address addr, uint256 txCount) public view returns (uint256) {
        uint256 fee = _baseFee + _unitFee * txCount;
        uint256 discount = _vips[addr];
        fee = (fee * (100 - discount)) / 100;
        return fee;
    }

    function sendETH(
        address payable[] memory payees,
        uint256[] memory amounts,
        address payable referrer
    ) public payable {
        uint256 txCount = payees.length;
        require(txCount == amounts.length, "Params not match");

        uint256 remain = msg.value;
        uint256 fee = calcFee(msg.sender, txCount);
        require(remain >= fee, "Fee is not enough");
        remain -= fee;

        for (uint256 i = 0; i < txCount; i++) {
            remain -= amounts[i];
            // payees[i].transfer(amounts[i]);
            (bool success, ) = payees[i].call{ value: amounts[i] }("");
            require(success, "Transfer failed");
        }

        if (fee > 0 && _refBonus > 0 && referrer != address(0x0) && referrer != msg.sender) {
            uint256 bonus = (fee * 100) / _refBonus;
            // use send to enable fail
            referrer.send(bonus);
        }
    }

    function sendToken(
        address token,
        address payable[] memory payees,
        uint256[] memory amounts,
        address payable referrer
    ) public payable {
        uint256 txCount = payees.length;
        require(txCount == amounts.length, "Params not match");

        uint256 fee = calcFee(msg.sender, txCount);
        require(msg.value >= fee, "Fee is not enough");

        for (uint256 i = 0; i < txCount; i++) {
            // safeTransferFrom is required
            IERC20(token).safeTransferFrom(msg.sender, payees[i], amounts[i]);
        }

        if (fee > 0 && _refBonus > 0 && referrer != address(0x0) && referrer != msg.sender) {
            uint256 bonus = (fee * 100) / _refBonus;
            // use send to enable fail
            referrer.send(bonus);
        }
    }
}