// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../RefundableNftSale.sol";

contract TitaniumFightersSale is RefundableNftSale {
    constructor(
        address _nftToken,
        address _paymentToken,
        uint256 _startTime,
        uint256 _price,
        uint256 _refundTimeLimit
    )
        RefundableNftSale(
            _nftToken,
            _paymentToken,
            _startTime,
            _price,
            _refundTimeLimit
        )
    {}
}