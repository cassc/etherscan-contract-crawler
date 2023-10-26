// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
import "../utils/DAOUpgradeableContract.sol";
import "../utils/NameService.sol";
import "./GoodReserveCDai.sol";

contract ExchangeHelper is DAOUpgradeableContract {
	uint256 private _status;

	function initialize(INameService _ns) public virtual initializer {
		setDAO(_ns);
		setAddresses();
		_status = 1;
	}

	// Emits when GD tokens are purchased
	event TokenPurchased(
		// The initiate of the action
		address indexed caller,
		// The convertible token address
		// which the GD tokens were
		// purchased with
		address indexed inputToken,
		// Reserve tokens amount
		uint256 inputAmount,
		// Actual return after the
		// conversion
		uint256 actualReturn,
		// Address of the receiver of tokens
		address indexed receiverAddress
	);
	// Emits when GD tokens are sold
	event TokenSold(
		// The initiate of the action
		address indexed caller,
		// The convertible token address
		// which the GD tokens were
		// sold to
		address indexed outputToken,
		// GD tokens amount
		uint256 gdAmount,
		// The amount of GD tokens that
		// was contributed during the
		// conversion
		uint256 contributionAmount,
		// Actual return after the
		// conversion
		uint256 actualReturn,
		// Address of the receiver of tokens
		address indexed receiverAddress
	);
	address public daiAddress;
	address public cDaiAddress;
	/**
	 * @dev Prevents a contract from calling itself, directly or indirectly.
	 * Calling a `nonReentrant` function from another `nonReentrant`
	 * function is not supported. It is possible to prevent this from happening
	 * by making the `nonReentrant` function external, and make it call a
	 * `private` function that does the actual work.
	 */
	modifier nonReentrant() {
		// On the first call to nonReentrant, _notEntered will be true
		require(_status != 2, "ReentrancyGuard: reentrant call");

		// Any calls to nonReentrant after this point will fail
		_status = 2;

		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_status = 1;
	}

	function setAddresses() public {
		daiAddress = nameService.getAddress("DAI");
		cDaiAddress = nameService.getAddress("CDAI");
		// Approve transfer to cDAI contract
		ERC20(daiAddress).approve(cDaiAddress, type(uint256).max);
		ERC20(daiAddress).approve(
			nameService.getAddress("UNISWAP_ROUTER"),
			type(uint256).max
		);
	}

	/**
	@dev Converts any 'buyWith' tokens to DAI then call reserve's buy function to convert it to GD tokens(no need reentrancy lock since we don't transfer external token's to user)
	* @param _buyPath The tokens swap path in order to buy G$ if initial token is not DAI or cDAI then end of the path must set to DAI
	* @param _tokenAmount The amount of `buyWith` tokens that should be converted to GD tokens
	* @param _minReturn The minimum allowed return in GD tokens
	* @param _minDAIAmount The mininmum dai out amount from Exchange swap function
	* @param _targetAddress address of g$ and gdx recipient if different than msg.sender
	* @return (gdReturn) How much GD tokens were transferred
	 */
	function buy(
		address[] memory _buyPath,
		uint256 _tokenAmount,
		uint256 _minReturn,
		uint256 _minDAIAmount,
		address _targetAddress
	) public payable nonReentrant returns (uint256) {
		require(_buyPath.length > 0, "Provide valid path");
		GoodReserveCDai reserve = GoodReserveCDai(
			nameService.getAddress("RESERVE")
		);
		address receiver = _targetAddress == address(0x0)
			? msg.sender
			: _targetAddress;

		if (_buyPath[0] == address(0)) {
			require(
				msg.value > 0 && _tokenAmount == msg.value,
				"you need to pay with ETH"
			);
		} else {
			require(
				msg.value == 0,
				"When input token is different than ETH message value should be zero"
			);
			require(
				ERC20(_buyPath[0]).transferFrom(
					msg.sender,
					address(_buyPath[0]) == cDaiAddress
						? address(reserve)
						: address(this),
					_tokenAmount
				) == true,
				"transferFrom failed, make sure you approved input token transfer"
			);
		}

		uint256 result;
		if (_buyPath[0] == cDaiAddress) {
			result = reserve.buy(_tokenAmount, _minReturn, receiver);
		} else if (_buyPath[0] == daiAddress) {
			result = _cdaiMintAndBuy(_tokenAmount, _minReturn, receiver);
		} else {
			require(
				_buyPath[_buyPath.length - 1] == daiAddress,
				"Target token in the path must be DAI"
			);
			uint256[] memory swap = _uniswapSwap(
				_buyPath,
				_tokenAmount,
				_minDAIAmount,
				0,
				address(this)
			);

			uint256 dai = swap[swap.length - 1];
			require(dai > 0, "token selling failed");

			result = _cdaiMintAndBuy(dai, _minReturn, receiver);
		}

		emit TokenPurchased(
			msg.sender,
			_buyPath[0],
			_tokenAmount,
			result,
			receiver
		);

		return result;
	}

	/**
	 * @dev Converts GD tokens to cDAI through reserve then make further transactions according to desired _sellTo token(either send cDAI or DAI directly or desired token through uniswap)
	 * @param _sellPath The tokens swap path in order to sell G$ to target token if target token is not DAI or cDAI then first element of the path must be DAI
	 * @param _gdAmount The amount of GD tokens that should be converted to `_sellTo` tokens
	 * @param _minReturn The minimum allowed `sellTo` tokens return
	 * @param _minTokenReturn The mininmum dai out amount from Exchange swap function
	 * @param _targetAddress address of _sellTo token recipient if different than msg.sender
	 * @return (tokenReturn) How much `sellTo` tokens were transferred
	 */
	function sell(
		address[] memory _sellPath,
		uint256 _gdAmount,
		uint256 _minReturn,
		uint256 _minTokenReturn,
		address _targetAddress
	) public nonReentrant returns (uint256) {
		require(_sellPath.length > 0, "Provide valid path");
		address receiver = _targetAddress == address(0x0)
			? msg.sender
			: _targetAddress;

		uint256 result;
		uint256 contributionAmount;
		GoodReserveCDai reserve = GoodReserveCDai(
			nameService.getAddress("RESERVE")
		);
		IGoodDollar(nameService.getAddress("GOODDOLLAR")).burnFrom(
			msg.sender,
			_gdAmount
		);

		(result, contributionAmount) = reserve.sell(
			_gdAmount,
			_minReturn,
			(_sellPath.length == 1 && _sellPath[0] == cDaiAddress)
				? receiver
				: address(this), // if the tokens that will received is cDai then return it directly to receiver
			msg.sender
		);
		if (
			_sellPath.length == 1 &&
			(_sellPath[0] == daiAddress || _sellPath[0] == cDaiAddress)
		) {
			if (_sellPath[0] == daiAddress) {
				result = _redeemDAI(result);

				require(
					ERC20(_sellPath[0]).transfer(receiver, result) == true,
					"Transfer failed"
				);
			}
		} else if (_sellPath[0] != cDaiAddress) {
			result = _redeemDAI(result);
			require(
				_sellPath[0] == daiAddress,
				"Input token for uniswap must be DAI"
			);
			uint256[] memory swap = _uniswapSwap(
				_sellPath,
				result,
				0,
				_minTokenReturn,
				receiver
			);

			result = swap[swap.length - 1];
			require(result > 0, "token selling failed");
		} else {
			revert();
		}

		emit TokenSold(
			msg.sender,
			_sellPath[_sellPath.length - 1],
			_gdAmount,
			contributionAmount,
			result,
			receiver
		);
		return result;
	}

	/**
	 * @dev Redeem cDAI to DAI
	 * @param _amount Amount of cDAI to redeem for DAI
	 * @return the amount of DAI received
	 */
	function _redeemDAI(uint256 _amount) internal returns (uint256) {
		cERC20 cDai = cERC20(cDaiAddress);
		ERC20 dai = ERC20(daiAddress);

		uint256 currDaiBalance = dai.balanceOf(address(this));

		uint256 daiResult = cDai.redeem(_amount);
		require(daiResult == 0, "cDai redeem failed");

		uint256 daiReturnAmount = dai.balanceOf(address(this)) - currDaiBalance;

		return daiReturnAmount;
	}

	/**
	 * @dev Convert Dai to CDAI and buy
	 * @param _amount DAI amount to convert
	 * @param _minReturn The minimum allowed return in GD tokens
	 * @param _targetAddress address of g$ and gdx recipient if different than msg.sender
	 * @return (gdReturn) How much GD tokens were transferred
	 */
	function _cdaiMintAndBuy(
		uint256 _amount,
		uint256 _minReturn,
		address _targetAddress
	) internal returns (uint256) {
		GoodReserveCDai reserve = GoodReserveCDai(
			nameService.getAddress("RESERVE")
		);
		cERC20 cDai = cERC20(cDaiAddress);

		uint256 currCDaiBalance = cDai.balanceOf(address(this));

		//Mint cDAIs
		uint256 cDaiResult = cDai.mint(_amount);
		require(cDaiResult == 0, "Minting cDai failed");

		uint256 cDaiInput = cDai.balanceOf(address(this)) - currCDaiBalance;
		cDai.transfer(address(reserve), cDaiInput);
		return reserve.buy(cDaiInput, _minReturn, _targetAddress);
	}

	/**
	@dev Helper to swap tokens in the Uniswap
	*@param _inputPath token to used for buy
	*@param _tokenAmount token amount to sell or buy
	*@param _minDAIAmount minimum DAI amount to get in swap transaction if transaction is buy
	*@param _minTokenReturn minimum token amount to get in swap transaction if transaction is sell
	*@param _receiver receiver of tokens after swap transaction
	 */
	function _uniswapSwap(
		address[] memory _inputPath,
		uint256 _tokenAmount,
		uint256 _minDAIAmount,
		uint256 _minTokenReturn,
		address _receiver
	) internal returns (uint256[] memory) {
		Uniswap uniswapContract = Uniswap(nameService.getAddress("UNISWAP_ROUTER"));
		address wETH = uniswapContract.WETH();
		uint256[] memory swap;
		bool isBuy = _inputPath[_inputPath.length - 1] == daiAddress; // if outputToken is dai then transaction is buy with any ERC20 token
		if (_inputPath[0] == address(0x0)) {
			_inputPath[0] = wETH;
			swap = uniswapContract.swapExactETHForTokens{ value: _tokenAmount }(
				_minDAIAmount,
				_inputPath,
				address(this),
				block.timestamp
			);
			return swap;
		} else if (_inputPath[_inputPath.length - 1] == address(0x0)) {
			_inputPath[_inputPath.length - 1] = wETH;
			swap = uniswapContract.swapExactTokensForETH(
				_tokenAmount,
				_minTokenReturn,
				_inputPath,
				_receiver,
				block.timestamp
			);
			return swap;
		} else {
			if (isBuy)
				ERC20(_inputPath[0]).approve(address(uniswapContract), _tokenAmount);
			swap = uniswapContract.swapExactTokensForTokens(
				_tokenAmount,
				isBuy ? _minDAIAmount : _minTokenReturn,
				_inputPath,
				_receiver,
				block.timestamp
			);
			return swap;
		}
	}
}