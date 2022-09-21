// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../strategy/CurveVault.sol";
import "../interfaces/IGaugeController.sol";
import "../interfaces/ILiquidityGaugeStrat.sol";

interface CurveLiquidityGauge {
	function lp_token() external view returns (address);
}

/**
 * @title Factory contract usefull for creating new curve vaults that supports LP related
 * to the curve platform, and the gauge multi rewards attached to it.
 */

contract CurveVaultFactory {
	using ClonesUpgradeable for address;

	address public vaultImpl = address(new CurveVault());
	address public gaugeImpl;
	address public constant GOVERNANCE = 0xF930EBBd05eF8b25B1797b9b2109DDC9B0d43063;
	address public constant GAUGE_CONTROLLER = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB;
	address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
	address public constant VESDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;
	address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
	address public constant VEBOOST = 0xD67bdBefF01Fc492f1864E61756E5FBB3f173506;
	address public constant CLAIM_REWARDS = 0x633120100e108F03aCe79d6C78Aac9a56db1be0F;
	address public curveStrategy;
	address public sdtDistributor;

	event VaultDeployed(address proxy, address lpToken, address impl);
	event GaugeDeployed(address proxy, address stakeToken, address impl);

	constructor(
		address _gaugeImpl,
		address _curveStrategy,
		address _sdtDistributor
	) {
		gaugeImpl = _gaugeImpl;
		curveStrategy = _curveStrategy;
		sdtDistributor = _sdtDistributor;
	}

	/**
	 * @dev Function to clone Curve Vault and its gauge contracts
	 * @param _crvGaugeAddress curve liqudity gauge address
	 */
	function cloneAndInit(address _crvGaugeAddress) public {
		uint256 weight = IGaugeController(GAUGE_CONTROLLER).get_gauge_weight(_crvGaugeAddress);
		require(weight > 0, "must have weight");
		address vaultLpToken = CurveLiquidityGauge(_crvGaugeAddress).lp_token();
		string memory tokenSymbol = ERC20Upgradeable(vaultLpToken).symbol();
		uint256 liquidityGaugeType;
		// view function called only to recognize the gauge type
		bytes memory data = abi.encodeWithSignature("reward_tokens(uint256)", 0);
		(bool success, ) = _crvGaugeAddress.call(data);
		if (!success) {
			liquidityGaugeType = 1; // no extra reward
		}
		address vaultImplAddress = _cloneAndInitVault(
			vaultImpl,
			ERC20Upgradeable(vaultLpToken),
			GOVERNANCE,
			string(abi.encodePacked("sd", tokenSymbol, " Vault")),
			string(abi.encodePacked("sd", tokenSymbol, "-vault"))
		);
		address gaugeImplAddress = _cloneAndInitGauge(gaugeImpl, vaultImplAddress, GOVERNANCE, tokenSymbol);
		CurveVault(vaultImplAddress).setLiquidityGauge(gaugeImplAddress);
		CurveVault(vaultImplAddress).setGovernance(GOVERNANCE);
		CurveStrategy(curveStrategy).toggleVault(vaultImplAddress);
		CurveStrategy(curveStrategy).setGauge(vaultLpToken, _crvGaugeAddress);
		CurveStrategy(curveStrategy).setMultiGauge(_crvGaugeAddress, gaugeImplAddress);
		CurveStrategy(curveStrategy).manageFee(CurveStrategy.MANAGEFEE.PERFFEE, _crvGaugeAddress, 200); //%2 default
		CurveStrategy(curveStrategy).manageFee(CurveStrategy.MANAGEFEE.VESDTFEE, _crvGaugeAddress, 500); //%5 default
		CurveStrategy(curveStrategy).manageFee(CurveStrategy.MANAGEFEE.ACCUMULATORFEE, _crvGaugeAddress, 800); //%8 default
		CurveStrategy(curveStrategy).manageFee(CurveStrategy.MANAGEFEE.CLAIMERREWARD, _crvGaugeAddress, 50); //%0.5 default
		CurveStrategy(curveStrategy).setLGtype(_crvGaugeAddress, liquidityGaugeType);
		ILiquidityGaugeStrat(gaugeImplAddress).add_reward(CRV, curveStrategy);
		ILiquidityGaugeStrat(gaugeImplAddress).set_claimer(CLAIM_REWARDS);
		ILiquidityGaugeStrat(gaugeImplAddress).commit_transfer_ownership(GOVERNANCE);
	}

	/**
	 * @dev Internal function to clone the vault
	 * @param _impl address of contract to clone
	 * @param _lpToken curve LP token address
	 * @param _governance governance address
	 * @param _name vault name
	 * @param _symbol vault symbol
	 */
	function _cloneAndInitVault(
		address _impl,
		ERC20Upgradeable _lpToken,
		address _governance,
		string memory _name,
		string memory _symbol
	) internal returns (address) {
		CurveVault deployed = cloneVault(
			_impl,
			_lpToken,
			keccak256(abi.encodePacked(_governance, _name, _symbol, curveStrategy))
		);
		deployed.init(_lpToken, address(this), _name, _symbol, CurveStrategy(curveStrategy));
		return address(deployed);
	}

	/**
	 * @dev Internal function to clone the gauge multi rewards
	 * @param _impl address of contract to clone
	 * @param _stakingToken sd LP token address
	 * @param _governance governance address
	 * @param _symbol gauge symbol
	 */
	function _cloneAndInitGauge(
		address _impl,
		address _stakingToken,
		address _governance,
		string memory _symbol
	) internal returns (address) {
		ILiquidityGaugeStrat deployed = cloneGauge(_impl, _stakingToken, keccak256(abi.encodePacked(_governance, _symbol)));
		deployed.initialize(_stakingToken, address(this), SDT, VESDT, VEBOOST, sdtDistributor, _stakingToken, _symbol);
		return address(deployed);
	}

	/**
	 * @dev Internal function that deploy and returns a clone of vault impl
	 * @param _impl address of contract to clone
	 * @param _lpToken curve LP token address
	 * @param _paramsHash governance+name+symbol+strategy parameters hash
	 */
	function cloneVault(
		address _impl,
		ERC20Upgradeable _lpToken,
		bytes32 _paramsHash
	) internal returns (CurveVault) {
		address deployed = address(_impl).cloneDeterministic(keccak256(abi.encodePacked(address(_lpToken), _paramsHash)));
		emit VaultDeployed(deployed, address(_lpToken), _impl);
		return CurveVault(deployed);
	}

	/**
	 * @dev Internal function that deploy and returns a clone of gauge impl
	 * @param _impl address of contract to clone
	 * @param _stakingToken sd LP token address
	 * @param _paramsHash governance+name+symbol parameters hash
	 */
	function cloneGauge(
		address _impl,
		address _stakingToken,
		bytes32 _paramsHash
	) internal returns (ILiquidityGaugeStrat) {
		address deployed = address(_impl).cloneDeterministic(
			keccak256(abi.encodePacked(address(_stakingToken), _paramsHash))
		);
		emit GaugeDeployed(deployed, _stakingToken, _impl);
		return ILiquidityGaugeStrat(deployed);
	}

	/**
	 * @dev Function that predicts the future address passing the parameters
	 * @param _impl address of contract to clone
	 * @param _token token (LP or sdLP)
	 * @param _paramsHash parameters hash
	 */
	function predictAddress(
		address _impl,
		IERC20 _token,
		bytes32 _paramsHash
	) public view returns (address) {
		return address(_impl).predictDeterministicAddress(keccak256(abi.encodePacked(address(_token), _paramsHash)));
	}
}