// SPDX-License-Identifier: LGPL-3.0
pragma solidity =0.8.10;

import "./Registry.sol";
import "./dapphub/DSProxyFactory.sol";
import "./dapphub/DSProxy.sol";
import "./Config.sol";
import "./CentralLogger.sol";
import "./CommunityAcknowledgement.sol";
import "./LiquityMath.sol";
import "./SqrtMath.sol";
import "./interfaces/ITroveManager.sol";
import "./interfaces/IHintHelpers.sol";
import "./interfaces/ISortedTroves.sol";
import "./interfaces/ICollSurplusPool.sol";


/// @title Stargate contract serves as a gateway and a gatekeeper into the APUS protocol ecosystem
/// @notice The main motivation of Stargate is to give user understandable transaction to sign (i.e. no bytecode giberish) 
/// and to chain common sequence of transactions thus saving gas.
/// @dev It encodes all arguments and calls given user's Smart Account proxy with any additional arguments
contract Stargate is LiquityMath, SqrtMath {

	/* solhint-disable var-name-mixedcase */

	/// @notice Registry's contracts IDs
	bytes32 private constant EXECUTOR_ID = keccak256("Executor");
	bytes32 private constant CONFIG_ID = keccak256("Config");
	bytes32 private constant AUTHORITY_ID = keccak256("Authority");
	bytes32 private constant COMMUNITY_ACKNOWLEDGEMENT_ID = keccak256("CommunityAcknowledgement");
	bytes32 private constant CENTRAL_LOGGER_ID = keccak256("CentralLogger");

	/// @notice APUS registry address
	address public immutable registry;

	// MakerDAO's deployed contracts - Proxy Factory
	// see https://changelog.makerdao.com/
	DSProxyFactory public immutable ProxyFactory;

	// L1 Liquity deployed contracts addresses
	// see https://docs.liquity.org/documentation/resources#contract-addresses
	ITroveManager public immutable TroveManager;
	IHintHelpers public immutable HintHelpers;
	ISortedTroves public immutable SortedTroves;
	ICollSurplusPool public immutable CollSurplusPool;


	/// @notice Event raised on Stargate when a new Smart Account is created. 
	/// Corresponding event is also raised on the Central Logger
	event SmartAccountCreated(
		address indexed owner,
		address indexed smartAccountAddress
	);


	/// @notice Modifier will fail if message sender is not the proxy owner
	/// @param _proxy Proxy address that must be owned
	modifier onlyProxyOwner(address payable _proxy) {
		require(DSProxy(_proxy).owner() == msg.sender, "Sender has to be proxy owner");
		_;
	}

	/* solhint-disable-next-line func-visibility */
	constructor(
		address _registry,
		address _troveManager,
		address _hintHelpers,
		address _sortedTroves,
		address _collSurplusPool,
		address _proxyFactory
	) {
		registry = _registry;
		TroveManager = ITroveManager(_troveManager);
		HintHelpers = IHintHelpers(_hintHelpers);
		SortedTroves = ISortedTroves(_sortedTroves);
		CollSurplusPool = ICollSurplusPool(_collSurplusPool);
		ProxyFactory = DSProxyFactory(_proxyFactory);
	}

	/// @notice Execute proxy call with encoded transaction data and eth value
	/// @dev Proxy delegates call to executor address which is obtained from registry contract
	/// @param _proxy Proxy address to execute encoded transaction
	/// @param _value Value of eth to transfer with function call
	/// @param _data Transaction data to execute
	function _execute(address payable _proxy, uint256 _value, bytes memory _data) internal onlyProxyOwner(_proxy) {
		DSProxy(_proxy).execute{ value: _value }(Registry(registry).getAddress(EXECUTOR_ID), _data);
	}

	/// @notice Execute proxy call with encoded transaction data and eth value by anyone
	/** 
	 * @dev Proxy delegates call to executor address which is obtained from registry contract
	 *
	 * This is the DANGEROUS version as it enables the proxy call to be performed by anyone!
	 *
	 * However suitable for cases when user wants to provide ETH from other (proxy non-owning) accounts.
	 */
	/// @param _proxy Proxy address to execute encoded transaction
	/// @param _value Value of eth to transfer with function call
	/// @param _data Transaction data to execute
	function _executeByAnyone(address payable _proxy, uint256 _value, bytes memory _data) internal {
		DSProxy(_proxy).execute{ value: _value }(Registry(registry).getAddress(EXECUTOR_ID), _data);
	}

	// Stargate MUST NOT be able to receive ETH from sender to itself
	// in 0.8.x function() is split to receive() and fallback(); if both are undefined -> tx reverts

	// ------------------------------------------ User functions ------------------------------------------


	/// @notice Creates the Smart Account directly. Its new address is emitted to the event.
	/// It is cheaper to open Smart Account while opening Credit Line wihin 1 transaction.
	function openSmartAccount() external {
		_openSmartAccount();
	}

	/// @notice Builds the new MakerDAO's proxy aka Smart Account with enabled calls from this Stargate
	function _openSmartAccount() internal returns (address payable) {
	
		// Deploy a new MakerDAO's proxy onto blockchain
		DSProxy smartAccount = ProxyFactory.build();

		// Enable Stargate's user functions to call the Smart Account	
		DSAuthority stargateAuthority = DSAuthority(Registry(registry).getAddress(AUTHORITY_ID));
		smartAccount.setAuthority(stargateAuthority); 

		// Set owner of MakerDAO's proxy aka Smart Account to be the user
		smartAccount.setOwner(msg.sender);

		// Emit centraly at this contract and the Central Logger
		emit SmartAccountCreated(msg.sender, address(smartAccount));
		CentralLogger logger = CentralLogger(Registry(registry).getAddress(CENTRAL_LOGGER_ID));
		logger.log(
			address(this), msg.sender, "openSmartAccount", abi.encode(smartAccount)
		);
				
		return payable(smartAccount);
	}

	/// @notice Get the gasless information on Credit Line (Liquity) status of the given Smart Account
	/// @param _smartAccount Smart Account address.
	/// @return status Status of the Credit Line within Liquity protocol, where:
	/// 0..nonExistent,
	/// 1..active,
	/// 2..closedByOwner,
	/// 3..closedByLiquidation,
	/// 4..closedByRedemption
	/// @return collateral ETH collateral.
	/// @return debtToRepay Total amount of LUSD needed to close the Credit Line (exluding the 200 LUSD liquidation reserve).
	/// @return debtComposite Composite debt including the liquidation reserve. Valid for LTV (CR) calculations.   
	function getCreditLineStatusLiquity(address payable _smartAccount) external view returns (
		uint8 status,
		uint256 collateral,
		uint256 debtToRepay, 
		uint256 debtComposite
	) {
		(debtComposite, collateral, , status, ) = TroveManager.Troves(_smartAccount);	
		debtToRepay = debtComposite > LIQUITY_LUSD_GAS_COMPENSATION ? debtComposite - LIQUITY_LUSD_GAS_COMPENSATION : 0;
	}

	/// @notice Calculates Liquity sorting hints based on the provided NICR
	function getLiquityHints(uint256 NICR) internal view returns (
		address upperHint,
		address lowerHint
	) {
		// Get an approximate address hint from the deployed HintHelper contract.
		uint256 numTroves = SortedTroves.getSize();
		uint256 numTrials = sqrt(numTroves) * 15;
		(address approxHint, , ) = HintHelpers.getApproxHint(NICR, numTrials, 0x41505553);

		// Use the approximate hint to get the exact upper and lower hints from the deployed SortedTroves contract
		(upperHint, lowerHint) = SortedTroves.findInsertPosition(NICR, approxHint, approxHint);
	}

	/// @notice Calculates LUSD expected debt to repay. 
	/// Includes _LUSDRequested, Adoption Contribution, Liquity protocol fee.
	/// Adoption Contribution reflects the Adoption Contribution Rate and Recognised Community Contributor Acknowledgement Rate if applicable.
	function getLiquityExpectedDebtToRepay(uint256 _LUSDRequested) internal view returns (uint256 expectedDebtToRepay) {
		uint16 applicableAcr;
		uint256 expectedLiquityProtocolRate;

		(applicableAcr, expectedLiquityProtocolRate) = getLiquityRates();

		uint256 neededLUSDAmount = calcNeededLiquityLUSDAmount(_LUSDRequested, expectedLiquityProtocolRate, applicableAcr);

		uint256 expectedLiquityProtocolFee = TroveManager.getBorrowingFeeWithDecay(neededLUSDAmount);

		expectedDebtToRepay = neededLUSDAmount + expectedLiquityProtocolFee;
	}

	/// @notice Calculates the rates related to Liquity for the msg.sender
	/// @return applicableAcr Adoption Contribution Rate with applied Recognised Community Contributor Acknowledgement Rate of msg.sender if applicable.
	/// @return expectedLiquityProtocolRate Current rate of the Liquity protocol
	function getLiquityRates() internal view returns (uint16 applicableAcr, uint256 expectedLiquityProtocolRate) {
		// Get and apply Recognised Community Contributor Acknowledgement Rate
		CommunityAcknowledgement ca = CommunityAcknowledgement(Registry(registry).getAddress(COMMUNITY_ACKNOWLEDGEMENT_ID));
		uint16 rccar = ca.getAcknowledgementRate(keccak256(abi.encodePacked(msg.sender)));

		Config config = Config(Registry(registry).getAddress(CONFIG_ID));

		applicableAcr = applyRccarOnAcr(rccar, config.adoptionContributionRate());

		expectedLiquityProtocolRate = TroveManager.getBorrowingRateWithDecay();
	}

	/// @notice Calculates the current rate for the msg.sender as related to Liquity and Adoption Contribution incl. RCCAR
	function userAdoptionRate() external view returns (uint256) {
		uint16 applicableAcr;
		uint256 expectedLiquityProtocolRate;

		(applicableAcr, expectedLiquityProtocolRate) = getLiquityRates();

		// Normalise applicable ACR 1e4 -> 1e18
        uint256 r = DECIMAL_PRECISION / ACR_DECIMAL_PRECISION * applicableAcr;

        // Apply Liquity protocol rate when applicable ACR is lower
        return r < expectedLiquityProtocolRate ? expectedLiquityProtocolRate : r;
	}

	/// @notice Makes a gasless calculation to get the data for the Credit Line's initial setup on Liquity protocol
    /// @param _LUSDRequested Requested LUSD amount to be taken by borrower. In e18 (1 LUSD = 1e18).
	///	  		Adoption Contribution including protocol's fees is applied in the form of additional debt.
    /// @param _collateralAmount Amount of ETH to be deposited into the Credit Line. In wei (1 ETH = 1e18).
	/// @return expectedDebtToRepay Total amount of LUSD needed to close the Credit Line (exluding the 200 LUSD liquidation reserve).
	/// @return liquidationReserve Liquidation gas reserve required by the Liquity protocol.
	/// @return expectedCompositeDebtLiquity Total debt of the new Credit Line including the liquidation reserve. Valid for LTV (CR) calculations.
	/// @return NICR Nominal Individual Collateral Ratio for this calculation as defined and used by Liquity protocol.
	/// @return upperHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
	/// @return lowerHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
    function calculateInitialLiquityParameters(uint256 _LUSDRequested, uint256 _collateralAmount) public view returns (
		uint256 expectedDebtToRepay,
		uint256 liquidationReserve,
		uint256 expectedCompositeDebtLiquity,
        uint256 NICR,
		address upperHint,
		address lowerHint
    ) {
		liquidationReserve = LIQUITY_LUSD_GAS_COMPENSATION;

		expectedDebtToRepay = getLiquityExpectedDebtToRepay(_LUSDRequested);

		expectedCompositeDebtLiquity = expectedDebtToRepay + LIQUITY_LUSD_GAS_COMPENSATION;

		// Get the nominal NICR of the new Liquity's trove
		NICR = _collateralAmount * 1e20 / expectedCompositeDebtLiquity;

		(upperHint, lowerHint) = getLiquityHints(NICR);
    }

	/// @notice Makes a gasless calculation to get the data for the Credit Line's adjustement on Liquity protocol
	/// @param _isDebtIncrease Indication whether _LUSDRequestedChange increases debt (true), decreases debt(false) or does not impact debt (false).
	/// @param _LUSDRequestedChange Amount of LUSD to be returned or further borrowed. The increase or decrease is indicated by _isDebtIncrease.
	///			Adoption Contribution including protocol's fees is applied in the form of additional debt in case of requested debt increase.
	/// @param _isCollateralIncrease Indication whether _LUSDRequestedChange increases debt (true), decreases debt(false) or does not impact debt (false).
	/// @param _collateralChange Amount of ETH collateral to be withdrawn or added. The increase or decrease is indicated by _isCollateralIncrease.
	/// @return newCollateral Calculated future collateral.
	/// @return expectedDebtToRepay Total future amount of LUSD needed to close the Credit Line (exluding the 200 LUSD liquidation reserve).
	/// @return liquidationReserve Liquidation gas reserve required by the Liquity protocol.
	/// @return expectedCompositeDebtLiquity Total future debt of the new Credit Line including the liquidation reserve. Valid for LTV (CR) calculations.
	/// @return NICR Nominal Individual Collateral Ratio for this calculation as defined and used by Liquity protocol.
	/// @return upperHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
	/// @return lowerHint Calculated hint for gas optimalization of the Liquity protocol when opening new Credit Line with openCreditLineLiquity.
	/// @dev bools and uints are used to avoid typecasting and overflow issues and to explicitely signal the direction
	function calculateChangedLiquityParameters(
		bool _isDebtIncrease,
		uint256 _LUSDRequestedChange,
		bool _isCollateralIncrease,
		uint256 _collateralChange,
		address payable _smartAccount
	)  public view returns (
		uint256 newCollateral,
		uint256 expectedDebtToRepay,
		uint256 liquidationReserve,
		uint256 expectedCompositeDebtLiquity,
        uint256 NICR,
		address upperHint,
		address lowerHint
    ) {
		liquidationReserve = LIQUITY_LUSD_GAS_COMPENSATION;

		// Get the current LUSD debt and ETH collateral
		(uint256 currentCompositeDebt, uint256 currentCollateral, , ) = TroveManager.getEntireDebtAndColl(_smartAccount);

		uint256 currentDebtToRepay = currentCompositeDebt - LIQUITY_LUSD_GAS_COMPENSATION;

		if (_isCollateralIncrease) {
			newCollateral = currentCollateral + _collateralChange;
		} else {
			newCollateral = currentCollateral - _collateralChange;
		}

		if (_isDebtIncrease) {
			uint256 additionalDebtToRepay = getLiquityExpectedDebtToRepay(_LUSDRequestedChange);
			expectedDebtToRepay = currentDebtToRepay + additionalDebtToRepay;
		} else {
			expectedDebtToRepay = currentDebtToRepay - _LUSDRequestedChange;
		}

		expectedCompositeDebtLiquity = expectedDebtToRepay + LIQUITY_LUSD_GAS_COMPENSATION;

		// Get the nominal NICR of the new Liquity's trove
		NICR = newCollateral * 1e20 / expectedCompositeDebtLiquity;

		(upperHint, lowerHint) = getLiquityHints(NICR);

	}

	/// @notice Opens a new Credit Line using Liquity protocol by depositing ETH collateral and borrowing LUSD.
	/// Creates the new Smart Account (MakerDAO's proxy) if requested.
	/// Use calculateInitialLiquityParameters for gasless calculation of proper Hints for _LUSDRequested.
	/// @param _LUSDRequested Amount of LUSD caller wants to borrow and withdraw. In e18 (1 LUSD = 1e18).
	/// @param _LUSDTo Address that will receive the generated LUSD. Can be different to save gas on transfer.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateInitialLiquityParameters for gasless calculation of proper Hints for _LUSDRequested.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateInitialLiquityParameters for gasless calculation of proper Hints for _LUSDRequested.
	/// @param _smartAccount Smart Account address. When 0x0000...00 sender requests to open a new Smart Account.
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Value is amount of ETH to deposit into Liquity protocol.
	function openCreditLineLiquity(uint256 _LUSDRequested, address _LUSDTo, address _upperHint, address _lowerHint, address payable _smartAccount) external payable {

		// By submitting 0x00..0 as the smartAccount address the caller wants to open a new Smart Account during this 1 transaction and thus saving gas.
		_smartAccount = (_smartAccount == address(0)) ? _openSmartAccount() : _smartAccount;

		_execute(_smartAccount, msg.value, abi.encodeWithSignature(
			"openCreditLineLiquity(uint256,address,address,address,address)",
			_LUSDRequested, _LUSDTo, _upperHint, _lowerHint, msg.sender
		));

	}

	/// @notice Allows a borrower to repay all LUSD debt, withdraw all their ETH collateral, and close their Credit Line on Liquity protocol.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _collateralTo Address that will receive the withdrawn ETH.
	/// @param _smartAccount Smart Account address
	function closeCreditLineLiquity(address _LUSDFrom, address payable _collateralTo, address payable _smartAccount) public {

		_execute(_smartAccount, 0, 
			abi.encodeWithSignature(
				"closeCreditLineLiquity(address,address,address)",
				_LUSDFrom,
				_collateralTo, 
				msg.sender
		));

	}

	/// @notice Allows a borrower to repay all LUSD debt, withdraw all their ETH collateral, and close their Credit Line on Liquity protocol using EIP2612 Permit.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _collateralTo Address that will receive the withdrawn ETH.
	/// @param v EIP2612 secp256k1 permit signature part
	/// @param r EIP2612 secp256k1 permit signature part
	/// @param s EIP2612 secp256k1 permit signature part
	/// @param _smartAccount Smart Account address
	function closeCreditLineLiquityWithPermit(address _LUSDFrom, address payable _collateralTo, uint8 v, bytes32 r, bytes32 s, address payable _smartAccount) external {

		_execute(_smartAccount, 0, abi.encodeWithSignature(
			"closeCreditLineLiquityWithPermit(address,address,uint8,bytes32,bytes32,address)",
			_LUSDFrom, _collateralTo, v, r, s, msg.sender
		));

	}

	/// @notice Enables a borrower to simultaneously change both their collateral and debt.
	/// Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _isDebtIncrease Indication whether _LUSDRequestedChange increases debt (true), decreases debt(false) or does not impact debt (false).
	/// @param _LUSDRequestedChange Amount of LUSD to be returned or further borrowed.
	///			The increase or decrease is indicated by _isDebtIncrease.
	///			Adoption Contribution and protocol's fees are applied in the form of additional debt in case of requested debt increase.
	/// @param _LUSDAddress Address where the LUSD is being pulled from in case of to repaying debt.
	/// Or address that will receive the generated LUSD in case of increasing debt.
	/// Approval of LUSD transfers for given Smart Account is required in case of repaying debt.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw. MUST be 0 if ETH is provided to increase collateral.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _smartAccount Smart Account address
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Hints should reflect calculated neededLUSDAmount instead of _LUSDRequestedChange
	/// @dev Value is amount of ETH to deposit into Liquity protocol
	function adjustCreditLineLiquity(
		bool _isDebtIncrease,
		uint256 _LUSDRequestedChange,
		address _LUSDAddress,
		uint256 _collWithdrawal,
		address payable _collateralTo,
		address _upperHint, address _lowerHint,
		address payable _smartAccount) external payable {

		_execute(_smartAccount, msg.value, abi.encodeWithSignature(
			"adjustCreditLineLiquity(bool,uint256,address,uint256,address,address,address,address)",
			_isDebtIncrease, _LUSDRequestedChange, _LUSDAddress, _collWithdrawal, _collateralTo, _upperHint, _lowerHint, msg.sender
		));

	}

	/// @notice Enables a borrower to simultaneously change both their collateral and decrease debt providing LUSD from ANY ADDRESS using EIP2612 Permit. 
	/// Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// It is useful only when the debt decrease is requested while working with collateral.
	/// In all other cases [adjustCreditLineLiquity()] MUST be used. It is cheaper on gas.
	/// @param _LUSDRequestedChange Amount of LUSD to be returned.
	/// @param _LUSDFrom Address where the LUSD is being pulled from. Can be ANY ADDRESS with enough LUSD.
	/// Approval of LUSD transfers for given Smart Account is ensured by the offchain signature from that address.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw. MUST be 0 if ETH is provided to increase collateral.
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param v EIP2612 secp256k1 permit signature part
	/// @param r EIP2612 secp256k1 permit signature part
	/// @param s EIP2612 secp256k1 permit signature part
	/// @param _smartAccount Smart Account address
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Value is amount of ETH to deposit into Liquity protocol
	function adjustCreditLineLiquityWithPermit(
		uint256 _LUSDRequestedChange,
		address _LUSDFrom,
		uint256 _collWithdrawal,
		address payable _collateralTo,
		address _upperHint, address _lowerHint,
		uint8 v, bytes32 r, bytes32 s,
		address payable _smartAccount) external payable {

		_execute(_smartAccount, msg.value, abi.encodeWithSignature(
			"adjustCreditLineLiquityWithPermit(uint256,address,uint256,address,address,address,uint8,bytes32,bytes32,address)",
			_LUSDRequestedChange, _LUSDFrom, _collWithdrawal, _collateralTo, _upperHint, _lowerHint, v, r, s, msg.sender
		));

	}

	/// @notice Gasless check if there is anything to be claimed after the forced closure of the Liquity Credit Line
	function checkClaimableCollateralLiquity(address _smartAccount) external view returns (uint256) {
		return CollSurplusPool.getCollateral(_smartAccount);
	}

	/// @notice Claims remaining collateral from the user's closed Credit Line (Liquity protocol) due to a redemption or a liquidation.
	/// @param _collateralTo Address that will receive the claimed collateral ETH.
	/// @param _smartAccount Smart Account address
	function claimRemainingCollateralLiquity(address payable _collateralTo, address payable _smartAccount) external {
		_execute(_smartAccount, 0, abi.encodeWithSignature(
			"claimRemainingCollateralLiquity(address,address)",
			_collateralTo,
			msg.sender
		));
	}


	/// @notice Allows ANY ADDRESS (calling and paying) to add ETH collateral to borrower's Credit Line (Liquity protocol) and thus increase CR (decrease LTV ratio).
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _smartAccount Smart Account address
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	function addCollateralLiquity(address _upperHint, address _lowerHint, address payable _smartAccount) external payable {

		// Must be executable by anyone in order to be able to provide ETH by addresses, which do not own smart account proxy
		_executeByAnyone(_smartAccount, msg.value, abi.encodeWithSignature(
			"addCollateralLiquity(address,address,address)",
			_upperHint, _lowerHint, msg.sender
		));
	}

	/// @notice Withdraws amount of ETH collateral from the Credit Line and transfer to _collateralTo address.
	/// @param _collWithdrawal Amount of ETH collateral to withdraw
	/// @param _collateralTo Address that will receive the withdrawn collateral ETH
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints.
	/// @param _smartAccount Smart Account address
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	function withdrawCollateralLiquity(uint256 _collWithdrawal, address payable _collateralTo, address _upperHint, address _lowerHint, address payable _smartAccount) external {

		_execute(_smartAccount, 0, abi.encodeWithSignature(
			"withdrawCollateralLiquity(uint256,address,address,address,address)",
			_collWithdrawal, _collateralTo, _upperHint, _lowerHint, msg.sender
		));

	}

	/// @notice Issues amount of LUSD from the liquity's protocol to the provided address.
	/// This increases the debt on the Credit Line, decreases CR (increases LTV).
	/// @param _LUSDRequestedChange Amount of LUSD to further borrow.
	/// @param _LUSDTo Address that will receive the generated LUSD. When 0 msg.sender is used.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _smartAccount Smart Account address
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	/// @dev Hints should reflect calculated new debt instead of _LUSDRequestedChange
	/// @dev This is facade to adjustCreditLineLiquity
	function borrowLUSDLiquity(uint256 _LUSDRequestedChange, address _LUSDTo, address _upperHint, address _lowerHint, address payable _smartAccount) external {

		_execute(_smartAccount, 0, abi.encodeWithSignature(
			"adjustCreditLineLiquity(bool,uint256,address,uint256,address,address,address,address)",
			true, _LUSDRequestedChange, _LUSDTo, 0, msg.sender, _upperHint, _lowerHint, msg.sender
//			_isDebtIncrease, _LUSDRequestedChange, _LUSDAddress, _collWithdrawal, _collateralTo, _upperHint, _lowerHint, msg.sender
		));

	}

	/// @notice Enables credit line owner to partially repay the debt from ANY ADDRESS by the given amount of LUSD.
	/// Approval of LUSD transfers for given Smart Account is required.
	/// Cannot repay below 2000 LUSD composite debt. Use closeCreditLineLiquity to repay whole debt instead.
	/// @param _LUSDRequestedChange Amount of LUSD to be repaid in e18 (1 LUSD = 1e18). Repaying is subject to leaving 2000 LUSD min. debt in the Liquity protocol.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _smartAccount Smart Account address.
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	function repayLUSDLiquity(uint256 _LUSDRequestedChange, address _LUSDFrom, address _upperHint, address _lowerHint, address payable _smartAccount) external {

		_execute(_smartAccount, 0, abi.encodeWithSignature(
			"repayLUSDLiquity(uint256,address,address,address,address)",
			_LUSDRequestedChange, _LUSDFrom, _upperHint, _lowerHint, msg.sender
		));

	}

	/// @notice Enables credit line owner to partially repay the debt from ANY ADDRESS by the given amount of LUSD using EIP2612 Permit.
	/// Approval of LUSD transfers for given Smart Account is ensured by the offchain signature.
	/// Cannot repay below 2000 LUSD composite debt. Use closeCreditLineLiquity to repay whole debt instead.
	/// @param _LUSDRequestedChange Amount of LUSD to be repaid in e18 (1 LUSD = 1e18). Repaying is subject to leaving 2000 LUSD min. debt in the Liquity protocol.
	/// @param _LUSDFrom Address where the LUSD is being pulled from to repay debt.
	/// @param _upperHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param _lowerHint For gas optimalisation when using Liquity protocol. Use calculateChangedLiquityParameters for gasless calculation of proper Hints for _LUSDRequestedChange.
	/// @param v EIP2612 secp256k1 permit signature part
	/// @param r EIP2612 secp256k1 permit signature part
	/// @param s EIP2612 secp256k1 permit signature part
	/// @param _smartAccount Smart Account address.
	/// @dev Hints explained: https://github.com/liquity/dev#supplying-hints-to-trove-operations
	function repayLUSDLiquityWithPermit(uint256 _LUSDRequestedChange, address _LUSDFrom, address _upperHint, address _lowerHint, uint8 v, bytes32 r, bytes32 s, address payable _smartAccount) external {

		_execute(_smartAccount, 0, abi.encodeWithSignature(
			"repayLUSDLiquityWithPermit(uint256,address,address,address,uint8,bytes32,bytes32,address)",
			_LUSDRequestedChange, _LUSDFrom, _upperHint, _lowerHint, v, r, s, msg.sender
		));

	}

}