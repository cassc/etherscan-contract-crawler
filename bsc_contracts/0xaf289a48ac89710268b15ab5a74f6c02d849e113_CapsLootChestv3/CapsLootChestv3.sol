/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-18
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;


abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }


    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }


    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);


    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);


    function transfer(address to, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _transferOwnership(_msgSender());
    }


    modifier onlyOwner() {
        _checkOwner();
        _;
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract CapsLootChestv3 is ReentrancyGuard, Ownable {
    IERC20 public SURGE;
    IERC20 public CAPTAIN_SURGE;
    IERC20 public customToken;

    uint256 public normalWithdrawalTime;
    uint256 public silverWithdrawalTime;
    uint256 public goldWithdrawalTime;

    uint256 public dailyDripRatePercentage;
    uint256 public lastDripResetTime;
    uint256 public claimableTokens;

    uint256 public totalDrippedSinceLaunch;
    uint256 public totalDrippedLast24Hours;

    mapping(address => uint256) public lastClaimed;
    mapping(address => bool) public excludedAddresses;
    mapping(address => UserTier) public userTiers;

    uint256 public bronzeThreshold;
    uint256 public silverThreshold;
    uint256 public goldThreshold;

    enum UserTier { BRONZE, SILVER, GOLD }

    event Claimed(address indexed user, uint256 amount);
    event ThresholdChanged(uint256 bronze, uint256 silver, uint256 gold);
    event TokensAdded(uint256 amount); 
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    event TokensClaimable(uint256 amount);
    event DripTimerReset(uint256 resetTime);

    constructor() {
        SURGE = IERC20(0x9f19c8e321bD14345b797d43E01f0eED030F5Bff);
        CAPTAIN_SURGE = IERC20(0x2379aA12E3DE1FDDBC47Bb9E8013122F9CBa357c);
        


        normalWithdrawalTime = 72 hours;
        silverWithdrawalTime = 48 hours;
        goldWithdrawalTime = 24 hours;
        dailyDripRatePercentage = 10; 


        bronzeThreshold = 10000 * 10**9;
        silverThreshold = 100000 * 10**9;
        goldThreshold = 250000 * 10**9;

        lastDripResetTime = block.timestamp;
        resetDrip();
    }

    function setCustomToken(address _token) external onlyOwner {
    require(_token != address(0), "Invalid token address");
    customToken = IERC20(_token);
    }

    function getAvailableTokens() external view returns (uint256) {
        return claimableTokens;
    }

    function getTotalDrippedSinceLaunch() external view returns (uint256) {
        return totalDrippedSinceLaunch;
    }

    function getTotalDrippedLast24Hours() external view returns (uint256) {
        return totalDrippedLast24Hours;
    }

    function getCaptainSurgeBalance() external view returns (uint256) {
        return CAPTAIN_SURGE.balanceOf(address(this));
    }

        // Function to return the SURGE balance instead of CAPTAIN_SURGE balance
    function getSurgeBalance() external view returns (uint256) {
        return SURGE.balanceOf(address(this));
    }

    // Function to return the custom token balance
    function getCustomTokenBalance() external view returns (uint256) {
        return customToken.balanceOf(address(this));
    }

    function changeTierThresholds(uint256 _bronze, uint256 _silver, uint256 _gold) external onlyOwner {
        bronzeThreshold = _bronze;
        silverThreshold = _silver;
        goldThreshold = _gold;
        emit ThresholdChanged(_bronze, _silver, _gold);
    }

    function claimWaitTime(address _user) external view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 lastClaimTime = lastClaimed[_user];

        uint256 withdrawalTime;
        if (userTiers[_user] == UserTier.BRONZE) {
            withdrawalTime = normalWithdrawalTime;
        } else if (userTiers[_user] == UserTier.SILVER) {
            withdrawalTime = silverWithdrawalTime;
        } else {
            withdrawalTime = goldWithdrawalTime;
        }

        if (currentTime - lastClaimTime >= withdrawalTime) {
            return 0;
        } else {
            return withdrawalTime - (currentTime - lastClaimTime);
        }
    }

    function resetDrip() private {
        uint256 contractBalance = SURGE.balanceOf(address(this));
        claimableTokens = (contractBalance * dailyDripRatePercentage) / 100;
        lastDripResetTime = block.timestamp;
    }

    function setWithdrawalTimes(uint256 _normal, uint256 _silver, uint256 _gold) external onlyOwner {
        normalWithdrawalTime = _normal;
        silverWithdrawalTime = _silver;
        goldWithdrawalTime = _gold;
    }

    function setDailyDripRatePercentage(uint256 _dailyDripRatePercentage) external onlyOwner {
        dailyDripRatePercentage = _dailyDripRatePercentage;
    }

    function setExcluded(address _user, bool _excluded) external onlyOwner {
        excludedAddresses[_user] = _excluded;
    }

    function setUserTier(address _user) private {
        uint256 balance = CAPTAIN_SURGE.balanceOf(_user);
        if (balance >= goldThreshold) {
            userTiers[_user] = UserTier.GOLD;
        } else if (balance >= silverThreshold) {
            userTiers[_user] = UserTier.SILVER;
        } else if (balance >= bronzeThreshold) {
            userTiers[_user] = UserTier.BRONZE;
        } else {
            revert("User balance is below the minimum threshold for any tier");
        }
    }

    function updateUserTier(address _user) external onlyOwner {
        setUserTier(_user);
    }

    function checkUserTier(address _user) public view returns (bool) {
        uint256 balance = CAPTAIN_SURGE.balanceOf(_user);
        return balance >= bronzeThreshold || balance >= silverThreshold || balance >= goldThreshold;
    }    

    function liveView() public view returns (uint256) {
        if (block.timestamp - lastDripResetTime >= 24 hours) {
            uint256 contractBalance = SURGE.balanceOf(address(this));
            return (contractBalance * dailyDripRatePercentage) / 100;
        } else {
            uint256 elapsedTime = block.timestamp - lastDripResetTime;
            uint256 remainingTokens = (SURGE.balanceOf(address(this)) * dailyDripRatePercentage * elapsedTime) / (100 * 24 hours);
            return remainingTokens;
        }
    }

    function distributeDrip() private {
        if (block.timestamp - lastDripResetTime >= 24 hours) {
            resetDrip();
            totalDrippedLast24Hours = claimableTokens;
        } else {
            uint256 elapsedTime = block.timestamp - lastDripResetTime;
            uint256 remainingTokens = (SURGE.balanceOf(address(this)) * dailyDripRatePercentage * elapsedTime) / (100 * 24 hours);
            claimableTokens = remainingTokens;
        }
    }

    function claim(address _user) external nonReentrant {
    require(!excludedAddresses[_user], "Excluded address");

    setUserTier(_user);

    uint256 currentTime = block.timestamp;
    uint256 lastClaimTime = lastClaimed[_user];

    uint256 withdrawalTime;
    if (userTiers[_user] == UserTier.BRONZE) {
        withdrawalTime = normalWithdrawalTime;
    } else if (userTiers[_user] == UserTier.SILVER) {
        withdrawalTime = silverWithdrawalTime;
    } else {
        withdrawalTime = goldWithdrawalTime;
    }

    // Bypass the withdrawal time restriction for the contract owner
    if (_user != owner()) {
        require(currentTime - lastClaimTime >= withdrawalTime, "Not eligible to claim yet");
    }

    distributeDrip();

    uint256 tokensToClaim = claimableTokens;
    require(tokensToClaim > 0, "No tokens available to claim");

    if (tokensToClaim >= 500 * 10**9) {
        emit TokensClaimable(tokensToClaim);
    }

    lastClaimed[_user] = currentTime;
    SURGE.transfer(_user, tokensToClaim);
    totalDrippedSinceLaunch += tokensToClaim;

    // Reset claimableTokens to 0
    claimableTokens = 0;

    // Emit events
    emit Claimed(_user, tokensToClaim);

    if (SURGE.balanceOf(address(this)) >= 1000 * 10**9) {
        emit TokensAdded(SURGE.balanceOf(address(this)));
    }
    }

    function depositSurge(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        SURGE.transferFrom(msg.sender, address(this), amount);
        emit TokensAdded(amount);
    }

        // Function to start the drip manually (only callable by the contract owner)
    function startDrip() external onlyOwner {
        distributeDrip();
    }

    // Function to reset the drip timer manually (only callable by the contract owner)
    function resetDripTimer() external onlyOwner {
        lastDripResetTime = block.timestamp;
        emit DripTimerReset(lastDripResetTime);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 surgeBalance = SURGE.balanceOf(address(this));
        SURGE.transfer(msg.sender, surgeBalance);
        emit EmergencyWithdrawal(msg.sender, surgeBalance);
    
        if (address(customToken) != address(0)) {
            uint256 customTokenBalance = customToken.balanceOf(address(this));
            customToken.transfer(msg.sender, customTokenBalance);}
    }
}