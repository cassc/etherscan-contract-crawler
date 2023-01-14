// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IIERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


contract ZippaStaking is Initializable, OwnableUpgradeable , ReentrancyGuardUpgradeable {
    //user stakes zippa
    // user claims zipp and is taxed
    // user can only claim after 1 week of staking

    using SafeMathUpgradeable for uint256;
    struct StakedData {
        uint256 amountStaked;
        uint256 lastTimeStaked;
        uint256 accuredBeforeZipRestake;
        uint256 totalReferralEarningFromStake;
    }
    address public StakeToken;
    address public RewardToken;
    address public DeadAddress;
    uint256 public MinStakeAmount;
    uint256 public EarningPercentagePerSeconds;
    uint256 public amountEarnedForReferral;
    uint256 public minimumClaimSeconds;

    mapping(address => StakedData) public stakings;
    mapping(address => address) public referrals;
    mapping(address => address[]) public downlines;
    event StakeComplete(address staker, uint256 amount, uint256 time);
    event ClaimComplete(address staker, uint256 claimAmount, uint256 time);
    uint256 public claimTax;
    mapping(address => uint256) public claimed;

    function initialize() external virtual initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        DeadAddress = 0x000000000000000000000000000000000000dEaD;
        MinStakeAmount = 100e18;
        EarningPercentagePerSeconds = 1;
        amountEarnedForReferral = 10000000000000000000;
        minimumClaimSeconds = 86400;
    }

    // look into referral in staking
    // amount is exprected to be in wei
    function stake(uint256 _amount, address _staker) external nonReentrant {
        require(_amount > 0, "Amount must be above zero");
        require(MinStakeAmount <= _amount, "Amount must be above minimum");
        require(_staker != address(0), "Invalid stakers address");
        require(
            IIERC20(StakeToken).balanceOf(_staker) >= _amount,
            "Insufficient stake amount"
        );
        require(
            IIERC20(StakeToken).allowance(_staker,address(this)) >= _amount,
            "Insufficient allowance to spend  the stake amount"
        );
        IIERC20(StakeToken).transferFrom(_staker, address(this), _amount);
        uint amountStaked = _amount;
        // check for referrer and give him his earning
        if (
            referrals[_staker] != address(0) &&
            stakings[_staker].amountStaked == 0
        ) {
            IIERC20(StakeToken).transfer(
                referrals[_staker],
                amountEarnedForReferral
            ); // burn it
            amountStaked = amountStaked.sub(amountEarnedForReferral);
            stakings[referrals[_staker]].totalReferralEarningFromStake = stakings[referrals[_staker]].totalReferralEarningFromStake.add(amountEarnedForReferral);
        }
        if (stakings[_staker].amountStaked > 0) {
            uint256 totalSeconds = block.timestamp.sub(
                stakings[_staker].lastTimeStaked
            );
            uint256 scale = 1e18;
            uint256 earningPerSec = (stakings[_staker].amountStaked.mul(EarningPercentagePerSeconds)).div(100);
            uint256 totalEarning = (earningPerSec.mul(totalSeconds)).div(scale);
            stakings[_staker].accuredBeforeZipRestake = stakings[_staker]
                .accuredBeforeZipRestake
                .add(totalEarning);
        }
        stakings[_staker].amountStaked = stakings[_staker].amountStaked.add(_amount);
        stakings[_staker].lastTimeStaked = block.timestamp;
        IIERC20(StakeToken).transfer(DeadAddress, amountStaked); // burn it
        emit StakeComplete(_staker, _amount, block.timestamp);
    }

    function addReferrer(address ref) external nonReentrant {
        require(
            referrals[_msgSender()] == address(0),
            "You already have a referrer"
        );
        require(ref != address(0), "Invalid referral  address");
        referrals[_msgSender()] = ref;
        downlines[ref].push(_msgSender());
    }

    function claim() external nonReentrant {
        StakedData storage userData = stakings[_msgSender()];
        require(block.timestamp.sub(userData.lastTimeStaked) >= minimumClaimSeconds,
            "You can not claim after staking for less that 1 day"
        );
        require(userData.amountStaked > 0, "Insufficient amount to claim");
        uint256 scale = 1e18;
        uint256 totalSeconds = block.timestamp.sub(userData.lastTimeStaked);
        uint256 earningPerSec = (userData.amountStaked.mul(EarningPercentagePerSeconds)).div(100);
        uint256 totalClaim = ((earningPerSec.mul(totalSeconds)).add(userData.accuredBeforeZipRestake)).div(scale);
        userData.accuredBeforeZipRestake = 0;
        userData.lastTimeStaked = block.timestamp;
        uint256 tax = (totalClaim.mul(claimTax)).div(100);
        totalClaim = totalClaim.sub(tax);
        IIERC20(RewardToken).mint(_msgSender(), totalClaim);
        claimed[_msgSender()] = claimed[_msgSender()].add(totalClaim);
        emit ClaimComplete(_msgSender(), totalClaim, block.timestamp);
    }

    function getAvailableClaims(address user) external view returns (uint256) {
        StakedData storage userData = stakings[user];
        if(block.timestamp.sub(userData.lastTimeStaked) < minimumClaimSeconds){
            return 0;
        }
        if(userData.amountStaked <= 0){
            return 0;
        }
        uint256 totalSeconds = block.timestamp.sub(userData.lastTimeStaked);
        uint256 scale = 1e18;
        uint256 earningPerSec = (userData.amountStaked.mul(EarningPercentagePerSeconds)).div(100);
        uint256 totalClaim = ((earningPerSec.mul(totalSeconds)).add(userData.accuredBeforeZipRestake)).div(scale);
        uint256 tax = (totalClaim.mul(claimTax)).div(100);
        totalClaim = totalClaim.sub(tax);
        return totalClaim;
    }


    function getDownline(address ref) external view returns( address[] memory) {
        return downlines[ref];
    }


    function setReward(address token) external onlyOwner {
        require(token != address(0) && token != RewardToken, "Invalid address");
        RewardToken = token;
    }

    function setStakeToken(address token) external onlyOwner {
        require(token != address(0) && token != StakeToken, "Invalid address");
        StakeToken = token;
    }

    function setMinimumStakeAmount(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid Amount");
        MinStakeAmount = amount;
    }

    
    function setEarningPercentagePerSeconds(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid Amount");
        EarningPercentagePerSeconds = amount; // this variable is in wei
    }

    function setAmountEarnedForReferral(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid Amount");
        amountEarnedForReferral = amount;
    }

    function setMinimumClaimSeconds(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid Amount");
        minimumClaimSeconds = amount;
    }

    function setDeadAddress(address token) external onlyOwner {
        require(token != address(0) && token != DeadAddress, "Invalid address");
        DeadAddress = token;
    }

    function setClaimTax(uint256 tax) external onlyOwner {
        require(tax > 0 , "Invalid tax");
        claimTax = tax;
    }

    function transferAnyTokenOwnership(address token, address newOwner)
        external
        onlyOwner
    {
        require(
            token != address(0) && newOwner != address(0),
            "Invalid address"
        );
        IIERC20(token).transferOwnership(newOwner);
    }

    function withdrawBNB(address _recipient) external payable onlyOwner {
        payable(_recipient).transfer(payable(address(this)).balance);
    }

    function withdrawIERC20Upgradeable(address _token, address _recipient)
        external
        onlyOwner
    {
        uint _tokenBalance = IERC20Upgradeable(_token).balanceOf(address(this));
        require(
            _tokenBalance >= 1,
            "Sorry you don't have enough of this token."
        );
        IERC20Upgradeable(_token).transfer(_recipient, _tokenBalance);
    }

   



}