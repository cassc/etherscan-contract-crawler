// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../utils/DAOUpgradeableContract.sol";
import "../utils/NameService.sol";
import "../DAOStackInterfaces.sol";
import "../Interfaces.sol";
import "./GoodMarketMaker.sol";
import "./DistributionHelper.sol";

// import "hardhat/console.sol";

interface ContributionCalc {
	function calculateContribution(
		GoodMarketMaker _marketMaker,
		GoodReserveCDai _reserve,
		address _contributer,
		ERC20 _token,
		uint256 _gdAmount
	) external view returns (uint256);

	function setContributionRatio(uint256 _nom, uint256 _denom) external;
}

/**
@title Reserve based on cDAI and dynamic reserve ratio market maker
*/
contract GoodReserveCDai is
	DAOUpgradeableContract,
	ERC20PresetMinterPauserUpgradeable,
	GlobalConstraintInterface
{
	bytes32 public constant RESERVE_MINTER_ROLE =
		keccak256("RESERVE_MINTER_ROLE");

	/// @dev G$ minting cap;
	uint256 public cap;

	// The last block number which
	// `mintUBI` has been executed in
	uint256 public lastMinted;

	address public daiAddress;
	address public cDaiAddress;

	/// @dev merkleroot for GDX airdrop
	bytes32 public gdxAirdrop;

	/// @dev mark if user claimed his GDX
	mapping(address => bool) public isClaimedGDX;

	uint32 private unused_nonUbiBps; //keep for storage structure upgrades. //how much of expansion G$ to allocate for non Ubi causes
	DistributionHelper public distributionHelper; //in charge of distributing non UBI to different recipients

	bool public gdxDisabled;
	bool public discountDisabled;
	// Emits when new GD tokens minted
	event UBIMinted(
		//epoch of UBI
		uint256 indexed day,
		//the token paid as interest
		address indexed interestToken,
		//wei amount of interest paid in interestToken
		uint256 interestReceived,
		// Amount of GD tokens that was
		// added to the supply as a result
		// of `mintInterest`
		uint256 gdInterestMinted,
		// Amount of GD tokens that was
		// added to the supply as a result
		// of `mintExpansion`
		uint256 gdExpansionMinted,
		// Amount of GD tokens that was
		// minted to the `ubiCollector`
		uint256 gdUbiTransferred
	);

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

	event NonUBIMinted(
		address distributionHelper,
		uint256 amountMinted,
		bool distributionSucceeded
	);

	event DistributionHelperSet(address distributionHelper, uint32 bps);

	function initialize(
		INameService _ns,
		bytes32 _gdxAirdrop
	) public virtual initializer {
		__ERC20PresetMinterPauser_init("GDX", "G$X");
		setDAO(_ns);

		//fixed cdai/dai
		setAddresses();

		//gdx roles
		renounceRole(MINTER_ROLE, _msgSender());
		renounceRole(PAUSER_ROLE, _msgSender());
		renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(DEFAULT_ADMIN_ROLE, address(avatar));

		//mint access through reserve
		_setupRole(RESERVE_MINTER_ROLE, address(avatar)); //only Avatar can manage minters

		cap = 22 * 1e14; //22 trillion G$ cents

		gdxAirdrop = _gdxAirdrop;
	}

	/// @dev GDX decimals
	function decimals() public pure override returns (uint8) {
		return 2;
	}

	function setAddresses() public {
		daiAddress = nameService.getAddress("DAI");
		cDaiAddress = nameService.getAddress("CDAI");
		// Approve transfer to cDAI contract
		ERC20(daiAddress).approve(cDaiAddress, type(uint256).max);
	}

	/**
	 * @dev get current MarketMaker from name service
	 * The address of the market maker contract
	 * which makes the calculations and holds
	 * the token and accounts info (should be owned by the reserve)
	 */
	function getMarketMaker() public view returns (GoodMarketMaker) {
		return GoodMarketMaker(nameService.getAddress("MARKET_MAKER"));
	}

	/**
	 * @dev Converts cDai tokens to GD tokens and updates the bonding curve params.
	 * `buy` occurs only if the GD return is above the given minimum. It is possible
	 * to buy only with cDAI and when the contract is set to active. MUST call to
	 * cDAI `approve` prior this action to allow this contract to accomplish the
	 * conversion. Will not work when paused (enforced via _mintGoodDollars)
	 * @param _tokenAmount The amount of cDAI tokens that should be converted to GD tokens
	 * @param _minReturn The minimum allowed return in GD tokens
	 * @param _targetAddress address of g$ and gdx recipient if different than msg.sender
	 * @return (gdReturn) How much GD tokens were transferred
	 */
	function buy(
		uint256 _tokenAmount,
		uint256 _minReturn,
		address _targetAddress
	) external returns (uint256) {
		ERC20 buyWith = ERC20(cDaiAddress);
		uint256 gdReturn = getMarketMaker().buy(buyWith, _tokenAmount);
		_targetAddress = _targetAddress == address(0x0)
			? msg.sender
			: _targetAddress;
		address exchangeHelper = nameService.getAddress("EXCHANGE_HELPER");
		if (msg.sender != exchangeHelper)
			require(
				buyWith.transferFrom(msg.sender, address(this), _tokenAmount) == true,
				"transferFrom failed, make sure you approved input token transfer"
			);
		require(gdReturn >= _minReturn, "GD return must be above the minReturn");
		_mintGoodDollars(_targetAddress, gdReturn, true);
		//mint GDX
		_mintGDX(_targetAddress, gdReturn);

		emit TokenPurchased(
			msg.sender != exchangeHelper ? msg.sender : tx.origin,
			cDaiAddress,
			_tokenAmount,
			gdReturn,
			_targetAddress
		);
		return gdReturn;
	}

	/**
	 * @dev Mint rewards for staking contracts in G$ and update RR
	 * requires minting permissions which is enforced by _mintGoodDollars.
	 * Will not work when paused
	 * @param _to Receipent address for rewards
	 * @param _amount G$ amount to mint for rewards
	 */
	function mintRewardFromRR(
		address _token,
		address _to,
		uint256 _amount
	) external {
		getMarketMaker().mintFromReserveRatio(ERC20(_token), _amount);
		_mintGoodDollars(_to, _amount, false);
		//mint GDX
		_mintGDX(_to, _amount);
	}

	/**
	 * @dev sell helper function burns GD tokens and update the bonding curve params.
	 * `sell` occurs only if the token return is above the given minimum. Notice that
	 * there is a contribution amount from the given GD that remains in the reserve.
	 * Will not work when paused.
	 * @param _gdAmount The amount of GD tokens that should be converted to cDAI tokens
	 * @param _minReturn The minimum allowed `sellTo` tokens return
	 * @param _target address of the receiver of cDAI when sell G$
	 * @param _seller address of the seller when using helper contract
	 * @return (tokenReturn, contribution) (cDAI received, G$ exit contribution)
	 */
	function sell(
		uint256 _gdAmount,
		uint256 _minReturn,
		address _target,
		address _seller
	) external returns (uint256, uint256) {
		require(paused() == false, "paused");
		GoodMarketMaker mm = getMarketMaker();
		if (msg.sender != nameService.getAddress("EXCHANGE_HELPER")) {
			IGoodDollar(nameService.getAddress("GOODDOLLAR")).burnFrom(
				msg.sender,
				_gdAmount
			);
			_seller = msg.sender;
		}
		_target = _target == address(0x0) ? msg.sender : _target;
		//discount on exit contribution based on gdx

		uint256 discount;
		if (discountDisabled == false) {
			uint256 gdx = balanceOf(_seller);
			discount = gdx <= _gdAmount ? gdx : _gdAmount;

			//burn gdx used for discount
			if (discount > 0) _burn(_seller, discount);
		}

		uint256 contributionAmount = 0;
		uint256 gdAmountTemp = _gdAmount; // to prevent stack too deep errors
		if (discount < gdAmountTemp)
			contributionAmount = ContributionCalc(
				nameService.getAddress("CONTRIBUTION_CALCULATION")
			).calculateContribution(
					mm,
					this,
					_seller,
					ERC20(cDaiAddress),
					gdAmountTemp - discount
				);

		uint256 tokenReturn = mm.sellWithContribution(
			ERC20(cDaiAddress),
			gdAmountTemp,
			contributionAmount
		);
		require(
			tokenReturn >= _minReturn,
			"Token return must be above the minReturn"
		);
		require(
			cERC20(cDaiAddress).transfer(_target, tokenReturn),
			"cdai transfer failed"
		);

		emit TokenSold(
			_seller,
			cDaiAddress,
			_gdAmount,
			contributionAmount,
			tokenReturn,
			_target
		);

		return (tokenReturn, contributionAmount);
	}

	function currentPrice() public view returns (uint256) {
		return getMarketMaker().currentPrice(ERC20(cDaiAddress));
	}

	function currentPriceDAI() external view returns (uint256) {
		cERC20 cDai = cERC20(cDaiAddress);

		return (((currentPrice() * 1e10) * cDai.exchangeRateStored()) / 1e28); // based on https://compound.finance/docs#protocol-math
	}

	/**
	 * @dev helper to mint G$s
	 * @param _to the recipient of newly minted G$s
	 * @param _gdToMint how much G$ to mint
	 * @param _internalCall skip minting role validation for internal calls, used when "buying G$" to "allow" buyer to mint G$ in exchange for his cDAI
	 */
	function _mintGoodDollars(
		address _to,
		uint256 _gdToMint,
		bool _internalCall
	) internal {
		require(paused() == false, "paused");

		//enforce minting rules
		require(
			_internalCall ||
				_msgSender() == nameService.getAddress("FUND_MANAGER") ||
				hasRole(RESERVE_MINTER_ROLE, _msgSender()),
			"GoodReserve: not a minter"
		);

		require(
			IGoodDollar(nameService.getAddress("GOODDOLLAR")).totalSupply() +
				_gdToMint <=
				cap,
			"GoodReserve: cap enforced"
		);

		IGoodDollar(nameService.getAddress("GOODDOLLAR")).mint(_to, _gdToMint);
	}

	/// @dev helper to mint GDX to make _mint more verbose
	function _mintGDX(address _to, uint256 _gdx) internal {
		if (gdxDisabled == false) _mint(_to, _gdx);
	}

	/**
	 * @dev only FundManager or other with mint G$ permission can call this to trigger minting.
	 * Reserve sends UBI + interest to FundManager.
	 * @param _daiToConvert DAI amount to convert cDAI
	 * @param _startingCDAIBalance Initial cDAI balance before staking collect process start
	 * @param _interestToken The token that was transfered to the reserve
	 * @return gdUBI,interestInCdai how much GD UBI was minted and how much cDAI collected from staking contracts
	 */
	function mintUBI(
		uint256 _daiToConvert,
		uint256 _startingCDAIBalance,
		ERC20 _interestToken
	) external returns (uint256, uint256) {
		cERC20(cDaiAddress).mint(_daiToConvert);
		uint256 interestInCdai = _interestToken.balanceOf(address(this)) -
			_startingCDAIBalance;
		uint256 gdInterestToMint = getMarketMaker().mintInterest(
			_interestToken,
			interestInCdai
		);
		uint256 gdExpansionToMint = getMarketMaker().mintExpansion(_interestToken);

		lastMinted = block.number;
		uint256 gdUBI = gdInterestToMint + gdExpansionToMint;

		require(address(distributionHelper) != address(0), "helper not set");
		_mintGoodDollars(address(distributionHelper), gdUBI, false); //mintGoodDollars enforces that only minter can call mintUBI

		// if bridging fails this will revert. this is expected behavior
		distributionHelper.onDistribution(gdUBI);

		emit UBIMinted(
			lastMinted,
			address(_interestToken),
			interestInCdai,
			gdInterestToMint,
			gdExpansionToMint,
			gdUBI
		);

		return (gdUBI, interestInCdai);
	}

	/**
	 * @notice allows Avatar to change or set the distribution helper
	 * @param _helper address of distributionhelper contract
	 */
	function setDistributionHelper(DistributionHelper _helper) external {
		_onlyAvatar();
		distributionHelper = _helper;
		emit DistributionHelperSet(address(_helper), 10000);
	}

	/**
	 * @dev Allows the DAO to change the daily expansion rate
	 * it is calculated by _nom/_denom with e27 precision. Emits
	 * `ReserveRatioUpdated` event after the ratio has changed.
	 * Only Avatar can call this method.
	 * @param _nom The numerator to calculate the global `reserveRatioDailyExpansion` from
	 * @param _denom The denominator to calculate the global `reserveRatioDailyExpansion` from
	 */
	function setReserveRatioDailyExpansion(
		uint256 _nom,
		uint256 _denom
	) external {
		_onlyAvatar();
		getMarketMaker().setReserveRatioDailyExpansion(_nom, _denom);
	}

	//
	/**
	 * @dev Sets the GDX and discount disabled flags.
	 * @param _gdxDisabled Whether GDX minting is disabled or not.
	 * @param _discountDisabled Whether the discount for existing GDX holders is disabled or not.
	 */
	function setGDXDisabled(bool _gdxDisabled, bool _discountDisabled) external {
		_onlyAvatar();
		gdxDisabled = _gdxDisabled;
		discountDisabled = _discountDisabled;
	}

	/**
	 * @dev Remove minting rights after it has transferred the cDAI funds to `_avatar`
	 * Only the Avatar can execute this method
	 */
	function end() external {
		_onlyAvatar();
		// remaining cDAI tokens in the current reserve contract
		if (ERC20(cDaiAddress).balanceOf(address(this)) > 0) {
			require(
				ERC20(cDaiAddress).transfer(
					address(avatar),
					ERC20(cDaiAddress).balanceOf(address(this))
				),
				"recover transfer failed"
			);
		}

		//restore minting to avatar, so he can re-delegate it
		IGoodDollar gd = IGoodDollar(nameService.getAddress("GOODDOLLAR"));
		if (gd.isMinter(address(avatar)) == false) gd.addMinter(address(avatar));

		IGoodDollar(nameService.getAddress("GOODDOLLAR")).renounceMinter();
	}

	/**
	 * @dev method to recover any stuck erc20 tokens (ie compound COMP)
	 * @param _token the ERC20 token to recover
	 */
	function recover(ERC20 _token) external {
		_onlyAvatar();
		require(
			_token.transfer(address(avatar), _token.balanceOf(address(this))),
			"recover transfer failed"
		);
	}

	//no longer required all gdx was distributed
	// /**
	//  * @notice prove user balance in a specific blockchain state hash
	//  * @dev "rootState" is a special state that can be supplied once, and actually mints reputation on the current blockchain
	//  * @param _user the user to prove his balance
	//  * @param _gdx the balance we are prooving
	//  * @param _proof array of byte32 with proof data (currently merkle tree path)
	//  * @return true if proof is valid
	//  */

	// function claimGDX(
	// 	address _user,
	// 	uint256 _gdx,
	// 	bytes32[] memory _proof
	// ) public returns (bool) {
	// 	require(isClaimedGDX[_user] == false, "already claimed gdx");
	// 	bytes32 leafHash = keccak256(abi.encode(_user, _gdx));
	// 	bool isProofValid = MerkleProofUpgradeable.verify(
	// 		_proof,
	// 		gdxAirdrop,
	// 		leafHash
	// 	);

	// 	require(isProofValid, "invalid merkle proof");

	// 	_mintGDX(_user, _gdx);

	// 	isClaimedGDX[_user] = true;
	// 	return true;
	// }

	// implement minting constraints through the GlobalConstraintInterface interface. prevent any minting not through reserve
	function pre(
		address _scheme,
		bytes32 _hash,
		bytes32 _method
	) public pure override returns (bool) {
		_scheme;
		_hash;
		_method;
		if (_method == "mintTokens") return false;

		return true;
	}

	function when() public pure override returns (CallPhase) {
		return CallPhase.Pre;
	}
}