// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './access/Ownable2Step.sol';

error TokenVesting_AddressIsZero();
error TokenVesting_AmountExcessive(uint256 amount, uint256 limit);
error TokenVesting_AmountZero();
error TokenVesting_BeneficiaryNoneActiveVestings();
error TokenVesting_ContractIsPaused(bool isPaused);
error TokenVesting_Error(string msg);

/**
 * @title Token Vesting Contract
 */
contract TokenVesting is Ownable2Step {
    using SafeERC20 for IERC20;
    /**
     * @dev Event is triggered when vesting schedule is changed
     * @param _name string vesting schedule name
     * @param _amount uint256 vesting schedule amount
     */
    event VestingScheduleCreated(string _name, uint256 _amount);

    /**
     * @dev Event is triggered when vesting schedule is revoked
     * @param _name string vesting schedule name
     */
    event VestingScheduleRevoked(string _name);

    /**
     * @dev Event is triggered when allocation added
     * @param _beneficiary address of beneficiary
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     * @param _currentAllocation uint256 current allocation for vesting schedule
     */
    event AllocationAdded(
        address _beneficiary,
        string _vestingScheduleName,
        uint256 _amount,
        uint256 _currentAllocation
    );

    /**
     * @dev Event is triggered when allocation removed
     * @param _beneficiary address of beneficiary
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     * @param _currentAllocation uint256 current allocation for vesting schedule
     */
    event AllocationRemoved(
        address _beneficiary,
        string _vestingScheduleName,
        uint256 _amount,
        uint256 _currentAllocation
    );

    /**
     * @dev Event is triggered when contract paused or unpaused
     * @param _paused bool is paused
     */
    event ContractPaused(bool _paused);

    /**
     * @dev Event is triggered when beneficiary deleted
     * @param _beneficiary address of beneficiary
     */
    event BeneficiaryDeleted(address _beneficiary);

    /**
     * @dev Event is triggered when tokens claimed
     * @param _beneficiary address of beneficiary
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     * @param _releasedAmount uint256 released amount of beneficiary tokens for current vesting schedule
     */
    event TokensClaimed(address _beneficiary, string _vestingScheduleName, uint256 _amount, uint256 _releasedAmount);

    struct VestingSchedule {
        string name;
        uint256 terms;
        uint256 cliff;
        uint256 duration;
        uint256 totalAmount;
        uint256 allocatedAmount;
        uint256 releasedAmount;
        bool initialized;
        bool revoked;
    }

    struct Vesting {
        string name;
        uint256 amount;
        uint256 timestamp;
    }

    struct VestingExpectation {
        Vesting vesting;
        uint256 beneficiaryAmount;
    }

    struct BeneficiaryOverview {
        string name;
        uint256 terms;
        uint256 cliff;
        uint256 duration;
        uint256 allocatedAmount;
        uint256 withdrawnAmount;
    }

    struct Beneficiary {
        uint256 allocatedAmount;
        uint256 withdrawnAmount;
    }

    IERC20 private immutable token;
    string[] private vestingSchedulesNames;
    uint256 private vestingSchedulesTotalReservedAmount;
    uint256 private validVestingSchedulesCount;
    uint256 public tgeTimestamp;
    address public treasuryAddress;
    bool public paused;
    mapping(string => VestingSchedule) private vestingSchedules;
    mapping(address => mapping(string => Beneficiary)) private beneficiaries;

    constructor(
        address _tokenContractAddress,
        uint256 _tgeTimestamp,
        address _treasuryAddress
    ) {
        if (_tokenContractAddress == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        if (_tgeTimestamp == 0) {
            revert TokenVesting_Error('The TGE Timestamp is zero!');
        }
        if (_treasuryAddress == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        token = IERC20(_tokenContractAddress);
        tgeTimestamp = _tgeTimestamp;
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @dev Revokes all schedules and sends tokens to a set address
     */
    function emergencyWithdrawal() external onlyOwner {
        if (token.balanceOf(address(this)) == 0) {
            revert TokenVesting_Error('Nothing to withdraw!');
        }
        string[] memory vestingScheduleNames = getValidVestingScheduleNames();
        uint256 scheduleNamesLength = vestingScheduleNames.length;
        for (uint256 i = 0; i < scheduleNamesLength; i++) {
            _revokeVestingSchedule(vestingScheduleNames[i]);
        }
        token.safeTransfer(treasuryAddress, token.balanceOf(address(this)));
    }

    /**
     * @dev Pauses contract
     */
    function pauseContract() external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        paused = true;
        emit ContractPaused(paused);
    }

    /**
     * @dev Unpauses contract
     */
    function unpauseContract() external onlyOwner {
        if (!paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        paused = false;
        emit ContractPaused(paused);
    }

    /**
     * @dev Gets ERC20 token address
     * @return address of token
     */
    function getToken() external view returns (address) {
        return address(token);
    }

    /**
     * @dev Creates a new vesting schedule
     * @param _name string vesting schedule name
     * @param _terms vesting schedule terms in seconds
     * @param _cliff cliff in seconds after which tokens will begin to vest
     * @param _duration the number of terms during which the tokens will be vested
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function createVestingSchedule(
        string calldata _name,
        uint256 _terms,
        uint256 _cliff,
        uint256 _duration,
        uint256 _amount
    ) external onlyOwner {
        uint256 unusedAmount = getUnusedAmount();

        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (bytes(_name).length == 0) {
            revert TokenVesting_Error('The name is empty!');
        }
        if (!isNameUnique(_name)) {
            revert TokenVesting_Error('The name is duplicated!');
        }
        if (unusedAmount < _amount) {
            revert TokenVesting_AmountExcessive(_amount, unusedAmount);
        }
        if (_duration == 0) {
            revert TokenVesting_Error('The duration is zero!');
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (_terms == 0) {
            revert TokenVesting_Error('The terms are zero!');
        }
        vestingSchedules[_name] = VestingSchedule({
            name: _name,
            terms: _terms,
            cliff: _cliff,
            duration: _duration,
            totalAmount: _amount,
            allocatedAmount: 0,
            releasedAmount: 0,
            initialized: true,
            revoked: false
        });
        vestingSchedulesTotalReservedAmount += _amount;
        vestingSchedulesNames.push(_name);
        validVestingSchedulesCount++;
        emit VestingScheduleCreated(_name, _amount);
    }

    /**
     * @dev Revokes vesting schedule
     * @param _name string schedule name
     */
    function revokeVestingSchedule(string memory _name) external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        _revokeVestingSchedule(_name);
    }

    /**
     * @dev Gets the vesting schedule information
     * @param _name string vesting schedule name
     * @return VestingSchedule structure information
     */
    function getVestingSchedule(string calldata _name) external view returns (VestingSchedule memory) {
        return vestingSchedules[_name];
    }

    /**
     * @dev Gets all vesting schedules
     * @return VestingSchedule structure list of all vesting schedules
     */
    function getAllVestingSchedules() external view returns (VestingSchedule[] memory) {
        uint256 scheduleNamesLength = vestingSchedulesNames.length;
        if (scheduleNamesLength == 0) {
            revert TokenVesting_Error('No vesting schedules!');
        }
        VestingSchedule[] memory allVestingSchedules = new VestingSchedule[](scheduleNamesLength);
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            allVestingSchedules[i] = vestingSchedules[vestingSchedulesNames[i]];
        }
        return allVestingSchedules;
    }

    /**
     * @dev Gets all valid vesting schedules
     * @return VestingSchedule structure list of all active vesting schedules
     */
    function getValidVestingSchedules() external view returns (VestingSchedule[] memory) {
        if (validVestingSchedulesCount == 0) {
            revert TokenVesting_Error('No valid vesting schedules!');
        }
        VestingSchedule[] memory validVestingSchedules = new VestingSchedule[](validVestingSchedulesCount);
        uint32 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (isVestingScheduleValid(vestingSchedulesNames[i])) {
                validVestingSchedules[j] = vestingSchedules[vestingSchedulesNames[i]];
                j++;
            }
        }
        return validVestingSchedules;
    }

    /**
     * INDECISIVE do we need it?
     * @dev Gets vesting schedules count
     * @return uint256 number of vesting schedules
     */
    function getVestingSchedulesCount() external view returns (uint256) {
        return vestingSchedulesNames.length;
    }

    /**
     * INDECISIVE do we need it?
     * @dev Gets valid vesting schedules count
     * @return uint256 number of vesting schedules
     */
    function getValidVestingSchedulesCount() external view returns (uint256) {
        return validVestingSchedulesCount;
    }

    /**
     * @dev Increases vesting schedule total amount
     * @param _name string vesting schedule name
     * @param _amount uint256 amount of tokens
     */
    function increaseVestingScheduleTotalAmount(uint256 _amount, string calldata _name) external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (isNameUnique(_name)) {
            revert TokenVesting_Error('The name doesnt exist!');
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (getUnusedAmount() < _amount) {
            revert TokenVesting_AmountExcessive(_amount, getUnusedAmount());
        }
        vestingSchedules[_name].totalAmount += _amount;
        vestingSchedulesTotalReservedAmount += _amount;
    }

    /**
     * @dev Decreases vesting schedule total amount
     * @param _name string vesting schedule name
     * @param _amount uint256 amount of tokens
     */
    function decreaseVestingScheduleTotalAmount(uint256 _amount, string calldata _name) external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (isNameUnique(_name)) {
            revert TokenVesting_Error('The name doesnt exist!');
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (getScheduleUnallocatedAmount(_name) < _amount) {
            revert TokenVesting_AmountExcessive(_amount, getScheduleUnallocatedAmount(_name));
        }
        vestingSchedules[_name].totalAmount -= _amount;
        vestingSchedulesTotalReservedAmount -= _amount;
    }

    /**
     * @dev Adds beneficiary allocation
     * @param _beneficiary address of user
     * @param _vestingScheduleName string
     * @param _amount uint256 amount of tokens
     */
    function addBeneficiaryAllocation(
        address _beneficiary,
        string memory _vestingScheduleName,
        uint256 _amount
    ) external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (_beneficiary == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        if (bytes(_vestingScheduleName).length == 0) {
            revert TokenVesting_Error('The name is empty!');
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (!isVestingScheduleValid(_vestingScheduleName)) {
            revert TokenVesting_Error('The schedule is invalid!');
        }
        if (getScheduleUnallocatedAmount(_vestingScheduleName) < _amount) {
            revert TokenVesting_AmountExcessive(_amount, getScheduleUnallocatedAmount(_vestingScheduleName));
        }

        beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount += _amount;
        vestingSchedules[_vestingScheduleName].allocatedAmount += _amount;

        emit AllocationAdded(
            _beneficiary,
            _vestingScheduleName,
            _amount,
            beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount
        );
    }

    /**
     * @dev Removes beneficiary allocation
     * @param _beneficiary address of user
     * @param _vestingScheduleName string
     * @param _amount uint256 amount of tokens
     */
    function removeBeneficiaryAllocation(
        address _beneficiary,
        string calldata _vestingScheduleName,
        uint256 _amount
    ) external onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (_beneficiary == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (bytes(_vestingScheduleName).length == 0) {
            revert TokenVesting_Error('The name is empty!');
        }
        if (!isVestingScheduleValid(_vestingScheduleName)) {
            revert TokenVesting_Error('The name is invalid!');
        }
        if (getBeneficiaryUnreleasedAmount(_beneficiary, _vestingScheduleName) < _amount) {
            revert TokenVesting_AmountExcessive(
                _amount,
                getBeneficiaryUnreleasedAmount(_beneficiary, _vestingScheduleName)
            );
        }
        beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount -= _amount;
        vestingSchedules[_vestingScheduleName].allocatedAmount -= _amount;

        emit AllocationRemoved(
            _beneficiary,
            _vestingScheduleName,
            _amount,
            beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount
        );
    }

    /**
     * @dev Gets beneficiary
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return Beneficiary struct
     */
    function getBeneficiary(address _beneficiary, string calldata _vestingScheduleName)
        external
        view
        returns (Beneficiary memory)
    {
        return beneficiaries[_beneficiary][_vestingScheduleName];
    }

    /**
     * @dev Deletes beneficiary
     * @param _beneficiary address of user
     */
    function deleteBeneficiary(address _beneficiary) external onlyOwner {
        if (_beneficiary == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        string[] memory scheduleNames = getBeneficiaryActiveScheduleNames(_beneficiary);
        uint256 scheduleNamesLength = scheduleNames.length;
        if (scheduleNamesLength == 0) {
            revert TokenVesting_BeneficiaryNoneActiveVestings();
        }
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            uint256 unreleasedAmount = getBeneficiaryUnreleasedAmount(_beneficiary, scheduleNames[i]);
            beneficiaries[_beneficiary][scheduleNames[i]].allocatedAmount -= unreleasedAmount;
            vestingSchedules[scheduleNames[i]].allocatedAmount -= unreleasedAmount;
        }
        emit BeneficiaryDeleted(_beneficiary);
    }

    /**
     * @dev Gets the beneficiary's next vestings
     * @param _beneficiary address of user
     * @return VestingExpectations[] structure
     */
    function getBeneficiaryNextVestings(address _beneficiary) external view returns (VestingExpectation[] memory) {
        string[] memory scheduleNames = getBeneficiaryActiveScheduleNames(_beneficiary);
        uint256 scheduleNamesLength = scheduleNames.length;
        if (scheduleNamesLength == 0) {
            revert TokenVesting_BeneficiaryNoneActiveVestings();
        }
        VestingExpectation[] memory vestingExpectations = new VestingExpectation[](scheduleNamesLength);
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            VestingExpectation memory vestingExpectation = VestingExpectation({
                vesting: getNextVesting(scheduleNames[i]),
                beneficiaryAmount: getNextUnlockAmount(_beneficiary, scheduleNames[i])
            });
            vestingExpectations[i] = vestingExpectation;
        }
        return vestingExpectations;
    }

    /**
     * @dev Gets beneficiary overview
     * @param _beneficiary address of user
     * @return BeneficiaryOverview[] structure
     */
    function getBeneficiaryOverview(address _beneficiary) external view returns (BeneficiaryOverview[] memory) {
        string[] memory scheduleNames = getBeneficiaryScheduleNames(_beneficiary);
        uint256 scheduleNamesLength = scheduleNames.length;
        if (scheduleNamesLength == 0) {
            revert TokenVesting_BeneficiaryNoneActiveVestings();
        }
        BeneficiaryOverview[] memory beneficiaryOverview = new BeneficiaryOverview[](scheduleNamesLength);
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            BeneficiaryOverview memory overview = BeneficiaryOverview({
                name: scheduleNames[i],
                terms: vestingSchedules[scheduleNames[i]].terms,
                cliff: vestingSchedules[scheduleNames[i]].cliff,
                duration: vestingSchedules[scheduleNames[i]].duration,
                allocatedAmount: beneficiaries[_beneficiary][scheduleNames[i]].allocatedAmount,
                withdrawnAmount: beneficiaries[_beneficiary][scheduleNames[i]].withdrawnAmount
            });
            beneficiaryOverview[i] = overview;
        }
        return beneficiaryOverview;
    }

    /**
     * @dev Gets the next vesting
     * @param _vestingScheduleName string
     * @return Vesting structure
     */
    function getNextVesting(string memory _vestingScheduleName) public view returns (Vesting memory) {
        if (isVestingScheduleFinished(_vestingScheduleName)) {
            revert TokenVesting_Error('The schedule is finished!');
        }
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        uint256 passedVestings = getPassedVestings(_vestingScheduleName);
        Vesting memory vesting;
        vesting.name = _vestingScheduleName;
        vesting.timestamp = tgeTimestamp + vestingSchedule.cliff + vestingSchedule.terms * (passedVestings + 1);
        vesting.amount = vestingSchedule.totalAmount / vestingSchedule.duration;
        return vesting;
    }

    /**
     * INDECISIVE public/internal
     * @dev Gets the amount of tokens locked for all schedules
     * @return uint256 unreleased amount of tokens
     */
    function getTotalLockedAmount() public view returns (uint256) {
        uint256 lockedAmount;
        string[] memory vestingScheduleNames = getAllVestingScheduleNames();
        uint256 scheduleNamesLength = vestingScheduleNames.length;
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            lockedAmount += getScheduleLockedAmount(vestingScheduleNames[i]);
        }
        return lockedAmount;
    }

    /**
     * @dev Claims caller's tokens
     * @param _vestingScheduleName string vesting schedule name
     * @param _amount uint256 amount of tokens
     */
    function claimTokens(string memory _vestingScheduleName, uint256 _amount) public {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        if (bytes(_vestingScheduleName).length == 0) {
            revert TokenVesting_Error('The name is empty!');
        }
        if (!isVestingScheduleValid(_vestingScheduleName)) {
            revert TokenVesting_Error('The name is invalid!');
        }
        if (_amount == 0) {
            revert TokenVesting_AmountZero();
        }
        if (getScheduleLockedAmount(_vestingScheduleName) < _amount) {
            revert TokenVesting_AmountExcessive(_amount, getScheduleLockedAmount(_vestingScheduleName));
        }
        if (getBeneficiaryUnclaimedAmount(_msgSender(), _vestingScheduleName) < _amount) {
            revert TokenVesting_AmountExcessive(
                _amount,
                getBeneficiaryUnclaimedAmount(_msgSender(), _vestingScheduleName)
            );
        }
        sendTokens(_msgSender(), _amount);
        vestingSchedulesTotalReservedAmount -= _amount;
        vestingSchedules[_vestingScheduleName].releasedAmount += _amount;
        beneficiaries[_msgSender()][_vestingScheduleName].withdrawnAmount += _amount;
        emit TokensClaimed(
            _msgSender(),
            _vestingScheduleName,
            _amount,
            beneficiaries[_msgSender()][_vestingScheduleName].withdrawnAmount
        );
    }

    /**
     * @dev Claims all caller's tokens for selected vesting schedule
     * @param _vestingScheduleName string vesting schedule name
     */
    function claimAllTokensForVestingSchedule(string memory _vestingScheduleName) public {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        uint256 amount = getBeneficiaryUnclaimedAmount(_msgSender(), _vestingScheduleName);
        claimTokens(_vestingScheduleName, amount);
    }

    /**
     * @dev Claims all caller's tokens
     */
    function claimAllTokens() public {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        string[] memory unclaimedVestingScheduleNames = getBeneficiaryUnclaimedScheduleNames(_msgSender());
        uint256 scheduleNamesLength = unclaimedVestingScheduleNames.length;
        if (scheduleNamesLength == 0) {
            revert TokenVesting_Error('There are no unclaimed tokens!');
        }
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            claimAllTokensForVestingSchedule(unclaimedVestingScheduleNames[i]);
        }
    }

    /**
     * @dev Returns the amount of tokens not involved in vesting schedules
     * @return uint256 amount of tokens
     */
    function getUnusedAmount() public view returns (uint256) {
        return token.balanceOf(address(this)) - vestingSchedulesTotalReservedAmount;
    }

    /**
     * @dev Returns current timestamp
     * @return uint256 timestamp
     */
    function getCurrentTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Checks is vesting schedule name unique
     * @param _name string vesting schedule name
     */
    function isNameUnique(string memory _name) internal view returns (bool) {
        uint256 scheduleNamesLength = vestingSchedulesNames.length;
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            if (keccak256(bytes(vestingSchedulesNames[i])) == keccak256(bytes(_name))) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Checks is vesting schedule valid
     * @param _vestingScheduleName string vesting schedule name
     * @return bool true if active
     */
    function isVestingScheduleValid(string memory _vestingScheduleName) internal view returns (bool) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.initialized && !vestingSchedule.revoked;
    }

    /**
     * @dev Gets all vesting schedule names
     * @return string list of schedule names
     */
    function getAllVestingScheduleNames() internal view virtual returns (string[] memory) {
        return vestingSchedulesNames;
    }

    /**
     * @dev Gets all valid vesting schedule names
     * @return string list of schedule names
     */
    function getValidVestingScheduleNames() internal view returns (string[] memory) {
        string[] memory validVestingSchedulesNames = new string[](validVestingSchedulesCount);
        uint256 scheduleNamesLength = vestingSchedulesNames.length;
        uint32 j;
        for (uint32 i = 0; i < scheduleNamesLength; i++) {
            if (isVestingScheduleValid(vestingSchedulesNames[i])) {
                validVestingSchedulesNames[j] = vestingSchedulesNames[i];
                j++;
            }
        }
        return validVestingSchedulesNames;
    }

    /**
     * @dev Revokes vesting schedule
     * @param _name string schedule name
     */
    function _revokeVestingSchedule(string memory _name) internal {
        if (isNameUnique(_name)) {
            revert TokenVesting_Error('The name doesnt exist!');
        }
        if (vestingSchedules[_name].revoked == true) {
            revert TokenVesting_Error('The schedule is revoked!');
        }
        vestingSchedules[_name].revoked = true;
        vestingSchedulesTotalReservedAmount -= getScheduleUnreleasedAmount(_name);
        validVestingSchedulesCount--;
        emit VestingScheduleRevoked(_name);
    }

    /**
     * @dev Checks is vesting schedule started
     * @param _vestingScheduleName string vesting schedule name
     * @return bool true if started
     */
    function isVestingScheduleStarted(string memory _vestingScheduleName) internal view returns (bool) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return getCurrentTimestamp() >= tgeTimestamp + vestingSchedule.cliff;
    }

    /**
     * @dev Checks is vesting schedule finished
     * @param _vestingScheduleName string vesting schedule name
     * @return bool true if finished
     */
    function isVestingScheduleFinished(string memory _vestingScheduleName) internal view returns (bool) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return
            getCurrentTimestamp() >
            tgeTimestamp + vestingSchedule.cliff + vestingSchedule.duration * vestingSchedule.terms;
    }

    /**
     * @dev Gets the vesting schedule passed duration
     * @param _vestingScheduleName string
     * @return uint256 number of passed vesting
     */
    function getPassedVestings(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        if (isVestingScheduleStarted(_vestingScheduleName)) {
            return (getCurrentTimestamp() - tgeTimestamp - vestingSchedule.cliff) / vestingSchedule.terms;
        }
        if (isVestingScheduleFinished(_vestingScheduleName)) {
            return vestingSchedule.duration;
        }
        return 0;
    }

    /**
     * @dev Returns the amount of tokens that can be released from vesting schedule
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unreleased amount of tokens
     */
    function getScheduleUnreleasedAmount(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.totalAmount - vestingSchedule.releasedAmount;
    }

    /**
     * @dev Returns the amount of locked tokens
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 locked amount of tokens
     */
    function getScheduleLockedAmount(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.allocatedAmount - vestingSchedule.releasedAmount;
    }

    /**
     * @dev Returns the amount of tokens that can be allocated from vesting schedule
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unallocated amount of tokens
     */
    function getScheduleUnallocatedAmount(string memory _vestingScheduleName) internal view returns (uint256) {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return vestingSchedule.totalAmount - vestingSchedule.allocatedAmount;
    }

    /**
     * @dev Gets beneficiary schedule names
     * @param _beneficiary address of user
     * @return string[] array schedule names assigned to beneficiary
     */
    function getBeneficiaryScheduleNames(address _beneficiary) internal view returns (string[] memory) {
        uint256 beneficiaryScheduleNamesCount;
        string[] memory vestingScheduleNames = getValidVestingScheduleNames();
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (beneficiaries[_beneficiary][vestingScheduleNames[i]].allocatedAmount > 0) {
                beneficiaryScheduleNamesCount++;
            }
        }

        string[] memory beneficiaryScheduleNames = new string[](beneficiaryScheduleNamesCount);
        uint256 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (beneficiaries[_beneficiary][vestingScheduleNames[i]].allocatedAmount > 0) {
                beneficiaryScheduleNames[j] = vestingScheduleNames[i];
                j++;
            }
        }
        return beneficiaryScheduleNames;
    }

    /**
     * @dev Gets beneficiary unclaimed schedule names
     * @param _beneficiary address of user
     * @return string[] array schedule names assigned to beneficiary
     */
    function getBeneficiaryUnclaimedScheduleNames(address _beneficiary) internal view returns (string[] memory) {
        uint256 beneficiaryScheduleNamesCount;
        string[] memory vestingScheduleNames = getValidVestingScheduleNames();
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (getBeneficiaryUnclaimedAmount(_beneficiary, vestingScheduleNames[i]) > 0) {
                beneficiaryScheduleNamesCount++;
            }
        }

        string[] memory beneficiaryScheduleNames = new string[](beneficiaryScheduleNamesCount);
        uint256 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (getBeneficiaryUnclaimedAmount(_beneficiary, vestingScheduleNames[i]) > 0) {
                beneficiaryScheduleNames[j] = vestingScheduleNames[i];
                j++;
            }
        }
        return beneficiaryScheduleNames;
    }

    /**
     * @dev Gets beneficiary active schedule names
     * @param _beneficiary address of user
     * @return string[] array schedule names assigned to beneficiary
     */
    function getBeneficiaryActiveScheduleNames(address _beneficiary) internal view returns (string[] memory) {
        uint256 beneficiaryActiveScheduleNamesCount;
        string[] memory vestingScheduleNames = getValidVestingScheduleNames();
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (
                beneficiaries[_beneficiary][vestingScheduleNames[i]].allocatedAmount > 0 &&
                !isVestingScheduleFinished(vestingScheduleNames[i])
            ) {
                beneficiaryActiveScheduleNamesCount++;
            }
        }

        string[] memory beneficiaryActiveScheduleNames = new string[](beneficiaryActiveScheduleNamesCount);
        uint256 j;
        for (uint32 i = 0; i < validVestingSchedulesCount; i++) {
            if (
                beneficiaries[_beneficiary][vestingScheduleNames[i]].allocatedAmount > 0 &&
                !isVestingScheduleFinished(vestingScheduleNames[i])
            ) {
                beneficiaryActiveScheduleNames[j] = vestingScheduleNames[i];
                j++;
            }
        }
        return beneficiaryActiveScheduleNames;
    }

    /**
     * @dev Gets beneficiary next unlocked amount
     * @param _beneficiary address of user
     * @param _vestingScheduleName string
     * @return uint256 allocation
     */
    function getNextUnlockAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        return beneficiaries[_beneficiary][_vestingScheduleName].allocatedAmount / vestingSchedule.duration;
    }

    /**
     * @dev Returns the unlocked amount of tokens for selected beneficiary and vesting schedule
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unlocked amount of tokens
     */
    function getBeneficiaryUnlockedAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleName];
        Beneficiary memory beneficiary = beneficiaries[_beneficiary][_vestingScheduleName];
        if (isVestingScheduleFinished(_vestingScheduleName)) {
            return beneficiary.allocatedAmount;
        }
        return (getPassedVestings(_vestingScheduleName) * beneficiary.allocatedAmount) / vestingSchedule.duration;
    }

    /**
     * @dev Returns the amount of tokens that can be claimed by beneficiary
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unclaimed amount of tokens
     */
    function getBeneficiaryUnclaimedAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        uint256 unlockedAmount = getBeneficiaryUnlockedAmount(_beneficiary, _vestingScheduleName);
        return unlockedAmount - beneficiaries[_beneficiary][_vestingScheduleName].withdrawnAmount;
    }

    /**
     * @dev Returns the amount of tokens that unreleased by beneficiary
     * @param _beneficiary address of user
     * @param _vestingScheduleName string vesting schedule name
     * @return uint256 unclaimed amount of tokens
     */
    function getBeneficiaryUnreleasedAmount(address _beneficiary, string memory _vestingScheduleName)
        internal
        view
        returns (uint256)
    {
        Beneficiary memory beneficiary = beneficiaries[_beneficiary][_vestingScheduleName];
        return beneficiary.allocatedAmount - beneficiary.withdrawnAmount;
    }

    /**
     * @dev Sends tokens to selected address
     * @param _to address of account
     * @param _amount uint256 amount of tokens
     */
    function sendTokens(address _to, uint256 _amount) internal {
        if (_to == address(0x0)) {
            revert TokenVesting_AddressIsZero();
        }
        if (_amount > getTotalLockedAmount()) {
            revert TokenVesting_AmountExcessive(_amount, getTotalLockedAmount());
        }
        token.safeTransfer(_to, _amount);
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        if (paused) {
            revert TokenVesting_ContractIsPaused(paused);
        }
        super.transferOwnership(newOwner);
    }
}