// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "../OwnedWithInit.sol";
import "../interfaces/IPositionalMarket.sol";
import "../interfaces/IOracleInstance.sol";

// Libraries
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";

// Internal references
import "./PositionalMarketManager.sol";
import "./Position.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";

contract PositionalMarket is OwnedWithInit, IPositionalMarket {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint;

    /* ========== TYPES ========== */

    struct Options {
        Position up;
        Position down;
    }

    struct Times {
        uint maturity;
        uint expiry;
    }

    struct OracleDetails {
        bytes32 key;
        uint strikePrice;
        uint finalPrice;
        bool customMarket;
        address iOracleInstanceAddress;
    }

    struct PositionalMarketParameters {
        address owner;
        IERC20 sUSD;
        IPriceFeed priceFeed;
        address creator;
        bytes32 oracleKey;
        uint strikePrice;
        uint[2] times; // [maturity, expiry]
        uint deposit; // sUSD deposit
        address up;
        address down;
        address thalesAMM;
    }

    /* ========== STATE VARIABLES ========== */

    Options public options;
    Times public override times;
    OracleDetails public oracleDetails;
    PositionalMarketManager.Fees public override fees;
    IPriceFeed public priceFeed;
    IERC20 public sUSD;

    // `deposited` tracks the sum of all deposits.
    // This must explicitly be kept, in case tokens are transferred to the contract directly.
    uint public override deposited;
    uint public initialMint;
    address public override creator;
    bool public override resolved;

    /* ========== CONSTRUCTOR ========== */

    bool public initialized = false;

    function initialize(PositionalMarketParameters calldata _parameters) external {
        require(!initialized, "Positional Market already initialized");
        initialized = true;
        initOwner(_parameters.owner);
        sUSD = _parameters.sUSD;
        priceFeed = _parameters.priceFeed;
        creator = _parameters.creator;

        oracleDetails = OracleDetails(_parameters.oracleKey, _parameters.strikePrice, 0, false, address(0));

        times = Times(_parameters.times[0], _parameters.times[1]);

        deposited = _parameters.deposit;
        initialMint = _parameters.deposit;

        // Instantiate the options themselves
        options.up = Position(_parameters.up);
        options.down = Position(_parameters.down);

        options.up.initialize("Position Up", "UP", _parameters.thalesAMM);
        options.down.initialize("Position Down", "DOWN", _parameters.thalesAMM);
        if (initialMint > 0) {
            require(
                !_manager().onlyAMMMintingAndBurning() || msg.sender == _manager().getThalesAMM(),
                "Only allowed from ThalesAMM"
            );
            _mint(creator, initialMint);
        }

        // Note: the ERC20 base contract does not have a constructor, so we do not have to worry
        // about initializing its state separately
    }

    /// @notice phase returns market phase
    /// @return Phase
    function phase() external view override returns (Phase) {
        if (!_matured()) {
            return Phase.Trading;
        }
        if (!_expired()) {
            return Phase.Maturity;
        }
        return Phase.Expiry;
    }

    /// @notice oraclePriceAndTimestamp returns oracle key price and last updated timestamp
    /// @return price updatedAt
    function oraclePriceAndTimestamp() external view override returns (uint price, uint updatedAt) {
        return _oraclePriceAndTimestamp();
    }

    /// @notice oraclePrice returns oracle key price
    /// @return price
    function oraclePrice() external view override returns (uint price) {
        return _oraclePrice();
    }

    /// @notice canResolve checks if market can be resolved
    /// @return bool
    function canResolve() public view override returns (bool) {
        return !resolved && _matured();
    }

    /// @notice result calculates market result based on market strike price
    /// @return Side
    function result() external view override returns (Side) {
        return _result();
    }

    /// @notice balancesOf returns balances of an account
    /// @return up down
    function balancesOf(address account) external view override returns (uint up, uint down) {
        return _balancesOf(account);
    }

    /// @notice totalSupplies returns total supplies of op and down options
    /// @return up down
    function totalSupplies() external view override returns (uint up, uint down) {
        return (options.up.totalSupply(), options.down.totalSupply());
    }

    /// @notice getMaximumBurnable returns maximum burnable amount of an account
    /// @param account address of the account
    /// @return amount
    function getMaximumBurnable(address account) external view override returns (uint amount) {
        return _getMaximumBurnable(account);
    }

    /// @notice getOptions returns up and down positions
    /// @return up down
    function getOptions() external view override returns (IPosition up, IPosition down) {
        up = options.up;
        down = options.down;
    }

    /// @notice getOracleDetails returns data from oracle source
    /// @return key strikePrice finalPrice
    function getOracleDetails()
        external
        view
        override
        returns (
            bytes32 key,
            uint strikePrice,
            uint finalPrice
        )
    {
        key = oracleDetails.key;
        strikePrice = oracleDetails.strikePrice;
        finalPrice = oracleDetails.finalPrice;
    }

    /// @notice requireUnpaused ensures that manager is not paused
    function requireUnpaused() external view {
        _requireManagerNotPaused();
    }

    /// @notice mint mints up and down tokens
    /// @param value to mint options for
    function mint(uint value) external override duringMinting {
        require(
            !_manager().onlyAMMMintingAndBurning() || msg.sender == _manager().getThalesAMM(),
            "Only allowed from ThalesAMM"
        );
        if (value == 0) {
            return;
        }

        _mint(msg.sender, value);

        _incrementDeposited(value);
        _manager().transferSusdTo(msg.sender, address(this), _manager().transformCollateral(value));
    }

    /// @notice burnOptionsMaximum burns option tokens based on maximum burnable account amount
    function burnOptionsMaximum() external override {
        require(
            !_manager().onlyAMMMintingAndBurning() || msg.sender == _manager().getThalesAMM(),
            "Only allowed from ThalesAMM"
        );
        _burnOptions(msg.sender, _getMaximumBurnable(msg.sender));
    }

    /// @notice burnOptions burns option tokens based on amount
    function burnOptions(uint amount) external override {
        require(
            !_manager().onlyAMMMintingAndBurning() || msg.sender == _manager().getThalesAMM(),
            "Only allowed from ThalesAMM"
        );
        _burnOptions(msg.sender, amount);
    }

    /// @notice resolve function for resolving market if possible
    function resolve() external onlyOwner afterMaturity managerNotPaused {
        require(canResolve(), "Can not resolve market");
        uint price;
        uint updatedAt;

        (price, updatedAt) = _oraclePriceAndTimestamp();
        oracleDetails.finalPrice = price;

        resolved = true;

        emit MarketResolved(_result(), price, updatedAt, deposited, 0, 0);
    }

    /// @notice exerciseOptions is used for exercising options from resolved market
    function exerciseOptions() external override afterMaturity returns (uint) {
        // The market must be resolved if it has not been.
        if (!resolved) {
            _manager().resolveMarket(address(this));
        }

        // If the account holds no options, revert.
        (uint upBalance, uint downBalance) = _balancesOf(msg.sender);
        require(upBalance != 0 || downBalance != 0, "Nothing to exercise");

        // Each option only needs to be exercised if the account holds any of it.
        if (upBalance != 0) {
            options.up.exercise(msg.sender);
        }
        if (downBalance != 0) {
            options.down.exercise(msg.sender);
        }

        // Only pay out the side that won.
        uint payout = (_result() == Side.Up) ? upBalance : downBalance;
        emit OptionsExercised(msg.sender, payout);
        if (payout != 0) {
            _decrementDeposited(payout);
            sUSD.transfer(msg.sender, _manager().transformCollateral(payout));
        }
        return payout;
    }

    /// @notice expire is used for exercising options from resolved market
    function expire(address payable beneficiary) external onlyOwner {
        require(_expired(), "Unexpired options remaining");
        emit Expired(beneficiary);
        _selfDestruct(beneficiary);
    }

    /// @notice _priceFeed internal function returns PriceFeed contract address
    /// @return IPriceFeed
    function _priceFeed() internal view returns (IPriceFeed) {
        return priceFeed;
    }

    /// @notice _manager internal function returns PositionalMarketManager contract address
    /// @return PositionalMarketManager
    function _manager() internal view returns (PositionalMarketManager) {
        return PositionalMarketManager(owner);
    }

    /// @notice _matured internal function checks if market is matured
    /// @return bool
    function _matured() internal view returns (bool) {
        return times.maturity < block.timestamp;
    }

    /// @notice _expired internal function checks if market is expired
    /// @return bool
    function _expired() internal view returns (bool) {
        return resolved && (times.expiry < block.timestamp || deposited == 0);
    }

    /// @notice _oraclePrice internal function returns oracle key price from source
    /// @return price
    function _oraclePrice() internal view returns (uint price) {
        return _priceFeed().rateForCurrency(oracleDetails.key);
    }

    /// @notice _oraclePriceAndTimestamp internal function returns oracle key price and last updated timestamp from source
    /// @return price updatedAt
    function _oraclePriceAndTimestamp() internal view returns (uint price, uint updatedAt) {
        return _priceFeed().rateAndUpdatedTime(oracleDetails.key);
    }

    /// @notice _result internal function calculates market result based on market strike price
    /// @return Side
    function _result() internal view returns (Side) {
        uint price;
        if (resolved) {
            price = oracleDetails.finalPrice;
        } else {
            price = _oraclePrice();
        }

        return oracleDetails.strikePrice <= price ? Side.Up : Side.Down;
    }

    /// @notice _balancesOf internal function gets account balances of up and down tokens
    /// @param account address of an account
    /// @return up down
    function _balancesOf(address account) internal view returns (uint up, uint down) {
        return (options.up.getBalanceOf(account), options.down.getBalanceOf(account));
    }

    /// @notice _getMaximumBurnable internal function gets account maximum burnable amount
    /// @param account address of an account
    /// @return amount
    function _getMaximumBurnable(address account) internal view returns (uint amount) {
        (uint upBalance, uint downBalance) = _balancesOf(account);
        return (upBalance > downBalance) ? downBalance : upBalance;
    }

    /// @notice _incrementDeposited internal function increments deposited value
    /// @param value increment value
    /// @return _deposited
    function _incrementDeposited(uint value) internal returns (uint _deposited) {
        _deposited = deposited.add(value);
        deposited = _deposited;
        _manager().incrementTotalDeposited(value);
    }

    /// @notice _decrementDeposited internal function decrements deposited value
    /// @param value decrement value
    /// @return _deposited
    function _decrementDeposited(uint value) internal returns (uint _deposited) {
        _deposited = deposited.sub(value);
        deposited = _deposited;
        _manager().decrementTotalDeposited(value);
    }

    /// @notice _requireManagerNotPaused internal function ensures that manager is not paused
    function _requireManagerNotPaused() internal view {
        require(!_manager().paused(), "This action cannot be performed while the contract is paused");
    }

    /// @notice _mint internal function mints up and down tokens
    /// @param amount value to mint options for
    function _mint(address minter, uint amount) internal {
        options.up.mint(minter, amount);
        options.down.mint(minter, amount);

        emit Mint(Side.Up, minter, amount);
        emit Mint(Side.Down, minter, amount);
    }

    /// @notice _burnOptions internal function for burning up and down tokens
    /// @param account address of an account
    /// @param amount burning amount
    function _burnOptions(address account, uint amount) internal {
        require(amount > 0, "Can not burn zero amount!");
        require(_getMaximumBurnable(account) >= amount, "There is not enough options!");

        // decrease deposit
        _decrementDeposited(amount);

        // decrease up and down options
        options.up.exerciseWithAmount(account, amount);
        options.down.exerciseWithAmount(account, amount);

        // transfer balance
        sUSD.transfer(account, _manager().transformCollateral(amount));

        // emit events
        emit OptionsBurned(account, amount);
    }

    /// @notice _selfDestruct internal function for market self desctruct
    /// @param beneficiary address of a market
    function _selfDestruct(address payable beneficiary) internal {
        uint _deposited = deposited;
        if (_deposited != 0) {
            _decrementDeposited(_deposited);
        }

        // Transfer the balance rather than the deposit value in case there are any synths left over
        // from direct transfers.
        uint balance = sUSD.balanceOf(address(this));
        if (balance != 0) {
            sUSD.transfer(beneficiary, balance);
        }

        // Destroy the option tokens before destroying the market itself.
        options.up.expire(beneficiary);
        options.down.expire(beneficiary);
        selfdestruct(beneficiary);
    }

    modifier duringMinting() {
        require(!_matured(), "Minting inactive");
        _;
    }

    modifier afterMaturity() {
        require(_matured(), "Not yet mature");
        _;
    }

    modifier managerNotPaused() {
        _requireManagerNotPaused();
        _;
    }

    /* ========== EVENTS ========== */

    event Mint(Side side, address indexed account, uint value);
    event MarketResolved(
        Side result,
        uint oraclePrice,
        uint oracleTimestamp,
        uint deposited,
        uint poolFees,
        uint creatorFees
    );

    event OptionsExercised(address indexed account, uint value);
    event OptionsBurned(address indexed account, uint value);
    event Expired(address beneficiary);
}