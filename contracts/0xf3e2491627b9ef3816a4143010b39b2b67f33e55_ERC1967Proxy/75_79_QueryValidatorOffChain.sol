// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@iden3/contracts/interfaces/IState.sol";
import "@iden3/contracts/lib/GenesisUtils.sol";
import "@iden3/contracts/lib/Poseidon.sol";

import "@dlsl/dev-modules/libs/zkp/snarkjs/VerifierHelper.sol";

import "../interfaces/validators/IOffChainCircuitValidator.sol";

abstract contract QueryValidatorOffChain is OwnableUpgradeable, IOffChainCircuitValidator {
    using VerifierHelper for address;

    IState public state;
    address public verifier;

    uint256 public revocationStateExpirationTime;

    function __QueryValidatorOffChain_init(
        address verifierContractAddr_,
        address stateContractAddr_
    ) public initializer {
        __Ownable_init();

        state = IState(stateContractAddr_);
        verifier = verifierContractAddr_;

        revocationStateExpirationTime = 1 hours;
    }

    function setRevocationStateExpirationTime(uint256 expirationTime_) public virtual onlyOwner {
        revocationStateExpirationTime = expirationTime_;
    }

    function verify(
        uint256[] calldata inputs_,
        uint256[2] calldata a_,
        uint256[2][2] calldata b_,
        uint256[2] calldata c_,
        uint256 queryHash
    ) external view virtual returns (bool) {
        // verify that zkp is valid
        require(
            verifier.verifyProof(inputs_, a_, b_, c_),
            "QueryMTPValidatorOffChain: proof is not valid"
        );
        require(
            queryHash == _getQueryHash(inputs_),
            "QueryMTPValidatorOffChain: query hash does not match the requested one"
        );

        ValidationParams memory params_ = _getInputValidationParameters(inputs_);

        _checkStateContractOrGenesis(params_.issuerId, params_.issuerClaimState);

        if (params_.isRevocationChecked) {
            _checkClaimNonRevState(params_.issuerId, params_.issuerClaimNonRevState);
        }

        return (true);
    }

    function getCircuitId() external view virtual override returns (string memory id);

    function _getInputValidationParameters(
        uint256[] calldata inputs_
    ) internal pure virtual returns (ValidationParams memory);

    function _checkStateContractOrGenesis(uint256 id_, uint256 state_) internal view {
        if (!GenesisUtils.isGenesisState(id_, state_)) {
            IState.StateInfo memory stateInfo_ = state.getStateInfoByIdAndState(id_, state_);

            require(
                id_ == stateInfo_.id,
                "QueryMTPValidatorOffChain: state doesn't exist in state contract"
            );
        }
    }

    function _checkClaimNonRevState(uint256 id_, uint256 claimNonRevState_) internal view {
        IState.StateInfo memory claimNonRevStateInfo_ = state.getStateInfoById(id_);

        if (claimNonRevStateInfo_.state == 0) {
            require(
                GenesisUtils.isGenesisState(id_, claimNonRevState_),
                "QueryMTPValidatorOffChain: non-revocation state isn't in state contract and not genesis"
            );
        } else {
            // The non-empty state is returned, and it's not equal to the state that the user has provided.
            if (claimNonRevStateInfo_.state != claimNonRevState_) {
                // Get the time of the latest state and compare it to the transition time of state provided by the user.
                IState.StateInfo memory claimNonRevLatestStateInfo_ = state
                    .getStateInfoByIdAndState(id_, claimNonRevState_);

                if (claimNonRevLatestStateInfo_.id == 0 || claimNonRevLatestStateInfo_.id != id_) {
                    revert(
                        "QueryMTPValidatorOffChain: state in transition info contains invalid id"
                    );
                }

                if (claimNonRevLatestStateInfo_.replacedAtTimestamp == 0) {
                    revert(
                        "QueryMTPValidatorOffChain: non-latest state doesn't contain replacement information"
                    );
                }

                if (
                    block.timestamp - claimNonRevLatestStateInfo_.replacedAtTimestamp >
                    revocationStateExpirationTime
                ) {
                    revert("QueryMTPValidatorOffChain: non-revocation state of Issuer expired");
                }
            }
        }
    }

    function _getQueryHash(uint256[] calldata inputs_) internal pure returns (uint256) {
        uint256 schema_ = inputs_[8];
        uint256 claimPathKey_ = inputs_[10];
        uint256 operator_ = inputs_[12];

        uint256 valuesHash_ = PoseidonFacade.poseidonSponge(_getValuesFromInputs(inputs_));

        return PoseidonFacade.poseidon6([schema_, 0, operator_, claimPathKey_, 0, valuesHash_]);
    }

    function _getValuesFromInputs(
        uint256[] calldata inputs_
    ) internal pure returns (uint256[] memory valuesArr_) {
        valuesArr_ = new uint256[](VALUES_ARR_SIZE);

        uint256 inputsArrOffset_ = inputs_.length - VALUES_ARR_SIZE;

        for (uint256 i = 0; i < VALUES_ARR_SIZE; i++) {
            valuesArr_[i] = inputs_[i + inputsArrOffset_];
        }
    }
}