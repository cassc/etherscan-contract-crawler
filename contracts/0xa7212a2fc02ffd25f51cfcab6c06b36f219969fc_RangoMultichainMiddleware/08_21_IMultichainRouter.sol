// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

/// @title The root contract that handles Rango's interaction with MultichainOrg bridge
/// @author George
interface IMultichainRouter {
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
    function anySwapOutNative(address token, address to, uint toChainID) external payable;
    function anySwapOut(address token, address to, uint amount, uint toChainID) external;
}

interface IMultichainV7Router {
    // Swaps `amount` `token` from this chain to `toChainID` chain and call anycall proxy with `data`
    // `to` is the fallback receive address when exec failed on the `destination` chain
    function anySwapOutAndCall(
        address token,
        string calldata to,
        uint256 amount,
        uint256 toChainID,
        string calldata anycallProxy,
        bytes calldata data
    ) external;

    // Swaps `amount` `token` from this chain to `toChainID` chain and call anycall proxy with `data`
    // `to` is the fallback receive address when exec failed on the `destination` chain
    function anySwapOutUnderlyingAndCall(
        address token,
        string calldata to,
        uint256 amount,
        uint256 toChainID,
        string calldata anycallProxy,
        bytes calldata data
    ) external;

    // Swaps `msg.value` `Native` from this chain to `toChainID` chain and call anycall proxy with `data`
    // `to` is the fallback receive address when exec failed on the `destination` chain
    function anySwapOutNativeAndCall(
        address token,
        string calldata to,
        uint256 toChainID,
        string calldata anycallProxy,
        bytes calldata data
    ) external payable;
}

/// IAnycallProxy interface of the anycall proxy
interface IAnycallProxy {
    /// @notice Executor function (called in destination chain)
    /// Note that the onlyAllowedExecutors limits the caller of this function to be only allowed executors.
    /// @param token The token that is received on destination
    /// @param receiver The address that should receive tokens in case of failure as a fallback.
    /// @param amount Token amount
    /// @param data The data sent along with the token
    function exec(
        address token,
        address receiver,
        uint256 amount,
        bytes calldata data
    ) external payable returns (bool success, bytes memory result);
}

interface CustomMultichainToken {
    function transfer(address toAddress, uint256 amount) external;
    function Swapout(uint256 amount,address destination) external;
}

interface IUnderlying {
    function underlying() external view returns (address);
}