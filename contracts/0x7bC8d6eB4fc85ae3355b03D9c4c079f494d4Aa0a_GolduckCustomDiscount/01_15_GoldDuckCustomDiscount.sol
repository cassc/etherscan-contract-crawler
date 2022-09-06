// SPDX-License-Identifier: MITs

pragma solidity 0.8.15;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract GolduckCustomDiscount is  Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public saleToken;
    IUniswapV2Router02 public uniswapV2Router; 

    enum saleType {BASEPRICE, MARKETPRICE} // 0 - BASEPRICE, 1 - MARKETPRICE

    saleType public currentSale;

    bool public isReferral;
    bool public isReferralTokenEnable;
    
    uint256 public soldOutTokens;
    uint256 public currentDiscount;
    uint256 public minimumDeposit;
    uint256 public maximumDeposit;
    uint256 public vestingDuration;
    uint256 public currentBasePrice;
    uint256 public rewardPoolShare;
    uint256 public treasuryShare;
    uint256 public buyBackShare;
    uint256 public referralShare;
    uint256 public currentLockTicket;
    uint256 private constant precision = 1e18;

    address payable public rewardPool;
    address payable public treasuryWallet;
    address public zeroAddress;
    
    struct userLockStore {
        address user;
        saleType sale;
        uint256 lockedAmount;
        uint256 lockedTime;
        uint256 unLockedTime;
        uint256 claimTime;
    }  

    struct referralStore {
        uint256 bnbEarned;
        uint256 tokenEarned;
        uint256 totalReferrals;
    }

    mapping (uint256 => userLockStore) public userLockInfo;
    mapping (address => EnumerableSet.UintSet) private userLockTicketInfo;
    mapping (address => referralStore) public referralCommission;

    event buyEvent(
        address indexed user,
        uint256 indexed ticket,
        string saleType,
        uint256 amountOut,
        uint256 lockedAmount
    );

    event claimEvent(
        address indexed user,
        uint256 indexed ticket,
        uint256 amount,
        uint256 time
    );

    function initialize(        
        address _token,
        address _rewardPool,
        address _tresuryWallet) initializer public {
        __Pausable_init();
        __Ownable_init();

        saleToken = IERC20(_token); 
        rewardPool = payable(_rewardPool);
        treasuryWallet = payable(_tresuryWallet);
        currentDiscount = 10;
        minimumDeposit = 0.01e18;
        maximumDeposit = 10e18;
        rewardPoolShare = 50;
        treasuryShare = 25;
        buyBackShare = 25;
        currentBasePrice = 5e18;
        vestingDuration = 15770000;

        currentSale = saleType.MARKETPRICE;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    }
    
    receive() external payable {}

    /**
     * @dev Triggers stopped state.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - The contract must not be paused.
    */
    function pause() public onlyOwner{
      _pause();
    }
    
    /**
     * @dev Triggers normal state.
     * 
     * Can only be called by the current owner.
     * 
     * Requirements:
     *
     * - The contract must not be unpaused.
     */
    function unpause() public onlyOwner{
      _unpause();
    }

    function recoverLeftOverBNB(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    /**
     * @dev This function is help to the recover the stucked funds.
     *
     * Can only be called by the platform owner. 
     * 
     * Requirements:
     *
     * - `token` token contract address.
     * - `amount` amount of tokens
     * 
     */      

    function recoverLeftOverToken(address token,uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(),amount);
    }

    function setReferralBonus(bool status) external onlyOwner {
        isReferral = status;
    }

    function setBasePrice(uint256 newPrice) external onlyOwner {
        currentBasePrice = newPrice;
    }

    function setVestingDuration(uint256 newDuration) external onlyOwner {
        vestingDuration = newDuration;
    }

    function setDiscount(uint256 newDiscount) external onlyOwner {
        currentDiscount = newDiscount;
    }

    function setSaleToken(address newToken) external onlyOwner {
        saleToken = IERC20(newToken);
    }

    function setSaleType(uint8 newType) external onlyOwner {
        require(newType <= uint8(type(saleType).max), "GoldDuckCustomDiscount: Invalid reward type");
        currentSale = saleType(newType);

        if(currentSale == saleType.BASEPRICE) {
            rewardPoolShare = 0;
            referralShare = 0;
            buyBackShare = 0;
        }
    }

    function setMinmumAndMaximumDeposit(uint256 _minimumDeposit,uint256 _maximumDeposit) external onlyOwner {
        minimumDeposit = _minimumDeposit;
        maximumDeposit = _maximumDeposit;
    }

    function setReferralTokenEnable(bool status) external onlyOwner {
        isReferralTokenEnable = status;
    }

    function setRewardShare(
        uint256 _rewardPoolShare,
        uint256 _treasuryShare,
        uint256 _buyBackShare,
        uint256 _referralShare
    ) external onlyOwner {
        require(_rewardPoolShare.add(_treasuryShare).add(_buyBackShare).add(_referralShare) <= 100, "GoldDuckCustomDiscount: Invalid Share");

        rewardPoolShare = _rewardPoolShare;
        treasuryShare = _treasuryShare;
        buyBackShare = _buyBackShare;
        referralShare = _referralShare;
    }

    function setRewardPool(address payable newRewardPool) external onlyOwner {
        require(newRewardPool != address(0), "GoldDuckCustomDiscount: New Address can't be zero");
        rewardPool = newRewardPool;
    }

    function setTreasuryWallet(address payable newTresuryWallet) external onlyOwner {
        require(newTresuryWallet != address(0), "GoldDuckCustomDiscount: New Address can't be zero");
        treasuryWallet = newTresuryWallet;
    }

    /**
     * @dev Returns the amount of tokens owned by `pool`.
     */  
    function bnbBalance() public view returns (uint256) {
        return (address(this).balance);        
    }

    /**
     * @dev Returns the amount of tokens owned by `pool`.
     */  
    function offerringTokenBalance() public view returns (uint256) {
        return saleToken.balanceOf(address(this));
    }

    function buy(address referrer) external payable nonReentrant whenNotPaused returns (bool) {
        return _buy(_msgSender(),referrer,msg.value);
    }

    /**
     * @dev This function is help to the buyback the all funds.
     *
     * Can only be called by the project owner and platform owner. 
     * 
     * 
     * - E.g. After the discount sale admin can be able to buyback the bnb to token.
     * 
     */  
    function buyBackDistribute(uint256 value) internal{
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(saleToken);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: value}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function multiClaim() external whenNotPaused nonReentrant {
        address user = _msgSender();
        uint8 totalCount = uint8(getUserLockTicketLength(user));

        for(uint8 i=totalCount;i>0; i--) {
            uint256 ticketId = getUserLockTicketAt(user,i);

            if(userLockInfo[ticketId].unLockedTime <= block.timestamp) {
                saleToken.safeTransfer(user,userLockInfo[ticketId].lockedAmount);
                userLockInfo[ticketId].lockedAmount = 0;
                userLockInfo[ticketId].claimTime = block.timestamp;
                userLockTicketInfo[user].remove(currentLockTicket);

                emit claimEvent(user,ticketId,userLockInfo[ticketId].lockedAmount,block.timestamp);
            }
        }
    }

    /**
     * @dev This function is help to the redeem the allocated tokens.
     * 
     * - E.g. after the sale end,user can able to claim their tokens.
     */ 
    function claim(uint256 lockTicket) external nonReentrant whenNotPaused {
        userLockStore storage store = userLockInfo[lockTicket];
        require(getUserLockTicketContains(_msgSender(),lockTicket), "GoldDuckCustomDiscount: Not able to access this ticketid");
        require(store.unLockedTime <= block.timestamp, "GoldDuckCustomDiscount: Unable to access this time");
        
        saleToken.safeTransfer(msg.sender,store.lockedAmount);
        store.lockedAmount = 0;
        store.claimTime = block.timestamp;
        userLockTicketInfo[_msgSender()].remove(currentLockTicket);
        emit claimEvent(_msgSender(),lockTicket,store.lockedAmount,block.timestamp);
    }

    function _buy(address user,address referrer,uint256 amount) internal returns (bool){
        require(minimumDeposit <= amount && maximumDeposit >= amount, "GoldDuckCustomDiscount: Deposit amount is invalid");
        require(user != referrer, "GoldDuckCustomDiscount: Referrer Address is invalid");

        uint256 amountOut;
        uint256 discount;
        if(currentSale == saleType.BASEPRICE) {
           (amountOut,discount) = _getAmountOutForBasePrice(amount);
        } else if(currentSale == saleType.MARKETPRICE) {
            (amountOut,discount) = _getAmountOutForMarketPrice(amount);
        }

        distribute(referrer,amount);

        if(discount > 0) {
            currentLockTicket++;
            userLockInfo[currentLockTicket] = userLockStore({
                user: user,
                sale: currentSale,
                lockedAmount: discount,
                lockedTime: block.timestamp,
                unLockedTime: block.timestamp + vestingDuration,
                claimTime: 0
            });
            userLockTicketInfo[user].add(currentLockTicket);

            emit buyEvent(
                user,
                currentLockTicket,
                currentSale == saleType.BASEPRICE ? "BASEPRICE" : "MARKETPRICE",
                amountOut,
                discount
            );
        }

        if(isReferralTokenEnable && isReferral && referrer != address(0)) {
            uint256 refTokenPayout = amountOut.mul(referralShare).div(1e2);
            saleToken.safeTransfer(referrer,refTokenPayout);
            referralCommission[referrer].tokenEarned = referralCommission[referrer].tokenEarned.add(refTokenPayout);
        }

        saleToken.safeTransfer(user,amountOut);
        soldOutTokens = soldOutTokens.add(amountOut.add(discount));
        return true;
    }

    function distribute(
        address referrer,
        uint256 amount
    ) internal {
        if(isReferral && referrer != address(0)) {
            referralCommission[referrer].totalReferrals++;
            uint256 referrerPayout = amount.mul(referralShare).div(1e2);
            payable(referrer).sendValue(referrerPayout);
            referralCommission[referrer].bnbEarned = referralCommission[referrer].bnbEarned.add(referrerPayout);
        }

        if(rewardPoolShare > 0) rewardPool.sendValue(amount.mul(rewardPoolShare).div(1e2));
        
        if(treasuryShare > 0) treasuryWallet.sendValue(amount.mul(treasuryShare).div(1e2));

        if(buyBackShare > 0) buyBackDistribute(amount.mul(buyBackShare).div(1e2));     
    }
    
    function _getAmountOutForBasePrice(
        uint256 amount
    ) internal view returns(        
        uint256 amountOut,
        uint256 discount){
        amountOut = amount.mul(currentBasePrice).div(precision);
        return (amountOut,amountOut.mul(currentDiscount).div(100));        
    }

    function _getAmountOutForMarketPrice(
        uint256 amount
    ) internal view returns(
        uint256 amountOut,
        uint256 discount){
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(saleToken);

        uint[] memory getAmountOut = uniswapV2Router.getAmountsOut(amount,path);
        return (getAmountOut[1],getAmountOut[1].mul(currentDiscount).div(100));   
    }

    function getAmountOutForBasePrice(
        uint256 amount
    ) external view returns(        
        uint256 amountOut,
        uint256 discount) {
        return (
            _getAmountOutForBasePrice(amount)
        );
    }

    function getAmountOutForMarketPrice(
        uint256 amount
    ) external view returns(        
        uint256 amountOut,
        uint256 discount) {
        return (
            _getAmountOutForMarketPrice(amount)
        );
    }

    function getUserLockTicketLength(address account) public view returns (uint256) {
         return userLockTicketInfo[account].length();
    }
    
    function getUserLockTicketAt(address account,uint256 index) public view returns (uint256) {
        return userLockTicketInfo[account].at(index);
    }

    function getUserAllLockTickets(address account) public view returns (uint256[] memory) {
        return userLockTicketInfo[account].values();
    }
    
    function getUserLockTicketContains(address account,uint256 ticket) public view returns (bool) {
        return userLockTicketInfo[account].contains(ticket);
    }

}