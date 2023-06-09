// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@sphynxswap/sphynx-swap-lib/contracts/access/Manageable.sol';
import '@sphynxswap/sphynx-swap-lib/contracts/token/BEP20/BEP20.sol';
import '@sphynxswap/sphynx-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@sphynxswap/sphynx-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@sphynxswap/swap-core/contracts/interfaces/ISphynxPair.sol';
import '@sphynxswap/swap-core/contracts/interfaces/ISphynxFactory.sol';
import '@sphynxswap/swap-periphery/contracts/interfaces/ISphynxRouter02.sol';

interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(uint80 _roundId)
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);

	function latestRoundData()
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);
}

contract SphynxToken is BEP20, Manageable {
	using SafeMath for uint256;
	using SafeBEP20 for IBEP20;

	ISphynxRouter02 public sphynxSwapRouter;
	address public sphynxSwapPair;

	bool private swapping;

	address public masterChef;
	address public sphynxBridge;

	address payable public marketingWallet = payable(0x3D458e65828d031B46579De28e9BBAAeb2729064);
	address payable public developmentWallet = payable(0x7dB8380C7A017F82CC1d2DC7F8F1dE2d29Fd1df6);
	address public lotteryAddress;

	uint256 public usdAmountToSwap = 500;

	uint256 public marketingFee;
	uint256 public developmentFee;
	uint256 public lotteryFee;
	uint256 public totalFees;
	uint256 public blockNumber;

	bool public SwapAndLiquifyEnabled = false;
	bool public sendToLottery = false;
	bool public stopTrade = false;
	bool public claimable = true;
	uint256 public maxTxAmount = 800000000 * (10 ** 18); // Initial Max Tx Amount
	mapping(address => bool) signers;
	mapping(uint256 => address) signersArray;
	mapping(address => bool) stopTradeSign;

	AggregatorV3Interface internal priceFeed;

	// exlcude from fees and max transaction amount
	mapping(address => bool) private _isExcludedFromFees;

	// getting fee addresses
	mapping(address => bool) public _isGetFees;

	// store addresses that are automated market maker pairs. Any transfer to these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public automatedMarketMakerPairs;

	uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

	modifier onlyMasterChefAndBridge() {
		require(msg.sender == masterChef || msg.sender == sphynxBridge, 'Permission Denied');
		_;
	}

	modifier onlySigner() {
		require(signers[msg.sender], 'not-a-signer');
		_;
	}

	modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

	// Contract Events
	event ExcludeFromFees(address indexed account, bool isExcluded);
	event GetFee(address indexed account, bool isGetFee);
	event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
	event DevelopmentWalletUpdated(address indexed newDevelopmentWallet, address indexed oldDevelopmentWallet);
	event LotteryAddressUpdated(address indexed newLotteryAddress, address indexed oldLotteryAddress);
	event UpdateSphynxSwapRouter(address indexed newAddress, address indexed oldAddress);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 nativeReceived, uint256 tokensIntoLiqudity);
	event UpdateSwapAndLiquify(bool value);
	event UpdateSendToLottery(bool value);
	event SetMarketingFee(uint256 value);
	event SetDevelopmentFee(uint256 value);
	event SetLotteryFee(uint256 value);
	event SetAllFeeToZero(uint256 marketingFee, uint256 developmentFee, uint256 lotteryFee);
	event MaxFees(uint256 marketingFee, uint256 developmentFee, uint256 lotteryFee);
	event SetUsdAmountToSwap(uint256 usdAmountToSwap);
	event SetBlockNumber(uint256 blockNumber);
	event UpdateMasterChef(address masterChef);
	event UpdateSphynxBridge(address sphynxBridge);
	event UpdateMaxTxAmount(uint256 txAmount);

	constructor() public BEP20('Sphynx ETH', 'SPHYNX') {
		uint256 _marketingFee = 5;
		uint256 _developmentFee = 5;
		uint256 _lotteryFee = 1;

		marketingFee = _marketingFee;
		developmentFee = _developmentFee;
		lotteryFee = _lotteryFee;
		totalFees = _marketingFee.add(_developmentFee);
		blockNumber = 0;

		ISphynxRouter02 _sphynxSwapRouter = ISphynxRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // mainnet
		// Create a sphynxswap pair for SPHYNX
		address _sphynxSwapPair = ISphynxFactory(_sphynxSwapRouter.factory()).createPair(address(this), _sphynxSwapRouter.WETH());

		sphynxSwapRouter = _sphynxSwapRouter;
		sphynxSwapPair = _sphynxSwapPair;

		_setAutomatedMarketMakerPair(sphynxSwapPair, true);

		// exclude from paying fees or having max transaction amount
		excludeFromFees(marketingWallet, true);
		excludeFromFees(developmentWallet, true);
		excludeFromFees(address(this), true);
		excludeFromFees(owner(), true);

		// set getFee addresses
		_isGetFees[address(_sphynxSwapRouter)] = true;
		_isGetFees[_sphynxSwapPair] = true;
		priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

		_mint(owner(), 800000000 * (10**18));

		_status = _NOT_ENTERED;

		//multi-sign-wallets
		signers[0x35BfE8dA53F94d6711F111790643D2D403992b56] = true;
		signers[0x96C463B615228981A2c30B842E8A8e4e933CEc46] = true;
		signers[0x7278fC9C49A2B6bd072b9d47E3c903ef0e12bb83] = true;
		signersArray[0] = 0x35BfE8dA53F94d6711F111790643D2D403992b56;
		signersArray[1] = 0x96C463B615228981A2c30B842E8A8e4e933CEc46;
		signersArray[2] = 0x7278fC9C49A2B6bd072b9d47E3c903ef0e12bb83;
	}

	receive() external payable {}

	// mint function for masterchef;
	function mint(address to, uint256 amount) public onlyMasterChefAndBridge {
		_mint(to, amount);
	}

	function updateSwapAndLiquifiy(bool value) public onlyManager {
		SwapAndLiquifyEnabled = value;
		emit UpdateSwapAndLiquify(value);
	}

	function updateSendToLottery(bool value) public onlyManager {
		sendToLottery = value;
		emit UpdateSendToLottery(value);
	}

	function setMarketingFee(uint256 value) external onlyManager {
		require(value <= 5, 'SPHYNX: Invalid marketingFee');
		marketingFee = value;
		totalFees = marketingFee.add(developmentFee);
		emit SetMarketingFee(value);
	}

	function setDevelopmentFee(uint256 value) external onlyManager {
		require(value <= 5, 'SPHYNX: Invalid developmentFee');
		developmentFee = value;
		totalFees = marketingFee.add(developmentFee);
		emit SetDevelopmentFee(value);
	}

	function setLotteryFee(uint256 value) external onlyManager {
		require(value <= 1, 'SPHYNX: Invalid lotteryFee');
		lotteryFee = value;
		emit SetLotteryFee(value);
	}

	function setAllFeeToZero() external onlyOwner {
		marketingFee = 0;
		developmentFee = 0;
		lotteryFee = 0;
		totalFees = 0;
		emit SetAllFeeToZero(marketingFee, developmentFee, lotteryFee);
	}

	function maxFees() external onlyOwner {
		marketingFee = 5;
		developmentFee = 5;
		lotteryFee = 1;
		totalFees = marketingFee.add(developmentFee);
		emit MaxFees(marketingFee, developmentFee, lotteryFee);
	}

	function updateSphynxSwapRouter(address newAddress) public onlyManager {
		require(newAddress != address(sphynxSwapRouter), 'SPHYNX: The router already has that address');
		emit UpdateSphynxSwapRouter(newAddress, address(sphynxSwapRouter));
		sphynxSwapRouter = ISphynxRouter02(newAddress);
		address _sphynxSwapPair;
		_sphynxSwapPair = ISphynxFactory(sphynxSwapRouter.factory()).getPair(address(this), sphynxSwapRouter.WETH());
		if(_sphynxSwapPair == address(0)) {
			_sphynxSwapPair = ISphynxFactory(sphynxSwapRouter.factory()).createPair(address(this), sphynxSwapRouter.WETH());
		}
		_setAutomatedMarketMakerPair(sphynxSwapPair, false);
		sphynxSwapPair = _sphynxSwapPair;
		_setAutomatedMarketMakerPair(sphynxSwapPair, true);
	}

	function updateMasterChef(address _masterChef) public onlyManager {
		require(masterChef != _masterChef, 'SPHYNX: MasterChef already exists!');
		masterChef = _masterChef;
		emit UpdateMasterChef(_masterChef);
	}

	function updateSphynxBridge(address _sphynxBridge) public onlyManager {
		require(sphynxBridge != _sphynxBridge, 'SPHYNX: SphynxBridge already exists!');
		_isExcludedFromFees[sphynxBridge] = false;
		sphynxBridge = _sphynxBridge;
		_isExcludedFromFees[sphynxBridge] = true;
		emit UpdateSphynxBridge(_sphynxBridge);
	}

	function excludeFromFees(address account, bool excluded) public onlyManager {
		require(_isExcludedFromFees[account] != excluded, "SPHYNX: Account is already the value of 'excluded'");
		_isExcludedFromFees[account] = excluded;

		emit ExcludeFromFees(account, excluded);
	}

	function setFeeAccount(address account, bool isGetFee) public onlyManager {
		require(_isGetFees[account] != isGetFee, "SPHYNX: Account is already the value of 'isGetFee'");
		_isGetFees[account] = isGetFee;

		emit GetFee(account, isGetFee);
	}

	function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
		for (uint256 i = 0; i < accounts.length; i++) {
			_isExcludedFromFees[accounts[i]] = excluded;
		}

		emit ExcludeMultipleAccountsFromFees(accounts, excluded);
	}

	function setAutomatedMarketMakerPair(address pair, bool value) public onlyManager {
		_setAutomatedMarketMakerPair(pair, value);
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, 'SPHYNX: Automated market maker pair is already set to that value');
		automatedMarketMakerPairs[pair] = value;

		emit SetAutomatedMarketMakerPair(pair, value);
	}

	function setUsdAmountToSwap(uint256 _usdAmount) public onlyManager {
		usdAmountToSwap = _usdAmount;
		emit SetUsdAmountToSwap(usdAmountToSwap);
	}

	function updateMarketingWallet(address newMarketingWallet) public onlyManager {
		require(newMarketingWallet != marketingWallet, 'SPHYNX: The marketing wallet is already this address');
		excludeFromFees(newMarketingWallet, true);
		excludeFromFees(marketingWallet, false);
		emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
		marketingWallet = payable(newMarketingWallet);
	}

	function updateDevelopmentgWallet(address newDevelopmentWallet) public onlyManager {
		require(newDevelopmentWallet != developmentWallet, 'SPHYNX: The development wallet is already this address');
		excludeFromFees(newDevelopmentWallet, true);
		excludeFromFees(developmentWallet, false);
		emit DevelopmentWalletUpdated(newDevelopmentWallet, developmentWallet);
		developmentWallet = payable(newDevelopmentWallet);
	}

	function updateLotteryAddress(address newLotteryAddress) public onlyManager {
		require(newLotteryAddress != lotteryAddress, 'SPHYNX: The lottery wallet is already this address');
		excludeFromFees(newLotteryAddress, true);
		excludeFromFees(lotteryAddress, false);
		emit LotteryAddressUpdated(newLotteryAddress, lotteryAddress);
		lotteryAddress = newLotteryAddress;
	}

	function setBlockNumber() public onlyOwner {
		blockNumber = block.number;
		emit SetBlockNumber(blockNumber);
	}

	function updateMaxTxAmount(uint256 _amount) public onlyManager {
		maxTxAmount = _amount;
		emit UpdateMaxTxAmount(_amount);
	}

	function updateTokenClaim(bool _claim) public onlyManager {
		claimable = _claim;
	}

	function updateStopTrade(bool _value) external onlySigner {
		require(stopTrade != _value, 'already-set');
		require(!stopTradeSign[msg.sender], 'already-sign');
		stopTradeSign[msg.sender] = true;
        if (
            stopTradeSign[signersArray[0]] &&
            stopTradeSign[signersArray[1]] &&
            stopTradeSign[signersArray[2]]
        ) {
			stopTrade = _value;
			stopTradeSign[signersArray[0]] = false;
			stopTradeSign[signersArray[1]] = false;
			stopTradeSign[signersArray[2]] = false;
		}
	}

	function updateSignerWallet(address _signer) external onlySigner {
		signers[msg.sender] = false;
		signers[_signer] = true;
		for(uint i = 0; i < 3; i++) {
			if(signersArray[i] == msg.sender) {
				signersArray[i] = _signer;
			}
		}
	}

	function isExcludedFromFees(address account) public view returns (bool) {
		return _isExcludedFromFees[account];
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal override {
		require(from != address(0), 'BEP20: transfer from the zero address');
		require(to != address(0), 'BEP20: transfer to the zero address');
		require(!stopTrade, 'trade-stopped');
		require(amount <= maxTxAmount, 'max-tx-amount-overflow');

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

        if(SwapAndLiquifyEnabled) {
            uint256 contractTokenBalance = balanceOf(address(this));
            uint256 nativeTokenAmount = _getTokenAmountFromNative();

		    bool canSwap = contractTokenBalance >= nativeTokenAmount;

            if (canSwap && !swapping && !automatedMarketMakerPairs[from]) {
                swapping = true;

                // Set number of tokens to sell to nativeTokenAmount
                contractTokenBalance = nativeTokenAmount;
                swapTokens(contractTokenBalance);
                swapping = false;
            }
        }

		// indicates if fee should be deducted from transfer
		bool takeFee = true;

		// if any account belongs to _isExcludedFromFee account then remove the fee
		if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
			takeFee = false;
		}

		if (takeFee) {
			if (block.number - blockNumber <= 10) {
				uint256 afterBalance = balanceOf(to) + amount;
				require(afterBalance <= 250000 * (10**18), 'Owned amount exceeds the maxOwnedAmount');
			}
			uint256 fees;
			if (_isGetFees[from] || _isGetFees[to]) {
				if (block.number - blockNumber <= 5) {
					fees = amount.mul(99).div(10**2);
				} else {
					fees = amount.mul(totalFees).div(10**2);
					if (sendToLottery) {
						uint256 lotteryAmount = amount.mul(lotteryFee).div(10**2);
						amount = amount.sub(lotteryAmount);
						super._transfer(from, lotteryAddress, lotteryAmount);
					}
				}

				amount = amount.sub(fees);
				super._transfer(from, address(this), fees);
			}
		}

		super._transfer(from, to, amount);
	}

	function swapTokens(uint256 tokenAmount) private {
		swapTokensForNative(tokenAmount);
		uint256 swappedNative = address(this).balance;
		uint256 marketingNative = swappedNative.mul(marketingFee).div(totalFees);
		uint256 developmentNative = swappedNative.sub(marketingNative);
		transferNativeToMarketingWallet(marketingNative);
		transferNativeToDevelopmentWallet(developmentNative);
	}

	// Swap tokens on PacakeSwap
	function swapTokensForNative(uint256 tokenAmount) private {
		// generate the sphynxswap pair path of token -> WETH
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = sphynxSwapRouter.WETH();

		_approve(address(this), address(sphynxSwapRouter), tokenAmount);

		// make the swap
		sphynxSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of Native
			path,
			address(this),
			block.timestamp
		);
	}

	function getNativeAmountFromUSD() public view returns (uint256 amount) {
		(
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        amount = usdAmountToSwap.mul(10 ** 26).div(uint256(price));
	}

	function _getTokenAmountFromNative() internal view returns (uint256) {
		uint256 tokenAmount;
		address[] memory path = new address[](2);
		path[0] = sphynxSwapRouter.WETH();
		path[1] = address(this);

		uint256 nativeAmountToSwap = getNativeAmountFromUSD();
		uint256[] memory amounts = sphynxSwapRouter.getAmountsOut(nativeAmountToSwap, path);
		tokenAmount = amounts[1];
		return tokenAmount;
	}

	function transferNativeToMarketingWallet(uint256 amount) private {
		marketingWallet.transfer(amount);
	}

	function transferNativeToDevelopmentWallet(uint256 amount) private {
		developmentWallet.transfer(amount);
	}
}