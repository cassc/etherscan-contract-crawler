// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libs/IUniswapV2Pair.sol";
import "./libs/IUniswapV2Factory.sol";
import "./libs/IUniswapV2Router.sol";

contract SwapperV2 is Initializable, OwnableUpgradeable {
	using SafeMath for uint256;
	
	
	IUniswapV2Router02 public  uniswapV2Router;	
	
	address private constant BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //BUSD mainnet		
	
	IToken private pistonToken;	
	address public _controllerAddress;
	
	//readers
	uint256 public maxBuyAmount;
	uint256 public maxSellAmount;
	uint256 public maxWalletBalance;
	uint256 public totalFees;
	uint256 public extraSellFee;	
	
	uint256 public started;

	ITokenPriceFeed private pistonTokenPriceFeed;
	bool public updateTwapEnabled;

	IUniswapV2Router02 public apeswapRouter;

	address public constant Pair_BUSD_Apeswap = address(0x57FA15D373cBBD3141A13f8baB10c380aC2B14D5);
	address public constant Pair_BUSD_PCS = address(0xdd52bd6CcE78f3114ba83B04F006aec03f432779);
	
	event TokenBuy(address _addr, uint256 _busd_amount, uint256 _token_amount, uint8 dex);
	
	function initialize() public virtual initializer {	
		__Ownable_init();				

		uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // pcs mainnet
		apeswapRouter = IUniswapV2Router02(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7); // apeswap mainnet

		pistonTokenPriceFeed = ITokenPriceFeed(0x87F6B58E5C28d16c77e2EeB3dA3E08ce18BaB32E);
		updateTwapEnabled = true;

		pistonToken = IToken(address(0xBfACD29427fF376FF3BC22dfFB29866277cA5Fb4));	
		_controllerAddress = address(0x3166C32FF270BD5255c948542726B099Dc5A6c63);
		
		started = 0;
	}
	
	
	function settersForPistonWeb(address   _Piston, address controllerAddress) external onlyOwner{
		pistonToken = IToken(address(_Piston));	
		_controllerAddress = controllerAddress;
	}
	
	function setStarted(uint256 _started) external onlyOwner{
		started = _started;
	}

	function setApeSwapRouter(address _value) external onlyOwner{
		apeswapRouter = IUniswapV2Router02(_value);
	}

	function updatePistonTokenPriceFeed(address _priceFeedAddress, bool _updateTwapEnabled) public onlyOwner {
        pistonTokenPriceFeed = ITokenPriceFeed(_priceFeedAddress);
		updateTwapEnabled = _updateTwapEnabled;
    }	
	
	function updateVariablesFromPistonToken() public{
		maxBuyAmount = pistonToken.maxBuyAmount();
		maxSellAmount = pistonToken.maxSellAmount();
		maxWalletBalance = pistonToken.maxWalletBalance();
		totalFees = pistonToken.totalFees();
		extraSellFee = pistonToken.extraSellFee();
	}
	
	function _buyChecks() internal view{
		//checks after pstn tokens bought
		//pstn tokens got <= maxBuyAmount
		//user balance + pstn tokens got <= maxWalletBalance
		
		require(getContractsPSTNBalance() <= maxBuyAmount, "maxBuyAmount check fail");
		require(getContractsPSTNBalance().add(getUsersPSTNBalance()) <= maxWalletBalance, "maxWalletBalance check fail");	
	}
	
	function _sellChecks() internal view {
		//checks
		//pstnAMount <= maxSellAmount
		//user balance + pstnAMount <= maxWalletBalance
		
		require(getContractsPSTNBalance() <= maxSellAmount, "maxSellAmount check fail");
		require(getContractsPSTNBalance().add(getUsersPSTNBalance()) <= maxWalletBalance, "maxWalletBalance check fail");			
	}
	
	function _takeFees() internal {
	
		//fee take and sell remaining
		//calculate fees
		uint256 feesToDeduct = getContractsPSTNBalance().mul(totalFees.add(extraSellFee)).div(100);
		
		//send fees controller
		pistonToken.transfer(_controllerAddress, feesToDeduct);			
	}
	
	function swapBUSDForTokens(uint256 busdAmount) external {
		_swapBUSDForTokens(busdAmount, /*pancake*/uniswapV2Router);

		uint256 _token_amount = busdAmount.mul(1e18).div(getPstnPriceLive_PCS(1));
		emit TokenBuy(msg.sender, busdAmount, _token_amount, 0);	
	}

	function swapBUSDForTokens_Apeswap(uint256 busdAmount) external {
		_swapBUSDForTokens(busdAmount, apeswapRouter);

		uint256 _token_amount = busdAmount.mul(1e18).div(getPstnPriceLive_Apeswap(1));
		emit TokenBuy(msg.sender, busdAmount, _token_amount, 1);	
	}

	function _swapBUSDForTokens(uint256 busdAmount, IUniswapV2Router02 router) internal {
	
		require(started == 1, "Not running!");
		
		updateVariablesFromPistonToken();

		require(busdAmount > 0, "amount check fail");

		//	Update the pricefeed 
		//
		UpdateTwapPrice();
		
		// this is separate contract, does not keep any BUSD/PSTN tokens
		// get BUSD from user
		IERC20(BUSD).transferFrom(address(msg.sender), address(this), busdAmount);
		// swap  BUSD to Tokens and send  tokens to user , path: BUSD->PSTN
		
		address[] memory path = new address[](2);
		path[0] = BUSD;
		path[1] = address(pistonToken);
		
		IERC20(BUSD).approve(address(router), busdAmount);
		
		// do the swap
		router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			busdAmount,
			0,
			path,
			address(this),
			block.timestamp.add(3600)
		);
		
		_buyChecks();
		
		//send to user
		pistonToken.transfer(msg.sender, getContractsPSTNBalance());	
	}
	
			
	function swapBNBForTokens() external payable{
	
		require(started == 1, "Not running!");

		updateVariablesFromPistonToken();

		require(msg.value > 0, "amount check fail");

		//	Update the pricefeed 
		//
		UpdateTwapPrice();
		
		// this is separate contract, does not keep any BNB/PSTN tokens
		// get BNB from user
		// swap  BNB to Tokens and send  tokens to user , path: BNB->BUSD->PSTN
		
		address[] memory path = new address[](3);
		path[0] = uniswapV2Router.WETH();
		path[1] = address(BUSD);
		path[2] = address(pistonToken);			
		
		// do the swap
		uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
			0,
			path,
			address(this),
			block.timestamp.add(3600)
		);
		
		_buyChecks();
		
		//send to user
		pistonToken.transfer(msg.sender, getContractsPSTNBalance());
			
	}
	
	
	function swapPSTNForBUSD(uint256 pstnAmount) external {
		swapPSTNForBUSD(pstnAmount, uniswapV2Router);
	}

	function swapPSTNForBUSD_Apeswap(uint256 pstnAmount) external {
		swapPSTNForBUSD(pstnAmount, apeswapRouter);
	}

	function swapPSTNForBUSD(uint256 pstnAmount, IUniswapV2Router02 router) internal {
	
		require(started == 1, "Not running!");

		updateVariablesFromPistonToken();

		require(pstnAmount > 0, "amount check fail");	
		
		//	Update the pricefeed 
		//
		UpdateTwapPrice();

		// this is separate contract, does not keep any BUSD/PSTN tokens
		// get PSTN from user
		pistonToken.transferFrom(address(msg.sender), address(this), pstnAmount);
		
		_sellChecks();
		
		//takefees and send to controller
		_takeFees();
		
		
		uint256 toSell = getContractsPSTNBalance();
		// swap  PSTN to BUSD and have exchange send BUSD to user , path: PSTN->BUSD
		pistonToken.approve(address(router), toSell); // approve
		
		address[] memory path = new address[](2);
		path[0] = address(pistonToken);
		path[1] = BUSD;		
		
		
		// do the swap
		router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			toSell,
			0,
			path,
			address(msg.sender), 
			block.timestamp.add(3600)
		);
			
	}
	
	function swapPSTNForBNB(uint256 pstnAmount) public {

		require(started == 1, "Not running!");

		updateVariablesFromPistonToken();

		require(pstnAmount > 0, "amount check fail");

		//	Update the pricefeed 
		//
		UpdateTwapPrice();
		
		// this is separate contract, does not keep any BNB/PSTN tokens
		// get PSTN from user
		pistonToken.transferFrom(address(msg.sender), address(this), pstnAmount);
		
		_sellChecks();
		
		//takefees and send to controller
		_takeFees();
		
		
		// swap  PSTN to BNB and have exchange send BNB to user , path: PSTN->BUSD->BNB
		uint256 toSell=getContractsPSTNBalance();
		pistonToken.approve(address(uniswapV2Router), toSell); // approve 
		
		address[] memory path = new address[](3);
		
		path[0] = address(pistonToken);	
		path[1] = address(BUSD);
		path[2] = uniswapV2Router.WETH();
		
		// do the swap
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			toSell,
			0,
			path,
			address(msg.sender), 
			block.timestamp.add(3600)
		);
		
	}

	function UpdateTwapPrice() internal {
		//	Update the pricefeed 
		//
		if(updateTwapEnabled == true){
			if(pistonTokenPriceFeed.needsUpdateTWAP()){
				pistonTokenPriceFeed.updateTWAP();
			}
		}
	}
	

	/* getters */
	
	function getContractsPSTNBalance() public view returns (uint256) {
		return pistonToken.balanceOf(address(this));
	}
	function getUsersPSTNBalance() public view returns (uint256) {
		return pistonToken.balanceOf(address(msg.sender));
	}
	
	function getPistonVariables() public view  returns (uint256, uint256, uint256, uint256, uint256) {	
		return (maxBuyAmount,maxSellAmount, maxWalletBalance, totalFees, extraSellFee);			
	}
	
	// view functions for the website
	function getPstnPriceLive_PCS(uint amount) public view returns(uint) {

		IUniswapV2Pair pair = IUniswapV2Pair(Pair_BUSD_PCS);
        IToken token0 = IToken(pair.token0());
        (uint Res0, uint Res1,) = pair.getReserves();

        // decimals
        uint _Res1 = Res1*(10**token0.decimals());
        uint _Res0 = Res0;
        
        return ((amount*_Res1)/_Res0);
    }

	// view functions for the website
	function getPstnPriceLive_Apeswap(uint amount) public view returns(uint) {

		IUniswapV2Pair pair = IUniswapV2Pair(Pair_BUSD_Apeswap);
        IToken token0 = IToken(pair.token0());
        (uint Res0, uint Res1,) = pair.getReserves();

        // decimals
        uint _Res1 = Res1*(10**token0.decimals());
        uint _Res0 = Res0;
        
        return ((amount*_Res1)/_Res0);
    }
	
}


interface IToken {
	//variable readers
	function maxBuyAmount() external returns(uint256);
	function maxSellAmount() external returns(uint256);
	function maxWalletBalance() external returns(uint256);
	function totalFees() external returns(uint256);
	function extraSellFee() external returns(uint256);

	// functions

	function decimals() external view returns (uint8);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
}

interface ITokenPriceFeed {
    function getPrice(uint amount) external view returns(uint);
	function needsUpdateTWAP() external view returns (bool);
	function updateTWAP() external;
}