// SPDX-License-Identifier:MIT	
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "hardhat/console.sol";

contract RewardPool is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public constant DECIMAL_PRECISION = 10000;
    uint256 public slotTime;
    uint256 public rewardPerSlot;
    uint256 public initialTime;
    uint256 public lastRewardTransactionTime;
    address public stakingAddress;
    address public ectTokenAddress;
    uint256 constant maxSlot = 5;

    // Events:
    event SlotTimeUpdated(
        uint256 oldSlot,
        uint256 newSlot,
        uint256 time,
        address user
    );

    event RewardPerSlotUpdated(
        uint256 oldRewardPerSlot,
        uint256 newRewardPerSlot,
        uint256 time,
        address user
    );

    event StakingAddressUpdated(
        address oldAddress,
        address newAddress,
        uint256 time,
        address user
    );

    event ECTTokenAddressUpdated(
        address oldAddress,
        address newAddress,
        uint256 time,
        address user
    );

    event Waved(uint256 time, uint256 wavedTill, uint256 reward, address user);
    event WaveFailed(uint256 time, string reason);
    event Withdraw(address indexed owner,uint256 amount);

    function initialize(
        uint256 _slotTime,
        uint256 _rewardPerSlot,
        address _stakingAddress,
        address _ectTokenAddress
    ) public initializer {
        __Ownable_init();
        slotTime = _slotTime;
        rewardPerSlot = _rewardPerSlot;
        initialTime = block.timestamp;
        lastRewardTransactionTime = initialTime;
        stakingAddress = _stakingAddress;
        ectTokenAddress = _ectTokenAddress;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @dev Method to set Reward per slot, allowed only to contract owner.
     * @notice This method will allow only owner to set Reward.
     * @param _amount: Amount to be set per slot.
     */
    function setRewardPerSlot(uint256 _amount) external onlyOwner {
        wave();
        emit RewardPerSlotUpdated(
            rewardPerSlot,
            _amount,
            block.timestamp,
            msg.sender
        );
        rewardPerSlot = _amount;
    }

    /**
     * @dev Method to set Slot time, allowed only to contract owner.
     * @notice This method will allow only owner to set Slot time.
     * @param _slotTime: SlotTime to be set in this method.
     */
    function setSlotTime(uint256 _slotTime) external onlyOwner {
        wave();
        emit SlotTimeUpdated(slotTime, _slotTime, block.timestamp, msg.sender);
        slotTime = _slotTime;
    }

    /**
     * @dev Method to updtate new Staking Address, allowed only to contract owner.
     * @notice This method will allow only owner to update Staking Address in smart contract.
     * @param _stakingAddress: Staking Address to be set in this method.
     */
    function setStakingAddress(address _stakingAddress) external onlyOwner {
        wave();
        emit StakingAddressUpdated(
            stakingAddress,
            _stakingAddress,
            block.timestamp,
            msg.sender
        );
        stakingAddress = _stakingAddress;
    }

    /**
     * @dev Method to update new Fathom Address, allowed only to contract owner.
     * @notice This method will allow only owner to update Fathom Token contract address in smart contract.
     * @param _ectTokenAddress: ECT Address to be set in this method.
     */
    function setECTokenAddress(address _ectTokenAddress) external onlyOwner {
        wave();
        emit ECTTokenAddressUpdated(
            ectTokenAddress,
            _ectTokenAddress,
            block.timestamp,
            msg.sender
        );
        ectTokenAddress = _ectTokenAddress;
    }

    /**
     * @dev Method will calculate the Reward with the help of
           Reduce Compound Interest - 0.1 with DECIMAL_PRECISION - 1000 
           Transfer calculated Reward to the Staking contract address 
    */
    function wave() public {
        uint256 reward = waveAmount();
        console.log(reward,"asdasd");
        if (reward < IERC20(ectTokenAddress).balanceOf(address(this))) {
            if(reward>0){
            IERC20(ectTokenAddress).transfer(stakingAddress, reward);
            }
            lastRewardTransactionTime += (((block.timestamp -
                lastRewardTransactionTime) / slotTime) * slotTime);
            emit Waved(
                block.timestamp,
                lastRewardTransactionTime,
                reward,
                msg.sender
            );
        } else {
            emit WaveFailed(
                block.timestamp,
                "RewardPool: Insufficient ECT Token in pool"
            );
        }
    }

    function waveAmount() public view returns (uint256) {
        uint256 principal = IERC20(ectTokenAddress).balanceOf(address(this));
        console.log(principal,"p");
        uint256 slots = (block.timestamp - lastRewardTransactionTime) /
            slotTime;
        uint256 reward = 0;
        while (slots > 0) {
            uint256 _slots;
            if (slots >= 5) {
                _slots = maxSlot;
                slots -= 5;
            } else {
                _slots = slots;
                slots = 0;
            }
            uint256 _reward = (principal -
                ((principal *
                    (((100 * DECIMAL_PRECISION) - rewardPerSlot)**_slots)) /
                    ((100 * DECIMAL_PRECISION)**_slots)));
            reward += _reward;
            principal -= _reward;
        }

        return reward;
    }


    /**
    * @dev Method allow the owner of the contract to withdraw ECT Tokens
    * @param _amount Amount to withdraw
    * @notice The owner of the contract can withdraw ECT Tokens
    */
    function withdraw(uint256 _amount) external onlyOwner{
        IERC20(ectTokenAddress).transfer(owner(),_amount);
        emit Withdraw(owner(), _amount);
    }
}