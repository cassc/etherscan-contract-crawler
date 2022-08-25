// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "ERC20.sol";
import "SafeERC20.sol";

import "AssetRecoverer.sol";
import "NormalizedAmounts.sol";
import "IWormholeTokenBridge.sol";

/// @title Jumpgate
/// @author mymphe
/// @notice Transfer an ERC20 token using a Wormhole token bridge with pre-determined parameters
/// @dev `IWormholeTokenBridge` and the logic in `_callBridgeTransfer` are specific to Wormhole Token Bridge
contract Jumpgate is AssetRecoverer {
    using NormalizedAmounts for uint256;
    using SafeERC20 for IERC20;

    event JumpgateCreated(
        address indexed _jumpgate,
        address indexed _token,
        address indexed _bridge,
        uint16 _recipientChain,
        bytes32 _recipient,
        uint256 _arbiterFee
    );

    event TokensBridged(
        address indexed _token,
        address indexed _bridge,
        uint16 _recipientChain,
        bytes32 _recipient,
        uint256 _arbiterFee,
        uint256 _amount,
        uint64 _transferSequence
    );

    /// ERC20 token to be bridged
    IERC20 public immutable token;

    /// Wormhole token bridge
    IWormholeTokenBridge public immutable bridge;

    /// Wormhole id of the target chain
    uint16 public immutable recipientChain;

    /// bytes32-encoded recipient address on the target chain
    bytes32 public immutable recipient;

    /// Wormhole arbiter fee
    uint256 public immutable arbiterFee;

    /// Transfer nonce
    uint32 public constant nonce = 0;

    constructor(
        address _owner,
        address _token,
        address _bridge,
        uint16 _recipientChain,
        bytes32 _recipient,
        uint256 _arbiterFee
    ) {
        transferOwnership(_owner);

        token = IERC20(_token);
        bridge = IWormholeTokenBridge(_bridge);
        recipientChain = _recipientChain;
        recipient = _recipient;
        arbiterFee = _arbiterFee;

        emit JumpgateCreated(
            address(this),
            _token,
            _bridge,
            _recipientChain,
            _recipient,
            _arbiterFee
        );
    }

    /// @notice transfer all of the tokens on this contract's balance to the cross-chain recipient
    /// @dev transfer amount is normalized due to bridging decimal shift which sometimes truncates decimals
    function bridgeTokens() external {
        uint256 amount = token.balanceOf(address(this));
        uint8 decimals = getDecimals();
        uint256 normalizedAmount = amount.normalize(decimals);
        require(normalizedAmount > 0, "Amount too small for bridging!");
        uint256 denormalizedAmount = normalizedAmount.denormalize(decimals);

        token.safeApprove(address(bridge), denormalizedAmount);
        uint64 sequence = _callBridgeTransfer(denormalizedAmount);

        emit TokensBridged(
            address(token),
            address(bridge),
            recipientChain,
            recipient,
            arbiterFee,
            denormalizedAmount,
            sequence
        );
    }

    /// @notice calls the transfer method on the bridge
    /// @dev implements the actual logic of the bridge transfer
    /// @param _amount amount of tokens to transfer
    function _callBridgeTransfer(uint256 _amount)
        private
        returns (uint64 sequence)
    {
        sequence = bridge.transferTokens(
            address(token),
            _amount,
            recipientChain,
            recipient,
            arbiterFee,
            nonce
        );
    }

    /// @notice get number of token decimals for normalization
    /// @dev using low-level `staticcall` because OpenZeppelin IERC20 doesn't include `decimals()`
    /// @return decimals number of token decimals
    function getDecimals() internal view returns (uint8 decimals) {
        (, bytes memory queriedDecimals) = address(token).staticcall(
            abi.encodeWithSignature("decimals()")
        );
        decimals = abi.decode(queriedDecimals, (uint8));
    }
}