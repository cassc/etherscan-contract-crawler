// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./interfaces/IToolbox.sol";
import "./interfaces/IDogsExchangeHelper.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FeeManager is Ownable {
    using SafeERC20 for IERC20;

    IUniswapV2Factory public constant PancakeFactory = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IUniswapV2Router02 public constant PancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IToolbox public Toolbox = IToolbox(0x78F316775ace6CBF33F14b52903900fb9Be02fb4);

    uint256 public busdSwapThreshold = 50 ether;

    address public constant busdCurrencyAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant wbnbCurrencyAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public pigPenAddress = 0x1f8a98bE5C102D145aC672ded99C5bE0330d7e4F;
    address public vaultAddress = 0x68Bdc7b480d5b4df3bB086Cc3f33b0AEf52F7d55;
    address public dogsLpReceiver = 0x000000000000000000000000000000000000dEaD;
    address public dogsV2Address = 0x198271b868daE875bFea6e6E4045cDdA5d6B9829;
    address public masterchefDogs = 0x78205CE1a7e714CAE95a32e65B6dA7b2dA8D8A10;
    address public dontSellAddress = 0xA76216D578BdA59d50B520AaF717B187D21F5121;
    IDogsExchangeHelper public DogsExchangeHelper = IDogsExchangeHelper(0xB59686fe494D1Dd6d3529Ed9df384cD208F182e8);

    uint256 public distributionPigPen = 2300; //23%
    uint256 public distributionVault  = 5000; //50%
    uint256 public distributionDogsLP = 2700; //27%

    address[] pathBusdDogs;

    mapping (address => bool) public viaWBNBTokens;
    mapping (address => bool) public dontSellTokens;

    constructor(){

        pathBusdDogs = _createRoute(busdCurrencyAddress, dogsV2Address);

        _approveTokenIfNeeded(busdCurrencyAddress, address(PancakeRouter));
        _approveTokenIfNeeded(dogsV2Address, address(PancakeRouter));

        _approveTokenIfNeeded(busdCurrencyAddress, address(DogsExchangeHelper));
        _approveTokenIfNeeded(dogsV2Address, address(DogsExchangeHelper));

        _setRouteViaBNBToken(0xF8A0BF9cF54Bb92F17374d9e9A321E6a111a51bD, true); // LINK
        _setRouteViaBNBToken(0xE0e514c71282b6f4e823703a39374Cf58dc3eA4f, true); // BELT
        _setRouteViaBNBToken(0x2170Ed0880ac9A755fd29B2688956BD959F933F8, true); // ETH
        _setRouteViaBNBToken(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402, true); // DOT

        dontSellTokens[0xa0feB3c81A36E885B6608DF7f0ff69dB97491b58] = true;
    }

    // MODIFIERS
    modifier onlyMasterchefDogs() {
        require(masterchefDogs == msg.sender, "masterchefDogs only");
        _;
    }

    // Events
    event DepositFeeConvertedToBUSD(address indexed inputToken, uint256 inputAmount, uint256 busdInstant, uint256 busdVault);
    event UpdateVault(address indexed vaultAddress);
    event UpdatePigPen(address indexed pigpenAddress);
    event UpdateLpReceiver(address indexed lpReceiverAddress);
    event UpdateDogsToken(address indexed dogsTokenAddress);
    event UpdateToolbox(address indexed toolBoxAddress);
    event SetRouteTokenViaBNB(address tokenAddress, bool shouldRoute);

    // EXTERNAL FUNCTIONS
    function swapDepositFeeForBUSD(address token, bool isLPToken) external onlyMasterchefDogs {
        uint256 totalTokenBalance;
        if(dontSellTokens[token]){
            totalTokenBalance = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(dontSellAddress, totalTokenBalance);
            return;
        }

        totalTokenBalance = IERC20(token).balanceOf(address(this));

        if (totalTokenBalance == 0 || token == busdCurrencyAddress){
            return;
        }

        uint256 busdValue = Toolbox.getTokenBUSDValue(totalTokenBalance, token, isLPToken);

        // only swap if a certain busd value
        if (busdValue < busdSwapThreshold)
            return;

        swapDepositFeeForTokensInternal(token, isLPToken);

        _distributeDepositFeeBusd();

    }

    /**
     * @dev un-enchant the lp token into its original components.
     */
    function unpairLPToken(address token, uint256 amount) internal returns(address token0, address token1, uint256 amountA, uint256 amountB){
        _approveTokenIfNeeded(token, address(PancakeRouter));

        IUniswapV2Pair lpToken = IUniswapV2Pair(token);
        address token0 = lpToken.token0();
        address token1 = lpToken.token1();

        // make the swap
        (uint256 amount0, uint256 amount1) = PancakeRouter.removeLiquidity(
            address(token0),
            address(token1),
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );

        return (token0, token1, amount0, amount1);

    }

    function swapDepositFeeForTokensInternal(address token, bool isLPToken) internal{

        uint256 totalTokenBalance = IERC20(token).balanceOf(address(this));

        if (isLPToken) {
            address token0;
            address token1;
            uint256 amount0;
            uint256 amount1;

            (token0, token1, amount0, amount1) = unpairLPToken(token, totalTokenBalance);
            // now I have 2 tokens...
            convertTokenToBUSD(token0, amount0);
            convertTokenToBUSD(token1, amount1);
        } else {
            convertTokenToBUSD(token, totalTokenBalance);
        }

    }

    function convertTokenToBUSD(address token, uint256 amount) internal {

        if (token == busdCurrencyAddress){
            return;
        }

        _approveTokenIfNeeded(token, address(PancakeRouter));

        address[] memory path;
        if (shouldRouteViaBNB(token)){
            path = new address[](3);
            path[0] = token;
            path[1] = wbnbCurrencyAddress;
            path[2] = busdCurrencyAddress;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = busdCurrencyAddress;
        }

        // make the swap
        PancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );

    }

    function _distributeDepositFeeBusd() internal {

        uint256 totalBusdBalance = IERC20(busdCurrencyAddress).balanceOf(address(this));

        uint256 amountPigPen        = totalBusdBalance * distributionPigPen / 10000;
        uint256 amountBusdVault     = totalBusdBalance * distributionVault / 10000;
        uint256 amountDogsLiquidity = totalBusdBalance - amountPigPen - amountBusdVault;

        IERC20(busdCurrencyAddress).transfer(pigPenAddress, amountPigPen);
        IERC20(busdCurrencyAddress).transfer(vaultAddress, amountBusdVault);
        _buybackDogsAddLiquidity(amountDogsLiquidity);
    }

    function _buybackDogsAddLiquidity(uint256 _amountBUSD) internal {
        // approved busd / dogs in constructor

        address[] memory path;
        path = _getBestBUSDDogsSwapPath(_amountBUSD / 2);

        DogsExchangeHelper.buyDogs(_amountBUSD / 2, 0, path);


        // add Dogs/Busd liquidity
        uint256 dogsTokenBalance = IERC20(dogsV2Address).balanceOf(address(this));
        uint256 busdTokenBalance = IERC20(busdCurrencyAddress).balanceOf(address(this));

        IUniswapV2Pair pair = IUniswapV2Pair(PancakeFactory.getPair(dogsV2Address, busdCurrencyAddress));

        DogsExchangeHelper.addDogsLiquidity(busdCurrencyAddress, busdTokenBalance, dogsTokenBalance);
        uint256 dogsBusdLpReceived = IERC20(address(pair)).balanceOf(address(this));
        IERC20(address(pair)).transfer(dogsLpReceiver, dogsBusdLpReceived);

    }

    function _getBestBUSDDogsSwapPath(uint256 _amountBUSD) internal view returns (address[] memory){

        address[] memory pathBUSD_BNB_Dogs = _createRoute3(busdCurrencyAddress, wbnbCurrencyAddress , dogsV2Address);

        uint256[] memory amountOutBUSD = PancakeRouter.getAmountsOut(_amountBUSD, pathBusdDogs);
        uint256[] memory amountOutBUSDviaBNB = PancakeRouter.getAmountsOut(_amountBUSD, pathBUSD_BNB_Dogs);

        if (amountOutBUSD[amountOutBUSD.length - 1] > amountOutBUSDviaBNB[amountOutBUSDviaBNB.length -1]){ 
            return pathBusdDogs;
        }
        return pathBUSD_BNB_Dogs;

    }

    function _createRoute(address _from, address _to) internal pure returns(address[] memory){
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        return path;
    }

    function _createRoute3(address _from, address _mid, address _to) internal pure returns(address[] memory){
        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = _mid;
        path[2] = _to;
        return path;
    }

    function _approveTokenIfNeeded(address token, address _contract) private {
        if (IERC20(token).allowance(address(this), address(_contract)) == 0) {
            IERC20(token).safeApprove(address(_contract), type(uint256).max);
        }
    }

    function setRouteViaBNBToken(address _token, bool _viaWbnb) external onlyOwner {
        _setRouteViaBNBToken(_token, _viaWbnb);
    }

    function _setRouteViaBNBToken(address _token, bool _viaWbnb) private {
        viaWBNBTokens[_token] = _viaWbnb;
        emit SetRouteTokenViaBNB(_token, _viaWbnb);
    }

    function setdontSellTokens(address _token, bool _bool) external onlyOwner {
        dontSellTokens[_token] = _bool;
    }
    
    function shouldRouteViaBNB(address _token) public view returns (bool){
        return viaWBNBTokens[_token];
    }

    // ADMIN FUNCTIONS
    function updateVaultAddress(address _vault) external onlyOwner {
        vaultAddress = _vault;
        emit UpdateVault(_vault);
    }

    function updatedontSellAddress(address _address) external onlyOwner {
        dontSellAddress = _address;
    }

    function updatePigPenAddress(address _pigPen) external onlyOwner {
        pigPenAddress = _pigPen;
        emit UpdatePigPen(_pigPen);
    }

    function updateDogsLpReceiver(address _lpReceiver) external onlyOwner {
        dogsLpReceiver = _lpReceiver;
        emit UpdateLpReceiver(_lpReceiver);
    }

    function updateDogsTokenAddress(address _dogsToken) external onlyOwner {
        dogsV2Address = _dogsToken;
        _approveTokenIfNeeded(_dogsToken, address(PancakeRouter));
        _approveTokenIfNeeded(_dogsToken, address(DogsExchangeHelper));
        pathBusdDogs = _createRoute(busdCurrencyAddress, _dogsToken);
        emit UpdateDogsToken(_dogsToken);
    }

    function updateToolbox(IToolbox _toolbox) external onlyOwner {
        Toolbox = _toolbox;

        emit UpdateToolbox(address(_toolbox));
    }

    function updateDistribution(uint256 _distributionPigPen , uint256 _distributionVault , uint256 _distributionDogsLP) external onlyOwner {
        require(_distributionPigPen <= 10000 && _distributionVault <= 10000 && _distributionDogsLP <= 10000);
        distributionPigPen = _distributionPigPen;
        distributionVault = _distributionVault;
        distributionDogsLP = _distributionDogsLP;
    }

    function updateAddDogsLiquidityHelper(IDogsExchangeHelper _dogsExchangeHelper) external onlyOwner {
        DogsExchangeHelper = _dogsExchangeHelper;
        _approveTokenIfNeeded(dogsV2Address, address(_dogsExchangeHelper));
        _approveTokenIfNeeded(busdCurrencyAddress, address(_dogsExchangeHelper));
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }
}