pragma solidity 0.4.24;

import "contracts/lib/IEVMScriptExecutor.sol";

interface IEVMScriptRegistry {
    function addScriptExecutor(IEVMScriptExecutor executor)
        external
        returns (uint256 id);

    function disableScriptExecutor(uint256 executorId) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function getScriptExecutor(bytes script)
        public
        view
        returns (IEVMScriptExecutor);
}