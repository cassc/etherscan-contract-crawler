// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@helix-foundation/eco-id/contracts/EcoID.sol";
import "@helix-foundation/eco-id/contracts/interfaces/IECO.sol";

contract EcoClaim is Ownable, EIP712("EcoClaim", "1") {
    /**
     * Use for validating merkel proof of claims for tokens
     */
    using MerkleProof for bytes32[];

    /**
     * Use for signarture recovery and verification on token claiming
     */
    using ECDSA for bytes32;

    /**
     * Use for tracking the nonces on signatures
     */
    using Counters for Counters.Counter;

    /**
     * Event for when the constructor has finished
     */
    event InitializeEcoClaim();

    /**
     * Event for when a claim is made
     */
    event Claim(
        string socialID,
        address indexed addr,
        uint256 eco,
        uint256 ecox
    );

    /**
     * Event for vesting release
     */
    event ReleaseVesting(
        address indexed addr,
        address indexed gasPayer,
        uint256 ecoBalance,
        uint256 vestedEcoXBalance,
        uint256 feeAmount
    );

    /**
     * Error for when the a signature has expired
     */
    error SignatureExpired();

    /**
     * Error for when the signature is invalid
     */
    error InvalidSignature();

    /**
     * Error for when the first claim is called after the claim period
     */
    error ClaimDeadlineExpired();

    /**
     * Error for when a claim has not been verified in the EcoID by the trusted verifier
     */
    error UnverifiedClaim();

    /**
     * Error for when the submitted proof fails to be validated against the merkle root
     */
    error InvalidProof();

    /**
     * Error for when the submitted proof is not the same depth as the merkle tree
     */
    error InvalidProofDepth();

    /**
     * Error for when the fee amount is greater than the available eco balance
     */
    error InvalidFee();

    /**
     * Error for when the user tries to claim with no points in their balance
     */
    error InvalidPoints();

    /**
     * Error for when the the caller of the release tokens is not the same as that stored in _claimBalances
     */
    error InvalidReleaseCaller();

    /**
     * Error for when the recipient is trying to release an empty balance
     */
    error EmptyVestingBalance();

    /**
     * Error for when the cliff date has not been reached yet and the user tries to release tokens
     */
    error CliffNotMet();

    /**
     * Error for when a user tries to claim tokens for a given social id, that have already been claimed
     */
    error TokensAlreadyClaimed();

    /**
     * Struct for holding the claim fields for a user
     */
    struct ClaimBalance {
        address recipient; //user's addres to send funds to
        uint256 points; //user's initial point balance
        uint256 claimTime; //timestamp of initial claim
    }

    /**
     * The hash of the register function signature for the recipient
     */
    bytes32 private constant CLAIM_TYPEHASH =
        keccak256(
            "Claim(string socialID,address recipient,uint256 feeAmount,uint256 deadline,uint256 nonce)"
        );

    /**
     * The hash of the register function signature for the recipient
     */
    bytes32 private constant RELEASE_TYPEHASH =
        keccak256(
            "Release(string socialID,address recipient,uint256 feeAmount,uint256 deadline,uint256 nonce)"
        );

    /**
     * The period that we use to determine how much the user has vested in ECOx
     */
    uint256 public constant VESTING_PERIOD = 30 days;

    /**
     * The period that a user can claim any tokens
     */
    uint256 public constant CLAIMABLE_PERIOD = 356 days;

    /**
     * The merkel root for the data that maps social ids to their points distribution
     */
    bytes32 public immutable _pointsMerkleRoot;

    /**
     * The depth of the merkel tree from root to leaf. We use this to verify the length of the
     * proofs submitted for verifiaction
     */
    uint256 public immutable _proofDepth;

    /**
     * The mapping that stores the claim status for an account
     */
    mapping(string => bool) public _claimedBalances;

    /**
     * The mapping that stores the claim status for a social id
     */
    mapping(string => ClaimBalance) public _claimBalances;

    /**
     * The mapping that store the current nonce for a social id
     */
    mapping(string => Counters.Counter) private _nonces;

    /**
     * The eco ERC20 contract
     */
    IECO public immutable _eco;

    /**
     * The ecoX ERC20 contract
     */
    ERC20 public immutable _ecoX;

    /**
     * The EcoID contract
     */
    EcoID public immutable _ecoID;

    /**
     * The vesting multiples that users generate over time
     * 0.5x ECOx + 5x ECO at 30 days after initial claim
     * 1.5x ECOx + 5x ECO at 6 mos / 180 days after initial claim
     * 2.5x ECOx + 5x ECO at 18 mos / 540 days after initial claim
     * 3.5x ECOx + 5x ECO at 24 mos / 720 days after initial claim
     */
    uint256[24] public _vestedMultiples = [
        5,
        5,
        5,
        5,
        5,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        25,
        25,
        25,
        25,
        25,
        25,
        35
    ];

    /**
     * The divider for calculating the ECOx vesting returns
     */
    uint256 public constant VESTING_DIVIDER = 10;

    /**
     * The multiplier for points to eco conversion
     */
    uint256 public constant POINTS_MULTIPLIER = 5;

    /**
     * The time that the contract is deployed
     */
    uint256 public immutable _deployTimestamp = block.timestamp;

    /**
     * The time that a user can claim their eco
     */
    uint256 public immutable _claimableEndTime =
        block.timestamp + CLAIMABLE_PERIOD;

    /**
     * The conversion coefficient for when we calculate how much ecox a participant is entitled to for every eco during the initial claim.
     * 2 means points * 1/2 = ecox
     */
    uint256 public constant POINTS_TO_ECOX_RATIO = 2;

    /**
     * The trusted verifier for the socialIDs in the EcoID contract
     */
    address public immutable _trustedVerifier;

    /**
     * The inflation multiplier for eco at deploy, used to calculate payouts
     */
    uint256 public immutable _initialInflationMultiplier;

    /**
     * Constructor that sets the initial conditions and emits an initialization event
     *
     * @param eco the address of the eco contract
     * @param ecoX the address of the ecox contract
     * @param ecoID the address of the EcoID we use to check verifiation
     * @param trustedVerifier the address of the trusted verifier for claims in the EcoID
     * @param merkelRoot the root of the merkle tree used to verify socialId and point distribution
     */
    constructor(
        IECO eco,
        ERC20 ecoX,
        EcoID ecoID,
        address trustedVerifier,
        bytes32 merkelRoot,
        uint256 proofDepth
    ) {
        _eco = eco;
        _ecoX = ecoX;
        _ecoID = ecoID;
        _trustedVerifier = trustedVerifier;
        _pointsMerkleRoot = merkelRoot;
        _proofDepth = proofDepth;
        _initialInflationMultiplier = _eco.getPastLinearInflation(block.number);

        emit InitializeEcoClaim();
    }

    /**
     * Claims tokens that the caller is owned. The caller needs to present the merkel proof
     * for their token allocation. The leaf is generated as the hash of the socialID and
     * points, in that order.
     *
     * @param proof The merkel proof that the socialID and points are correct
     * @param socialID the socialID of the recipient
     * @param points the amount of points the user can claim, must be same as in the merkel tree and not an arbitrary amount
     */
    function claimTokens(
        bytes32[] memory proof,
        string calldata socialID,
        uint256 points
    ) external {
        _claimTokens(proof, socialID, points, msg.sender, 0);
    }

    /**
     * Claims tokens on behalf of a recipient. The recipient has agreed to let another account make the on-chain tx for them, and
     * has agreed to pay them a fee in eco for the service. The caller needs to present the merkel proof for their token allocation.
     * The leaf is generated as the hash of the socialID and points, in that order.
     *
     * @param proof The merkel proof that the socialID and points are correct
     * @param socialID the socialID of the recipient
     * @param points the amount of points the user can claim, must be same as in the merkel tree and not an arbitrary amount
     * @param recipient the recipient of the tokens
     * @param feeAmount the fee in eco the payer is granted from the recipient
     * @param deadline the time at which the signature is no longer valid
     * @param recipientSig the signature signed by the recipient
     */
    function claimTokensOnBehalf(
        bytes32[] memory proof,
        string calldata socialID,
        uint256 points,
        address recipient,
        uint256 feeAmount,
        uint256 deadline,
        bytes calldata recipientSig
    ) external {
        //the claim signature is being called within its valid period
        if (block.timestamp > deadline) {
            revert SignatureExpired();
        }

        //the signature is properly signed
        if (
            !_verifyClaimSigature(
                socialID,
                recipient,
                feeAmount,
                deadline,
                _useNonce(socialID),
                recipientSig
            )
        ) {
            revert InvalidSignature();
        }

        _claimTokens(proof, socialID, points, recipient, feeAmount);
    }

    /**
     * Releases the vested tokens if its passed the initial cliff date. The further from the initial cliff this
     * method is called, the greater a multiple the recipients tokens generate.
     */
    function releaseTokens(string calldata socialID) external {
        _releaseTokens(socialID, msg.sender, 0);
    }

    /**
     * Releases the vested tokens if its passed the initial cliff date. The recipient is paying the caller of this contract
     * and reward them in ecoX. The caller has to present a valid signature to release the funds
     *
     * @param socialID the socialID of the recipient
     * @param recipient the recipient of the tokens
     * @param feeAmount the fee in eco the payer is granted from the recipient
     * @param deadline the time at which the signature is no longer valid
     * @param recipientSig the signature signed by the recipient
     */
    function releaseTokensOnBehalf(
        string calldata socialID,
        address recipient,
        uint256 feeAmount,
        uint256 deadline,
        bytes calldata recipientSig
    ) external {
        //the release signature is being called within its valid period
        if (block.timestamp > deadline) {
            revert SignatureExpired();
        }

        //the signature is properly signed
        if (
            !_verifyReleaseSigature(
                socialID,
                recipient,
                feeAmount,
                deadline,
                _useNonce(socialID),
                recipientSig
            )
        ) {
            revert InvalidSignature();
        }

        _releaseTokens(socialID, recipient, feeAmount);
    }

    /**
     * Makes the _domainSeparatorV4() function externally callable for signature generation
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * Claim the tokens. The caller needs to present the merkel proof for their token allocation.
     * The leaf is generated as the hash of the socialID and points, in that order.
     *
     * @param proof The merkel proof that the socialID and points are correct
     * @param socialID the socialID of the recipient
     * @param points the amount of points the user can claim, must be same as in the merkel tree and not an arbitrary amount
     * @param recipient the recipient of the tokens
     * @param feeAmount the fee in eco the payer is granted from the recipient
     */
    function _claimTokens(
        bytes32[] memory proof,
        string calldata socialID,
        uint256 points,
        address recipient,
        uint256 feeAmount
    ) internal {
        //Checks that the social id has not claimed its tokens
        if (_claimedBalances[socialID]) {
            revert TokensAlreadyClaimed();
        }

        //the claim is submitted in the claimable window since contract deploy
        if (block.timestamp > _claimableEndTime) {
            revert ClaimDeadlineExpired();
        }

        //require that the proof length is the same as the merkel tree depth
        if (proof.length != _proofDepth) {
            revert InvalidProofDepth();
        }

        //require that there are points to claim
        if (points == 0) {
            revert InvalidPoints();
        }

        //require that the fee is below the token amount
        if (feeAmount > points * POINTS_MULTIPLIER) {
            revert InvalidFee();
        }

        //eco tokens exist and have not been claimed yet
        if (!_ecoID.isClaimVerified(recipient, socialID, _trustedVerifier)) {
            revert UnverifiedClaim();
        }

        //verift merkle proof from input args
        bytes32 leaf = _getLeaf(socialID, points);
        if (!proof.verify(_pointsMerkleRoot, leaf)) {
            revert InvalidProof();
        }

        //set claimed for social id
        _claimedBalances[socialID] = true;

        //move the tokens
        _executeClaim(socialID, recipient, points, feeAmount);
    }

    /**
     * Performs the calculations and token transfers for a claim. It will send the eco tokens
     * to the recipient and any fee to the payer, also in eco, if there is one. The ecox will
     * also be calculated and transfered to the recipient
     *
     * @param socialID the socialID of the recipient
     * @param recipient the recipient of the tokens
     * @param points the amount of points the user can claim, must be same as in the merkel tree and not an arbitrary amount
     * @param feeAmount the fee in eco the payer is granted from the recipient
     */
    function _executeClaim(
        string calldata socialID,
        address recipient,
        uint256 points,
        uint256 feeAmount
    ) internal {
        uint256 ecoBalance = points * POINTS_MULTIPLIER;
        uint256 ecoXBalance = points / POINTS_TO_ECOX_RATIO;
        //store the eco balance and time of the recipient so we can calculate vesting later
        ClaimBalance storage cb = _claimBalances[socialID];
        cb.recipient = recipient;
        cb.points = points;
        cb.claimTime = block.timestamp;

        //the fee is below the token amount
        if (feeAmount > ecoBalance) {
            revert InvalidFee();
        }

        //transfer ecox
        _ecoX.transfer(recipient, ecoXBalance);

        uint256 currentInflationMult = _eco.getPastLinearInflation(
            block.number
        );

        //transfer eco to recipient and payer
        if (feeAmount != 0) {
            //if there is a payer executing this tx, pay them out
            _eco.transfer(
                msg.sender,
                _applyInflationMultiplier(feeAmount, currentInflationMult)
            );
            _eco.transfer(
                recipient,
                _applyInflationMultiplier(
                    ecoBalance - feeAmount,
                    currentInflationMult
                )
            );
        } else {
            _eco.transfer(
                recipient,
                _applyInflationMultiplier(ecoBalance, currentInflationMult)
            );
        }

        //emit event for succesfull claim
        emit Claim(
            socialID,
            recipient,
            _applyInflationMultiplier(ecoBalance, currentInflationMult),
            ecoXBalance
        );
    }

    /**
     * Releases the vested tokens if its passed the initial cliff date. The recipient can pay a payer for calling this contract
     * and reward them in ecoX
     *
     * @param socialID the social ID of the claim
     * @param recipient the recipient of the tokens
     * @param feeAmount the fee in ecoX the payer is granted from the recipient
     */
    function _releaseTokens(
        string calldata socialID,
        address recipient,
        uint256 feeAmount
    ) internal {
        uint256 currentTime = block.timestamp;
        ClaimBalance storage cb = _claimBalances[socialID];
        if (cb.recipient != recipient) {
            revert InvalidReleaseCaller();
        }
        uint256 points = cb.points;
        uint256 ecoBalance = points * POINTS_MULTIPLIER;

        //the recipient has a balance
        if (ecoBalance == 0) {
            revert EmptyVestingBalance();
        }

        //the cliff time has been passed
        if (cb.claimTime + VESTING_PERIOD > currentTime) {
            revert CliffNotMet();
        }

        //calculating balances
        uint256 currentInflationMult = _eco.getPastLinearInflation(
            block.number
        );
        uint256 vestedBalance;

        //find the vesting period the call is made in and distribute the funds
        for (uint256 i = _vestedMultiples.length; i > 0; i--) {
            if (currentTime > cb.claimTime + VESTING_PERIOD * i) {
                vestedBalance =
                    (points * _vestedMultiples[i - 1]) /
                    VESTING_DIVIDER;
                break;
            }
        }

        //clear out recipients balance
        cb.points = 0;
        cb.claimTime = 0;

        //transfer the balances
        //transfer the ecox
        _ecoX.transfer(recipient, vestedBalance);

        //transfer the eco
        if (feeAmount == 0) {
            _eco.transfer(
                recipient,
                _applyInflationMultiplier(ecoBalance, currentInflationMult)
            );
        } else {
            //the fee is below the token amount
            if (feeAmount > ecoBalance) {
                revert InvalidFee();
            }
            _eco.transfer(
                recipient,
                _applyInflationMultiplier(
                    ecoBalance - feeAmount,
                    currentInflationMult
                )
            );
            _eco.transfer(
                msg.sender,
                _applyInflationMultiplier(feeAmount, currentInflationMult)
            );
        }

        emit ReleaseVesting(
            recipient,
            msg.sender,
            _applyInflationMultiplier(
                ecoBalance - feeAmount,
                currentInflationMult
            ),
            vestedBalance,
            feeAmount
        );
    }

    /**
     * Verifies that the recipient signed the message, and that the message is the correct hash of the
     * parameters for determining the payer pay off and the length the signature is valid.
     *
     * @param socialID the socialID of the recipient
     * @param recipient the recipient of the tokens
     * @param feeAmount the fee in eco the payer is granted from the recipient
     * @param deadline the time at which the signature is no longer valid
     * @param nonce the nonce for the signatures for this claim registration
     * @param recipientSig the signature signed by the recipient
     *
     * @return true if the signature is valid, false otherwise
     */
    function _verifyClaimSigature(
        string calldata socialID,
        address recipient,
        uint256 feeAmount,
        uint256 deadline,
        uint256 nonce,
        bytes calldata recipientSig
    ) internal view returns (bool) {
        bytes32 hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    CLAIM_TYPEHASH,
                    keccak256(bytes(socialID)),
                    recipient,
                    feeAmount,
                    deadline,
                    nonce
                )
            )
        );
        return hash.recover(recipientSig) == recipient;
    }

    /**
     * Verifies that the recipient signed the message, and that the message is the correct hash of the
     * parameters for determining the payer pay off and the length the signature is valid.
     *
     * @param socialID the socialID of the recipient
     * @param recipient the recipient of the tokens
     * @param feeAmount the fee in eco the payer is granted from the recipient
     * @param deadline the time at which the signature is no longer valid
     * @param nonce the nonce for the signatures for this claim registration
     *
     * @return true if the signature is valid, false otherwise
     */
    function _verifyReleaseSigature(
        string calldata socialID,
        address recipient,
        uint256 feeAmount,
        uint256 deadline,
        uint256 nonce,
        bytes calldata recipientSig
    ) internal view returns (bool) {
        bytes32 hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    RELEASE_TYPEHASH,
                    keccak256(bytes(socialID)),
                    recipient,
                    feeAmount,
                    deadline,
                    nonce
                )
            )
        );
        return hash.recover(recipientSig) == recipient;
    }

    /**
     * Returns the current nonce for a given socialID
     *
     * @param socialID the socialID to get and increment the nonce for
     *
     * @return the nonce
     */
    function nonces(string calldata socialID) public view returns (uint256) {
        return _nonces[socialID].current();
    }

    /**
     * Returns the merkle tree leaf hash for the given data
     */
    function _getLeaf(string calldata socialID, uint256 points)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(socialID, points));
    }

    /**
     * Applies the inflation multiplier for eco balances before transfers
     */
    function _applyInflationMultiplier(
        uint256 value,
        uint256 currentInflationMultiplier
    ) internal view returns (uint256) {
        return
            (_initialInflationMultiplier * value) / currentInflationMultiplier;
    }

    /**
     * Returns the current nonce for a claim and automatically increament it
     *
     * @param socialID the socialID to get and increment the nonce for
     *
     * @return current current nonce before incrementing
     */
    function _useNonce(string calldata socialID)
        internal
        returns (uint256 current)
    {
        Counters.Counter storage nonce = _nonces[socialID];
        current = nonce.current();
        nonce.increment();
    }
}