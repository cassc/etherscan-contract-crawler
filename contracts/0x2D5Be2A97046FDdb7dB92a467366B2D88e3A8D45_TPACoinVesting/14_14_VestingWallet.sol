// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract TPACoinVesting is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Vesting {
        uint256 startedAt; // Timestamp in seconds
        uint256 totalAmount; // Vested amount TPA in TPA
        uint256 releasedAmount; // Amount that beneficiary withdraw
        uint256 stepDuration; // Duration of each step in seconds
    }
    // ===============================================================================================================
    // Members
    // ===============================================================================================================
    uint256 public totalVestedAmount;
    uint256 public totalReleasedAmount;
    IERC20Upgradeable public token;

    // Beneficiary address -> Array of Vesting params
    mapping(address => Vesting[]) vestingMap;

    // ===============================================================================================================
    // Constructor
    // ===============================================================================================================
    /// @notice Contract constructor - sets the token address that the contract facilitates.
    /// @param _token - ERC20 token address.

    // initialize function
    function initialize(address _token) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        token = IERC20Upgradeable(_token);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice Creates vesting for beneficiary, with a given amount of tokens to allocate.
    /// The allocation will start when the method is called (block.timestamp).
    /// @param _beneficiary - address of beneficiary.
    /// @param _amount - amount of tokens to allocate
    function addVestingFromNow(
        address _beneficiary,
        uint256 _amount,
        uint256 _stepDuration
    ) public onlyOwner {
        addVesting(_beneficiary, _amount, block.timestamp, _stepDuration);
    }

    /// @notice Creates vesting for beneficiary, with a given amount of funds to allocate,
    /// and timestamp of the allocation.
    /// @param _beneficiary - address of beneficiary.
    /// @param _amount - amount of tokens to allocate
    /// @param _startedAt - timestamp (in seconds) when the allocation should start
    function addVesting(
        address _beneficiary,
        uint256 _amount,
        uint256 _startedAt,
        uint256 _stepDuration
    ) public onlyOwner {
        require(
            _startedAt >= block.timestamp,
            "TIMESTAMP_CANNOT_BE_IN_THE_PAST"
        );
        require(_amount >= _stepDuration, "VESTING_AMOUNT_TO0_LOW");
        uint256 debt = totalVestedAmount.sub(totalReleasedAmount);
        uint256 available = token.balanceOf(address(this)).sub(debt);

        require(available >= _amount, "DON_T_HAVE_ENOUGH_TPA");

        Vesting memory v = Vesting({
            startedAt: _startedAt,
            totalAmount: _amount,
            releasedAmount: 0,
            stepDuration: _stepDuration
        });

        vestingMap[_beneficiary].push(v);
        totalVestedAmount = totalVestedAmount.add(_amount);
    }

    // get vesting info for beneficiary
    function getVestingInfo(address _beneficiary)
        public
        view
        returns (Vesting[] memory)
    {
        return vestingMap[_beneficiary];
    }

    // Add multiple vesting for multiple beneficiaries
    function addMultipleVesting(
        address[] memory _beneficiaries,
        uint256[] memory _amounts,
        uint256 _startedAt,
        uint256 _stepDuration
    ) external onlyOwner {
        require(
            _beneficiaries.length == _amounts.length,
            "BENEFICIARIES_AND_AMOUNTS_MUST_HAVE_SAME_LENGTH"
        );
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            addVesting(
                _beneficiaries[i],
                _amounts[i],
                _startedAt,
                _stepDuration
            );
        }
    }

    // remove vesting for beneficiary
    function removeVesting(address _beneficiary, uint256 _index)
        external
        onlyOwner
    {
        Vesting[] storage vestings = vestingMap[_beneficiary];
        // index must be valid (within length)
        require(_index < vestings.length, "INVALID_INDEX");
        Vesting memory v = vestings[_index];
        totalVestedAmount = totalVestedAmount.sub(v.totalAmount);
        totalReleasedAmount = totalReleasedAmount.sub(v.releasedAmount);
        vestings[_index] = vestings[vestings.length - 1];
        vestings.pop();
    }

    // release all vesting for beneficiary
    function releaseVested(address[] memory _beneficiaries) external {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            // get vesting for beneficiary
            Vesting[] storage vestings = vestingMap[_beneficiaries[i]];
            for (uint256 j = 0; j < vestings.length; j++) {
                Vesting storage v = vestings[j];
                uint256 amount = getAvailableAmountAtTimestamp(
                    _beneficiaries[i],
                    j,
                    block.timestamp
                );
                if (amount > 0) {
                    v.releasedAmount = v.releasedAmount.add(amount);
                    totalReleasedAmount = totalReleasedAmount.add(amount);
                    token.safeTransfer(_beneficiaries[i], amount);
                }
            }
        }
    }

    function _removeAllvesting(address _beneficiary) internal {
        Vesting[] storage vestings = vestingMap[_beneficiary];
        for (uint256 i = 0; i < vestings.length; i++) {
            Vesting memory v = vestings[i];
            totalVestedAmount = totalVestedAmount.sub(v.totalAmount);
            totalReleasedAmount = totalReleasedAmount.sub(v.releasedAmount);
        }
        delete vestingMap[_beneficiary];
    }

    // remove all vesting for beneficiary
    function removeAllVesting(address _beneficiary) external onlyOwner {
        _removeAllvesting(_beneficiary);
    }

    // remove multiple vesting for multiple beneficiaries
    function removeMultipleVesting(address[] memory _beneficiaries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            _removeAllvesting(_beneficiaries[i]);
        }
    }

    /// @notice Method that allows a beneficiary to withdraw their allocated funds for a specific vesting ID.
    /// @param _vestingId - The ID of the vesting the beneficiary can withdraw their funds for.
    function withdraw(uint256 _vestingId) external {
        uint256 amount = getAvailableAmount(msg.sender, _vestingId);
        require(amount > 0, "DON_T_HAVE_RELEASED_TOKENS");

        // Increased released amount in in mapping
        vestingMap[msg.sender][_vestingId].releasedAmount = vestingMap[
            msg.sender
        ][_vestingId].releasedAmount.add(amount);

        // Increased total released in contract
        totalReleasedAmount = totalReleasedAmount.add(amount);
        token.safeTransfer(msg.sender, amount);
    }

    /// @notice Method that allows a beneficiary to withdraw all their allocated funds.
    function withdrawAllAvailable() external {
        uint256 aggregatedAmount = 0;

        uint256 maxId = vestingMap[msg.sender].length;
        for (uint vestingId = 0; vestingId < maxId; vestingId++) {
            uint256 availableInSingleVesting = getAvailableAmount(
                msg.sender,
                vestingId
            );
            aggregatedAmount = aggregatedAmount.add(availableInSingleVesting);

            // Update released amount in specific vesting
            vestingMap[msg.sender][vestingId].releasedAmount = vestingMap[
                msg.sender
            ][vestingId].releasedAmount.add(availableInSingleVesting);
        }

        // Increase released amount
        totalReleasedAmount = totalReleasedAmount.add(aggregatedAmount);

        // Transfer
        token.safeTransfer(msg.sender, aggregatedAmount);
    }

    /// @notice Method that allows the owner to withdraw unallocated funds to a specific address
    /// @param _receiver - address where the funds will be send
    function withdrawUnallocatedFunds(address _receiver) external onlyOwner {
        uint256 amount = getUnallocatedFundsAmount();
        require(amount > 0, "DON_T_HAVE_UNALLOCATED_TOKENS");
        token.safeTransfer(_receiver, amount);
    }

    // ===============================================================================================================
    // Getters
    // ===============================================================================================================

    /// @notice Returns smallest unused VestingId (unique per beneficiary).
    /// The next vesting ID can be used by the benficiary to see how many vestings / allocations has.
    /// @param _beneficiary - address of the beneficiary to return the next vesting ID
    function getNextVestingId(address _beneficiary)
        public
        view
        returns (uint256)
    {
        return vestingMap[_beneficiary].length;
    }

    /// @notice Returns amount of funds that beneficiary can withdraw using all vesting records of given beneficiary address
    /// @param _beneficiary - address of the beneficiary
    function getAvailableAmountAggregated(address _beneficiary)
        public
        view
        returns (uint256)
    {
        uint256 available = 0;
        uint256 maxId = vestingMap[_beneficiary].length;
        //
        for (uint vestingId = 0; vestingId < maxId; vestingId++) {
            // Optimization for gas saving in case vesting were already released
            if (
                vestingMap[_beneficiary][vestingId].totalAmount ==
                vestingMap[_beneficiary][vestingId].releasedAmount
            ) {
                continue;
            }

            available = available.add(
                getAvailableAmount(_beneficiary, vestingId)
            );
        }
        return available;
    }

    /// @notice Returns amount of funds that beneficiary can withdraw, vestingId should be specified (default is 0)
    /// @param _beneficiary - address of the beneficiary
    /// @param _vestingId - the ID of the vesting (default is 0)
    function getAvailableAmount(address _beneficiary, uint256 _vestingId)
        public
        view
        returns (uint256)
    {
        return
            getAvailableAmountAtTimestamp(
                _beneficiary,
                _vestingId,
                block.timestamp
            );
    }

    /// @notice Returns amount of funds that beneficiary will be able to withdraw at the given timestamp per vesting ID (default is 0).
    /// @param _beneficiary - address of the beneficiary
    /// @param _vestingId - the ID of the vesting (default is 0)
    /// @param _timestamp - Timestamp (in seconds) on which the beneficiary wants to check the withdrawable amount.
    function getAvailableAmountAtTimestamp(
        address _beneficiary,
        uint256 _vestingId,
        uint256 _timestamp
    ) public view returns (uint256) {
        if (_vestingId >= vestingMap[_beneficiary].length) {
            return 0;
        }

        Vesting memory vesting = vestingMap[_beneficiary][_vestingId];

        uint256 rewardPerMonth = vesting.totalAmount.div(vesting.stepDuration);

        // stepDuration Month
        uint256 monthPassed = _timestamp.sub(vesting.startedAt).div(30 days); // We say that 1 month is always 30 days

        uint256 alreadyReleased = vesting.releasedAmount;

        // In stepDuration month 100% of tokens is already released:
        if (monthPassed >= vesting.stepDuration) {
            return vesting.totalAmount.sub(alreadyReleased);
        }

        return rewardPerMonth.mul(monthPassed).sub(alreadyReleased);
    }

    /// @notice Returns amount of unallocated funds that contract owner can withdraw
    function getUnallocatedFundsAmount() public view returns (uint256) {
        uint256 debt = totalVestedAmount.sub(totalReleasedAmount);
        uint256 available = token.balanceOf(address(this)).sub(debt);
        return available;
    }
}