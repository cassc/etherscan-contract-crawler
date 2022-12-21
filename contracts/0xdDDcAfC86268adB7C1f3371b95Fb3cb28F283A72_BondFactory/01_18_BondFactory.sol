// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IBondFactory.sol";
import "./interfaces/IBond.sol";
import "./libs/Adminable.sol";
import "./libs/DuetTransparentUpgradeableProxy.sol";
import "@private/shared/libs/Keepable.sol";

contract BondFactory is IBondFactory, Initializable, Adminable, Keepable {
    /**
     * @dev factor for percentage that described in integer. It makes 10000 means 100%, and 20 means 0.2%;
     *      Calculation formula: x * percentage / PERCENTAGE_FACTOR
     */
    uint16 public constant PERCENTAGE_FACTOR = 10000;
    // kind => impl
    mapping(string => address) public bondImplementations;
    // kind => bond addresses
    mapping(string => address[]) public kindBondsMapping;
    // series => bond addresses
    mapping(string => address[]) public seriesBondsMapping;
    string[] public bondKinds;
    string[] public bondSeries;
    string[] public bondIsins;

    // isin => bond address
    mapping(string => address) public isinBondMapping;

    // bond => price
    mapping(address => BondPrice) public bondPrices;

    event PriceUpdated(address indexed bondToken, uint256 price, uint256 previousPrice);
    event BondImplementationUpdated(string kind, address implementation, address previousImplementation);
    event BondCreated(address bondToken);
    event BondRemoved(address bondToken);

    modifier onlyAdminOrKeeper() virtual {
        require(msg.sender == admin || msg.sender == keeper, "UNAUTHORIZED");

        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin_) public initializer {
        _setAdmin(admin_);
    }

    function setKeeper(address newKeeper) external onlyAdmin {
        _setKeeper(newKeeper);
    }

    function verifyPrice(BondPrice memory price) public view returns (BondPrice memory) {
        require(
            price.price > 0 && price.bid > 0 && price.ask > 0 && price.ask >= price.bid,
            "BondFactory: INVALID_PRICE"
        );
        return price;
    }

    function createBond(
        string memory kind_,
        string memory name_,
        string memory symbol_,
        BondPrice calldata initialPrice_,
        uint256 initialGrant_,
        string memory series_,
        IERC20MetadataUpgradeable underlyingToken_,
        uint256 maturity_,
        string memory isin_
    ) external onlyAdmin returns (address bondTokenAddress) {
        address proxyAdmin = address(this);
        address bondImpl = bondImplementations[kind_];
        require(bondImpl != address(0), "BondFactory: Invalid bond implementation");
        require(isinBondMapping[isin_] == address(0), "A bond for this isin already exists");
        verifyPrice(initialPrice_);
        bytes memory proxyData;
        DuetTransparentUpgradeableProxy proxy = new DuetTransparentUpgradeableProxy(bondImpl, proxyAdmin, proxyData);
        bondTokenAddress = address(proxy);
        IBond(bondTokenAddress).initialize(name_, symbol_, series_, address(this), underlyingToken_, maturity_, isin_);
        isinBondMapping[isin_] = bondTokenAddress;

        if (seriesBondsMapping[series_].length == 0) {
            bondSeries.push(series_);
        }
        bondIsins.push(isin_);
        setPrice(bondTokenAddress, initialPrice_.price, initialPrice_.bid, initialPrice_.ask);
        if (initialGrant_ > 0) {
            grant(bondTokenAddress, initialGrant_);
        }
        seriesBondsMapping[series_].push(bondTokenAddress);
        kindBondsMapping[kind_].push(bondTokenAddress);
        emit BondCreated(bondTokenAddress);
    }

    function getBondKinds() external view returns (string[] memory) {
        return bondKinds;
    }

    function getKindBondLength(string memory kind_) external view returns (uint256) {
        return kindBondsMapping[kind_].length;
    }

    function getBondSeries() external view returns (string[] memory) {
        return bondSeries;
    }

    function getBondIsins() external view returns (string[] memory) {
        return bondIsins;
    }

    function getSeriesBondLength(string memory series_) external view returns (uint256) {
        return seriesBondsMapping[series_].length;
    }

    function setBondImplementation(
        string calldata kind_,
        address impl_,
        bool upgradeDeployed_
    ) external onlyAdmin {
        if (bondImplementations[kind_] == address(0)) {
            bondKinds.push(kind_);
        }
        emit BondImplementationUpdated(kind_, impl_, bondImplementations[kind_]);
        bondImplementations[kind_] = impl_;
        if (!upgradeDeployed_) {
            return;
        }
        for (uint256 i = 0; i < kindBondsMapping[kind_].length; i++) {
            DuetTransparentUpgradeableProxy(payable(kindBondsMapping[kind_][i])).upgradeTo(impl_);
        }
    }

    function setPrice(
        address bondToken_,
        uint256 price,
        uint256 bid,
        uint256 ask
    ) public onlyAdminOrKeeper {
        emit PriceUpdated(bondToken_, price, bondPrices[bondToken_].price);
        bondPrices[bondToken_] = BondPrice({ price: price, bid: bid, ask: ask, lastUpdated: block.timestamp });
        verifyPrice(bondPrices[bondToken_]);
    }

    function getPrice(address bondToken_) public view returns (BondPrice memory) {
        BondPrice memory price = bondPrices[bondToken_];
        verifyPrice(price);
        return price;
    }

    function priceDecimals() public view returns (uint256) {
        return 8;
    }

    function priceFactor() public view returns (uint256) {
        return 10**priceDecimals();
    }

    function underlyingOut(address bondToken_, uint256 amount_) external onlyAdmin {
        IBond(bondToken_).underlyingOut(amount_, msg.sender);
    }

    function grant(address bondToken_, uint256 amount_) public onlyAdmin {
        IBond(bondToken_).grant(amount_);
    }

    function removeBond(IBond bondToken_) external onlyAdmin {
        require(bondToken_.totalSupply() <= 0, "BondFactory: CANT_REMOVE");
        string memory kind = bondToken_.kind();
        string memory series = bondToken_.series();
        bytes32 isin = keccak256(bytes(bondToken_.isin()));

        address bondTokenAddress = address(bondToken_);

        uint256 kindBondLength = kindBondsMapping[kind].length;
        for (uint256 i = 0; i < kindBondLength; i++) {
            if (kindBondsMapping[kind][i] != bondTokenAddress) {
                continue;
            }
            kindBondsMapping[kind][i] = kindBondsMapping[kind][kindBondLength - 1];
            kindBondsMapping[kind].pop();
            break;
        }

        uint256 seriesBondLength = seriesBondsMapping[series].length;
        for (uint256 j = 0; j < seriesBondLength; j++) {
            if (seriesBondsMapping[series][j] != bondTokenAddress) {
                continue;
            }
            seriesBondsMapping[series][j] = seriesBondsMapping[series][seriesBondLength - 1];
            seriesBondsMapping[series].pop();
            break;
        }

        uint256 isinsLength = bondIsins.length;
        for (uint256 k = 0; k < isinsLength; k++) {
            if (keccak256(bytes(bondIsins[k])) != isin) {
                continue;
            }
            bondIsins[k] = bondIsins[isinsLength - 1];
            bondIsins.pop();
            break;
        }

        delete isinBondMapping[bondToken_.isin()];

        emit BondRemoved(bondTokenAddress);
    }

    function emergencyWithdraw(
        IBond bond_,
        IERC20MetadataUpgradeable token_,
        uint256 amount_
    ) external onlyAdmin {
        bond_.emergencyWithdraw(token_, msg.sender, amount_);
    }

    function calculateFee(string memory kind_, uint256 tradingAmount) public view returns (uint256) {
        // TODO
        return 0;
    }
}