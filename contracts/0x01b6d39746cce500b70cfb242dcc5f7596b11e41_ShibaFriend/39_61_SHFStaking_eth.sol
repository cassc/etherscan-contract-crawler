// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* @title Staking Contract
*/
contract SHFStakingETH is AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable{
    using EnumerableSet for EnumerableSet.AddressSet;
    enum StakeStatus{ WITHDREW, IN_PROGRESS }

    bytes32 public constant PRIVATE_SALE_ROLE = keccak256("PRIVATE_SALE_ROLE");
    bytes32 public constant GAME_POOL_ROLE = keccak256("GAME_POOL_ROLE");

    struct RoundInfo {
        uint256 id;
        uint256 planStakedAmount;
        uint256 totalReward;
    }

    struct UserStakingInfo {
        address user;
        uint256 stakedAmount;
        uint256 startRoundID;
        StakeStatus status;
    }

    address public tokenAddress;

    uint256 private totalStakedAmount;

    RoundInfo [] public rewardRounds;

    EnumerableSet.AddressSet private investors;

    mapping(address => UserStakingInfo[]) public investorDetails;

    function initialize() initializer public {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init_unchained();
    }

    /*
        admin's functions
    */
    function setTokenAddress(address _currency)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAddress = _currency;
    }

    function distributeTokenReward(uint256 _totalReward)
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_totalReward > 0, "SHFStaking: Reward must be greater than 0.");

        require(msg.value >= _totalReward, "SHFStaking: Not enough balance.");

        uint256 id = rewardRounds.length;

        rewardRounds.push(RoundInfo(id, totalStakedAmount, _totalReward));
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address _currency)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_currency == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(_currency);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        User's functions
    */

    /*
        Stake function of user
    */
    function userStake(uint256 tokenAmount)
        external
    {
        _stake(msg.sender, tokenAmount);
    }

    /*
        Stake function of contract: Private sale send tokens to stake for a user
    */
    function contractStake(address _user, uint256 _tokenAmount)
        external
    {
        require(hasRole(PRIVATE_SALE_ROLE, msg.sender), "SHFStaking: Caller is not Private Sale");
        _stake(_user, _tokenAmount);
    }

    /**
    * @notice Stake method that update the user's balance
    * @notice Staking will start in next Round
    */
    function _stake(address _user, uint256 _tokenAmount)
        internal
    {
        require(_user != address(0), "SHFStaking: Address Zero cannot stake.");
        require(_tokenAmount > 0, "SHFStaking: Amount of token must be greater than 0.");

        // get tokens from sender
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
        
        // update total stacked token of contract
        totalStakedAmount = totalStakedAmount + _tokenAmount;
        
        // add _user to list of investors
        if(!investors.contains(_user)) {
            investors.add(_user);
        }

        // Add another staking to _user
        uint256 nextRound = rewardRounds.length;

        investorDetails[_user].push(UserStakingInfo(_user, _tokenAmount, nextRound, StakeStatus.IN_PROGRESS));
    }

    /**
    * @notice Allow users to withdraw their staked amount from the contract
    */
    function withdraw()
        external
    {
        _sendToken(msg.sender);
        if(_calculateReward(msg.sender) > 0) {
            _sendReward(msg.sender);
        }
        _closeStakingUser(msg.sender);
    }

    function _sendToken(address _user)
        internal
    {
        require(_user != address(0), "SHFStaking: Cannot send token to address zero.");

        uint amountToken = _calculateStakedToken(_user);

        require(amountToken > 0, "SHFStaking: Amount of token too small.");

        IERC20(tokenAddress).transfer(_user, amountToken);

        totalStakedAmount = totalStakedAmount - amountToken;
    }

    function _closeStakingUser(address _user)
        internal
    {
        for(uint i = 0; i < investorDetails[_user].length; i++) {
            if(investorDetails[_user][i].status == StakeStatus.IN_PROGRESS) {
                investorDetails[_user][i].status = StakeStatus.WITHDREW;
                
            } 
        }
    }

    function calculateStakedToken()
        external
        view
        returns(uint)
    {
        return _calculateStakedToken(msg.sender);
    }

    function _calculateStakedToken(address _user)
        internal
        view
        returns(uint)
    {
        uint stakedToken = 0;

        for(uint i = 0; i < investorDetails[_user].length; i++) {
            if(investorDetails[_user][i].status == StakeStatus.IN_PROGRESS) {
                stakedToken = stakedToken + investorDetails[_user][i].stakedAmount;
            } 
        }

        return stakedToken;
    }

    /*
        User claim his reward without withdraw token
    */
    function claimReward()
        public
    {
        _sendReward(msg.sender);
        _changeStartRound(msg.sender);
    }

    function _sendReward(address _user)
        internal
        nonReentrant
    {
        require(_user != address(0), "SHFStaking: Cannot send reward to address zero.");

        uint reward = _calculateReward(_user);

        require(reward > 0, "SHFStaking: Reward too small.");

        // DO NOT use transfer because reentrancy attacks
        // payable(_user).transfer(reward);
        (bool success, ) = address(_user).call{ value: reward }("");

        require(success, "SHFStaking: Reward failed to send");
    }

    function _changeStartRound(address _user)
        internal
    {
        for(uint i = 0; i < investorDetails[_user].length; i++) {
            if(investorDetails[_user][i].status == StakeStatus.IN_PROGRESS) {
                investorDetails[_user][i].startRoundID = rewardRounds.length;
            } 
        }
    }
    
    function calculateReward()
        external
        view
        returns(uint)
    {
        return _calculateReward(msg.sender);
    }

    function _calculateReward(address _user)
        internal
        view
        returns(uint)
    {
        uint reward = 0;
        
        if(investors.contains(_user)) {
            uint currentRound = rewardRounds.length - 1;
            for(uint i = 0; i < investorDetails[_user].length; i++) {
                if(investorDetails[_user][i].status == StakeStatus.IN_PROGRESS) {
                    for(uint j = investorDetails[_user][i].startRoundID; j <= currentRound; j++) {
                        uint totalRw = rewardRounds[j].totalReward;
                        uint userAmount = investorDetails[_user][i].stakedAmount;
                        uint totalAmount = rewardRounds[j].planStakedAmount;

                        uint roundReward = totalRw * userAmount / totalAmount;

                        reward = reward + roundReward;
                    }
                } 
            }
        }
        
        return reward;
    }

    function _userGetStake(address _user)
        internal
        view
        returns(UserStakingInfo[] memory)
    {
        UserStakingInfo[] memory ret = new UserStakingInfo[](investorDetails[_user].length);
        for (uint i = 0; i < investorDetails[_user].length; i++) {
            ret[i] = investorDetails[_user][i];
        }
        return ret;
    }

    function adminGetUserStake(address _user)
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns(UserStakingInfo[] memory)
    {
        return _userGetStake(_user);
    }

    function userGetStake()
        public
        view
        returns(UserStakingInfo[] memory)
    {
        return _userGetStake(msg.sender);
    }

    function getAllRounds()
        public
        view
        returns (RoundInfo[] memory)
    {
        RoundInfo[] memory ret = new RoundInfo[](rewardRounds.length);
        for (uint i = 0; i < rewardRounds.length; i++) {
            ret[i] = rewardRounds[i];
        }
        return ret;
    }
}