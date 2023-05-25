// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "rainbow-bridge/contracts/eth/nearprover/contracts/ProofDecoder.sol";
import "rainbow-bridge/contracts/eth/nearbridge/contracts/Borsh.sol";
import "rainbow-bridge/contracts/eth/nearbridge/contracts/AdminControlled.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Bridge, INearProver } from "./Bridge.sol";

contract eNear is ERC20, Bridge, AdminControlled {

    uint constant PAUSE_FINALISE_FROM_NEAR = 1 << 0;
    uint constant PAUSE_TRANSFER_TO_NEAR = 1 << 1;

    event TransferToNearInitiated (
        address indexed sender,
        uint256 amount,
        string accountId
    );

    event NearToEthTransferFinalised (
        uint128 amount,
        address indexed recipient
    );

    struct BridgeResult {
        uint128 amount;
        address recipient;
    }

    /// @param _tokenName Name given to the token (can be admin updated)
    /// @param _tokenSymbol Symbol given to the token (can be admin updated)
    /// @param _nearConnector Near account ID of the near connector bridge
    /// @param _prover Address of the prover contract on ETH
    /// @param _minBlockAcceptanceHeight The contract will accept proofs from this block onwards
    /// @param _admin Address that can make admin changes to the contract
    /// @param _pausedFlags Flag settings which controls whether certain methods are paused or active
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        bytes memory _nearConnector,
        INearProver _prover,
        uint64 _minBlockAcceptanceHeight,
        address _admin,
        uint256 _pausedFlags
    ) public ERC20(_tokenName, _tokenSymbol) AdminControlled(_admin, _pausedFlags) Bridge(_prover, _nearConnector, _minBlockAcceptanceHeight) {
        // Match yocto Near
        _setupDecimals(24);
    }

    function finaliseNearToEthTransfer(bytes memory proofData, uint64 proofBlockHeight)
    external pausable (PAUSE_FINALISE_FROM_NEAR) {
        ProofDecoder.ExecutionStatus memory status = _parseAndConsumeProof(proofData, proofBlockHeight);
        BridgeResult memory result = _decodeBridgeResult(status.successValue);

        _mint(result.recipient, result.amount);

        emit NearToEthTransferFinalised(result.amount, result.recipient);
    }

    function transferToNear(uint256 _amount, string memory _nearReceiverAccountId)
    external pausable (PAUSE_TRANSFER_TO_NEAR) {
        _burn(msg.sender, _amount);
        emit TransferToNearInitiated(msg.sender, _amount, _nearReceiverAccountId);
    }

    function _decodeBridgeResult(bytes memory data) internal pure returns(BridgeResult memory result) {
        Borsh.Data memory borshData = Borsh.from(data);
        uint8 flag = borshData.decodeU8();
        require(flag == 0, "ERR_NOT_WITHDRAW_RESULT");
        result.amount = borshData.decodeU128();
        bytes20 recipient = borshData.decodeBytes20();
        result.recipient = address(uint160(recipient));
    }
}