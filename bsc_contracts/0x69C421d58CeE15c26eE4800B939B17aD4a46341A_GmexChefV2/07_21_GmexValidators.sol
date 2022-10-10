// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract GmexValidators is OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    address[] private validators;
    mapping(address => bool) private validatorExists;
    uint256 private numberOfValidatorAllowed;
    uint256 private validatorMinStake;
    uint256 private castedVoteCount;
    mapping(address => bool) private castedVote;
    mapping(address => uint256) private voteCount;
    mapping(address => uint256) private votingPower;
    mapping(address => bool) private blocklisted;
    EnumerableSetUpgradeable.AddressSet private whitelisted;
    uint256 private previlegeForValidatorTill;

    modifier validValidatorsOnly() {
        require(
            validatorExists[msg.sender],
            "GmexGovernance: Only validators can cast a vote"
        );
        _;
    }

    modifier previlegedApplied() {
        require(
            block.timestamp > previlegeForValidatorTill ||
                whitelisted.contains(msg.sender),
            "GmexGovernance: You are not previleged for the action. Please wait"
        );
        _;
    }

    function __GmexValidators_init(address[] memory _whitelisted)
        public
        initializer
    {
        __Ownable_init();
        numberOfValidatorAllowed = 10;
        validatorMinStake = 200;

        for (uint256 i = 0; i < _whitelisted.length; i++) {
            whitelisted.add(_whitelisted[i]);
        }

        previlegeForValidatorTill = block.timestamp + 1 weeks;
    }

    function getValidators() public view returns (address[] memory) {
        return validators;
    }

    function getVoteCount(address validator) public view returns (uint256) {
        return voteCount[validator];
    }

    function getWhitelistedValidators() public view returns (address[] memory) {
        return whitelisted.values();
    }

    function getValidatorsWhoHaveNotCastedVotes()
        internal
        view
        returns (address[] memory)
    {
        address[] memory offlineValidators = new address[](
            validators.length - castedVoteCount
        );
        uint256 numberOfOfflineValidators = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            if (!castedVote[validators[i]]) {
                offlineValidators[numberOfOfflineValidators] = validators[i];
                numberOfOfflineValidators++;
            }
        }
        return offlineValidators;
    }

    function getValidatorsWhoHaveCastedVotes()
        internal
        view
        returns (address[] memory)
    {
        address[] memory onlineValidators = new address[](castedVoteCount);
        uint256 numberOfOnlineValidators = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            if (castedVote[validators[i]]) {
                onlineValidators[numberOfOnlineValidators] = validators[i];
                numberOfOnlineValidators++;
            }
        }
        return onlineValidators;
    }

    function getValidatorsExists(address _validator)
        public
        view
        returns (bool)
    {
        return validatorExists[_validator];
    }

    function updateCastedVote(bool _castedVote) internal {
        if (_castedVote && !castedVote[msg.sender]) {
            castedVoteCount++;
        } else if (!_castedVote && castedVote[msg.sender]) {
            castedVoteCount--;
        }
        castedVote[msg.sender] = _castedVote;
    }

    function haveCastedVote(address _validator) public view returns (bool) {
        return castedVote[_validator];
    }

    function getValidatorsMinStake() public view returns (uint256) {
        return validatorMinStake;
    }

    // update validator min stake
    function updateValidatorMinStake(uint256 _validatorMinStake)
        public
        onlyOwner
    {
        validatorMinStake = _validatorMinStake;
    }

    // apply for validator
    function applyForValidator() public virtual previlegedApplied {
        require(!blocklisted[msg.sender], "GmexGovernance: Blocklisted wallet");
        require(
            validators.length < numberOfValidatorAllowed,
            "Validators allowed exceeded"
        );

        validatorExists[msg.sender] = true;
        validators.push(msg.sender);
    }

    function leaveFromValidator() public {
        require(
            validatorExists[msg.sender],
            "GmexGovernance: Only validators can leave from validator"
        );
        require(
            validators.length > 1,
            "GmexGovernance: At least one validator must be present"
        );

        removeFromValidator(msg.sender);
    }

    // remove for validator
    function removeFromValidatorByIndex(uint256 index) public onlyOwner {
        require(
            index < validators.length,
            "GmexGovernance: Validator index out of bounds"
        );
        validatorExists[validators[index]] = false;
        validators[index] = validators[validators.length - 1];
        validators.pop();
    }

    function getValidatorIndex(address _validator)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == _validator) {
                return i;
            }
        }
        return 0;
    }

    function removeFromValidator(address _validator) internal {
        removeFromValidatorByIndex(getValidatorIndex(_validator));
    }

    // update numberOfValidatorAllowed
    function updateNumberOfValidatorAllowed(uint256 _numberOfValidatorAllowed)
        public
        onlyOwner
    {
        numberOfValidatorAllowed = _numberOfValidatorAllowed;
    }

    function addToBlocklist(address _user) public {
        blocklisted[_user] = true;
    }

    function removeFromBlocklist(address _user) public {
        blocklisted[_user] = false;
    }

    function vestVotes(address validator, uint256 _votingPower) internal {
        voteCount[validator] += _votingPower;
        votingPower[msg.sender] = _votingPower;
    }

    function withdrawVotes(address validator) internal {
        voteCount[validator] -= votingPower[msg.sender];
    }

    function _vestVotesToDifferentValidator(
        address nominator,
        address previousValidator,
        address newValidator
    ) internal {
        voteCount[previousValidator] -= votingPower[nominator];
        voteCount[newValidator] += votingPower[nominator];
    }
}