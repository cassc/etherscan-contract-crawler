// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract GmexVoters {
    address[] private voters;
    mapping(address => bool) private delagatedValidator;
    mapping(address => address[3]) private votedToValidator; // addresses of the validators a nominator has choosen
    mapping(address => uint256) private votingPower;

    function getVoters() public view returns (address[] memory) {
        return voters;
    }

    function addVoter(address _voter) internal {
        voters.push(_voter);
    }

    function resetVoters() internal {
        delete voters;
    }

    function haveDelagatedValidator(address _voter) public view returns (bool) {
        return delagatedValidator[_voter];
    }

    function delegateValidator(address validator) public virtual {
        require(
            !delagatedValidator[msg.sender],
            "GmexGovernance: You have already delegated a validator"
        );
        votedToValidator[msg.sender][0] = validator;

        if (!delagatedValidator[msg.sender]) {
            addVoter(msg.sender);
            delagatedValidator[msg.sender] = true;
        }
    }

    function delegateMoreValidator(address validator) public {
        require(
            delagatedValidator[msg.sender],
            "GmexGovernance: Delegate one validator first"
        );
        if (votedToValidator[msg.sender][1] == address(0)) {
            votedToValidator[msg.sender][1] = validator;
        } else if (votedToValidator[msg.sender][2] == address(0)) {
            votedToValidator[msg.sender][2] = validator;
        } else {
            revert("GmexGovernance: You have already delegated 3 validators");
        }
    }

    function changeValidatorOrder(
        uint8 firstValidatorIndex,
        uint8 secondValidatorIndex
    ) public {
        require(
            firstValidatorIndex < 3,
            "GmexGovernance: First validator index out of bounds"
        );
        require(
            secondValidatorIndex < 3,
            "GmexGovernance: Second validator index out of bounds"
        );
        address temp = votedToValidator[msg.sender][firstValidatorIndex];
        votedToValidator[msg.sender][firstValidatorIndex] = votedToValidator[
            msg.sender
        ][secondValidatorIndex];
        votedToValidator[msg.sender][secondValidatorIndex] = temp;
    }

    function unDelegateValidator() internal {
        require(
            delagatedValidator[msg.sender],
            "GmexGovernance: You have not delegated a validator"
        );
        delete votedToValidator[msg.sender];
        delete delagatedValidator[msg.sender];
    }

    function getValidatorsNominatedByNominator(address _voter)
        public
        view
        returns (address[3] memory)
    {
        return votedToValidator[_voter];
    }

    function vestVotes(uint256 _votingPower) internal {
        votingPower[msg.sender] = _votingPower;
    }
}