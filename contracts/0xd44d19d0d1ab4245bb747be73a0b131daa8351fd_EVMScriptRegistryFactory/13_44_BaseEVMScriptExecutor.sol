pragma solidity 0.4.24;

import "contracts/lib/Autopetrified.sol";
import "contracts/lib/IEVMScriptExecutor.sol";

contract BaseEVMScriptExecutor is IEVMScriptExecutor, Autopetrified {
    uint256 internal constant SCRIPT_START_LOCATION = 4;
}