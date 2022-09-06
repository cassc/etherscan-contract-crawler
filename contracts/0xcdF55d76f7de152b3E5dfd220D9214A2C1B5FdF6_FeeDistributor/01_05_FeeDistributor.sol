// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IVotingEscrow {
    function balanceOfAt(address _address, uint _block) external view returns (uint);
    function totalSupplyAt(uint _block) external view returns (uint);
}

/**
 * @title FeeDistributor
 * @notice Contract shouldn't have added rewards more than tx limit can handle because claiming rewards loops on added rewards
 */
contract FeeDistributor {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Reward {
        address token;
        uint blockNumber;
        uint amount; 
    }

    mapping(address => bool) public isManager;
    mapping(uint => Reward) public rewards;
    //index of reward that is next to be claimed
    mapping(address => uint) public lastClaimed;
    mapping(address => mapping(uint => bool)) public isClaimed;

    uint public numberOfRewards;
    IVotingEscrow public votingEscrow;

    constructor(address _votingEscrow) public {
        votingEscrow = IVotingEscrow(_votingEscrow);
        isManager[msg.sender] = true;
    }

    /** 
     * @notice Adds a new reward distribution
     * @param _token The address of the token
     * @param _amount The amount of token
     */
    function addReward(
        address _token,
        uint _amount
    )
        external
        onlyManager
    {
        Reward memory newReward;
        newReward.blockNumber = block.number;
        newReward.token = _token;
        newReward.amount = _amount;

        rewards[numberOfRewards] = newReward;
        numberOfRewards++;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);    
    }

    /** 
     * @notice Adds a new reward distribution at a specific block
     * @param _token The address of the token
     * @param _amount The amount of token
     * @param _block Block number
     */
    function addRewardAtBlock(
        address _token,
        uint _amount,
        uint _block
    )
        external
        onlyManager
    {
        Reward memory newReward;
        newReward.blockNumber = _block;
        newReward.token = _token;
        newReward.amount = _amount;

        rewards[numberOfRewards] = newReward;
        numberOfRewards++;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);    
    }

    /** 
     * @notice Returns reward amount of _address in _token
     * @param _token The address of the token
     * @param _address The address
     */
    function getRewardAmount(
        address _token,
        address _address
    )
        external
        view
        returns(uint reward)
    {
        uint addressLastClaimed = lastClaimed[_address];
        
        while(addressLastClaimed < numberOfRewards) {
            Reward memory cReward = rewards[addressLastClaimed];

            //skip if reward is in a different token or if _address already claimed this reward individually
            if(cReward.token != _token || isClaimed[_address][addressLastClaimed]) {
                addressLastClaimed++;
                continue;
            }
            
            //_address share of total supply of veYAXIS at _block times reward amount
            reward += votingEscrow.balanceOfAt(_address, cReward.blockNumber).mul(cReward.amount).div(votingEscrow.totalSupplyAt(cReward.blockNumber));
            addressLastClaimed++;
        } 
    }

    /** 
     * @notice Claims rewards in _token
     * @param _token The address of the token
     */
    function claimRewards(
        address _token
    )
        external
    {
        uint addressLastClaimed = lastClaimed[msg.sender];
        require(addressLastClaimed < numberOfRewards, "No rewards to claim");

        uint reward;
        while(addressLastClaimed < numberOfRewards) {
            Reward memory cReward = rewards[addressLastClaimed];
            
            //skip if sender already claimed this reward individually
            if(cReward.token != _token || isClaimed[msg.sender][addressLastClaimed]) {
                addressLastClaimed++;
                continue;
            }
            
            //sender share of total supply of veYAXIS at _block times reward amount
            reward += votingEscrow.balanceOfAt(msg.sender, cReward.blockNumber).mul(cReward.amount).div(votingEscrow.totalSupplyAt(cReward.blockNumber));
            isClaimed[msg.sender][addressLastClaimed] = true;
            addressLastClaimed++;
        } 
        //to avoid wasting gas on claiming zero tokens 
        require(reward > 0, "!rewards");

        IERC20(_token).safeTransfer(msg.sender, reward);
        updateLastClaimed(msg.sender);
    }

    /** 
     * @notice Claims reward by index in _token
     * @param _token The address of the token
     * @param _index The index of the reward
     */
    function claimRewardsByIndex(
        address _token,
        uint _index
    )
        external
    {
        require(_index < numberOfRewards, "Wrong index");
        require(!isClaimed[msg.sender][_index], "Reward is already claimed");

        Reward memory cReward = rewards[_index];

        uint reward = votingEscrow.balanceOfAt(msg.sender, cReward.blockNumber).mul(cReward.amount).div(votingEscrow.totalSupplyAt(cReward.blockNumber));
        isClaimed[msg.sender][_index] = true;
        
        //to avoid wasting gas on claiming zero tokens
        require(reward > 0, "!rewards");

        IERC20(_token).safeTransfer(msg.sender, reward);
        updateLastClaimed(msg.sender);
    }

    /**
     * @notice Updates lastClaimed that is used to reduce loops
     * @param _address The address to optimize
     */
    function updateLastClaimed(
        address _address
    )
        internal
    {
        uint addressLastClaimed = lastClaimed[_address];

        while(addressLastClaimed < numberOfRewards) {
            if(!isClaimed[_address][addressLastClaimed]) {
                lastClaimed[_address] = addressLastClaimed;
                break;
            }
            addressLastClaimed++;
        }
    }

    /**
     * @notice Sets the status of a manager
     * @param _manager The address of the manager
     * @param _status The status to allow the manager 
     */
    function setManager(
        address _manager,
        bool _status
    )
        external
        onlyManager
    {
        isManager[_manager] = _status;
    }

    modifier onlyManager() {
        require(isManager[msg.sender], "!manager");
        _;
    }
}