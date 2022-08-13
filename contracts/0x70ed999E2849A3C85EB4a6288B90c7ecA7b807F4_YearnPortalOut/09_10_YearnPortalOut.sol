/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Yearn Vaults into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "./interface/IVault.sol";

/// Thrown when insufficient liquidity is received after withdrawal
/// @param buyAmount The amount of tokens received
/// @param minBuyAmount The minimum acceptable quantity of buyAmount
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract YearnPortalOut is PortalBaseV1_1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is exited
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Remove liquidity from Yearn like vaults into network tokens/ERC20 tokens
    /// @param sellToken The vault token address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param intermediateToken The intermediate token to swap from (must be the vault underlying token)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner
    ) public payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);

        uint256 balance = _getBalance(address(this), intermediateToken);
        IVault(sellToken).withdraw(amount);
        amount = _getBalance(address(this), intermediateToken) - balance;

        buyAmount = _execute(intermediateToken, amount, buyToken, target, data);

        buyAmount = _getFeeAmount(buyAmount, fee);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyToken == address(0)
            ? msg.sender.safeTransferETH(buyAmount)
            : ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalOut(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Remove liquidity from Yearn like vaults into network tokens/ERC20 tokens with permit
    /// @param sellToken The vault token address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param intermediateToken The intermediate token to swap from (must be the vault underlying token)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param signature A valid secp256k1 signature of Permit by owner encoded as r, s, v
    /// @return buyAmount The quantity of buyToken acquired
    function portalOutWithPermit(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        bytes calldata signature
    ) external payable pausable returns (uint256 buyAmount) {
        _permit(sellToken, sellAmount, signature);

        return
            portalOut(
                sellToken,
                sellAmount,
                intermediateToken,
                buyToken,
                minBuyAmount,
                target,
                data,
                partner
            );
    }

    function _permit(
        address sellToken,
        uint256 sellAmount,
        bytes calldata signature
    ) internal {
        bool success = IVault(sellToken).permit(
            msg.sender,
            address(this),
            sellAmount,
            0,
            signature
        );
        require(success, "Could Not Permit");
    }
}