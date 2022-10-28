// SPDX-License-Identifier: MIT
// prettier-ignore

pragma solidity 0.8.4;

import {Ownable} from "../lib/Ownable.sol";
import {Address} from "../lib/Address.sol";
import {PassportScoreVerifiable} from "../lib/PassportScoreVerifiable.sol";
import {SapphireTypes} from "./SapphireTypes.sol";
import {ISapphireMapper} from "./ISapphireMapper.sol";
import {ISapphirePassportScores} from "./ISapphirePassportScores.sol";
import {ISapphireAssessor} from "./ISapphireAssessor.sol";

contract SapphireAssessor is Ownable, ISapphireAssessor, PassportScoreVerifiable {

    /* ========== Libraries ========== */

    using Address for address;

    /* ========== Variables ========== */

    ISapphireMapper public mapper;

    uint16 public maxScore;

    /* ========== Events ========== */

    event MapperSet(address _newMapper);

    event PassportScoreContractSet(address _newCreditScoreContract);

    event MaxScoreSet(uint16 _maxScore);

    /* ========== Constructor ========== */

    constructor(
        address _mapper,
        address _passportScores,
        uint16 _maxScore
    ) {
        require(
            _mapper.isContract() &&
            _passportScores.isContract(),
            "SapphireAssessor: mapper and passport scores must be valid contracts"
        );

        mapper = ISapphireMapper(_mapper);
        passportScoresContract = ISapphirePassportScores(_passportScores);
        setMaxScore(_maxScore);
    }

    /* ========== View Functions ========== */

    function getPassportScoresContract() 
        external 
        view
        override
        returns (address)
    {
        return address(passportScoresContract);
    }
    
    /* ========== Public Functions ========== */

    /**
     * @notice  Takes a lower and upper bound, and based on the user's credit score
     *          and given its proof, returns the appropriate value between these bounds.
     *
     * @param _lowerBound       The lower bound
     * @param _upperBound       The upper bound
     * @param _scoreProof       The score proof
     * @param _isScoreRequired  The flag, which require the proof of score if the account already
                                has a score
     * @return A value between the lower and upper bounds depending on the credit score
     */
    function assess(
        uint256 _lowerBound,
        uint256 _upperBound,
        SapphireTypes.ScoreProof memory _scoreProof,
        bool _isScoreRequired
    )
        external
        view
        override
        checkScoreProof(_scoreProof, _isScoreRequired, false)
        returns (uint256)
    {
        require(
            _upperBound > 0,
            "SapphireAssessor: The upper bound cannot be zero"
        );

        require(
            _lowerBound < _upperBound,
            "SapphireAssessor: The lower bound must be smaller than the upper bound"
        );

        bool isProofPassed = _scoreProof.merkleProof.length > 0;

        // If the proof is passed, use the score from the score proof since at this point
        // the proof should be verified if the score is > 0
        uint256 result = mapper.map(
            isProofPassed ? _scoreProof.score : 0,
            maxScore,
            _lowerBound,
            _upperBound
        );

        require(
            result >= _lowerBound &&
            result <= _upperBound,
            "SapphireAssessor: The mapper returned a value out of bounds"
        );

        return result;
    }

    function assessBorrowLimit(
        uint256 _borrowAmount,
        SapphireTypes.ScoreProof calldata _borrowLimitProof
    )
        external
        view
        override
        checkScoreProof(_borrowLimitProof, true, false)
        returns (bool)
    {

        require(
            _borrowAmount > 0,
            "SapphireAssessor: The borrow amount cannot be zero"
        );

        bool _isBorrowAmountValid = _borrowAmount <= _borrowLimitProof.score;

        return _isBorrowAmountValid;
    }

    function setMapper(
        address _mapper
    )
        external
        onlyOwner
    {
        require(
            _mapper.isContract(),
            "SapphireAssessor: _mapper is not a contract"
        );

        require(
            _mapper != address(mapper),
            "SapphireAssessor: The same mapper is already set"
        );

        mapper = ISapphireMapper(_mapper);

        emit MapperSet(_mapper);
    }

    function setPassportScoreContract(
        address _creditScore
    )
        external
        onlyOwner
    {
        require(
            _creditScore.isContract(),
            "SapphireAssessor: _creditScore is not a contract"
        );

        require(
            _creditScore != address(passportScoresContract),
            "SapphireAssessor: The same credit score contract is already set"
        );

        passportScoresContract = ISapphirePassportScores(_creditScore);

        emit PassportScoreContractSet(_creditScore);
    }

    function setMaxScore(
        uint16 _maxScore
    )
        public
        onlyOwner
    {
        require(
            _maxScore > 0,
            "SapphireAssessor: max score cannot be zero"
        );

        maxScore = _maxScore;

        emit MaxScoreSet(_maxScore);
    }

    function renounceOwnership()
        public
        view
        onlyOwner
        override
    {
        revert("SapphireAssessor: cannot renounce ownership");
    }
}