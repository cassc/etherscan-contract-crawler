// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IETHDKG.sol";
import "contracts/interfaces/ISnapshots.sol";
import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/interfaces/IValidatorPool.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/utils/CustomEnumerableMaps.sol";
import "contracts/utils/DeterministicAddress.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/libraries/errors/ValidatorPoolErrors.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableSnapshots.sol";
import "contracts/utils/auth/ImmutableETHDKG.sol";
import "contracts/utils/auth/ImmutableValidatorStaking.sol";
import "contracts/utils/auth/ImmutableALCA.sol";

contract ValidatorPoolMock is
    Initializable,
    IValidatorPool,
    ImmutableFactory,
    ImmutableSnapshots,
    ImmutableETHDKG,
    ImmutableValidatorStaking,
    ImmutableALCA
{
    using CustomEnumerableMaps for ValidatorDataMap;
    error OnlyAdminAllowed();

    uint256 public constant POSITION_LOCK_PERIOD = 3; // Actual is 172800

    uint256 internal _maxIntervalWithoutSnapshots = 0; // Actual is 8192

    uint256 internal _tokenIDCounter;
    //IETHDKG immutable internal _ethdkg;
    //ISnapshots immutable internal _snapshots;

    ValidatorDataMap internal _validators;

    address internal _admin;

    bool internal _isMaintenanceScheduled;
    bool internal _isConsensusRunning;

    uint256 internal _stakeAmount;

    modifier onlyAdmin() {
        if (msg.sender != _admin) {
            revert OnlyAdminAllowed();
        }
        _;
    }

    // solhint-disable no-empty-blocks
    constructor()
        ImmutableFactory(msg.sender)
        ImmutableValidatorStaking()
        ImmutableSnapshots()
        ImmutableETHDKG()
        ImmutableALCA()
    {}

    function initialize() public onlyFactory initializer {
        //20000*10**18 ALCAWei = 20k ALCAs
        _stakeAmount = 20000 * 10 ** 18;
    }

    function initializeETHDKG() public {
        IETHDKG(_ethdkgAddress()).initializeETHDKG();
    }

    function setDisputerReward(uint256 disputerReward_) public {}

    function pauseConsensusOnArbitraryHeight(uint256 aliceNetHeight_) public onlyFactory {
        uint256 targetBlockNumber = ISnapshots(_snapshotsAddress())
            .getCommittedHeightFromLatestSnapshot() + _maxIntervalWithoutSnapshots;
        if (block.number <= targetBlockNumber) {
            revert ValidatorPoolErrors.MinimumBlockIntervalNotMet(block.number, targetBlockNumber);
        }
        _isConsensusRunning = false;
        IETHDKG(_ethdkgAddress()).setCustomAliceNetHeight(aliceNetHeight_);
    }

    function mintValidatorStaking() public returns (uint256 stakeID_) {
        IERC20Transferable(_alcaAddress()).transferFrom(msg.sender, address(this), _stakeAmount);
        IERC20Transferable(_alcaAddress()).approve(_validatorStakingAddress(), _stakeAmount);
        stakeID_ = IStakingNFT(_validatorStakingAddress()).mint(_stakeAmount);
    }

    function burnValidatorStaking(
        uint256 tokenID_
    ) public returns (uint256 payoutEth, uint256 payoutALCA) {
        return IStakingNFT(_validatorStakingAddress()).burn(tokenID_);
    }

    function mintToValidatorStaking(address to_) public returns (uint256 stakeID_) {
        IERC20Transferable(_alcaAddress()).transferFrom(msg.sender, address(this), _stakeAmount);
        IERC20Transferable(_alcaAddress()).approve(_validatorStakingAddress(), _stakeAmount);
        stakeID_ = IStakingNFT(_validatorStakingAddress()).mintTo(to_, _stakeAmount, 1);
    }

    function burnToValidatorStaking(
        uint256 tokenID_,
        address to_
    ) public returns (uint256 payoutEth, uint256 payoutALCA) {
        return IStakingNFT(_validatorStakingAddress()).burnTo(to_, tokenID_);
    }

    function minorSlash(address validator, address disputer) public {
        disputer; //no-op to suppress warning of not using disputer address
        _removeValidator(validator);
    }

    function majorSlash(address validator, address disputer) public {
        disputer; //no-op to suppress warning of not using disputer address
        _removeValidator(validator);
    }

    function unregisterValidators(address[] memory validators) public {
        for (uint256 idx; idx < validators.length; idx++) {
            _removeValidator(validators[idx]);
        }
    }

    function unregisterAllValidators() public {
        while (_validators.length() > 0) {
            _removeValidator(_validators.at(_validators.length() - 1)._address);
        }
    }

    function completeETHDKG() public {
        _isMaintenanceScheduled = false;
        _isConsensusRunning = true;
    }

    function pauseConsensus() public onlySnapshots {
        _isConsensusRunning = false;
    }

    function scheduleMaintenance() public {
        _isMaintenanceScheduled = true;
    }

    function setConsensusRunning(bool isRunning) public {
        _isConsensusRunning = isRunning;
    }

    function setMaxIntervalWithoutSnapshots(uint256 maxIntervalWithoutSnapshots) public {
        if (maxIntervalWithoutSnapshots == 0) {
            revert ValidatorPoolErrors.MaxIntervalWithoutSnapshotsMustBeNonZero();
        }
        _maxIntervalWithoutSnapshots = maxIntervalWithoutSnapshots;
    }

    function setStakeAmount(uint256 stakeAmount_) public {}

    function setSnapshot(address _address) public {}

    function setMaxNumValidators(uint256 maxNumValidators_) public {}

    function setLocation(string memory ip) public {}

    function registerValidators(
        address[] memory validators,
        uint256[] memory stakerTokenIDs
    ) public {
        stakerTokenIDs;
        _registerValidators(validators);
    }

    function isValidator(address participant) public view returns (bool) {
        return _isValidator(participant);
    }

    function getStakeAmount() public view returns (uint256) {
        return _stakeAmount;
    }

    function getMaxIntervalWithoutSnapshots()
        public
        view
        returns (uint256 maxIntervalWithoutSnapshots)
    {
        return _maxIntervalWithoutSnapshots;
    }

    function getValidatorsCount() public view returns (uint256) {
        return _validators.length();
    }

    function getValidator(uint256 index_) public view returns (address) {
        if (index_ >= _validators.length()) {
            revert ValidatorPoolErrors.InvalidIndex(index_);
        }
        return _validators.at(index_)._address;
    }

    function getValidatorsAddresses() public view returns (address[] memory addresses) {
        return _validators.addressValues();
    }

    function isMaintenanceScheduled() public view returns (bool) {
        return _isMaintenanceScheduled;
    }

    function isConsensusRunning() public view returns (bool) {
        return _isConsensusRunning;
    }

    function getValidatorData(uint256 index) public view returns (ValidatorData memory) {
        return _validators.at(index);
    }

    function isAccusable(address participant) public view returns (bool) {
        participant;
        return _isValidator(participant);
    }

    function getMaxNumValidators() public pure returns (uint256) {
        return 5;
    }

    function getDisputerReward() public pure returns (uint256) {
        return 1;
    }

    function claimExitingNFTPosition() public pure returns (uint256) {
        return 0;
    }

    function tryGetTokenID(address account_) public pure returns (bool, address, uint256) {
        account_; //no-op to suppress compiling warnings
        return (false, address(0), 0);
    }

    function collectProfits() public pure returns (uint256 payoutEth, uint256 payoutToken) {
        return (0, 0);
    }

    function getLocations(address[] memory validators_) public pure returns (string[] memory) {
        validators_;
        return new string[](1);
    }

    function isInExitingQueue(address participant) public pure returns (bool) {
        participant;
        return false;
    }

    function getLocation(address validator) public pure returns (string memory) {
        validator;
        return "";
    }

    function isMock() public pure returns (bool) {
        return true;
    }

    function _removeValidator(address validator_) internal {
        _validators.remove(validator_);
    }

    function _registerValidators(address[] memory v) internal {
        for (uint256 idx; idx < v.length; idx++) {
            uint256 tokenID = _tokenIDCounter + 1;
            _validators.add(ValidatorData(v[idx], tokenID));
            _tokenIDCounter = tokenID;
        }
    }

    function _isValidator(address participant) internal view returns (bool) {
        return _validators.contains(participant);
    }
}