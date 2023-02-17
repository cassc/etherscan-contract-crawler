// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Defii.sol";

abstract contract DefiiWithCustomExit is Defii {
    function exitWithParams(bytes memory params) external onlyOnwerOrExecutor {
        _exitWithParams(params);
    }

    function exitWithParamsAndWithdraw(
        bytes memory params
    ) public onlyOnwerOrExecutor {
        _exitWithParams(params);
        _withdrawFunds();
    }

    function _exitWithParams(bytes memory params) internal virtual;

    function _exit() internal virtual override {
        revert("Run exitWithParams");
    }
}