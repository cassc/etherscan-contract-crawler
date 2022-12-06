// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Phaseable {
    uint256 private _totalPhases = 0;
    mapping(uint256 => MintPhase) private _mintPhases;
    mapping(uint256 => mapping(address => uint32)) private _claimsPerWallet;
    mapping(uint256 => uint32) private _claimsPerPhase;

    /**
     *  @notice Mint phase
     *
     *  @param startTimestamp                 The unix timestamp after which the mint phase applies.
     *                                        The same pahse applies until the `endTimestamp`
     *
     *  @param endTimestamp                   The unix timestamp until the claim condition applies.
     *                                        0 means no end time.
     *
     *  @param pricePerToken                  The price required to pay per token claimed.
     *
     *  @param maxClaimable                   The maximum claims that can be made in the minting phase.
     *                                        0 means no limit.
     *
     *  @param walletLimit                    The maximum tokens a wallet can claim in the minting phase.
     *                                        0 means no limit.
     *
     *  @param merkleRoot                     The allowlist of addresses that can claim tokens during the
     *                                        minting phase.
     */
    struct MintPhase {
        uint128 startTimestamp;
        uint128 endTimestamp;
        uint256 pricePerToken;
        uint32 maxClaimable;
        uint32 walletLimit;
        bytes32 merkleRoot;
    }

    /// @dev Emitted when the contract's minting phases are updated.
    event MintingPhasesUpdated(MintPhase[] claimConditions);

    function getActiveMintPhase()
        public
        view
        returns (MintPhase memory, uint256)
    {
        for (uint256 i = 0; i < _totalPhases; i++) {
            MintPhase memory phase = _mintPhases[i];
            if (
                phase.startTimestamp <= block.timestamp &&
                (phase.endTimestamp == 0 ||
                    phase.endTimestamp > block.timestamp)
            ) {
                return (phase, i);
            }
        }
        revert("No active minting");
    }

    function setMintingPhases(MintPhase[] calldata _phases) external {
        require(_canSetMintingPhases(), "Unauthorized");
        _setupMintingPhases(_phases);
    }

    function getMintingPhases() external view returns (MintPhase[] memory) {
        MintPhase[] memory phases = new MintPhase[](_totalPhases);
        for (uint256 i = 0; i < _totalPhases; i++) {
            phases[i] = _mintPhases[i];
        }
        return phases;
    }

    function getClaimsByWallet(
        uint256 _id,
        address _recipient
    ) external view returns (uint256 phaseClaims, uint256 walletClaims) {
        require(_mintPhaseExists(_id), "Mint phase does not exist");
        phaseClaims = _claimsPerPhase[_id];
        walletClaims = _claimsPerWallet[_id][_recipient];
    }

    function getClaimsByPhase(
        uint256 _id
    ) external view returns (uint256 phaseClaims) {
        require(_mintPhaseExists(_id), "Mint phase does not exist");
        phaseClaims = _claimsPerPhase[_id];
    }

    function _mintPhaseExists(uint256 _id) internal view returns (bool) {
        return _totalPhases > _id;
    }

    function _registerClaim(
        uint256 mintPhaseId,
        address _recipient,
        uint32 _quantity
    ) internal {
        _claimsPerWallet[mintPhaseId][_recipient] += _quantity;
        _claimsPerPhase[mintPhaseId] += _quantity;
    }

    function verifyClaim(
        address _recipient,
        uint32 _quantity,
        bytes32[] calldata _proof
    ) public view returns (MintPhase memory mintPhase, uint256 mintPhaseId) {
        (mintPhase, mintPhaseId) = getActiveMintPhase();
        require(
            mintPhase.maxClaimable == 0 ||
                _claimsPerPhase[mintPhaseId] + _quantity <=
                mintPhase.maxClaimable,
            "Mint phase limit reached"
        );
        if (mintPhase.merkleRoot != bytes32(0)) {
            verifyMerkleProof(_recipient, mintPhase.merkleRoot, _proof);
        }
        require(
            mintPhase.walletLimit == 0 ||
                _claimsPerWallet[mintPhaseId][_recipient] + _quantity <=
                mintPhase.walletLimit,
            "Wallet limit reached"
        );
    }

    function verifyMerkleProof(
        address _recipient,
        bytes32 _merkleRoot,
        bytes32[] calldata _merkleProof
    ) internal pure {
        require(
            MerkleProof.verify(
                _merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(_recipient))
            ),
            "Recipient not whitelisted"
        );
    }

    function _setupMintingPhases(MintPhase[] calldata _phases) internal {
        for (uint256 i = 0; i < _totalPhases; i++) {
            delete _mintPhases[i];
        }

        uint128 lastStartTime;
        uint128 lastEndTime;
        for (uint256 i = 0; i < _phases.length; i++) {
            MintPhase memory mintPhase = _phases[i];
            require(
                mintPhase.startTimestamp > 0 &&
                    mintPhase.startTimestamp >= lastEndTime,
                "Start time must be greater than 0 and previous end time"
            );
            require(
                i == 0 || lastEndTime > 0,
                "Only last phase can have no end time"
            );
            require(
                i == 0 || lastStartTime < mintPhase.startTimestamp,
                "Sort by timestamp"
            );
            require(
                mintPhase.endTimestamp == 0 ||
                    mintPhase.startTimestamp < mintPhase.endTimestamp,
                "Start must be before end"
            );
            _mintPhases[i] = mintPhase;
            lastStartTime = mintPhase.startTimestamp;
            lastEndTime = mintPhase.endTimestamp;
        }
        _totalPhases = _phases.length;

        emit MintingPhasesUpdated(_phases);
    }

    /// @dev Determine what wallet can update claim conditions
    function _canSetMintingPhases() internal virtual returns (bool);
}