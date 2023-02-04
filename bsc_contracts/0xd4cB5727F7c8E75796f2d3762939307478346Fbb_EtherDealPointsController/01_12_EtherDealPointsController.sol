// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../../DealPointsController.sol';
import './IEtherDealPointsController.sol';
import './../../DealPointDataInternal.sol';

contract EtherDealPointsController is
    DealPointsController,
    IEtherDealPointsController
{
    constructor(address dealsController_)
        DealPointsController(dealsController_)
    {}

    function dealPointTypeId() external pure returns (uint256) {
        return 1;
    }

    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        uint256 count_
    ) external onlyFactory {
        uint256 pointId = _dealsController.getTotalDealPointsCount() + 1;
        _data[pointId] = DealPointDataInternal(dealId_, count_, from_, to_);
        _dealsController.addDealPoint(dealId_, address(this), pointId);
    }

    function _execute(uint256 pointId, address) internal virtual override {
        DealPointDataInternal memory point = _data[pointId];
        // transfer
        uint256 count = point.value;
        require(msg.value >= count, 'not enough eth');
        _balances[pointId] = count;

        // calculate fee
        _fee[pointId] =
            (count * _dealsController.feePercent()) /
            _dealsController.feeDecimals();
    }

    function _withdraw(
        uint256 pointId,
        address withdrawAddr,
        uint256 withdrawCount
    ) internal virtual override {
        uint256 pointFee = _fee[pointId];
        if (!this.isSwapped(pointId)) pointFee = 0;
        uint256 toTransfer = withdrawCount - pointFee;
        if (pointFee > 0) {
            (bool sentFee, ) = payable(_dealsController.feeAddress()).call{
                value: pointFee
            }('');
            require(sentFee, 'sent fee error: ether is not sent');
        }
        (bool sent, ) = payable(withdrawAddr).call{ value: toTransfer }('');
        require(sent, 'withdraw error: ether is not sent');
    }

    function feeIsEthOnWithdraw() external pure returns (bool) {
        return false;
    }    
    
    function executeEtherValue(uint256 pointId) external view returns (uint256) {
        return _data[pointId].value;
    }
}