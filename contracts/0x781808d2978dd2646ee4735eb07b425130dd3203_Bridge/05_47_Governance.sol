//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import "./Structs.sol";
import "./Authority.sol";
import "./Setters.sol";

/// @title Governance
/// @notice This contract is a message handler for governance messages.
/// @author Piotr "pibu" Buda
contract Governance is Authority, Setters, ERC1967Upgrade {
    /// @notice This error is raised when the BridgeUpgrade message contains a timelock setting - the value of onlyAfterBlock != 0
    /// and the current block.number is not after that value.
    /// @param currentBlock the value of block.number
    /// @param onlyAfterBlock the value of the BridgeUpgrade.onlyAfterBlock
    error UpgradeTimelockViolation(uint256 currentBlock, uint256 onlyAfterBlock);

    /// @notice Allows to change the authorities responsible for signing the messages sent to the bridge.
    /// new authorities MUST contain at least one address
    /// @param message the message signed by the current authority with payload allowing to change the authorities
    function changeAuthorities(Structs.VSM calldata message) external {
        verifyAndUseGovernanceMessage(message);

        address[] memory keys = abi.decode(message.payload, (address[]));
        require(keys.length > 0, "NO_AUTHORITIES");

        setAuthorities(keys);
        emit AuthoritiesChanged(keys);
    }

    /// @notice Executes the upgrade message and if the init value is set, executes the call. If the onlyAfterBlock value is set,
    /// then the upgrade will fail if the current block number is not after the set value. This method reverts if the message is not signed,
    /// there is no quorum or the message doesn't come from the governance chaincode from the Play blockchain.
    /// @param message The VSM containing the Structs.BridgeUpgrade as payload.
    function upgrade(Structs.VSM calldata message) external {
        verifyAndUseGovernanceMessage(message);

        Structs.BridgeUpgrade memory bu = abi.decode(message.payload, (Structs.BridgeUpgrade));

        if (block.number < bu.onlyAfterBlock) {
            revert UpgradeTimelockViolation(block.number, bu.onlyAfterBlock);
        }

        _upgradeToAndCall(bu.newImplementation, bu.init, false);
    }

    /// @notice This is an extension of the verifyMessage function from the Authority contract that verifies that a message comes from governance entity.
    /// @dev The governance messages must originate from a specific contract, configured during the bridge deployment.
    /// This methodusedGovernanceMessagesr field of the VSM is not set to governanceContract value in the state.
    function verifyGovernanceMessage(Structs.VSM calldata message, bytes32 messageHash) public view returns (bool result, string memory failureReason) {
        if (isGovernanceMessageUsed(messageHash)) {
            return (false, "GOVERNANCE_MESSAGE_CONSUMED");
        }

        if (message.emitter != governanceContract()) {
            return (false, "NOT_FROM_GOVERNANCE_CONTRACT");
        }

        return verifyMessage(message, messageHash);
    }

    /// @dev a helper method to prevent recalculation of the message hash
    function verifyAndUseGovernanceMessage(Structs.VSM calldata message) internal {
        bytes32 messageHash = keccak256(abi.encodePacked(message.emitter, message.chainId, message.sequence, message.nonce, message.payload));
        (bool isValid, string memory reason) = verifyGovernanceMessage(message, messageHash);
        require(isValid, reason);
        useGovernanceMessage(messageHash);
    }
}