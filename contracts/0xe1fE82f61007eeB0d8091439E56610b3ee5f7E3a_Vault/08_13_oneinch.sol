// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for CHI gas token
interface IOneInchChi is IERC20 {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256 freed);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

interface IOneInchGasDiscountExtension {
    function calculateGas(uint256 gasUsed, uint256 flags, uint256 calldataLength) external view returns (IOneInchChi, uint256);
}

interface IOneInchAggregationExecutor is IOneInchGasDiscountExtension {
    /// @notice Make calls on `msgSender` with specified data
    function callBytes(address msgSender, bytes calldata data) external payable;  // 0x2636f7f8
}

struct OneInchSwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

interface IOneInchAggregationRouterV4 {

    /// @notice Performs a swap, delegating all calls encoded in `data` to `caller`. See tests for usage examples
    /// @param caller Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount Resulting token amount
    /// @return gasLeft Gas left
    function swap(
        IOneInchAggregationExecutor caller,
        OneInchSwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft);

}