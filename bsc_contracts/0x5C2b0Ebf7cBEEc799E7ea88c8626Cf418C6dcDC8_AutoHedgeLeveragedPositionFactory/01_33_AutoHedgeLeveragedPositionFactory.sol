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
		IMasterPriceOracle oracle_,
		IComptroller comptroller_
	) public initializer {
		__Ownable_init_unchained();
		beacon = beacon_;

		setFlashloanWrapper(flw_);
		setOracle(oracle_);
		setComptroller(comptroller_);
	}

	IFlashloanWrapper public override flw;
	address public beacon;
	IMasterPriceOracle public override oracle;
	mapping(address => mapping(address => address)) public leveragedPositions;
	IComptroller public override comptroller;

	function createLeveragedPosition(IAutoHedgeLeveragedPosition.TokensLev memory tokens)
		external
		override
		returns (address lvgPos)
	{
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

	function setFlashloanWrapper(IFlashloanWrapper flw_) public onlyOwner {
		require(address(flw_) != address(0), "AHLPFac: invalid flw");

		flw = flw_;

		emit FlashloanWrapperUpdated(address(flw));
	}

	function setOracle(IMasterPriceOracle oracle_) public onlyOwner {
		require(address(oracle_) != address(0), "AHLPFac: invalid oracle");

		oracle = oracle_;

		emit OracleUpdated(address(oracle));
	}

	function setComptroller(IComptroller comptroller_) public onlyOwner {
		require(address(comptroller_) != address(0), "AHLPFac: invalid comptroller");

		comptroller = comptroller_;

		emit ComptrollerUpdated(address(comptroller));
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}
}