// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./AdapterBase.sol";
import "../libraries/Errors.sol";
import "../interfaces/external/IXSwapper.sol";

contract XYAdapter is AdapterBase {
    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) AdapterBase(target_) {}

    struct XArgs {
        IXSwapper.SwapDescription swapDesc;
        bytes aggregatorData;
        IXSwapper.ToChainDescription toChainDesc;
    }

    /// @inheritdoc AdapterBase
    function _executeCall(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) internal override {
        XArgs memory xArgs = abi.decode(args, (XArgs));
        require(
            xArgs.swapDesc.fromToken == tokenIn,
            Errors.INVALID_INCOMING_TOKEN
        );
        xArgs.swapDesc.amount = amountIn;
        IXSwapper(target).swap(
            xArgs.swapDesc,
            xArgs.aggregatorData,
            xArgs.toChainDesc
        );
    }
}