// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IValidatorPool.sol";
import "contracts/libraries/ethdkg/ETHDKGStorage.sol";
import "contracts/interfaces/IETHDKGEvents.sol";
import "contracts/utils/ETHDKGUtils.sol";
import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/libraries/errors/ETHDKGErrors.sol";

/// @custom:salt ETHDKGAccusations
/// @custom:deploy-type deployUpgradeable
/// @custom:deploy-group ethdkg
/// @custom:deploy-group-index 0
contract ETHDKGAccusations is ETHDKGStorage, IETHDKGEvents, ETHDKGUtils {
    constructor() ETHDKGStorage() {}

    function accuseParticipantNotRegistered(address[] memory dishonestAddresses) external {
        if (
            _ethdkgPhase != Phase.RegistrationOpen ||
            block.number < _phaseStartBlock + _phaseLength ||
            block.number >= _phaseStartBlock + 2 * _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.RegistrationOpen,
                _phaseStartBlock + _phaseLength,
                _phaseStartBlock + 2 * _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        uint16 badParticipants = _badParticipants;
        for (uint256 i = 0; i < dishonestAddresses.length; i++) {
            if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddresses[i])) {
                revert ETHDKGErrors.AccusedNotValidator(dishonestAddresses[i]);
            }

            // check if the dishonestParticipant didn't participate in the registration phase,
            // so it doesn't have a Participant object with the latest nonce
            Participant memory dishonestParticipant = _participants[dishonestAddresses[i]];
            if (dishonestParticipant.nonce == _nonce) {
                revert ETHDKGErrors.AccusedParticipatingInRound(dishonestAddresses[i]);
            }

            // this makes sure we cannot accuse someone twice because a minor fine will be enough to
            // evict the validator from the pool
            IValidatorPool(_validatorPoolAddress()).minorSlash(dishonestAddresses[i], msg.sender);
            badParticipants++;
        }
        _badParticipants = badParticipants;
    }

    function accuseParticipantDidNotDistributeShares(address[] memory dishonestAddresses) external {
        if (
            _ethdkgPhase != Phase.ShareDistribution ||
            block.number < _phaseStartBlock + _phaseLength ||
            block.number >= _phaseStartBlock + 2 * _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.ShareDistribution,
                _phaseStartBlock + _phaseLength,
                _phaseStartBlock + 2 * _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        uint16 badParticipants = _badParticipants;

        for (uint256 i = 0; i < dishonestAddresses.length; i++) {
            if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddresses[i])) {
                revert ETHDKGErrors.AccusedNotValidator(dishonestAddresses[i]);
            }
            Participant memory dishonestParticipant = _participants[dishonestAddresses[i]];

            if (dishonestParticipant.nonce != _nonce) {
                revert ETHDKGErrors.AccusedNotParticipatingInRound(dishonestAddresses[i]);
            }

            if (dishonestParticipant.phase == Phase.ShareDistribution) {
                revert ETHDKGErrors.AccusedDistributedSharesInRound(dishonestAddresses[i]);
            }

            if (dishonestParticipant.distributedSharesHash != 0x0) {
                revert ETHDKGErrors.AccusedDistributedSharesInRound(dishonestAddresses[i]);
            }
            if (
                dishonestParticipant.commitmentsFirstCoefficient[0] != 0 ||
                dishonestParticipant.commitmentsFirstCoefficient[1] != 0
            ) {
                revert ETHDKGErrors.AccusedHasCommitments(dishonestAddresses[i]);
            }

            IValidatorPool(_validatorPoolAddress()).minorSlash(dishonestAddresses[i], msg.sender);
            badParticipants++;
        }

        _badParticipants = badParticipants;
    }

    function accuseParticipantDistributedBadShares(
        address dishonestAddress,
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments,
        uint256[2] memory sharedKey,
        uint256[2] memory sharedKeyCorrectnessProof
    ) external {
        // We should allow accusation, even if some of the participants didn't participate
        {
            bool isInDisputeShareDistribution = _ethdkgPhase == Phase.DisputeShareDistribution &&
                block.number >= _phaseStartBlock &&
                block.number < _phaseStartBlock + _phaseLength;
            bool isInShareDistribution = _ethdkgPhase == Phase.ShareDistribution &&
                block.number >= _phaseStartBlock + _phaseLength &&
                block.number < _phaseStartBlock + 2 * _phaseLength;
            if (!isInDisputeShareDistribution && !isInShareDistribution) {
                PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](2);
                expectedPhaseInfos[0] = PhaseInformation(
                    Phase.DisputeShareDistribution,
                    _phaseStartBlock,
                    _phaseStartBlock + _phaseLength
                );
                expectedPhaseInfos[1] = PhaseInformation(
                    Phase.ShareDistribution,
                    _phaseStartBlock + _phaseLength,
                    _phaseStartBlock + 2 * _phaseLength
                );
                revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
            }
        }

        if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddress)) {
            revert ETHDKGErrors.AccusedNotValidator(dishonestAddress);
        }

        Participant memory dishonestParticipant = _participants[dishonestAddress];
        Participant memory disputer = _participants[msg.sender];

        if (disputer.nonce != _nonce) {
            revert ETHDKGErrors.DisputerNotParticipatingInRound(msg.sender);
        }

        if (dishonestParticipant.nonce != _nonce) {
            revert ETHDKGErrors.AccusedNotParticipatingInRound(dishonestAddress);
        }

        if (dishonestParticipant.phase != Phase.ShareDistribution) {
            revert ETHDKGErrors.AccusedDidNotDistributeSharesInRound(dishonestAddress);
        }

        if (disputer.phase != Phase.ShareDistribution) {
            revert ETHDKGErrors.DisputerDidNotDistributeSharesInRound(msg.sender);
        }

        if (
            dishonestParticipant.distributedSharesHash !=
            keccak256(
                abi.encodePacked(
                    keccak256(abi.encodePacked(encryptedShares)),
                    keccak256(abi.encodePacked(commitments))
                )
            )
        ) {
            revert ETHDKGErrors.SharesAndCommitmentsMismatch(
                dishonestParticipant.distributedSharesHash,
                keccak256(
                    abi.encodePacked(
                        keccak256(abi.encodePacked(encryptedShares)),
                        keccak256(abi.encodePacked(commitments))
                    )
                )
            );
        }

        if (
            !CryptoLibrary.discreteLogEquality(
                [CryptoLibrary.G1_X, CryptoLibrary.G1_Y],
                disputer.publicKey,
                dishonestParticipant.publicKey,
                sharedKey,
                sharedKeyCorrectnessProof
            )
        ) {
            revert ETHDKGErrors.InvalidKeyOrProof();
        }

        // Since all provided data is valid so far, we load the share and use the verified shared
        // key to decrypt the share for the disputer.
        uint256 share;
        if (disputer.index < dishonestParticipant.index) {
            share = encryptedShares[disputer.index - 1];
        } else {
            share = encryptedShares[disputer.index - 2];
        }
        share ^= uint256(keccak256(abi.encodePacked(sharedKey[0], disputer.index)));

        // Verify the share for it's correctness using the polynomial defined by the commitments.
        // First, the polynomial (in group G1) is evaluated at the disputer's idx.
        uint256 x = disputer.index;
        uint256[2] memory result = commitments[0];
        uint256[2] memory tmp = CryptoLibrary.bn128Multiply(
            [commitments[1][0], commitments[1][1], x]
        );
        result = CryptoLibrary.bn128Add([result[0], result[1], tmp[0], tmp[1]]);
        for (uint256 j = 2; j < commitments.length; j++) {
            x = mulmod(x, disputer.index, CryptoLibrary.GROUP_ORDER);
            tmp = CryptoLibrary.bn128Multiply([commitments[j][0], commitments[j][1], x]);
            result = CryptoLibrary.bn128Add([result[0], result[1], tmp[0], tmp[1]]);
        }
        // Then the result is compared to the point in G1 corresponding to the decrypted share.
        // In this case, either the shared value is invalid, so the dishonestAddress
        // should be burned; otherwise, the share is valid, and whoever
        // submitted this accusation should be burned. In any case, someone
        // will have his stake burned.
        tmp = CryptoLibrary.bn128Multiply([CryptoLibrary.G1_X, CryptoLibrary.G1_Y, share]);
        if (result[0] != tmp[0] || result[1] != tmp[1]) {
            IValidatorPool(_validatorPoolAddress()).majorSlash(dishonestAddress, msg.sender);
        } else {
            IValidatorPool(_validatorPoolAddress()).majorSlash(msg.sender, dishonestAddress);
        }
        _badParticipants++;
    }

    function accuseParticipantDidNotSubmitKeyShares(address[] memory dishonestAddresses) external {
        if (
            _ethdkgPhase != Phase.KeyShareSubmission ||
            block.number < _phaseStartBlock + _phaseLength ||
            block.number >= _phaseStartBlock + 2 * _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.KeyShareSubmission,
                _phaseStartBlock + _phaseLength,
                _phaseStartBlock + 2 * _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        uint16 badParticipants = _badParticipants;

        for (uint256 i = 0; i < dishonestAddresses.length; i++) {
            if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddresses[i])) {
                revert ETHDKGErrors.AccusedNotValidator(dishonestAddresses[i]);
            }

            Participant memory dishonestParticipant = _participants[dishonestAddresses[i]];

            if (dishonestParticipant.nonce != _nonce) {
                revert ETHDKGErrors.AccusedNotParticipatingInRound(dishonestAddresses[i]);
            }

            if (dishonestParticipant.phase == Phase.KeyShareSubmission) {
                revert ETHDKGErrors.AccusedSubmittedSharesInRound(dishonestAddresses[i]);
            }

            if (dishonestParticipant.keyShares[0] != 0 || dishonestParticipant.keyShares[1] != 0) {
                revert ETHDKGErrors.AccusedSubmittedSharesInRound(dishonestAddresses[i]);
            }

            // evict the validator that didn't submit his shares
            IValidatorPool(_validatorPoolAddress()).minorSlash(dishonestAddresses[i], msg.sender);
            badParticipants++;
        }
        _badParticipants = badParticipants;
    }

    function accuseParticipantDidNotSubmitGPKJ(address[] memory dishonestAddresses) external {
        if (
            _ethdkgPhase != Phase.GPKJSubmission ||
            block.number < _phaseStartBlock + _phaseLength ||
            block.number >= _phaseStartBlock + 2 * _phaseLength
        ) {
            PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](1);
            expectedPhaseInfos[0] = PhaseInformation(
                Phase.GPKJSubmission,
                _phaseStartBlock + _phaseLength,
                _phaseStartBlock + 2 * _phaseLength
            );
            revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
        }

        uint16 badParticipants = _badParticipants;

        for (uint256 i = 0; i < dishonestAddresses.length; i++) {
            if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddresses[i])) {
                revert ETHDKGErrors.AccusedNotValidator(dishonestAddresses[i]);
            }
            Participant memory dishonestParticipant = _participants[dishonestAddresses[i]];

            if (dishonestParticipant.nonce != _nonce) {
                revert ETHDKGErrors.AccusedNotParticipatingInRound(dishonestAddresses[i]);
            }

            if (dishonestParticipant.phase == Phase.GPKJSubmission) {
                revert ETHDKGErrors.AccusedDidNotParticipateInGPKJSubmission(dishonestAddresses[i]);
            }

            // todo: being paranoic, check if we need this or if it's expensive
            if (
                dishonestParticipant.gpkj[0] != 0 ||
                dishonestParticipant.gpkj[1] != 0 ||
                dishonestParticipant.gpkj[2] != 0 ||
                dishonestParticipant.gpkj[3] != 0
            ) {
                revert ETHDKGErrors.AccusedDistributedGPKJ(dishonestAddresses[i]);
            }

            IValidatorPool(_validatorPoolAddress()).minorSlash(dishonestAddresses[i], msg.sender);
            badParticipants++;
        }

        _badParticipants = badParticipants;
    }

    function accuseParticipantSubmittedBadGPKJ(
        address[] memory validators,
        bytes32[] memory encryptedSharesHash,
        uint256[2][][] memory commitments,
        address dishonestAddress
    ) external {
        // We should allow accusation, even if some of the participants didn't participate
        {
            bool isInDisputeGPKJSubmission = _ethdkgPhase == Phase.DisputeGPKJSubmission &&
                block.number >= _phaseStartBlock &&
                block.number < _phaseStartBlock + _phaseLength;
            bool isInGPKJSubmission = _ethdkgPhase == Phase.GPKJSubmission &&
                block.number >= _phaseStartBlock + _phaseLength &&
                block.number < _phaseStartBlock + 2 * _phaseLength;
            if (!isInDisputeGPKJSubmission && !isInGPKJSubmission) {
                PhaseInformation[] memory expectedPhaseInfos = new PhaseInformation[](2);
                expectedPhaseInfos[0] = PhaseInformation(
                    Phase.DisputeGPKJSubmission,
                    _phaseStartBlock,
                    _phaseStartBlock + _phaseLength
                );
                expectedPhaseInfos[1] = PhaseInformation(
                    Phase.GPKJSubmission,
                    _phaseStartBlock + _phaseLength,
                    _phaseStartBlock + 2 * _phaseLength
                );
                revert ETHDKGErrors.IncorrectPhase(_ethdkgPhase, block.number, expectedPhaseInfos);
            }
        }

        if (!IValidatorPool(_validatorPoolAddress()).isValidator(dishonestAddress)) {
            revert ETHDKGErrors.AccusedNotValidator(dishonestAddress);
        }

        Participant memory dishonestParticipant = _participants[dishonestAddress];
        Participant memory disputer = _participants[msg.sender];

        if (
            dishonestParticipant.nonce != _nonce ||
            dishonestParticipant.phase != Phase.GPKJSubmission
        ) {
            revert ETHDKGErrors.AccusedDidNotSubmitGPKJInRound(dishonestAddress);
        }

        if (disputer.nonce != _nonce || disputer.phase != Phase.GPKJSubmission) {
            revert ETHDKGErrors.DisputerDidNotSubmitGPKJInRound(msg.sender);
        }

        uint16 badParticipants = _badParticipants;
        // n is total _participants;
        // t is threshold, so that t+1 is BFT majority.
        uint256 numParticipants = IValidatorPool(_validatorPoolAddress()).getValidatorsCount() +
            badParticipants;
        uint256 threshold = _getThreshold(numParticipants);

        // Begin initial check
        ////////////////////////////////////////////////////////////////////////
        // First, check length of things
        if (
            validators.length != numParticipants ||
            encryptedSharesHash.length != numParticipants ||
            commitments.length != numParticipants
        ) {
            revert ETHDKGErrors.ArgumentsLengthDoesNotEqualNumberOfParticipants(
                validators.length,
                encryptedSharesHash.length,
                commitments.length,
                numParticipants
            );
        }
        {
            uint256 bitMap = 0;
            uint256 nonce = _nonce;
            // Now, ensure sub-arrays are the correct length as well
            for (uint256 k = 0; k < numParticipants; k++) {
                if (commitments[k].length != threshold + 1) {
                    revert ETHDKGErrors.InvalidCommitments(commitments[k].length, threshold + 1);
                }

                bytes32 commitmentsHash = keccak256(abi.encodePacked(commitments[k]));
                Participant memory participant = _participants[validators[k]];
                if (
                    participant.nonce != nonce ||
                    participant.index > type(uint8).max ||
                    _isBitSet(bitMap, uint8(participant.index))
                ) {
                    revert ETHDKGErrors.InvalidOrDuplicatedParticipant(validators[k]);
                }

                if (
                    participant.distributedSharesHash !=
                    keccak256(abi.encodePacked(encryptedSharesHash[k], commitmentsHash))
                ) {
                    revert ETHDKGErrors.InvalidSharesOrCommitments(
                        participant.distributedSharesHash,
                        keccak256(abi.encodePacked(encryptedSharesHash[k], commitmentsHash))
                    );
                }
                bitMap = _setBit(bitMap, uint8(participant.index));
            }
        }

        ////////////////////////////////////////////////////////////////////////
        // End initial check

        // Info for looping computation
        uint256 pow;
        uint256[2] memory gpkjStar;
        uint256[2] memory tmp;
        uint256 idx;

        // Begin computation loop
        //
        // We remember
        //
        //      F_i(x) = C_i0 * C_i1^x * C_i2^(x^2) * ... * C_it^(x^t)
        //             = Prod(C_ik^(x^k), k = 0, 1, ..., t)
        //
        // We now compute gpkj*. We have
        //
        //      gpkj* = Prod(F_i(j), i)
        //            = Prod( Prod(C_ik^(j^k), k = 0, 1, ..., t), i)
        //            = Prod( Prod(C_ik^(j^k), i), k = 0, 1, ..., t)    // Switch order
        //            = Prod( [Prod(C_ik, i)]^(j^k), k = 0, 1, ..., t)  // Move exponentiation outside
        //
        // More explicitly, we have
        //
        //      gpkj* =  Prod(C_i0, i)        *
        //              [Prod(C_i1, i)]^j     *
        //              [Prod(C_i2, i)]^(j^2) *
        //                  ...
        //              [Prod(C_it, i)]^(j^t) *
        //
        ////////////////////////////////////////////////////////////////////////
        // Add constant terms
        gpkjStar = commitments[0][0]; // Store initial constant term
        for (idx = 1; idx < numParticipants; idx++) {
            gpkjStar = CryptoLibrary.bn128Add(
                [gpkjStar[0], gpkjStar[1], commitments[idx][0][0], commitments[idx][0][1]]
            );
        }

        // Add linear term
        tmp = commitments[0][1]; // Store initial linear term
        pow = dishonestParticipant.index;
        for (idx = 1; idx < numParticipants; idx++) {
            tmp = CryptoLibrary.bn128Add(
                [tmp[0], tmp[1], commitments[idx][1][0], commitments[idx][1][1]]
            );
        }
        tmp = CryptoLibrary.bn128Multiply([tmp[0], tmp[1], pow]);
        gpkjStar = CryptoLibrary.bn128Add([gpkjStar[0], gpkjStar[1], tmp[0], tmp[1]]);

        // Loop through higher order terms
        for (uint256 k = 2; k <= threshold; k++) {
            tmp = commitments[0][k]; // Store initial degree k term
            // Increase pow by factor
            pow = mulmod(pow, dishonestParticipant.index, CryptoLibrary.GROUP_ORDER);
            for (idx = 1; idx < numParticipants; idx++) {
                tmp = CryptoLibrary.bn128Add(
                    [tmp[0], tmp[1], commitments[idx][k][0], commitments[idx][k][1]]
                );
            }
            tmp = CryptoLibrary.bn128Multiply([tmp[0], tmp[1], pow]);
            gpkjStar = CryptoLibrary.bn128Add([gpkjStar[0], gpkjStar[1], tmp[0], tmp[1]]);
        }
        ////////////////////////////////////////////////////////////////////////
        // End computation loop

        // We now have gpkj*; we now verify.
        uint256[4] memory gpkj = dishonestParticipant.gpkj;
        bool isValid = CryptoLibrary.bn128CheckPairing(
            [
                gpkjStar[0],
                gpkjStar[1],
                CryptoLibrary.H2_XI,
                CryptoLibrary.H2_X,
                CryptoLibrary.H2_YI,
                CryptoLibrary.H2_Y,
                CryptoLibrary.G1_X,
                CryptoLibrary.G1_Y,
                gpkj[0],
                gpkj[1],
                gpkj[2],
                gpkj[3]
            ]
        );
        if (!isValid) {
            IValidatorPool(_validatorPoolAddress()).majorSlash(dishonestAddress, msg.sender);
        } else {
            IValidatorPool(_validatorPoolAddress()).majorSlash(msg.sender, dishonestAddress);
        }
        badParticipants++;
        _badParticipants = badParticipants;
    }
}