// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IDollar.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IPool.sol";
import "../interfaces/ICollateralReserve.sol";
import "../interfaces/IBasisAsset.sol";

//import "hardhat/console.sol";

contract Pool is OwnableUpgradeable, ReentrancyGuard, IPool {
    using SafeERC20 for IERC20;

    /* ========== ADDRESSES ================ */
    address public dollar; // BCAKE ::: (1 BCAKE) = (0.4 CAKE) + (0.4-CAKE in WBNB) + (0.3-CAKE in BCXS) if CR = 0.8
    address public share; // BCXS

    address public mainCollateral; // CAKE
    address public secondCollateral; // WBNB

    address public treasury;

    address public oracleDollar;
    address public oracleShare;
    address public oracleMainCollateral;
    address public oracleSecondCollateral;

    /* ========== STATE VARIABLES ========== */

    mapping(address => uint256) public redeem_main_collateral_balances;
    mapping(address => uint256) public redeem_second_collateral_balances;
    mapping(address => uint256) public redeem_share_balances;

    uint256 private unclaimed_pool_main_collateral_;
    uint256 private unclaimed_pool_second_collateral_;
    uint256 private unclaimed_pool_share_;

    mapping(address => uint256) public last_redeemed;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e18;

    // Number of seconds to wait before being able to collectRedemption()
    uint256 public redemption_delay;

    // AccessControl state variables
    bool public mint_paused = false;
    bool public redeem_paused = false;
    bool public contract_allowed = false;
    mapping(address => bool) public whitelisted;

    uint256 private targetCollateralRatio_;

    uint256 public updateStepTargetCR;

    uint256 public updateCoolingTimeTargetCR;

    uint256 public lastUpdatedTargetCR;

    mapping(address => bool) public strategist;

    uint256 public constant T_ZERO_TIMESTAMP = 1669852800; // (Thursday, 1 December 2022 00:00:00 UTC)

    mapping(uint256 => uint256) public totalMintedHourly; // hour_index => total_minted
    mapping(uint256 => uint256) public totalMintedDaily; // day_index => total_minted
    mapping(uint256 => uint256) public totalRedeemedHourly; // hour_index => total_redeemed
    mapping(uint256 => uint256) public totalRedeemedDaily; // day_index => total_redeemed

    uint256 private mintingLimitOnce_;
    uint256 private mintingLimitHourly_;
    uint256 private mintingLimitDaily_;

    /* =================== Added variables (need to keep orders for proxy to work) =================== */
    // ...

    /* ========== EVENTS ========== */

    event TreasuryUpdated(address indexed newTreasury);
    event StrategistStatusUpdated(address indexed account, bool status);
    event MintPausedUpdated(bool mint_paused);
    event RedeemPausedUpdated(bool redeem_paused);
    event ContractAllowedUpdated(bool contract_allowed);
    event WhitelistedUpdated(address indexed account, bool whitelistedStatus);
    event TargetCollateralRatioUpdated(uint256 targetCollateralRatio_);
    event Mint(address indexed account, uint256 dollarAmount, uint256 mainCollateralAmount, uint256 secondCollateralAmount, uint256 shareAmount, uint256 shareFee);
    event Redeem(address indexed account, uint256 dollarAmount, uint256 mainCollateralAmount, uint256 secondCollateralAmount, uint256 shareAmount, uint256 shareFee);
    event CollectRedemption(address indexed account, uint256 mainCollateralAmount, uint256 secondCollateralAmount, uint256 shareAmount);

    /* ========== MODIFIERS ========== */

    modifier onlyTreasury() {
        require(msg.sender == treasury, "!treasury");
        _;
    }

    modifier onlyTreasuryOrOwner() {
        require(msg.sender == treasury || msg.sender == owner(), "!treasury && !owner");
        _;
    }

    modifier onlyStrategist() {
        require(strategist[msg.sender] || msg.sender == treasury || msg.sender == owner(), "!strategist && !treasury && !owner");
        _;
    }

    modifier checkContract() {
        if (!contract_allowed && !whitelisted[msg.sender]) {
            uint256 size;
            address addr = msg.sender;
            assembly {
                size := extcodesize(addr)
            }
            require(size == 0, "contract not allowed");
            require(tx.origin == msg.sender, "contract not allowed");
        }
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _dollar,
        address _share,
        address _mainCollateral,
        address _secondCollateral,
        address _treasury
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();

        dollar = _dollar; // BCAKE
        share = _share; // BCXS
        mainCollateral = _mainCollateral; // CRO
        secondCollateral = _secondCollateral; // WBNB

        treasury = _treasury;

        unclaimed_pool_main_collateral_ = 0;
        unclaimed_pool_second_collateral_ = 0;
        unclaimed_pool_share_ = 0;

        targetCollateralRatio_ = 9000; // 90%

        lastUpdatedTargetCR = block.timestamp;

        updateStepTargetCR = 25; // 0.25%

        updateCoolingTimeTargetCR = 6000; // to update every 2 hours

        mintingLimitOnce_ = 50000 ether;
        mintingLimitHourly_ = 100000 ether;
        mintingLimitDaily_ = 1000000 ether;

        redemption_delay = 10;
        mint_paused = false;
        redeem_paused = false;
        contract_allowed = false;
    }

    /* ========== VIEWS ========== */

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        return (
            unclaimed_pool_main_collateral_, // unclaimed amount of CAKE
            unclaimed_pool_second_collateral_, // unclaimed amount of WBNB
            unclaimed_pool_share_, // unclaimed amount of SHARE
            PRICE_PRECISION, // collateral price
            mint_paused,
            redeem_paused
        );
    }

    function targetCollateralRatio() external override view returns (uint256) {
        return targetCollateralRatio_;
    }

    function unclaimed_pool_main_collateral() external override view returns (uint256) {
        return unclaimed_pool_main_collateral_;
    }

    function unclaimed_pool_second_collateral() external override view returns (uint256) {
        return unclaimed_pool_second_collateral_;
    }

    function unclaimed_pool_share() external override view returns (uint256) {
        return unclaimed_pool_share_;
    }

    function collateralReserve() public view returns (address) {
        return ITreasury(treasury).collateralReserve();
    }

    function getMainCollateralPrice() public view override returns (uint256) {
        address _oracle = oracleMainCollateral;
        return (_oracle == address(0)) ? PRICE_PRECISION : IOracle(oracleMainCollateral).consult();
    }

    function getSecondCollateralPrice() public view override returns (uint256) {
        address _oracle = oracleSecondCollateral;
        return (_oracle == address(0)) ? 1 : IOracle(oracleSecondCollateral).consult();
    }

    function getDollarPrice() public view override returns (uint256) {
        address _oracle = oracleDollar;
        return (_oracle == address(0)) ? PRICE_PRECISION : IOracle(_oracle).consult(); // DOLLAR: default = 1 CAKE
    }

    function getSharePrice() public view override returns (uint256) {
        address _oracle = oracleShare;
        return (_oracle == address(0)) ? PRICE_PRECISION / 100 : IOracle(_oracle).consult(); // BCXS: default = 0.01 CAKE
    }

    function getTrueSharePrice() public view returns (uint256) {
        address _oracle = oracleShare;
        return (_oracle == address(0)) ? PRICE_PRECISION / 100 : IOracle(_oracle).consultTrue(); // BCXS: default = 0.01 CAKE
    }

    function getRedemptionOpenTime(address _account) public view override returns (uint256) {
        uint256 _last_redeemed = last_redeemed[_account];
        return (_last_redeemed == 0) ? 0 : _last_redeemed + redemption_delay;
    }

    function mintingLimitOnce() public view returns (uint256 _limit) {
        _limit = mintingLimitOnce_;
        if (_limit > 0) {
            _limit = Math.max(_limit, IERC20(dollar).totalSupply() * 25 / 10000); // Max(50k, 0.25% of total supply)
        }
    }

    function mintingLimitHourly() public override view returns (uint256 _limit) {
        _limit = mintingLimitHourly_;
        if (_limit > 0) {
            _limit = Math.max(_limit, IERC20(dollar).totalSupply() * 50 / 10000); // Max(100K, 0.5% of total supply)
        }
    }

    function mintingLimitDaily() public override view returns (uint256 _limit) {
        _limit = mintingLimitDaily_;
        if (_limit > 0) {
            _limit = Math.max(_limit, IERC20(dollar).totalSupply() * 500 / 10000); // Max(1M, 5% of total supply)
        }
    }

    function calcMintableDollarHourly() public override view returns (uint256 _limit) {
        uint256 _mintingLimitHourly = mintingLimitHourly();
        if (_mintingLimitHourly == 0) {
            _limit = 1000000 ether;
        } else {
            uint256 _hourIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 hours;
            uint256 _totalMintedHourly = totalMintedHourly[_hourIndex];
            if (_totalMintedHourly < _mintingLimitHourly) {
                _limit = _mintingLimitHourly - _totalMintedHourly;
            }
        }
    }

    function calcMintableDollarDaily() public override view returns (uint256 _limit) {
        uint256 _mintingLimitDaily = mintingLimitDaily();
        if (_mintingLimitDaily == 0) {
            _limit = 1000000 ether;
        } else {
            uint256 _dayIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 days;
            uint256 _totalMintedDaily = totalMintedDaily[_dayIndex];
            if (_totalMintedDaily < _mintingLimitDaily) {
                _limit = _mintingLimitDaily - _totalMintedDaily;
            }
        }
    }

    function calcMintableDollar() public override view returns (uint256 _dollarAmount) {
        uint256 _mintingLimitOnce = mintingLimitOnce();
        _dollarAmount = (_mintingLimitOnce == 0) ? 1000000 ether : _mintingLimitOnce;
        if (_dollarAmount > 0) _dollarAmount = Math.min(_dollarAmount, calcMintableDollarHourly());
        if (_dollarAmount > 0) _dollarAmount = Math.min(_dollarAmount, calcMintableDollarDaily());
    }

    function calcRedeemableDollarHourly() public override view returns (uint256 _limit) {
        uint256 _mintingLimitHourly = mintingLimitHourly();
        if (_mintingLimitHourly == 0) {
            _limit = 1000000 ether;
        } else {
            uint256 _hourIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 hours;
            uint256 _totalRedeemedHourly = totalRedeemedHourly[_hourIndex];
            if (_totalRedeemedHourly < _mintingLimitHourly) {
                _limit = _mintingLimitHourly - _totalRedeemedHourly;
            }
        }
    }

    function calcRedeemableDollarDaily() public override view returns (uint256 _limit) {
        uint256 _mintingLimitDaily = mintingLimitDaily();
        if (_mintingLimitDaily == 0) {
            _limit = 1000000 ether;
        } else {
            uint256 _dayIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 days;
            uint256 _totalRedeemedDaily = totalRedeemedDaily[_dayIndex];
            if (_totalRedeemedDaily < _mintingLimitDaily) {
                _limit = _mintingLimitDaily - _totalRedeemedDaily;
            }
        }
    }

    function calcRedeemableDollar() public override view returns (uint256 _dollarAmount) {
        uint256 _mintingLimitOnce = mintingLimitOnce();
        _dollarAmount = (_mintingLimitOnce == 0) ? 1000000 ether : _mintingLimitOnce;
        if (_dollarAmount > 0) _dollarAmount = Math.min(_dollarAmount, calcRedeemableDollarHourly());
        if (_dollarAmount > 0) _dollarAmount = Math.min(_dollarAmount, calcRedeemableDollarDaily());
    }

    function calcMintInput(uint256 _dollarAmount) public view override returns (uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee) {
        uint256 _second_collateral_price = getSecondCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _targetCollateralRatio = targetCollateralRatio_;

        // _dollarFullValue = _dollarAmount (1:1)
        uint256 _collateralFullValue = _dollarAmount * _targetCollateralRatio / 10000;
        _mainCollateralAmount = _collateralFullValue / 2;
        _secondCollateralAmount = _mainCollateralAmount * PRICE_PRECISION / _second_collateral_price;

        uint256 _required_shareValue = _dollarAmount - _collateralFullValue;
        uint256 _mintingFee = ITreasury(treasury).minting_fee();
        uint256 _feePercentOnShare = _mintingFee * 10000 / (10000 - _targetCollateralRatio);

        uint256 _required_shareAmount = _required_shareValue * PRICE_PRECISION / _share_price;
        _shareFee = _required_shareAmount * _feePercentOnShare / 10000;
        _shareAmount = _required_shareAmount + _shareFee;
    }

    // Calculate other minting inputs and outputs from Main Collateral Amount: CAKE
    function calcMintOutputFromMainCollateral(uint256 _mainCollateralAmount) public view override returns (uint256 _dollarAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee) {
        uint256 _second_collateral_price = getSecondCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _targetCollateralRatio = targetCollateralRatio_;

        // _collateralFullValue = _mainCollateralAmount * 2 (CAKE + WBNB)
        // _dollarFullValue = _dollarAmount (1:1)
        _secondCollateralAmount = _mainCollateralAmount * PRICE_PRECISION / _second_collateral_price;
        _dollarAmount = _mainCollateralAmount * 20000 / _targetCollateralRatio;

        uint256 _required_shareValue = _dollarAmount - (_mainCollateralAmount * 2);
        uint256 _mintingFee = ITreasury(treasury).minting_fee();
        uint256 _feePercentOnShare = _mintingFee * 10000 / (10000 - _targetCollateralRatio);

        uint256 _required_shareAmount = _required_shareValue * PRICE_PRECISION / _share_price;
        _shareFee = _required_shareAmount * _feePercentOnShare / 10000;
        _shareAmount = _required_shareAmount + _shareFee;
    }

    // Calculate other minting inputs and outputs from Second Collateral Amount: WBNB
    function calcMintOutputFromSecondCollateral(uint256 _secondCollateralAmount) public view override returns (uint256 _dollarAmount, uint256 _mainCollateralAmount, uint256 _shareAmount, uint256 _shareFee) {
        uint256 _second_collateral_price = getSecondCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _targetCollateralRatio = targetCollateralRatio_;

        // _secondCollateralFullValue = _mainCollateralAmount
        // _dollarFullValue = _dollarAmount (1:1)
        _mainCollateralAmount = _secondCollateralAmount * _second_collateral_price / PRICE_PRECISION;
        _dollarAmount = _mainCollateralAmount * 20000 / _targetCollateralRatio;

        uint256 _required_shareValue = _dollarAmount - (_mainCollateralAmount * 2);
        uint256 _mintingFee = ITreasury(treasury).minting_fee();
        uint256 _feePercentOnShare = _mintingFee * 10000 / (10000 - _targetCollateralRatio);

        uint256 _required_shareAmount = _required_shareValue * PRICE_PRECISION / _share_price;
        _shareFee = _required_shareAmount * _feePercentOnShare / 10000;
        _shareAmount = _required_shareAmount + _shareFee;
    }

    // Calculate other minting inputs and outputs from Share Amount: BCXS
    function calcMintOutputFromShare(uint256 _shareAmount) external view override returns (uint256 _dollarAmount, uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareFee) {
        if (_shareAmount > 0) {
            uint256 _second_collateral_price = getSecondCollateralPrice();
            uint256 _share_price = getTrueSharePrice();

            uint256 _targetReverseCR = 10000 - targetCollateralRatio_;
            uint256 _feePercentOnShare = ITreasury(treasury).minting_fee() * 10000 / _targetReverseCR;

            uint256 _shareAmountWithoutFee = _shareAmount * 10000 / (10000 + _feePercentOnShare);
            _shareFee = _shareAmount - _shareAmountWithoutFee;

            uint256 _shareFullValueWithoutFee = _shareAmountWithoutFee * _share_price / PRICE_PRECISION;

            // _dollarFullValue = _dollarAmount (1:1)
            _dollarAmount = _shareFullValueWithoutFee * 10000 / _targetReverseCR;

            _mainCollateralAmount = (_dollarAmount - _shareFullValueWithoutFee) / 2;
            _secondCollateralAmount = _mainCollateralAmount * PRICE_PRECISION / _second_collateral_price;
        }
    }

    function calcRedeemOutput(uint256 _dollarAmount) public view override returns (uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee) {
        ITreasury _treasury = ITreasury(treasury);

        uint256 _second_collateral_price = getSecondCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _dollar_totalSupply = IERC20(dollar).totalSupply();

        // uint256 _outputRatio = _dollarAmount * 1e18 / IERC20(dollar).totalSupply();

        _mainCollateralAmount = _treasury.globalMainCollateralBalance() * _dollarAmount / _dollar_totalSupply;
        _secondCollateralAmount = _treasury.globalSecondCollateralBalance() * _dollarAmount / _dollar_totalSupply;

        uint256 _collateralFullValue = _mainCollateralAmount + (_secondCollateralAmount * _second_collateral_price / PRICE_PRECISION);
        if (_collateralFullValue < _dollarAmount) {
            uint256 _required_shareValue = _dollarAmount - _collateralFullValue;
            uint256 _redemptionFee = ITreasury(treasury).redemption_fee();
            uint256 _feePercentOnShare = _redemptionFee * _dollarAmount / _required_shareValue;
            uint256 _required_shareAmount = _required_shareValue * PRICE_PRECISION / _share_price;
            if (_feePercentOnShare >= 10000) {
                _shareFee = _required_shareAmount;
                _shareAmount = 0;
            } else {
                _shareFee = _required_shareAmount * _feePercentOnShare / 10000;
                _shareAmount = _required_shareAmount - _shareFee;
            }
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _increaseMintedStats(uint256 _dollarAmount) internal {
        uint256 _hourIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 hours;
        uint256 _dayIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 days;
        totalMintedHourly[_hourIndex] = totalMintedHourly[_hourIndex] + _dollarAmount;
        totalMintedDaily[_dayIndex] = totalMintedDaily[_dayIndex] + _dollarAmount;
    }

    function _increaseRedeemedStats(uint256 _dollarAmount) internal {
        uint256 _hourIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 hours;
        uint256 _dayIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 days;
        totalRedeemedHourly[_hourIndex] = totalRedeemedHourly[_hourIndex] + _dollarAmount;
        totalRedeemedDaily[_dayIndex] = totalRedeemedDaily[_dayIndex] + _dollarAmount;
    }

    function mint(
        uint256 _mainCollateralAmount,
        uint256 _secondCollateralAmount,
        uint256 _shareAmount,
        uint256 _dollarOutMin
    ) external checkContract nonReentrant returns (uint256 _dollarOut, uint256 _required_main_collateralAmount, uint256 _required_second_collateralAmount, uint256 _required_shareAmount, uint256 _shareFee) {
        require(mint_paused == false, "Minting is paused");
        uint256 _mintableDollarLimit = calcMintableDollar() + 100;
        require(_dollarOutMin < _mintableDollarLimit, "over minting cap");

        (_dollarOut, _required_second_collateralAmount, _required_shareAmount, _shareFee) = calcMintOutputFromMainCollateral(_mainCollateralAmount);
        if (_required_second_collateralAmount > _secondCollateralAmount + 100) { // not enough WBNB
            (_dollarOut, _required_main_collateralAmount, _required_shareAmount, _shareFee) = calcMintOutputFromSecondCollateral(_secondCollateralAmount);
            require(_required_main_collateralAmount <= _mainCollateralAmount, "not enough mainCol");
        }
        require(_required_shareAmount <= _shareAmount + 100, "not enough share");
        require(_dollarOut >= _dollarOutMin, "slippage");

        (_required_main_collateralAmount, _required_second_collateralAmount, _required_shareAmount, _shareFee) = calcMintInput(_dollarOut);

        // plus some dust for overflow
        require(_required_main_collateralAmount <= _mainCollateralAmount + 100, "not enough mainCol");
        require(_required_second_collateralAmount <= _secondCollateralAmount + 100, "not enough mainCol");
        require(_required_shareAmount <= _shareAmount + 100, "Not enough share");
        require(_dollarOut <= _mainCollateralAmount * 21000 / targetCollateralRatio_, "Insanely big _dollarOut"); // double check - we dont want to mint too much dollar

        _transferCollateralsToReserve(msg.sender, _required_main_collateralAmount, _required_second_collateralAmount);
        _requestToBurnShareFromSender(msg.sender, _required_shareAmount);

        IDollar(dollar).poolMint(msg.sender, _dollarOut);

        _increaseMintedStats(_dollarOut);
        emit Mint(msg.sender, _dollarOut, _required_main_collateralAmount, _required_second_collateralAmount, _required_shareAmount, _shareFee);
    }

    function redeem(
        uint256 _dollarAmount,
        uint256 _main_collateral_out_min,
        uint256 _second_collateral_out_min,
        uint256 _share_out_min
    ) external checkContract nonReentrant returns (uint256 _main_collateral_out, uint256 _second_collateral_out, uint256 _share_out, uint256 _shareFee) {
        require(redeem_paused == false, "Redeeming is paused");
        uint256 _redeemableDollarLimit = calcRedeemableDollar() + 100;
        require(_dollarAmount < _redeemableDollarLimit, "over redeeming cap");

        (_main_collateral_out, _second_collateral_out, _share_out, _shareFee) = calcRedeemOutput(_dollarAmount);
        require(_main_collateral_out >= _main_collateral_out_min, "short of mainCol");
        require(_second_collateral_out >= _second_collateral_out_min, "short of secondCol");
        require(_share_out >= _share_out_min, "short of share");

        redeem_main_collateral_balances[msg.sender] += _main_collateral_out;
        unclaimed_pool_main_collateral_ += _main_collateral_out;

        redeem_second_collateral_balances[msg.sender] += _second_collateral_out;
        unclaimed_pool_second_collateral_ += _second_collateral_out;

        redeem_share_balances[msg.sender] += _share_out;
        unclaimed_pool_share_ += _share_out;

        IDollar(dollar).poolBurnFrom(msg.sender, _dollarAmount);

        last_redeemed[msg.sender] = block.timestamp;
        _increaseRedeemedStats(_dollarAmount);
        emit Redeem(msg.sender, _dollarAmount, _main_collateral_out, _second_collateral_out, _share_out, _shareFee);
    }

    function collectRedemption() external {
        require(getRedemptionOpenTime(msg.sender) <= block.timestamp, "too early");

        uint256 _mainCollateralAmount = redeem_main_collateral_balances[msg.sender];
        if (_mainCollateralAmount > 0) {
            redeem_main_collateral_balances[msg.sender] = 0;
            unclaimed_pool_main_collateral_ -= _mainCollateralAmount;
            _requestTransferFromReserve(mainCollateral, msg.sender, _mainCollateralAmount);
        }

        uint256 _secondCollateralAmount = redeem_second_collateral_balances[msg.sender];
        if (_secondCollateralAmount > 0) {
            redeem_second_collateral_balances[msg.sender] = 0;
            unclaimed_pool_second_collateral_ -= _secondCollateralAmount;
            _requestTransferFromReserve(secondCollateral, msg.sender, _secondCollateralAmount);
        }

        uint256 _shareAmount = redeem_share_balances[msg.sender];
        if (_shareAmount > 0) {
            redeem_share_balances[msg.sender] = 0;
            unclaimed_pool_share_ = unclaimed_pool_share_ - _shareAmount;
            IDollar(share).poolMint(msg.sender, _shareAmount);
        }

        emit CollectRedemption(msg.sender, _mainCollateralAmount, _secondCollateralAmount, _shareAmount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _transferCollateralsToReserve(address _sender, uint256 _mainCollateralAmount, uint256 _secondCollateralAmount) internal {
        address _reserve = collateralReserve();
        require(_reserve != address(0), "zero");
        if (_mainCollateralAmount > 0) IERC20(mainCollateral).safeTransferFrom(_sender, _reserve, _mainCollateralAmount);
        if (_secondCollateralAmount > 0) IERC20(secondCollateral).safeTransferFrom(_sender, _reserve, _secondCollateralAmount);
        ITreasury(treasury).reserveReceiveCollaterals(_mainCollateralAmount, _secondCollateralAmount);
    }

    function _requestToBurnShareFromSender(address _sender, uint256 _amount) internal {
        if (_amount > 0) {
            IDollar(share).poolBurnFrom(_sender, _amount);
        }
    }

    function _requestTransferFromReserve(address _token, address _receiver, uint256 _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            ITreasury(treasury).requestTransfer(_token, _receiver, _amount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "zero");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setStrategistStatus(address _account, bool _status) external onlyOwner {
        strategist[_account] = _status;
        emit StrategistStatusUpdated(_account, _status);
    }

    function toggleMinting() external onlyOwner {
        mint_paused = !mint_paused;
        emit MintPausedUpdated(mint_paused);
    }

    function toggleRedeeming() external onlyOwner {
        redeem_paused = !redeem_paused;
        emit RedeemPausedUpdated(redeem_paused);
    }

    function toggleContractAllowed() external onlyOwner {
        contract_allowed = !contract_allowed;
        emit ContractAllowedUpdated(contract_allowed);
    }

    function toggleWhitelisted(address _account) external onlyOwner {
        whitelisted[_account] = !whitelisted[_account];
        emit WhitelistedUpdated(_account, whitelisted[_account]);
    }

    function setMintingLimits(uint256 _mintingLimitOnce, uint256 _mintingLimitHourly, uint256 _mintingLimitDaily) external onlyOwner {
        mintingLimitOnce_ = _mintingLimitOnce;
        mintingLimitHourly_ = _mintingLimitHourly;
        mintingLimitDaily_ = _mintingLimitDaily;
    }

    function setOracleDollar(address _oracleDollar) external onlyOwner {
        require(_oracleDollar != address(0), "zero");
        oracleDollar = _oracleDollar;
    }

    function setOracleShare(address _oracleShare) external onlyOwner {
        require(_oracleShare != address(0), "zero");
        oracleShare = _oracleShare;
    }

    function setOracleMainCollateral(address _oracle) external onlyOwner {
        require(_oracle != address(0), "zero");
        oracleMainCollateral = _oracle;
    }

    function setOracleSecondCollateral(address _oracle) external onlyOwner {
        require(_oracle != address(0), "zero");
        oracleSecondCollateral = _oracle;
    }

    function setRedemptionDelay(uint256 _redemption_delay) external onlyOwner {
        redemption_delay = _redemption_delay;
    }

    function setTargetCollateralRatioConfig(uint256 _updateStepTargetCR, uint256 _updateCoolingTimeTargetCR) external onlyOwner {
        updateStepTargetCR = _updateStepTargetCR;
        updateCoolingTimeTargetCR = _updateCoolingTimeTargetCR;
    }

    function setTargetCollateralRatio(uint256 _targetCollateralRatio) external onlyTreasuryOrOwner {
        require(_targetCollateralRatio <= 9500 && _targetCollateralRatio >= 8000, "OoR");
        lastUpdatedTargetCR = block.timestamp;
        targetCollateralRatio_ = _targetCollateralRatio;
        emit TargetCollateralRatioUpdated(_targetCollateralRatio);
    }

    function updateTargetCollateralRatio() external override onlyStrategist {
        if (lastUpdatedTargetCR + updateCoolingTimeTargetCR <= block.timestamp) { // to avoid update too frequent
            lastUpdatedTargetCR = block.timestamp;
            uint256 _dollarPrice = getDollarPrice();
            if (_dollarPrice >= PRICE_PRECISION) {
                // When BCAKE is at or above 1 CAKE, meaning the market’s demand for BCAKE is high,
                // the system should be in de-collateralize mode by decreasing the collateral ratio, minimum to 80%
                targetCollateralRatio_ = Math.max(8000, targetCollateralRatio_ - updateStepTargetCR);
            } else {
                // When the price of BCAKE is below 1 CAKE, the function increases the collateral ratio, maximum to 95%
                targetCollateralRatio_ = Math.min(9500, targetCollateralRatio_ + updateStepTargetCR);
            }
            emit TargetCollateralRatioUpdated(targetCollateralRatio_);
        }
    }

    /* ========== EMERGENCY ========== */

    function rescueStuckErc20(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}