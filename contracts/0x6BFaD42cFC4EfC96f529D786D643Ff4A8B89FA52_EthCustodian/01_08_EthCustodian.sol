// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import 'rainbow-bridge/contracts/eth/nearbridge/contracts/AdminControlled.sol';
import 'rainbow-bridge/contracts/eth/nearbridge/contracts/Borsh.sol';
import 'rainbow-bridge/contracts/eth/nearprover/contracts/ProofDecoder.sol';
import { INearProver, ProofKeeper } from './ProofKeeper.sol';

contract EthCustodian is ProofKeeper, AdminControlled {

    uint constant UNPAUSED_ALL = 0;
    uint constant PAUSED_DEPOSIT_TO_EVM = 1 << 0;
    uint constant PAUSED_DEPOSIT_TO_NEAR = 1 << 1;
    uint constant PAUSED_WITHDRAW = 1 << 2;

    event Deposited (
        address indexed sender,
        string recipient,
        uint256 amount,
        uint256 fee
    );

    event Withdrawn(
        address indexed recipient,
        uint128 amount
    );

    // Function output from burning nETH on Near side.
    struct BurnResult {
        uint128 amount;
        address recipient;
        address ethCustodian;
    }

    /// EthCustodian is linked to the EVM on NEAR side.
    /// It also links to the prover that it uses to withdraw the tokens.
    constructor(
        bytes memory nearEvm,
        INearProver prover,
        uint64 minBlockAcceptanceHeight,
        address _admin,
        uint pausedFlags
    )
        AdminControlled(_admin, pausedFlags)
        ProofKeeper(nearEvm, prover, minBlockAcceptanceHeight)
        public
    {
    }

    /// Deposits the specified amount of provided ETH (except from the relayer's fee) into the smart contract.
    /// `ethRecipientOnNear` - the ETH address of the recipient in NEAR EVM
    /// `fee` - the amount of fee that will be paid to the near-relayer in nETH.
    function depositToEVM(
        string memory ethRecipientOnNear, 
        uint256 fee
    )
        external
        payable
        pausable(PAUSED_DEPOSIT_TO_EVM)
    {
        require(
            fee < msg.value,
            'The fee cannot be bigger than the transferred amount.'
        );

        string memory separator = ':';
        string memory protocolMessage = string(
            abi.encodePacked(
                string(nearProofProducerAccount_),
                separator, ethRecipientOnNear
            )
        );

        emit Deposited(
            msg.sender, 
            protocolMessage, 
            msg.value, 
            fee
        );
    }

    /// Deposits the specified amount of provided ETH (except from the relayer's fee) into the smart contract.
    /// `nearRecipientAccountId` - the AccountID of the recipient in NEAR
    /// `fee` - the amount of fee that will be paid to the near-relayer in nETH.
    function depositToNear(
        string memory nearRecipientAccountId, 
        uint256 fee
    )
        external
        payable
        pausable(PAUSED_DEPOSIT_TO_NEAR)
    {
        require(
            fee < msg.value,
            'The fee cannot be bigger than the transferred amount.'
        );

        emit Deposited(
            msg.sender, 
            nearRecipientAccountId, 
            msg.value, 
            fee
        );
    }

    /// Withdraws the appropriate amount of ETH which is encoded in `proofData`
    function withdraw(
        bytes calldata proofData, 
        uint64 proofBlockHeight
    )
        external
        pausable(PAUSED_WITHDRAW)
    {
        ProofDecoder.ExecutionStatus memory status = _parseAndConsumeProof(proofData, proofBlockHeight);

        BurnResult memory result = _decodeBurnResult(status.successValue);
        require(
            result.ethCustodian == address(this),
            'Can only withdraw coins that were expected for the current contract'
        );
        payable(result.recipient).transfer(result.amount);
        emit Withdrawn(
            result.recipient,
            result.amount
        );
    }

    function _decodeBurnResult(bytes memory data)
        internal
        pure
        returns (BurnResult memory result)
    {
        Borsh.Data memory borshData = Borsh.from(data);
        result.amount = borshData.decodeU128();
        bytes20 recipient = borshData.decodeBytes20();
        result.recipient = address(uint160(recipient));
        bytes20 ethCustodian = borshData.decodeBytes20();
        result.ethCustodian = address(uint160(ethCustodian));
    }
}