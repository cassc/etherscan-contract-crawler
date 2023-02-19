// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokenVesting
 */
contract TokenVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct VestingSchedule{
        bool initialized;
        bool revoked;                   // if the vesting schedule has been revoked
        address beneficiary;            // beneficiary of tokens after they are released
        uint8 vestingType; // 0 - standard, 1 - non-standard, 2 - waterfall, 3- standard 2
        uint256 amountTotal;            // total amount of tokens to be released at the end of the vesting
        uint256  released;              // amount of tokens released
    }

    // address of the ERC20 token
    IERC20 immutable private _token;

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private burntTotalAmount;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    event Transfer(address from, address to, uint256 value);
    event Released(uint256 amount);
    event Revoked();

    /**
    * @dev Reverts if no vesting schedule matches the passed identifier.
    */
    modifier onlyIfVestingScheduleExists(bytes32 vestingScheduleId) {
        require(vestingSchedules[vestingScheduleId].initialized == true);
        _;
    }

    /**
    * @dev Reverts if the vesting schedule does not exist or has been revoked.
    */
    modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
        require(vestingSchedules[vestingScheduleId].initialized == true);
        require(vestingSchedules[vestingScheduleId].revoked == false);
        _;
    }

    /**
     * @dev Creates a vesting contract.
     * @param token_ address of the ERC20 token contract
     */
    constructor(address token_) {
        require(token_ != address(0x0));
        _token = IERC20(token_);
    }

    /**
    * @dev Returns the number of vesting schedules associated to a beneficiary.
    * @return scheduleCount the number of vesting schedules
    */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary) external view returns(uint256 scheduleCount){
        return holdersVestingCount[_beneficiary];
    }

    /**
    * @dev Returns the vesting schedule id at the given index.
    * @return vestingId the vesting id
    */
    function getVestingIdAtIndex(uint256 index) external view returns(bytes32 vestingId){
        require(index < getVestingSchedulesCount(), "TokenVesting: index out of bounds");
        return vestingSchedulesIds[index];
    }

    /**
    * @notice Returns the vesting schedule information for a given holder and index.
    * @return vestingSchedule the vesting schedule structure information
    */
    function getVestingScheduleByAddressAndIndex(address holder, uint256 index) external view returns(VestingSchedule memory vestingSchedule){
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(holder, index));
    }


    /**
    * @notice Returns the total amount of vesting schedules.
    * @return totalNumberOfVestingSchedules the total amount of vesting schedules
    */
    function getVestingSchedulesTotalAmount() external view returns(uint256 totalNumberOfVestingSchedules){
        return vestingSchedulesTotalAmount;
    }

    /**
    * @dev Returns the address of the ERC20 token managed by the vesting contract.
    * @return tokenAddress address of the ERC20 token
    */
    function getToken() external view returns(address tokenAddress){
        return address(_token);
    }

    /**
    * @notice Creates a new vesting schedule for a beneficiary.
    * @param beneficiaryAddress address of the vesting schedule's beneficiary
    * @param vestingAmount number of tokens
    * @param vestingType 0 - Standard, 1 - Non-Standard, 2 - Waterfall, 3 - Standard 2
    */
    function createVestingSchedule(address beneficiaryAddress, uint256 vestingAmount, uint8 vestingType) external onlyOwner nonReentrant {
        require(getWithdrawableAmount() >= vestingAmount, "TokenVesting: not enough withdrawable funds");
        require(vestingAmount > 0, "TokenVesting: amount must be > 0");

        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(beneficiaryAddress);

        vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            false,
            beneficiaryAddress,
            vestingType,
            vestingAmount,
            0
        );

        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(vestingAmount);
        vestingSchedulesIds.push(vestingScheduleId);
        uint256 currentVestingCount = holdersVestingCount[beneficiaryAddress];
        holdersVestingCount[beneficiaryAddress] = currentVestingCount.add(1);
    }

    /**
    * @notice Revokes the vesting schedule for given identifier.
    * @param vestingScheduleId the vesting schedule identifier
    */
    function revoke(bytes32 vestingScheduleId) external onlyOwner onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if(vestedAmount > 0){
            release(vestingScheduleId, vestedAmount);
        }
        uint256 unreleased = vestingSchedule.amountTotal.sub(vestingSchedule.released);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(unreleased);
        vestingSchedule.revoked = true;
    }

    /**
    * @notice Release vested amount of tokens.
    * @param vestingScheduleId the vesting schedule identifier
    * @param amount the amount to release
    */
    function release(bytes32 vestingScheduleId, uint256 amount) public nonReentrant onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];

        // Only allows the beneficiary or the owner to release the vested tokens
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "TokenVesting: only beneficiary and owner can release vested tokens"
        );

        // Only release vested amounts;
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount >= amount, "TokenVesting: cannot release tokens, not enough vested tokens");

        // Increase the amount of released totals
        vestingSchedule.released = vestingSchedule.released.add(amount);

        // Reduce the amount that is vested
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(amount);

        //  Transfers the total to the beneficiary
        address payable beneficiaryPayable = payable(vestingSchedule.beneficiary);
        _token.safeTransfer(beneficiaryPayable, amount);
    }

    /**
    * @dev Returns the number of vesting schedules managed by this contract.
    * @return totalNumberOfVestingSchedules the number of vesting schedules
    */
    function getVestingSchedulesCount() public view returns(uint256 totalNumberOfVestingSchedules){
        return vestingSchedulesIds.length;
    }

    /**
    * @notice Computes the vested amount of tokens for the given vesting schedule identifier
    * @param vestingScheduleId the id of the vesting schedule
    * @return releasableAmount the vested amount
    */
    function computeReleasableAmount(bytes32 vestingScheduleId)
        external
        onlyIfVestingScheduleNotRevoked(vestingScheduleId)
        view
        returns(uint256 releasableAmount){
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
    * @notice Returns the vesting schedule information for a given identifier.
    * @param vestingScheduleId the id of the vesting schedule
    * @return vestingInformation the vesting schedule structure information
    */
    function getVestingSchedule(bytes32 vestingScheduleId) public view returns(VestingSchedule memory vestingInformation){
        return vestingSchedules[vestingScheduleId];
    }

    /**
     * @notice burns token amount. cannot be more than the withdrawable amount of funds.
     * @param burnAmount total amount of tokens to be burnt
     */
    function burn(uint256 burnAmount) external onlyOwner nonReentrant {
        require(0 < burnAmount, "TokenBurning: must be more than zero");
        require(getWithdrawableAmount() >= burnAmount, "TokenBurning: not enough withdrawable funds");

        _token.approve(address(0x000000000000000000000000000000000000dEaD), 0);
        _token.approve(address(0x000000000000000000000000000000000000dEaD), burnAmount);
        _token.transfer(address(0x000000000000000000000000000000000000dEaD), burnAmount);

        burntTotalAmount = burntTotalAmount.add(burnAmount);

        emit Transfer(address(this), address(0x000000000000000000000000000000000000dEaD), burnAmount);
    }

    /**
     * @notice the number of tokens burnt
     * @return amountBurnt number of tokens burnt so far
     */
    function getBurntTotalAmount() external view returns(uint256 amountBurnt) {
        return burntTotalAmount;
    }

    /**
    * @dev Returns the amount of tokens that can be withdrawn by the owner.
    * @return withdrawableAmount the amount of tokens
    */
    function getWithdrawableAmount() public view returns(uint256 withdrawableAmount){
        return _token.balanceOf(address(this)).sub(vestingSchedulesTotalAmount);
    }

    /**
    * @dev Computes the next vesting schedule identifier for a given holder address.
    * @param holder the beneficiary address
    * @return nextScheduleId the next vesting schedule id for the holder
    */
    function computeNextVestingScheduleIdForHolder(address holder) public view returns(bytes32 nextScheduleId){
        return computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder]);
    }

    /**
    * @dev Returns the last vesting schedule for a given holder address.
    * @param holder the beneficiary address
    * @return vestingSchedule the last vesting schedule
    */
    function getLastVestingScheduleForHolder(address holder)
        external
        view
        returns(VestingSchedule memory vestingSchedule){
        return vestingSchedules[computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder] - 1)];
    }

    /**
    * @dev Computes the vesting schedule identifier for an address and an index.
    * @param holder address of the beneficiary
    * @param index the index of the schedule
    * @return scheduleId the schedule id
    */
    function computeVestingScheduleIdForAddressAndIndex(address holder, uint256 index)
        public
        pure
        returns(bytes32 scheduleId){
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
    * @dev Computes the releasable amount of tokens for a vesting schedule.
    * @param vestingSchedule the vesting schedule
    * @return amountOfReleasableTokens the amount of releasable tokens
    */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule) internal view returns(uint256 amountOfReleasableTokens){
        uint256 currentTime = getCurrentTime();
        uint256 vestingPercentage = 0; // divide by 100,000

        if (vestingSchedule.vestingType == 0) {
            // 0 - Standard Vesting Schedule
            if (currentTime > 1702857600) { vestingPercentage = vestingPercentage.add(30000); }   // 18 Dec 2023: 30%
            if (currentTime > 1710720000) { vestingPercentage = vestingPercentage.add(7500); }    // 18 Mar 2024: 7.5%
            if (currentTime > 1718668800) { vestingPercentage = vestingPercentage.add(7500); }    // 18 Jun 2024: 7.5%
            if (currentTime > 1726617600) { vestingPercentage = vestingPercentage.add(7500); }    // 18 Sep 2024: 7.5%
            if (currentTime > 1734480000) { vestingPercentage = vestingPercentage.add(7500); }    // 18 Dec 2024: 7.5%
            if (currentTime > 1742256000) { vestingPercentage = vestingPercentage.add(10000); }   // 18 Mar 2025: 10%
            if (currentTime > 1750204800) { vestingPercentage = vestingPercentage.add(10000); }   // 18 Jun 2025: 10%
            if (currentTime > 1758153600) { vestingPercentage = vestingPercentage.add(10000); }   // 18 Sep 2025: 10%
            if (currentTime > 1766016000) { vestingPercentage = vestingPercentage.add(10000); }   // 18 Dec 2025: 10%

            return vestingSchedule.amountTotal.mul(vestingPercentage).div(100000).sub(vestingSchedule.released);
        } else if (vestingSchedule.vestingType == 1) {
            // 1 - Non-Standard Vesting Schedule
            if (currentTime > 1702857600) { vestingPercentage = vestingPercentage.add(10000); }   // 18 Dec 2023: 10%
            if (currentTime > 1705536000) { vestingPercentage = vestingPercentage.add(10000); }   // 18 Jan 2024: 10%
            if (currentTime > 1708214400) { vestingPercentage = vestingPercentage.add(8000); }    // 18 Feb 2024: 8%
            if (currentTime > 1710720000) { vestingPercentage = vestingPercentage.add(8000); }    // 18 Mar 2024: 8%
            if (currentTime > 1713398400) { vestingPercentage = vestingPercentage.add(8000); }    // 18 Apr 2024: 8%
            if (currentTime > 1715990400) { vestingPercentage = vestingPercentage.add(8000); }    // 18 May 2024: 8%
            if (currentTime > 1718668800) { vestingPercentage = vestingPercentage.add(8000); }    // 18 Jun 2024: 8%
            if (currentTime > 1721260800) { vestingPercentage = vestingPercentage.add(8000); }    // 18 Jul 2024: 8%
            if (currentTime > 1723939200) { vestingPercentage = vestingPercentage.add(8000); }    // 18 Aug 2024: 8%
            if (currentTime > 1726617600) { vestingPercentage = vestingPercentage.add(8000); }    // 18 Sep 2024: 8%
            if (currentTime > 1729209600) { vestingPercentage = vestingPercentage.add(8000); }    // 18 Oct 2024: 8%
            if (currentTime > 1731888000) { vestingPercentage = vestingPercentage.add(8000); }    // 18 Nov 2024: 8%

            return vestingSchedule.amountTotal.mul(vestingPercentage).div(100000).sub(vestingSchedule.released);
        } else if (vestingSchedule.vestingType == 2) {
            // 2 - Waterfall Vesting Schedule
            // 100% released on 18 Dec 2023 (1702857600)
            return currentTime > 1702857600 ? vestingSchedule.amountTotal.sub(vestingSchedule.released) : 0;
        } else if (vestingSchedule.vestingType == 3) {
            // 3 - Standard 2
            if (currentTime > 1734480000) { vestingPercentage = vestingPercentage.add(30000); }   // 18 Dec 2024: 30%
            if (currentTime > 1742256000) { vestingPercentage = vestingPercentage.add(7500); }    // 18 Mar 2025: 7.5%
            if (currentTime > 1750204800) { vestingPercentage = vestingPercentage.add(7500); }    // 18 Jun 2025: 7.5%
            if (currentTime > 1758153600) { vestingPercentage = vestingPercentage.add(7500); }    // 18 Sep 2025: 7.5%
            if (currentTime > 1766016000) { vestingPercentage = vestingPercentage.add(7500); }    // 18 Dec 2025: 7.5%
            if (currentTime > 1773792000) { vestingPercentage = vestingPercentage.add(10000); }   // 18 Mar 2026: 10%
            if (currentTime > 1781740800) { vestingPercentage = vestingPercentage.add(10000); }   // 18 Jun 2026: 10%
            if (currentTime > 1789689600) { vestingPercentage = vestingPercentage.add(10000); }   // 18 Sep 2026: 10%
            if (currentTime > 1797552000) { vestingPercentage = vestingPercentage.add(10000); }   // 18 Dec 2026: 10%

            return vestingSchedule.amountTotal.mul(vestingPercentage).div(100000).sub(vestingSchedule.released);
        } else {
            revert("Invalid vesting schedule type.");
        }
    }

    /**
     * @dev gets the current time
     * @return currentTime the timestamp of the block
     */
    function getCurrentTime() internal virtual view returns(uint256 currentTime){
        return block.timestamp;
    }

}