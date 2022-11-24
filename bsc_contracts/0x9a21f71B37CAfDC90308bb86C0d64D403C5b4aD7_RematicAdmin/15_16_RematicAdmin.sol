// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./PancakeswapInterface/IPancakeRouter02.sol";
import "./IRematic.sol";
import "./TokenTrackers/IDefaultTracker.sol";

contract RematicAdmin is UUPSUpgradeable, OwnableUpgradeable {

    IPancakeRouter02  public pancakeSwapV2Router;
    address public  pancakeSwapPair;
    address public  REWARD;

    uint256 public liquidityFeeRate;
    uint256 public pensionFeeRate;
    uint256 public legalFeeRate;
    uint256 public teamFeeRate;
    uint256 public holdersSdtFeeRate;

    address public pensionWallet;
    address public legalWallet;
    address public teamWallet;

    address public defaultTokenTracker;

    address public rematicAddress;

    bool public isOnTeamFee;
    bool public isOnLegalFee;
    bool public isOnPensionFee;
    address public pairCreator;

    address public botWallet;

    bool public isLiquidationProcessing;

    event Error(string indexed messageType, string message);
    

    modifier onlyRematicFinance() {
        require(rematicAddress == address(msg.sender), "Message sender needs to be Rematic Contract");
        _;
    }

    modifier onlyTeamWallet() {
        require(teamWallet == address(msg.sender), "Message sender needs to be Team wallet");
        _;
    }

    modifier onlyBotWallet() {
        require(botWallet == address(msg.sender), "Message sender needs to be Team wallet");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _routerAddrss, 
        address _REWARD, 
        address _pensionWallet, 
        address _legalWallet, 
        address _teamWallet,
        address _defaultTokenTracker
    ) public initializer{

        __Ownable_init();

        // init
    	pancakeSwapV2Router = IPancakeRouter02(_routerAddrss);

        REWARD = _REWARD;

        liquidityFeeRate = 800;
        pensionFeeRate = 0; 
        legalFeeRate = 0; 
        teamFeeRate = 3200;
        holdersSdtFeeRate = 7200;

        pensionWallet = _pensionWallet;
        legalWallet = _legalWallet;
        teamWallet = _teamWallet;
        
        defaultTokenTracker = _defaultTokenTracker;

        isOnTeamFee  = true;
        isOnLegalFee  = false;
        isOnPensionFee  = false;
        pairCreator = owner();
    }

    function _authorizeUpgrade(address newImplementaion) internal override onlyOwner {}

    function startLiquidate() external onlyRematicFinance {
        _performLiquidate();
    }

    function _performLiquidate() internal {

        if(_continueLiqudate()){
            return;
        }

        isLiquidationProcessing = true;

        uint256 activeLiquidateAmount = IERC20(rematicAddress).balanceOf(address(this));
        require(activeLiquidateAmount > 0, "No token for liquidation");
        
        uint256 totalFee = liquidityFeeRate + pensionFeeRate + legalFeeRate + teamFeeRate + holdersSdtFeeRate;

        uint256 liquidityRMTX = activeLiquidateAmount * liquidityFeeRate / totalFee;

        //add liquidity
        addLiquidity(rematicAddress, liquidityRMTX);

        uint256 bnbPercetange = pensionFeeRate + legalFeeRate + teamFeeRate;
        uint256 bnbRMTX = bnbPercetange * activeLiquidateAmount / totalFee; 

        uint256 bnbAmount = swapTokensForEth(rematicAddress, bnbRMTX);

        //send some rewardBNB to Pension wallet
        uint256 pAmount = bnbAmount * pensionFeeRate / bnbPercetange;
        _sendBNBToPensionWallet(pAmount);

        //send some rewardBNB to Team wallet
        uint256 tAmount = bnbAmount * teamFeeRate / bnbPercetange;
        _sendBNBToTeamWallet(tAmount);

        uint256 lAmount = bnbAmount - pAmount - tAmount;
        //send some rewardBNB to LegalWallet
        _sendBNBToLegalWallet(lAmount);
        
        //distrubute BUSD on Default Token Tracker (Holders Standard in diagram)
        _distributeRewardDividends(activeLiquidateAmount - liquidityRMTX - bnbRMTX);

        isLiquidationProcessing = false;

    }

    function startManualLiquidate() external onlyBotWallet {
        _performLiquidate();
    }

    function _swapTokensForREWARD(uint256 _amountIn) internal returns( uint256 ){

        address[] memory path = new address[](3);
        require(path.length <= 3, "fail");
        path[0] = rematicAddress;
        path[1] = pancakeSwapV2Router.WETH();
        path[2] = REWARD;

        IERC20(rematicAddress).approve(address(pancakeSwapV2Router), _amountIn);

        uint256 initialBUSD = IERC20(path[2]).balanceOf(address(this));

        // make the swap
        pancakeSwapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            0,
            path,
            address(this),
            block.timestamp + 200
        );

        // after swaping
        uint256 newBUSD = IERC20(path[2]).balanceOf(address(this));

        return newBUSD - initialBUSD;
    }

    function swapTokensForEth(address tokenAddress, uint256 tokenAmount) private returns (uint256){

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        require(path.length <= 2, "fail");
        path[0] = tokenAddress;
        path[1] = pancakeSwapV2Router.WETH();

        uint256 initialBalance = address(this).balance;

        IERC20(tokenAddress).approve(address(pancakeSwapV2Router), tokenAmount);

        // make the swap
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 200
        );

        return address(this).balance - initialBalance;
    }


    function addLiquidity(address tokenAddress, uint256 tokenAmount) private {

        //swapTokensForEth
        uint256 liquidityBNB = swapTokensForEth(tokenAddress, tokenAmount / 2);
        uint256 liquidityToken = tokenAmount - tokenAmount / 2;
        
        // approve token transfer to cover all possible scenarios
        IERC20(tokenAddress).approve(address(pancakeSwapV2Router), liquidityToken);

        // add the liquidity
        pancakeSwapV2Router.addLiquidityETH{value: liquidityBNB}(
            tokenAddress,
            liquidityToken,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            pairCreator,
            block.timestamp + 200
        );
    }

    
    function setLiquidityFeeRate(uint256 _liquidityFeeRate) public onlyOwner {
        require(liquidityFeeRate != _liquidityFeeRate, "already set value.");
        liquidityFeeRate = _liquidityFeeRate;
    }

    function setPensionFeeRate(uint256 _pensionFeeRate) public onlyOwner {
        require(pensionFeeRate != _pensionFeeRate, "already set value.");
        pensionFeeRate = _pensionFeeRate;

    }

    function setLegalFeeRate(uint256 _legalFeeRate) public onlyOwner {
        require(legalFeeRate != _legalFeeRate, "already set value.");
        legalFeeRate = _legalFeeRate;

    }

    function setTeamFeeRate(uint256 _teamFeeRate) public onlyOwner {
        require(teamFeeRate != _teamFeeRate, "already set value.");
        teamFeeRate = _teamFeeRate;

    }

    function setHoldersSdtFeeRate(uint256 _holdersSdtFeeRate) public onlyOwner {
        require(holdersSdtFeeRate != _holdersSdtFeeRate, "already set value.");
        holdersSdtFeeRate = _holdersSdtFeeRate;

    }

    function setPensionWallet(address _address) public onlyOwner {
        require(_address != address(0), "invalid address");
        require(pensionWallet != _address, "already set same value");
        pensionWallet = _address;
    }
    function setLegalWallet(address _address) public onlyOwner {
        require(_address != address(0), "invalid address");
        require(pensionWallet != _address, "already set same value");
        legalWallet = _address;
    }
    function setTeamWallet(address _address) public onlyOwner {
        require(_address != address(0), "invalid address");
        require(teamWallet != _address, "already set same value");
        teamWallet = _address;
    }

    receive() external payable {
        // custom function code
    }

    function _sendBNBToPensionWallet(uint256 amount) internal {
        if(amount > 0 && isOnPensionFee ){
            (bool success, ) = address(pensionWallet).call{value: amount}(new bytes(0));
            require(success, '_sendBNBToPensionWallet: ETH transfer failed');
        }
    }

    function _sendBNBToLegalWallet(uint256 amount) internal {
        if(amount > 0 && isOnLegalFee){
            (bool success, ) = address(legalWallet).call{value: amount}(new bytes(0));
            require(success, '_sendBNBToLegalWallet: ETH transfer failed');
        }
    }

    function _sendBNBToTeamWallet(uint256 amount) internal {
        if(amount > 0 && isOnTeamFee){
            (bool success, ) = address(teamWallet).call{value: amount}(new bytes(0));
            require(success, '_sendBNBToTeamWallet: ETH transfer failed');
        }
    }

    function _distributeRewardDividends(uint256 amount) internal {

        uint256 rewardAmount = _swapTokensForREWARD(amount);

        // send tokens to default
        if(amount > 0){
            bool success = IERC20(REWARD).transfer(address(defaultTokenTracker), rewardAmount);
            if(success){
                IDefaultTracker(defaultTokenTracker).distributeRewardDividends(rewardAmount);
            }
            try IDefaultTracker(defaultTokenTracker).process() {} catch {}
        }
    }

    function setBalance(address payable account, uint256 newBalance) external onlyRematicFinance  {
        if(account != pancakeSwapPair){
            // buying
            IDefaultTracker(defaultTokenTracker).setBalance(account, newBalance);
        }
    }

    function setDefaultTokenTracker(address _address) public onlyOwner {
        require(_address != address(defaultTokenTracker), "RMTX Admin: The defaultTokenTracker already has that address");
        defaultTokenTracker = _address;
    }

    function setRematic(address _address) public onlyOwner {
        require(rematicAddress != _address, "RMTX Admin: already same value");
        rematicAddress = _address;
    }

    // config
    function excludeContractAddressesFromDividendTracker() public onlyOwner {

        IDefaultTracker(defaultTokenTracker)._excludeFromDividendsByAdminContract(defaultTokenTracker);
        IDefaultTracker(defaultTokenTracker)._excludeFromDividendsByAdminContract(address(this));
        IDefaultTracker(defaultTokenTracker)._excludeFromDividendsByAdminContract(owner());
        IDefaultTracker(defaultTokenTracker)._excludeFromDividendsByAdminContract(address(pancakeSwapV2Router));
        IDefaultTracker(defaultTokenTracker)._excludeFromDividendsByAdminContract(pancakeSwapPair);
        address burnWallet = IRematic(rematicAddress).burnWallet();
        IDefaultTracker(defaultTokenTracker)._excludeFromDividendsByAdminContract(burnWallet);
    }

    function _excludeFromDividendsByRematic(address _address) public onlyRematicFinance {
        IDefaultTracker(defaultTokenTracker)._excludeFromDividendsByAdminContract(_address);
    }

    function setBurnWallet(address _address) public onlyOwner {
        // burnWallet = _address;
        IRematic(rematicAddress).setBurnWallet(_address);
    }
    function setStakingWallet(address _address) public onlyOwner {
        IRematic(rematicAddress).setStakingWallet(_address);
    }
    function setTxFeeRate(uint256 _newValue) public onlyOwner {
        IRematic(rematicAddress).setTxFeeRate(_newValue);
    }
    function setBurnFeeRate(uint256 _newValue) public onlyOwner {
        IRematic(rematicAddress).setBurnFeeRate(_newValue);
    }
    function setStakingFeeRate(uint256 _newValue) public onlyOwner {
        IRematic(rematicAddress).setStakingFeeRate(_newValue);
    }

    function setIsOnTeamFee(bool flag) public onlyOwner {
        require(isOnTeamFee != flag, "same value is set already");
        isOnTeamFee = flag;
    }

    function setIsOnLegalFee(bool flag) public onlyOwner {
        require(isOnLegalFee != flag, "same value is set already");
        isOnLegalFee = flag;
    }

    function setIsOnPensionFee(bool flag) public onlyOwner {
        require(isOnPensionFee != flag, "same value is set already");
        isOnPensionFee = flag;
    }

    function setIsOnBurnFeeForRematic(bool flag) public onlyOwner {
        IRematic(rematicAddress).setIsOnBurnFee(flag);
    }

    function setIsOnStakingFeeForRematic(bool flag) public onlyOwner {
        IRematic(rematicAddress).setIsOnStakingFee(flag);
    }

    function setPancakeSwapPair(address _address) public onlyOwner {
        require(pancakeSwapPair != _address, "already same value");
        pancakeSwapPair = _address;
    }

    function setPairCreator(address _address) external onlyOwner {
        require(pairCreator != _address, "already same value");
        pairCreator = _address;
    }

    function setRewardToken(address _address) external onlyOwner {
        require(REWARD != _address, "already same value");
        REWARD = _address;
        IDefaultTracker(defaultTokenTracker).setRewardToken(_address);
    }

    function withdrawToken(address token, address account) external onlyOwner {

        uint256 balance =IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(account, balance);

    }

    function withdrawBNB(address _to) external onlyOwner {
        (bool success, ) = address(_to).call{value: address(this).balance}(new bytes(0));
        require(success, "Transfer failed");
    }

    function setBotWallet(address _bot) external onlyOwner {
        require(botWallet != _bot, "same wallet already");
        botWallet = _bot;
    }

    function _continueLiqudate() internal returns(bool){
        uint256 lastProcessedIndex = IDefaultTracker(defaultTokenTracker).lastProcessedIndex();
        if(lastProcessedIndex > 0){
            IDefaultTracker(defaultTokenTracker).process();
            return true;
        }else{
            return false;
        }
    }

    function setIsLiquidationProcessing(bool flag) external onlyOwner {
        require(isLiquidationProcessing != flag, "same value already!");
        isLiquidationProcessing = flag;
    }
}