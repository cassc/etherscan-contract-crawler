pragma solidity 0.8.6;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/IAutoHedgeLeveragedPositionFactory.sol";

contract AutoHedgeLeveragedPositionFactory is
	Initializable,
	UUPSUpgradeable,
	OwnableUpgradeable,
	IAutoHedgeLeveragedPositionFactory
{
	function initialize(
		address beacon_,
		IFlashloanWrapper flw_,
		IMasterPriceOracle oracle_
	) public initializer {
		__Ownable_init_unchained();
		beacon = beacon_;
		flw = flw_;
		oracle = oracle_;
	}

	IFlashloanWrapper public override flw;
	address public beacon;
	IMasterPriceOracle public override oracle;
	mapping(address => mapping(address => address)) public leveragedPositions;

	function createLeveragedPosition(
		IComptroller comptroller,
		IAutoHedgeLeveragedPosition.TokensLev memory tokens
	) external override returns (address lvgPos) {
		address pair = address(tokens.pair);
		require(
			leveragedPositions[msg.sender][pair] == address(0),
			"AHLPFac: already have leveraged position"
		);

		bytes32 salt = keccak256(abi.encodePacked(msg.sender, pair));
		bytes memory data = abi.encodeWithSelector(
			IAutoHedgeLeveragedPosition.initialize.selector,
			address(this),
			comptroller,
			tokens
		);
		lvgPos = address(new BeaconProxy{salt: salt}(beacon, data));
		leveragedPositions[msg.sender][pair] = lvgPos;
		OwnableUpgradeable(lvgPos).transferOwnership(msg.sender);

		emit LeveragedPositionCreated(msg.sender, pair, lvgPos);
	}

	function setFlashloanWrapper(IFlashloanWrapper flw_) external onlyOwner {
		require(address(flw_) != address(0), "AHLPFac: invalid flashloan wrapper");
		flw = flw_;
	}

	function setOracle(IMasterPriceOracle oracle_) external onlyOwner {
		require(address(oracle_) != address(0), "AHLPFac: invalid oracle");
		oracle = oracle_;
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}
}