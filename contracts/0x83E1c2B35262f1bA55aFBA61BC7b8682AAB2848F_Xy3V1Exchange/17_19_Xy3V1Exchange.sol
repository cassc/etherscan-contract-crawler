// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IDelegateV3.sol";
import {IExchange} from "../interfaces/IExchange.sol";
import "../common/ExchangeConfig.sol";
import {EXCHANGE_CALLER_ROLE} from "../../Roles.sol";

interface IXY3V1 {
    function repay(uint32 _loanId) external;

    function loanDetails(
        uint32 _loanId
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            uint32,
            uint16,
            uint64,
            address,
            address,
            bool
        );
}

contract Xy3V1Exchange is IExchange, ExchangeConfig {
    using SafeERC20 for IERC20;

    constructor(
        address _admin,
        address _xy3,
        address _delegateV3
    ) ExchangeConfig(_admin, _xy3, _delegateV3) {}

    function exchange(
        address sender,
        bytes memory params_
    )
        external
        override
        onlyRole(EXCHANGE_CALLER_ROLE)
        returns (bool, address, uint256)
    {
        uint32 loanId = abi.decode(params_, (uint32));
        (
            ,
            uint256 repayAmount,
            uint256 nftTokenId,
            address borrowAsset,
            ,
            ,
            ,
            address nftAsset,
            ,

        ) = IXY3V1(target).loanDetails(loanId);
        IDelegateV3(delegate).erc20Transfer(
            sender,
            address(this),
            borrowAsset,
            repayAmount
        );

        _approve(delegate, borrowAsset, repayAmount);
        IXY3V1(target).repay(loanId);

        return (true, nftAsset, nftTokenId);
    }
}