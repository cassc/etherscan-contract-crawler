// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../../DealPointsController.sol';
import './IErc20DealPointsController.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../DealPointRef.sol';
import './../../DealPointDataInternal.sol';

contract Erc20DealPointsController is
    DealPointsController,
    IErc20DealPointsController
{
    using SafeERC20 for IERC20;

    constructor(address dealsController_)
        DealPointsController(dealsController_)
    {}

    function dealPointTypeId() external pure returns (uint256) {
        return 2;
    }

    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 count_
    ) external onlyFactory {
        uint256 pointId = _dealsController.getTotalDealPointsCount() + 1;
        _data[pointId] = DealPointDataInternal(dealId_, count_, from_, to_);
        _tokenAddress[pointId] = token_;
        _dealsController.addDealPoint(dealId_, address(this), pointId);
    }

    function _execute(uint256 pointId, address from) internal virtual override {
        // transfer
        DealPointDataInternal memory point = _data[pointId];
        IERC20 token = IERC20(_tokenAddress[pointId]);
        uint256 lastBalance = token.balanceOf(address(this));
        //token.safeTransferFrom(from, address(this), _value[pointId]);
        token.safeTransferFrom(from, address(this), point.value);
        uint256 pointBalance = token.balanceOf(address(this)) - lastBalance;
        _balances[pointId] = pointBalance;
        //point.balance = pointBalance;

        // calculate fee
        _fee[pointId] =
            (pointBalance * _dealsController.feePercent()) /
            _dealsController.feeDecimals();
        //point.fee =
        //   (pointBalance * _dealsController.feePercent()) /
        //    _dealsController.feeDecimals();
    }

    function _withdraw(
        uint256 pointId,
        address withdrawAddr,
        uint256 withdrawCount
    ) internal virtual override {
        if (!this.isSwapped(pointId)) _fee[pointId] = 0;
        uint256 toTransfer = withdrawCount - _fee[pointId];
        IERC20 token = IERC20(_tokenAddress[pointId]);
        if (_fee[pointId] > 0)
            token.safeTransfer(_dealsController.feeAddress(), _fee[pointId]);
        token.safeTransfer(withdrawAddr, toTransfer);
    }

    function feeIsEthOnWithdraw() external pure returns (bool) {
        return false;
    }

    function executeEtherValue(uint256 pointId) external pure returns(uint256){
        return 0;
    }
}