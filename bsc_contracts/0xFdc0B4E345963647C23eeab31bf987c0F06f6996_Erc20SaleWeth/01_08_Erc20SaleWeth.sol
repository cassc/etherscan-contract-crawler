// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './Erc20Sale.sol';
import '../weth/IgWETH.sol';

contract Erc20SaleWeth {
    Erc20Sale immutable _sale;
    IgWETH immutable _weth;

    constructor(address saleAlg, address weth) {
        _sale = Erc20Sale(saleAlg);
        _weth = IgWETH(weth);
    }

    function getSaleAlg() external view returns (address) {
        return address(_sale);
    }

    function buy(
        uint256 positionId,
        address to,
        uint256 count,
        uint256 priceNom,
        uint256 priceDenom
    ) external payable {
        PositionData memory position = _sale.getPosition(positionId);
        require(
            position.asset2 == address(_weth),
            'sale position is not require eth for purchase'
        );
        uint256 toSpend = _sale.spendToBuy(positionId, count);
        require(msg.value >= toSpend, 'not enough ether');
        uint256 dif = msg.value - toSpend;
        _weth.mint{ value: toSpend }();
        _sale.buy(positionId, to, count, priceNom, priceDenom);
        if (dif > 0) {
            (bool sent, ) = payable(msg.sender).call{ value: dif }('');
            require(sent, 'sent ether error: ether is not sent');
        }
    }
}