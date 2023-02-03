// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../../../DealPointsController.sol';
import './IErc721ItemDealPointsController.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../../../DealPointDataInternal.sol';

contract Erc721ItemDealPointsController is
    DealPointsController,
    IErc721ItemDealPointsController
{
    constructor(address dealsController_)
        DealPointsController(dealsController_)
    {}

    function dealPointTypeId() external pure returns (uint256) {
        return 3;
    }

    /// @dev creates the deal point
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 tokenId_
    ) external {
        uint256 pointId = _dealsController.getTotalDealPointsCount() + 1;
        _data[pointId] = DealPointDataInternal(dealId_, tokenId_, from_, to_);
        _tokenAddress[pointId] = token_;
        _dealsController.addDealPoint(dealId_, address(this), pointId);
    }

    function tokenId(uint256 pointId) external view returns (uint256) {
        return _data[pointId].value;
    }

    function _execute(uint256 pointId, address from) internal virtual override {
        DealPointDataInternal memory point = _data[pointId];
        // transfer
        IERC721 token = IERC721(_tokenAddress[pointId]);
        token.transferFrom(from, address(this), point.value);
        _balances[pointId] = 1;

        // calculate fee
        _fee[pointId] = _dealsController.feeEth();
    }

    function _withdraw(
        uint256 pointId,
        address withdrawAddr,
        uint256
    ) internal virtual override {
        DealPointDataInternal memory point = _data[pointId];
        uint256 pointFee = _fee[pointId];
        if (!this.isSwapped(pointId)) pointFee = 0;
        IERC721 token = IERC721(_tokenAddress[pointId]);
        if (pointFee > 0) {
            require(msg.value >= pointFee, 'not enough eth fee for withdraw');
            (bool sentFee, ) = payable(_dealsController.feeAddress()).call{
                value: pointFee
            }('');
            require(sentFee, 'sent fee error: ether is not sent');
        }
        token.transferFrom(address(this), withdrawAddr, point.value);
        _balances[pointId] = 0;
    }

    function feeIsEthOnWithdraw() external pure returns (bool) {
        return true;
    }

    function executeEtherValue(uint256 pointId)
        external
        pure
        returns (uint256)
    {
        return 0;
    }
}