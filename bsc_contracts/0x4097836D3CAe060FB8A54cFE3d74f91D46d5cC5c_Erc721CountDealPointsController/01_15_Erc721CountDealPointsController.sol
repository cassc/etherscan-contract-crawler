// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../../../DealPointsController.sol';
import './IErc721CountDealPointsController.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import './../../../DealPointDataInternal.sol';

contract Erc721CountDealPointsController is
    DealPointsController,
    IErc721CountDealPointsController
{
    mapping(uint256 => uint256[]) _tokensId;

    constructor(address dealsController_)
        DealPointsController(dealsController_)
    {}

    function dealPointTypeId() external pure returns (uint256) {
        return 4;
    }

    /// @dev creates the deal point
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 count_
    ) external {
        uint256 pointId = _dealsController.getTotalDealPointsCount() + 1;
        _data[pointId] = DealPointDataInternal(dealId_, count_, from_, to_);
        _tokenAddress[pointId] = token_;
        _dealsController.addDealPoint(dealId_, address(this), pointId);
    }

    function tokensId(uint256 pointId)
        external
        view
        returns (uint256[] memory)
    {
        return _tokensId[pointId];
    }

    function _execute(uint256 pointId, address from) internal virtual override {
        // transfer
        DealPointDataInternal memory point = _data[pointId];
        IERC721Enumerable token = IERC721Enumerable(_tokenAddress[pointId]);
        uint256 cnt = point.value;
        uint256[] memory items = new uint256[](cnt);
        for (uint256 i = 0; i < cnt; ++i) {
            uint256 tokenId = token.tokenOfOwnerByIndex(from, 0);
            token.transferFrom(from, address(this), tokenId);
            items[i] = tokenId;
        }
        _tokensId[pointId] = items;
        ++_balances[pointId];

        // calculate fee
        _fee[pointId] = _dealsController.feeEth();
    }

    function _withdraw(
        uint256 pointId,
        address withdrawAddr,
        uint256 withdrawCount
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
        uint256 cnt = point.value;
        uint256[] memory items = _tokensId[pointId];
        for (uint256 i = 0; i < cnt; ++i) {
            uint256 tokenId = items[i];
            token.transferFrom(address(this), withdrawAddr, tokenId);
        }
        delete _tokensId[pointId];
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