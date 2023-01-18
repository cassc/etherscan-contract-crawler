// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./AdapterBase.sol";
import "../libraries/Errors.sol";
import "../interfaces/external/IConnext.sol";

contract ConnextAdapter is AdapterBase {
    constructor(address target_) AdapterBase(target_) {}

    function _executeCall(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) internal override {
        IConnext.PrepareArgs memory prepareArgs = abi.decode(
            args,
            (IConnext.PrepareArgs)
        );
        require(
            prepareArgs.invariantData.sendingAssetId == tokenIn,
            Errors.INVALID_INCOMING_TOKEN
        );
        prepareArgs.amount = amountIn;

        uint256 value = tokenIn == address(0) ? amountIn : 0;
        IConnext(target).prepare{value: value}(prepareArgs);
    }
}