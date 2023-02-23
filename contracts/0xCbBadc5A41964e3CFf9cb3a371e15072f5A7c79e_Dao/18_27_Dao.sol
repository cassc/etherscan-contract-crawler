// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DaoSetters.sol";
import "./Bonding.sol";
import "../external/AggregatorV3Interface.sol";
import "../pool/IPool.sol";

contract Comptroller is Setters {
    using SafeMath for uint256;

    function setPrice(Decimal.D256 memory price) internal {
        _state.price = price;
    }

    function getPrice() external view returns (uint256) {
        return _state.price.value;
    }

    function mintToAccount(address account, uint256 amount) internal {
        if(amount > 0){
            dollar().mint(account, amount);
        }
        balanceCheck();
    }

    function burnFromAccount(address account, uint256 amount) internal {
        dollar().transferFrom(account, address(this), amount);
        dollar().burn(amount);

        balanceCheck();
    }

    function increaseSupply(uint256 newSupply) internal returns (uint256) {
        // 0-a. Pay out to lp Pool
        uint256 lpPoolReward = newSupply
            .mul(Constants.getOraclePoolRatio())
            .div(100);
        mintToPool(lpPoolReward);

        // 0-b. Pay out to dontdiememe pool
        uint256 dontDieMemePoolReward = newSupply
            .mul(Constants.getDontDieMemePoolRatio())
            .div(100);
        mintToDontDieMemePool(dontDieMemePoolReward);

        uint256 rewards = lpPoolReward.add(dontDieMemePoolReward);
        newSupply = newSupply > rewards ? newSupply.sub(rewards) : 0;

        // 1. Payout to DAO
        if (totalBonded() == 0) {
            newSupply = 0;
        }
        if (newSupply > 0) {
            mintToDAO(newSupply);
        }

        balanceCheck();

        return newSupply.add(rewards);
    }

    function balanceCheck() private view {
        require(
            dollar().balanceOf(address(this)) >=
                totalBonded().add(totalStaged()).sub(totalCouponStaged()),
            "Inconsistent balances"
        );
    }

    function mintToDAO(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(address(this), amount);
            incrementTotalBonded(amount);
        }
    }

    function mintToDontDieMemePool(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(dontdiememe(), amount);
        }
    }

    function mintToPool(uint256 amount) private {
        if (amount > 0) {
            dollar().mint(pool(), amount);
            IPool(pool()).distributeReward(amount);
        }
    }
}

// Regulator
contract Regulator is Comptroller {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    event SupplyIncrease(
        uint256 indexed epoch,
        uint256 price,
        uint256 newBonded
    );
    event SupplyNeutral(uint256 indexed epoch);

    function regulatorStep() internal {
        Decimal.D256 memory price = oracleCapture();
        setPrice(price);
        growSupply(price);

        emit SupplyNeutral(epoch());
    }

    function growSupply(Decimal.D256 memory price) private {
        Decimal.D256 memory delta = limit(price);
        uint256 newSupply = delta.mul(totalNet()).asUint256();
        uint256 newBonded = increaseSupply(newSupply);
        emit SupplyIncrease(epoch(), price.value, newBonded);
    }

    function limit(Decimal.D256 memory price)
        private
        pure
        returns (Decimal.D256 memory)
    {
        Decimal.D256 memory supplyChangeDivisor = Constants
            .getSupplyChangeDivisor();
        Decimal.D256 memory supplyChangeLimit = Constants
            .getSupplyChangeLimit();
        Decimal.D256 memory supplyChangeMin = Constants.getSupplyChangeMin();

        if (price.greaterThan(Decimal.one())) {
            Decimal.D256 memory delta = price.sub(Decimal.one()).div(
                supplyChangeDivisor
            );
            if (delta.greaterThan(supplyChangeLimit)) return supplyChangeLimit;
            else if (delta.greaterThan(supplyChangeMin)) return delta;
            else return supplyChangeMin;
        }
        return supplyChangeMin;
    }

    function oracleCapture() private returns (Decimal.D256 memory) {
        (Decimal.D256 memory price, bool valid) = oracle().capture();

        if (bootstrapping()) {
            return Constants.getBootstrappingPrice();
        }
        if (!valid) {
            return Decimal.one();
        }

        return price;
    }
}

contract Dao is
    State,
    Bonding,
    Regulator,
    Initializable,
    AccessControlEnumerableUpgradeable
{
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant ADVANCE_ROLE = keccak256("ADVANCE_ROLE");
    uint256 private ADVANCE_INCENTIVE;
    bool private isPreMinted;

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);
    event Incentivization(address indexed account, uint256 amount);

    function initialize(
        address dollar,
        address oracle,
        address pool,
        address dontdiememe,
        address coupon
    ) public initializer {
        __AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender);

        //set dollar oracle pool
        _state.provider.dollar = IDollar(dollar);
        _state.provider.oracle = IOracle(oracle);
        _state.provider.pool = pool;
        _state.provider.dontdiememe = dontdiememe;
        _state.provider.coupon = ICoupon(coupon);

        ADVANCE_INCENTIVE = 150e18;
    }

    function setDollar(address dollar) external onlyRole(GOVERNOR_ROLE) {
        _state.provider.dollar = IDollar(dollar);
    }

    function setOracle(address oracle) external onlyRole(GOVERNOR_ROLE) {
        _state.provider.oracle = IOracle(oracle);
    }

    function setPool(address pool) external onlyRole(GOVERNOR_ROLE) {
        _state.provider.pool = pool;
    }

    function setDontdiememe(address dontdiememe) external onlyRole(GOVERNOR_ROLE) {
        _state.provider.dontdiememe = dontdiememe;
    }

    function setCoupon(address coupon) external onlyRole(GOVERNOR_ROLE) {
        _state.provider.coupon = ICoupon(coupon);
    }

    function setAdvance(uint256 advanceIncentive) external onlyRole(GOVERNOR_ROLE) {
        ADVANCE_INCENTIVE = advanceIncentive;
    }

    function advance() external incentivized{
        Bonding.bondingStep();
        Regulator.regulatorStep();

        emit Advance(epoch(), block.number, block.timestamp);
    }

    modifier incentivized() {
        mintToAccount(msg.sender, ADVANCE_INCENTIVE);
        emit Incentivization(msg.sender, ADVANCE_INCENTIVE);
        _;
    }
}