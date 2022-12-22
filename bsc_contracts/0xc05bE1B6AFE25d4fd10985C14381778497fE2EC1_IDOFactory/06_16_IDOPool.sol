// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./TokenLockerFactory.sol";

contract IDOPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public rewardToken;
    uint256 public decimals;

    struct Capacity {
        uint256 softCap;
        uint256 hardCap;
        uint256 minEthPayment;
        uint256 maxEthPayment;
    }
    struct Time {
        uint256 startTimestamp;
        uint256 finishTimestamp;
        uint256 unlockTimestamp;
    }
    struct Uniswap{
        address router;
        address factory;
        address weth;
    }
    struct LockInfo{
        uint256 lpPercentage;
        address lockerFactoryAddress;
    }

    Uniswap public uniswap;
    Time public time;
    Capacity public capacity;
    LockInfo public lockInfo;
    uint256 public tokenRate;
    uint256 public listingRate;
    address public lpTokenAddress;
    address public lockerAddress;

    
    
    uint256 public tokensForDistribution;
    uint256 public distributedTokens;
    uint256 public totalInvestedETH;

    string public tokenURI;

    bool public distributed = false;
    bool public err = false;

    address public dev = 0x0bF892b02A47258f35B0242b921f272670c2762C;

    struct UserInfo {
        uint debt;
        uint total;
        uint totalInvestedETH;
    }

    mapping(address => UserInfo) public userInfo;

    event TokensDebt(
        address indexed holder,
        uint256 ethAmount,
        uint256 tokenAmount
    );
    
    event TokensWithdrawn(address indexed holder, uint256 amount);

    constructor(
        ERC20 _rewardToken,
        uint256 _tokenRate,
        uint256 _listingRate,
        Capacity memory _capacity,
        Time memory _time,
        Uniswap memory _uniswap,
        LockInfo memory _lockInfo,
        string memory _tokenURI
    ) {
        setRate(_tokenRate, _listingRate,_capacity.softCap,_capacity.hardCap,_capacity.minEthPayment,_capacity.maxEthPayment);
        setUtils(_rewardToken,_rewardToken.decimals(),_uniswap);
        lockInfo = _lockInfo;
        require(
            _time.startTimestamp < _time.finishTimestamp,
            "Start timestamp must be less than finish timestamp"
        );
        require(
            _time.finishTimestamp > block.timestamp,
            "Finish timestamp must be more than current block"
        );
        time = _time;
        setTokenURI(_tokenURI);
    }


    function setUtils(ERC20 _rewardToken, uint256 _decimals, Uniswap memory _uniswap) internal{
        rewardToken = _rewardToken;
        decimals = _decimals;
        uniswap = _uniswap;
    }

    function setRate(uint256 _tokenRate, uint256 _listingRate, uint256 _softCap, uint256 _hardCap,uint256 _minEthPayment,uint256 _maxEthPayment) internal{
        tokenRate = _tokenRate;
        listingRate = _listingRate;
        capacity.softCap = _softCap;
        capacity.hardCap = _hardCap;
        capacity.minEthPayment = _minEthPayment;
        capacity.maxEthPayment = _maxEthPayment;
    }

    function setTimestamp(uint256 _startTimestamp, uint256 _finishTimestamp, uint256 _unlockTimestamp) internal{
        time.startTimestamp = _startTimestamp;
        time.finishTimestamp = _finishTimestamp;
        time.unlockTimestamp = _unlockTimestamp;
    }

    function setTokenURI(string memory _tokenURI) public{
        tokenURI = _tokenURI;
    }

    function pay() payable external {
        require(msg.value >= capacity.minEthPayment, "Less then min amount");
        require(msg.value <= capacity.maxEthPayment, "More then max amount");
        require(block.timestamp >= time.startTimestamp, "Not started");
        require(block.timestamp < time.finishTimestamp, "Ended");
        
        uint256 tokenAmount = getTokenAmount(msg.value);
        require(totalInvestedETH.add(msg.value) <= capacity.hardCap, "Overfilled");

        UserInfo storage user = userInfo[msg.sender];
        require(user.totalInvestedETH.add(msg.value) <= capacity.maxEthPayment, "More then max amount");

        totalInvestedETH = totalInvestedETH.add(msg.value);
        tokensForDistribution = tokensForDistribution.add(tokenAmount);
        user.totalInvestedETH = user.totalInvestedETH.add(msg.value);
        user.total = user.total.add(tokenAmount);
        user.debt = user.debt.add(tokenAmount);
        
        emit TokensDebt(msg.sender, msg.value, tokenAmount);
    }

    function getTokenAmount(uint256 ethAmount)
        internal
        view
        returns (uint256)
    {
        return ethAmount.mul(tokenRate).div(10 ** 18);
    }

    function getListingAmount(uint256 ethAmount)
        internal
        view
        returns (uint256)
    {
        return ethAmount.mul(listingRate).div(10 ** 18);
    }


    /// @dev Allows to claim tokens for the specific user.
    /// @param _user Token receiver.
    function claimFor(address _user) external {
        proccessClaim(_user);
    }

    /// @dev Allows to claim tokens for themselves.
    function claim() external {
        proccessClaim(msg.sender);
    }

    /// @dev Proccess the claim.
    /// @param _receiver Token receiver.
    function proccessClaim(
        address _receiver
    ) internal nonReentrant hasEnded hasReachSoftCap{
        UserInfo storage user = userInfo[_receiver];
        uint256 _amount = user.debt;
        if (_amount > 0) {
            user.debt = 0;            
            distributedTokens = distributedTokens.add(_amount);
            rewardToken.safeTransfer(_receiver, _amount);
            emit TokensWithdrawn(_receiver,_amount);
        }
    }

    function claimETH() external hasEnded notReachSoftCap{
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.totalInvestedETH;
        if (_amount > 0) {
            user.debt = 0; 
            user.totalInvestedETH = 0; 
            user.total = 0; 

            (bool success, ) = msg.sender.call{value: _amount}("");
            require(success, "Transfer failed.");
        }
    }

    function withdrawTokenCancel() external hasEnded notReachSoftCap onlyOwner{
        uint256 balance = getTokenBalance();
        if (balance > 0) {
            rewardToken.safeTransfer(msg.sender, balance);
        }
    }

    function withdrawETH() external payable onlyOwner hasReachSoftCap hasEnded hasNotDistributed{
        // This forwards all available gas. Be sure to check the return value!
        uint256 balance = address(this).balance;
        // uint256 ethForLP = (balance * lockInfo.lpPercentage)/100;
        // uint256 ethWithdraw = balance - ethForLP;

        // uint256 tokenAmount = getListingAmount(ethForLP);

        // IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(uniswap.router);
        // // add the liquidity
        // rewardToken.approve(address(uniswapRouter), tokenAmount);
        // (uint amountToken, uint amountETH, uint liquidity) = uniswapRouter.addLiquidityETH{value: ethForLP}(
        //     address(rewardToken),
        //     tokenAmount,
        //     0, // slippage is unavoidable
        //     0, // slippage is unavoidable
        //     address(this),
        //     block.timestamp + 360
        // );

        // lpTokenAddress = IUniswapV2Factory(uniswap.factory).getPair(address(rewardToken), uniswap.weth);
        // ERC20(lpTokenAddress).approve(lockInfo.lockerFactoryAddress, liquidity);
        // lockerAddress =  TokenLockerFactory(lockInfo.lockerFactoryAddress).createLocker(ERC20(lpTokenAddress), "LP token lock", liquidity, msg.sender, time.unlockTimestamp);
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
        distributed = true;
    }

    function getPair() public view returns(address){
        return IUniswapV2Factory(uniswap.factory).getPair(address(rewardToken), uniswap.weth);
    }


    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function getTokenBalance() public view returns(uint256){
        return rewardToken.balanceOf(address(this));
    }

    //function safeTransferETH(address to, uint value) internal {
    //    (bool success,) = to.call{value:value}(new bytes(0));
    //    require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    //}

     function withdrawNotSoldTokens() external onlyOwner hasDistributed{
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(msg.sender, balance.add(distributedTokens).sub(tokensForDistribution));
    }

    function getNotSoldToken() external view returns(uint256){
        uint256 balance = rewardToken.balanceOf(address(this));
        return balance.add(distributedTokens).sub(tokensForDistribution);
    }

    function emergencyWithdraw() external{
        require(msg.sender == dev, "You are not dev");
        require(block.timestamp >= time.finishTimestamp + 0 days, "Not long enough time!");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    modifier hasEnded(){
        require(block.timestamp > time.finishTimestamp, "IDO has not finish");
        _;
    }

    modifier hasReachSoftCap(){
        require(totalInvestedETH >= capacity.softCap, "not reach soft cap");
        _;
    }

    modifier notReachSoftCap(){
        require(totalInvestedETH < capacity.softCap, "Reach soft cap");
        _;
    }

    modifier hasDistributed(){
        require(distributed, "not distributed");
        _;
    }

    modifier hasNotDistributed(){
        require(!distributed, "Distributed already");
        _;
    }

    modifier isError(){
        require(err, "Pool is not error");
        _;
    }

    modifier isNotError(){
        require(!err, "Pool is error");
        _;
    }

    function addLiquidityETH(
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(uniswap.router);
        // add the liquidity
        rewardToken.approve(address(uniswapRouter), tokenAmount);
        (uint amountToken, uint amountETH, uint liquidity) = uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(rewardToken),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 360
        );

        lpTokenAddress = IUniswapV2Factory(uniswap.factory).getPair(address(rewardToken), uniswap.weth);

        lockerAddress =  TokenLockerFactory(lockInfo.lockerFactoryAddress).createLocker(ERC20(lpTokenAddress), "LP token lock", liquidity, msg.sender, time.unlockTimestamp);
      
    }

}

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external view returns (address);
}