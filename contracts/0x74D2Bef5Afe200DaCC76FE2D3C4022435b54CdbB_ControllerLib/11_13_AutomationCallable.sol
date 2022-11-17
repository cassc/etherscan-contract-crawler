// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AutomationCallable is Initializable {
    address public autoExecutor;
    event ChangeAutomation(address oldExecutor, address newExecutor);

    function _setAutomation(address newExecutor) internal {
        address oldExecutor = autoExecutor;
        autoExecutor = newExecutor;
        emit ChangeAutomation(oldExecutor, newExecutor);
    }
}