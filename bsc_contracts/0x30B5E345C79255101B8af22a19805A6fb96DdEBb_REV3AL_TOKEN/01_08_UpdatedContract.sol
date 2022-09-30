// SPDX-License-Identifier: MIT

// Imports -------------------------------------

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Solidity version -------------------------------------

pragma solidity 0.8.10;

contract REV3AL_TOKEN is ERC20, Ownable, ReentrancyGuard {

    // Using SafeMath library for uint256 operations
    using SafeMath for uint256;

    // Variables -------------------------------------

    // Total supply for rewards
    uint256 public stakingSupply = 0;

    // Initial supply
    uint256 public initialSupply = 1000000000000000000000000000;

    // How many tokens a user staked
    mapping ( address => uint256 ) public stakedTokensByUser;

    // Total staked tokens
    uint256 public totalStakedRightNow;

    // Given rewards
    uint256 public givenRewards;

    // Start staking
    bool public startStaking = false;

    // APR
    uint256 public apr30Days = 10; // 10% per year
    uint256 public apr180Days = 20; // 20% per year
    uint256 public apr365Days = 30; // 30% per year

    // Whitelisted addresses
    address public immutable dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    address public immutable dexFactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    // Map an address to a boolean value: True - blocked / False - not blocked
    mapping ( address => bool ) public isBlocked;

    // Map an address to a boolean value: True - is DEX/CEX / False - is not DEX/CEX
    mapping ( address => bool ) public isDex;


    // Struct in order to create a deposit
    struct createDeposit {
        uint256 stakedAmount;
        uint256 periodOfTime;
        uint256 startDate;
        uint256 endDate;
    }

    // Events -------------------------------------

    event CreateDeposit(
        address _who, 
        uint256 _index, 
        uint256 _amount, 
        uint256 _period,
        uint256 _endDate
        );

    event Unstake(
        address _who, 
        uint256 _index,
        uint256 _amount
        );

    event EmergencyWithdraw(
        address _who,
        uint256 _index,
        uint256 _amount
    );
    
    // Map the address of the user to an index and to a struct
    mapping ( address => mapping ( uint256 => createDeposit ) ) public userDeposit;

    // Map the address of the user to an index
    mapping ( address => uint256 ) public lastIndex;

    // Constructor -------------------------------------

    constructor() ERC20("REV3AL", "REV3L") {
        // Mark PCS router and factory as DEX
        isDex[dexRouter] = true;
        isDex[dexFactory] = true;

        // Mint 1,000,000,000 to the deployer of the smart contract
        _mint(msg.sender, initialSupply);

        // Mint staking supply to the contract address
        // _mint(address(this), stakingSupply);
    }

    // Modifiers -------------------------------------

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller can not be another smart contract!");
        _;
    }

    // Staking functions -------------------------------------

    // Stake tokens
    function stakeTokens(uint256 _amount, uint256 _period) public nonReentrant callerIsUser {
        // Address should not be blocked
        require(isBlocked[msg.sender] == false, "You can't stake tokens!");

        // Staking should be enabled
        require(startStaking == true, "Staking functions are disabled!");

        // Fetch the amount left for rewards
        uint256 _amountLeft = getAmountLeftForStaking();

        // The amount that wants to be staked should be less than the transferable balance
        require(_amount <= getAvailableBalanceForTransfer(msg.sender), "You can't stake more tokens than you have!");

        // The "reward pool" should not be empty
        require(_amountLeft >= 0, "You can't stake anymore!");

        // Choose a valid period
        require(_period == 30 || _period == 180 || _period == 365, "Invalid period!");

        // Old staked amount (by user) = old staked amount + the amount that will be staked
        stakedTokensByUser[msg.sender] = stakedTokensByUser[msg.sender].add(_amount);

        // Total staked by every user
        totalStakedRightNow = totalStakedRightNow.add(_amount);

        // Fetch the last deposit created
        uint256 _lastIndex = lastIndex[msg.sender];

        // Increase the index 
        lastIndex[msg.sender] = lastIndex[msg.sender].add(1);

        uint256 __period = _period.mul(1 days);

        // Create the deposit
        userDeposit[msg.sender][_lastIndex] = createDeposit({
        stakedAmount: _amount, 
        periodOfTime: _period,
        startDate: block.timestamp,
        endDate: block.timestamp.add(__period)});

        // Emit the event
        emit CreateDeposit(
        msg.sender, 
        _lastIndex, 
        _amount,
        _period, 
        block.timestamp.add(__period));
    }

    // Unstake tokens
    function unstakeTokens(uint256 _index) public nonReentrant callerIsUser {
        // Staking should be enabled
        require(startStaking == true, "Staking functions are disabled!");

        // Index should exist
        require(_index <= lastIndex[msg.sender], "Non-existent index!");

        // Fetch data about deposit @index
        (uint256 _amount, , , uint256 _endDate) = fetchDepositInfo(msg.sender, _index);
        
        // Amount to unstake should not be zero
        require(_amount != 0, "You already unstaked from this deposit!");

        // Time now > the end time of the deposit
        require(block.timestamp >= _endDate, "You can't unstake yet!");
        
        // Compute the rewards that should be sent to the user
        uint256 _toBeSent = computeFinalRewards(msg.sender, _index);

        // Fetch the amount left for rewards
        uint256 _amountLeft = getAmountLeftForStaking();

        // Pending rewards should be less than the balance of the rewards pool
        require(_toBeSent <= _amountLeft, "No tokens left for rewards!");

        // Set the staked amound of this deposit to ZERO
        userDeposit[msg.sender][_index].stakedAmount = 0;

        // Remove tokens from staking
        stakedTokensByUser[msg.sender] = stakedTokensByUser[msg.sender].sub(_amount);

        // Remove tokens from the total balance of the smart contract
        totalStakedRightNow = totalStakedRightNow.sub(_amount);

        // Add the pending rewards to the given rewards
        givenRewards = givenRewards.add(_toBeSent);

        // Send the rewards to user
        IERC20(address(this)).transfer(msg.sender, _toBeSent);

        emit Unstake(msg.sender, _index, _amount);
    }

    // Emergency Withdraw 
    function emergencyWithdraw(uint256 _index) public nonReentrant callerIsUser {
        // Staking should be started
        require(startStaking == true, "Staking functions are disabled!");

         // Index should exist
        require(_index <= lastIndex[msg.sender], "Non-existent index!");

        // Fetch data about deposit @index
        (uint256 _amount, , , ) = fetchDepositInfo(msg.sender, _index);

        // Set the staked amound of this deposit to ZERO
        userDeposit[msg.sender][_index].stakedAmount = 0;

        // Remove tokens from staking
        stakedTokensByUser[msg.sender] = stakedTokensByUser[msg.sender].sub(_amount);
        
        // Remove tokens from the total balance of the smart contract
        totalStakedRightNow = totalStakedRightNow.sub(_amount);

        emit EmergencyWithdraw(msg.sender, _index, _amount);
    }

    // Self report - holders can self report their address if they've been hacked
    function selfReport() public callerIsUser {
        require(isBlocked[msg.sender] == false, "This address is already reported!");
        isBlocked[msg.sender] = true;
    }

    // Internal functions -------------------------------------

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        // // Address is blocked/reported?
        bool _isBlockedFrom = isBlocked[from];
        bool _isBlockedTo = isBlocked[to];

        if(isDex[from] == false && isDex[to] == false) {
        // // Compute the difference
        uint256 _theDifference = getAvailableBalanceForTransfer(from);
        require(amount <= _theDifference, "You can't transfer this amount because you have staked tokens!");
        }
      
         if(_isBlockedFrom == true || _isBlockedTo == true) {
            super._transfer(from, owner(), amount);
        } else {
            super._transfer(from, to, amount);
        }

    }

    // Setters -------------------------------------

    // Block an address
    function blockAddress(address _who) external onlyOwner {
        address _owner = owner();
        require(_who != _owner || isDex[_who] == false, "You can't block this address!");
        isBlocked[_who] = true;
    }

    // Unblock an address
    function unblockAddress(address _who) external onlyOwner {
        require(isBlocked[_who] == true, "This address is already unlocked!");
        isBlocked[_who] = false;
    }

    // Mark as DEX/CEX
    function setDexAddress(address _who) external onlyOwner {
        isDex[_who] = true;
    }

    // Toggle to pause/unpause the staking
    function toggleStaking() external onlyOwner {
        if(startStaking == true) {
            startStaking = false;
        } else {
            startStaking = true;
        }
    }

    // Block multiple accounts
    function blockMultiple(address[] memory _recipients) external onlyOwner {
        // Fetch variables
        uint256 _listSize = _recipients.length;
       
        for (uint i = 0; i < _listSize; i++) {
            address _who = _recipients[i];

        address _owner = owner();
        require(_who != _owner || isDex[_who] == false, "You can't block this address!");


            isBlocked[_who] = true;
        }
    }

     // Un-Block multiple accounts
    function unblockMultiple(address[] memory _recipients) external onlyOwner {
          // Fetch variables
        uint256 _listSize = _recipients.length;
       
        for (uint i = 0; i < _listSize; i++) {
            address _who = _recipients[i];
            isBlocked[_who] = false;
        }
    }

    // Change APR for future pools
    function changeAPR(uint256 _apr30, uint256 _apr180, uint256 _apr365) external onlyOwner {
        apr30Days = _apr30;
        apr180Days = _apr180;
        apr365Days = _apr365;
    }

    function setStakingSupply(uint256 _newStakingSupply) external onlyOwner {
        stakingSupply = _newStakingSupply;
    }

    // Manage tokens that are sent by mistake -------------------------------------

    // What we do if somebody send blockchain's native tokens to the smart contract
    receive() external payable {
        // @Note
        // Calling a revert statement implies an exception is thrown, 
        // the unused gas is returned and the state reverts to its original state.
            revert("You are not allowed to do that!");
        }

    // Withdraw wrong tokens
    function withdrawWrongTokens(address _whatToken, uint256 _amount) external onlyOwner {

        IERC20 _tokenToWitdhraw = IERC20(_whatToken);

        // Transfer the tokens to the owner of the smart contract
        _tokenToWitdhraw.transfer(owner(), _amount);
    }

    // Getters -------------------------------------

    function getAvailableBalanceForTransfer(address _who) public view returns (uint256) {
        // Fetch the balance of the user
        uint256 _userBalance = IERC20(address(this)).balanceOf(_who);

        // Return the difference
        return _userBalance.sub(stakedTokensByUser[msg.sender]);
    }

    function fetchDepositInfo(address _who, uint256 _index) public view returns (uint256, uint256, uint256, uint256) {
        // Create the instance of the deposit
        createDeposit storage _userDeposit = userDeposit[_who][_index];

        return (_userDeposit.stakedAmount, _userDeposit.periodOfTime, _userDeposit.startDate, _userDeposit.endDate);
    }

    function computeFinalRewards(address _who, uint256 _index) public view returns (uint256) {
         (uint256 _stakedAmount, uint256 _periodOfTime, , )  = fetchDepositInfo(_who, _index);

         uint256 _toBeSent = 0;

         if(_periodOfTime == 30) {
            _toBeSent = _stakedAmount.mul(apr30Days).div(uint256(100).mul(12));
         } else if(_periodOfTime == 180) {
            _toBeSent = _stakedAmount.mul(apr180Days).div(uint256(100).mul(2));
         } else if(_periodOfTime == 365) {
             _toBeSent = _stakedAmount.mul(apr365Days).div(100);
         }

         return _toBeSent;
    }

    function computePendingRewards(address _who, uint256 _index) public view returns (uint256) {
        ( , uint256 _period, uint256 _startDate, uint256 _endDate)  = fetchDepositInfo(_who, _index);

        uint256 _delta = 0;
        uint256 _pendingRewards = 0;
        uint256 _rewardsPerMinute = 0;
        uint256 _finalRewards = computeFinalRewards(_who, _index);

        // Time now - start date
        uint256 _timeNow = block.timestamp;

        if(_timeNow < _endDate) {
            _delta = _timeNow.sub(_startDate);

            if(_period == 30) {
                _rewardsPerMinute = _finalRewards.div(uint256(30).mul(24).mul(60));
                _pendingRewards = _delta.div(60).mul(_rewardsPerMinute);
                return _pendingRewards;
            } else if(_period == 180) {
                _rewardsPerMinute = _finalRewards.div(uint256(180).mul(24).mul(60));
                _pendingRewards = _delta.div(60).mul(_rewardsPerMinute);
                return _pendingRewards;
            } else if(_period == 365) {
                _rewardsPerMinute = _finalRewards.div(uint256(365).mul(24).mul(60));
                 _pendingRewards = _delta.div(60).mul(_rewardsPerMinute);
                return _pendingRewards;
            }
        } else {
            return _finalRewards;
        }
        return _pendingRewards;
    }

    function getGivenRewards() public view returns (uint256) {
        return givenRewards;
    }

    function getAmountLeftForStaking() public view returns (uint256) {
        return stakingSupply.sub(givenRewards);
    }

    function getStatus(address _who) public view returns (bool) {
        return isBlocked[_who];
    }

    function getAPRs() public view returns (uint256, uint256, uint256) {
        return (apr30Days, apr180Days, apr365Days);
    }

    function getTotalStakedByUser(address _who) public view returns (uint256) {
        return stakedTokensByUser[_who];
    }
}

// Smart Contract built by @polthedev at DRIVENlabs Inc
// www.drivenecosystem.com