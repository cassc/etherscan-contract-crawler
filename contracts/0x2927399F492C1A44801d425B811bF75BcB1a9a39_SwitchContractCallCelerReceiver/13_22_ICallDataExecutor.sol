pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ICallDataExecutor {
    function execute(
        IERC20 token,
        address addr,
        address approveAddress,
        address contractOutputsToken,
        address recipient,
        uint256 amount,
        uint256 gasLimit,
        bytes memory payload
    ) external payable;

    function sendNativeAndExecute(
        IERC20 token,
        address callTo,
        address approveAddress,
        address contractOutputsToken,
        address recipient,
        uint256 amount,
        uint256 gasLimit,
        bytes memory payload
    ) external payable;

    function sendAndExecute(
        IERC20 token,
        address callTo,
        address approveAddress,
        address contractOutputsToken,
        address recipient,
        uint256 amount,
        uint256 gasLimit,
        bytes memory payload
    ) external payable;
}