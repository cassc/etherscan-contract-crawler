// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= OperatorRegistry =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Jack Corddry: https://github.com/corddry
// Justin Moore: https://github.com/0xJM

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Dennis: https://github.com/denett

import "./Utils/Owned.sol";

/// @title Keeps track of validators used for ETH 2.0 staking
/// @notice A permissioned owner can add and removed them at will
contract OperatorRegistry is Owned {

    struct Validator {
        bytes pubKey;
        bytes signature;
        bytes32 depositDataRoot;
    }

    Validator[] validators; // Array of unused / undeposited validators that can be used at a future time
    bytes curr_withdrawal_pubkey; // Pubkey for ETH 2.0 withdrawal creds. If you change it, you must empty the validators array
    address public timelock_address;

    constructor(address _owner, address _timelock_address, bytes memory _withdrawal_pubkey) Owned(_owner) {
        timelock_address = _timelock_address;
        curr_withdrawal_pubkey = _withdrawal_pubkey;
    }

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    /// @notice Add a new validator
    /** @dev You should verify offchain that the validator is indeed valid before adding it
        Reason we don't do that here is for gas */
    function addValidator(Validator calldata validator) public onlyByOwnGov {
        validators.push(validator);
        emit ValidatorAdded(validator.pubKey, curr_withdrawal_pubkey);
    }

    /// @notice Add multiple new validators in one function call
    /** @dev You should verify offchain that the validators are indeed valid before adding them
        Reason we don't do that here is for gas */
    function addValidators(Validator[] calldata validatorArray) external onlyByOwnGov {
        uint arrayLength = validatorArray.length;
        for (uint256 i = 0; i < arrayLength; ++i) {
            addValidator(validatorArray[i]);
        }
    }

    /// @notice Swap the location of one validator with another
    function swapValidator(uint256 from_idx, uint256 to_idx) public onlyByOwnGov {
        // Get the original values
        Validator memory fromVal = validators[from_idx];
        Validator memory toVal = validators[to_idx];

        // Set the swapped values
        validators[to_idx] = fromVal;
        validators[from_idx] = toVal;

        emit ValidatorsSwapped(fromVal.pubKey, toVal.pubKey, from_idx, to_idx);
    }

    /// @notice Remove validators from the end of the validators array, in case they were added in error
    function popValidators(uint256 times) public onlyByOwnGov {
        // Loop through and remove validator entries at the end
        for (uint256 i = 0; i < times; ++i) {
            validators.pop();
        }

        emit ValidatorsPopped(times);
    }

    /** @notice Remove a validator from the array. If dont_care_about_ordering is true,  
        a swap and pop will occur instead of a more gassy loop */ 
    function removeValidator(uint256 remove_idx, bool dont_care_about_ordering) public onlyByOwnGov {
        // Get the pubkey for the validator to remove (for informational purposes)
        bytes memory removed_pubkey = validators[remove_idx].pubKey;

        // Less gassy to swap and pop
        if (dont_care_about_ordering){
            // Swap the (validator to remove) with the (last validator in the array)
            swapValidator(remove_idx, validators.length - 1);

            // Pop off the validator to remove, which is now at the end of the array
            validators.pop();
        }
        // More gassy, loop
        else {
            // Save the original validators
            Validator[] memory original_validators = validators;

            // Clear the original validators list
            delete validators;

            // Fill the new validators array with all except the value to remove
            for (uint256 i = 0; i < original_validators.length; ++i) {
                if (i != remove_idx) {
                    validators.push(original_validators[i]);
                }
            }
        }

        emit ValidatorRemoved(removed_pubkey, remove_idx, dont_care_about_ordering);
    }

    // Internal
    /// @dev Remove the last validator from the validators array and return its information
    function getNextValidator()
        internal
        returns (
            bytes memory pubKey,
            bytes memory withdrawalCredentials,
            bytes memory signature,
            bytes32 depositDataRoot
        )
    {
        // Make sure there are free validators available
        uint numVals = numValidators();
        require(numVals != 0, "Validator stack is empty");

        // Pop the last validator off the array
        Validator memory popped = validators[numVals - 1];
        validators.pop();

        // Return the validator's information
        pubKey = popped.pubKey;
        withdrawalCredentials = curr_withdrawal_pubkey;
        signature = popped.signature;
        depositDataRoot = popped.depositDataRoot;
    }

    /// @notice Return the information of the i'th validator in the registry
    function getValidator(uint i) 
        view
        external
        returns (
            bytes memory pubKey,
            bytes memory withdrawalCredentials,
            bytes memory signature,
            bytes32 depositDataRoot
        )
    {
        Validator memory v = validators[i];

        // Return the validator's information
        pubKey = v.pubKey;
        withdrawalCredentials = curr_withdrawal_pubkey;
        signature = v.signature;
        depositDataRoot = v.depositDataRoot;
    }

    /// @notice Returns a Validator struct of the given inputs to make formatting addValidator inputs easier
    function getValidatorStruct(
        bytes memory pubKey, 
        bytes memory signature, 
        bytes32 depositDataRoot
    ) external pure returns (Validator memory) {
        return Validator(pubKey, signature, depositDataRoot);
    }

    /// @notice Requires empty validator stack as changing withdrawal creds invalidates signature
    /// @dev May need to call clearValidatorArray() first
    function setWithdrawalCredential(bytes memory _new_withdrawal_pubkey) external onlyByOwnGov {
        require(numValidators() == 0, "Clear validator array first");
        curr_withdrawal_pubkey = _new_withdrawal_pubkey;

        emit WithdrawalCredentialSet(_new_withdrawal_pubkey);
    }

    /// @notice Empties the validator array
    /// @dev Need to do this before setWithdrawalCredential()
    function clearValidatorArray() external onlyByOwnGov {
        delete validators;

        emit ValidatorArrayCleared();
    }

    /// @notice Returns the number of validators
    function numValidators() public view returns (uint256) {
        return validators.length;
    }

    /// @notice Set the timelock contract
    function setTimelock(address _timelock_address) external onlyByOwnGov {
        require(_timelock_address != address(0), "Zero address detected");
        timelock_address = _timelock_address;
        emit TimelockChanged(_timelock_address);
    }

    event TimelockChanged(address timelock_address);
    event WithdrawalCredentialSet(bytes _withdrawalCredential);
    event ValidatorAdded(bytes pubKey, bytes withdrawalCredential);
    event ValidatorArrayCleared();
    event ValidatorRemoved(bytes pubKey, uint256 remove_idx, bool dont_care_about_ordering);
    event ValidatorsPopped(uint256 times);
    event ValidatorsSwapped(bytes from_pubKey, bytes to_pubKey, uint256 from_idx, uint256 to_idx);
    event KeysCleared();
}