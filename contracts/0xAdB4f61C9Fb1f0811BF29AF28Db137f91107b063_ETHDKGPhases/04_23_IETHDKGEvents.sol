// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IETHDKGEvents {
    event RegistrationOpened(
        uint256 startBlock,
        uint256 numberValidators,
        uint256 nonce,
        uint256 phaseLength,
        uint256 confirmationLength
    );

    event AddressRegistered(address account, uint256 index, uint256 nonce, uint256[2] publicKey);

    event RegistrationComplete(uint256 blockNumber);

    event SharesDistributed(
        address account,
        uint256 index,
        uint256 nonce,
        uint256[] encryptedShares,
        uint256[2][] commitments
    );

    event ShareDistributionComplete(uint256 blockNumber);

    event KeyShareSubmitted(
        address account,
        uint256 index,
        uint256 nonce,
        uint256[2] keyShareG1,
        uint256[2] keyShareG1CorrectnessProof,
        uint256[4] keyShareG2
    );

    event KeyShareSubmissionComplete(uint256 blockNumber);

    event MPKSet(uint256 blockNumber, uint256 nonce, uint256[4] mpk);

    event GPKJSubmissionComplete(uint256 blockNumber);

    event ValidatorMemberAdded(
        address account,
        uint256 index,
        uint256 nonce,
        uint256 epoch,
        uint256 share0,
        uint256 share1,
        uint256 share2,
        uint256 share3
    );

    event ValidatorSetCompleted(
        uint256 validatorCount,
        uint256 nonce,
        uint256 epoch,
        uint256 ethHeight,
        uint256 aliceNetHeight,
        uint256 groupKey0,
        uint256 groupKey1,
        uint256 groupKey2,
        uint256 groupKey3
    );
}