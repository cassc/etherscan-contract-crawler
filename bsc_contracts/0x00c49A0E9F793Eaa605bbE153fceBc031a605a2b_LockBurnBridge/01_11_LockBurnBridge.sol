// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

import "./dependencies/MultiBridge.sol";
import "./interfaces/ISatelliteEMPIRE.sol";

/// @title LockBurnBridge: A contract for implementing a lock and mint/burn model for cross chain transfers 
/// @author Empire Capital (Splnty)
/// @dev A contract to use with the MultiBridge contract with a lock + mint/burn model
contract LockBurnBridge is MultiBridge {
    using SafeERC20 for ISatelliteEMPIRE;
    using Address for address payable;
    // Mintable / Burnable Token
    ISatelliteEMPIRE private immutable SATELLITE_EMPIRE;

    event CrossChainBurn(address indexed from, uint256 amount);

    // Gas Units Required for an `unlock`
    uint256 private constant SATELLITE_UNLOCK_COST = 152982;

    /// @param SatelliteEMPIRE The address of the EMPIRE token for the chain being deployed on
    /// @param chainList Chain IDs of blockchains that are supported by the bridge
    constructor(ISatelliteEMPIRE SatelliteEMPIRE, uint256[] memory chainList)
        MultiBridge(chainList)
    {
        SATELLITE_EMPIRE = SatelliteEMPIRE;
    }

    /// @notice Transfers `amount` of EMPIRE to address `to` on chain `chain`
    /// @dev Called by user to begin a cross chain transfer, locking tokens on outbund chain
    /// @param to The address that will receive the tokens
    /// @param amount The amount of tokens that are being sent
    /// @param chain The chain ID of the blockchain that the tokens are being sent to
    function lock(
        address to,
        uint256 amount,
        uint256 chain
    ) external payable override validFunding validChain(chain) {
        SATELLITE_EMPIRE.lock(msg.sender, amount);

        uint256 id = crossChainTransfer++;

        outwardTransfers[id] = CrossChainTransfer(
            to,
            false,
            safe88(
                tx.gasprice,
                "LockBurnBridge::lock: tx gas price exceeds 32 bits"
            ),
            amount,
            chain
        );

        // Optionally captured by off-chain migrator
        emit CrossChainTransferLocked(msg.sender, id);
    }

    /// @notice Bridge Tx `i` on `satelliteChain`: Receive `amount` of EMPIRE at address `to`
    /// @dev Called by the server after catching event CrossChainUnlockFundsReceived to complete unlock of tokens
    /// @param satelliteChain The chain that tokens are being received from
    /// @param i The bridge nonce for the current transaction
    /// @param to The address that will receive the tokens
    /// @param amount The amount of tokens that are being received
    function unlock(
        uint256 satelliteChain,
        uint256 i,
        address to,
        uint256 amount
    ) external override onlyOperator {
        bytes32 h = keccak256(abi.encode(satelliteChain, i, to, amount));

        uint256 refundGasPrice = inwardTransferFunding[h];
        if (refundGasPrice == PROCESSED) return;
        inwardTransferFunding[h] = PROCESSED;

        SATELLITE_EMPIRE.unlock(to, amount);
        if (refundGasPrice != 0)
            payable(msg.sender).sendValue(refundGasPrice * SATELLITE_UNLOCK_COST);

        emit CrossChainTransferUnlocked(to, amount, satelliteChain);
    }

}