// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IBasisAsset.sol";
import "../interfaces/ISynergyARK.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../utils/ContractGuard.sol";
import "../owner/Operator.sol";

contract Treasury is ContractGuard, Operator {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant EPOCH_DURATION = 8 hours;

    /* ========== STATE VARIABLES ========== */

    address public uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // flags
    bool public initialized = false;
    bool public isBoostEnabled = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 40;

    // exclusions from total supply
    address[] public excludedFromTotalSupply;

    // core components
    address public crystal;
    address public diamond;
    address public synergyARK;
    address public oracle;

    // price
    uint256 public crystalPriceOne;
    uint256 public seigniorageSaved;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;

    // 21 first epochs (1 week) with 4.5% expansion regardless of CRS price
    uint256 public bootstrapEpochs;
    uint256 public bootstrapSupplyExpansionPercent;

    /* =================== Added variables =================== */
    uint256 public previousEpochCRSPrice;

    address public treasuryFund;
    uint256 public treasuryFundSharedPercent;

    address public teamFund;
    uint256 public teamFundSharedPercent;

    address public lotteryFund;
    uint256 public lotteryFundSharedPercent;

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event TeamFunded(uint256 timestamp, uint256 seigniorage);
    event ARKFunded(uint256 timestamp, uint256 seigniorage);
    event LotteryFunded(uint256 timestamp, uint256 seigniorage);

    /* =================== Modifier =================== */

    modifier checkCondition() {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch() {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
    }

    modifier checkOperator() {
        require(
            IBasisAsset(crystal).operator() == address(this) &&
                IBasisAsset(diamond).operator() == address(this) &&
                Operator(synergyARK).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized() {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(EPOCH_DURATION));
    }

    // oracle
    function getCRSPrice() public view returns (uint256 _crystalPrice) {
        try IOracle(oracle).consult(crystal, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult CRS price from the oracle");
        }
    }

    function getCRSUpdatedPrice() public view returns (uint256 _crystalPrice) {
        try IOracle(oracle).twap(crystal, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult CRS price from the oracle");
        }
    }

    // expansion
    function getNextExpansionRate(uint256 _crystalPrice) public view returns (uint256) {
        uint256 crystalSupply = getCRSCirculatingSupply().sub(seigniorageSaved);
        uint256 expansionRate = 0;
        
        if (epoch < bootstrapEpochs || isBoostEnabled) {
            expansionRate = bootstrapSupplyExpansionPercent;
        } else {
            if (_crystalPrice > crystalPriceOne) {
                // Expansion ($CRS Price > 1 $BUSD): there is some seigniorage to be allocated
                expansionRate = _calculateMaxSupplyExpansionPercent(crystalSupply);
            }
        }

        return expansionRate;
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    // toggle flag variables
    function toggleBoostEnabled() external onlyOperator() returns (bool) {
        isBoostEnabled = !isBoostEnabled;
        return isBoostEnabled;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _crystal,
        address _diamond,
        address _oracle,
        address _ark,
        uint256 _startTime
    ) public notInitialized {
        crystal = _crystal;
        diamond = _diamond;
        oracle = _oracle;
        synergyARK = _ark;
        startTime = _startTime;

        crystalPriceOne = 1e18; // This is to allow a PEG of 1 CRS per BUSD

        // Dynamic max expansion percent
        supplyTiers = [500000 ether, 1000000 ether];
        maxExpansionTiers = [300, 250];

        maxSupplyExpansionPercent = 300; // Upto 2.5% supply for expansion

        // First 21 epochs with 4.5% expansion
        bootstrapEpochs = 21;
        bootstrapSupplyExpansionPercent = 450;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(crystal).balanceOf(address(this));

        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function setARK(address _ark) external onlyOperator {
        synergyARK = _ark;
    }

    function setOracle(address _oracle) external onlyOperator {
        oracle = _oracle;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent) external onlyOperator {
        require(_maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000, "_maxSupplyExpansionPercent: out of range");
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 2, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < 1) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 2, "Index has to be lower than count of tiers");
        require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setBootstrap(uint256 _bootstrapEpochs, uint256 _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 90, "_bootstrapEpochs: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000, "_bootstrapSupplyExpansionPercent: out of range"); // [1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function setExtraFunds(
        address _treasuryFund,
        uint256 _treasuryFundSharedPercent,
        address _teamFund,
        uint256 _teamFundSharedPercent,
        address _lotteryFund,
        uint256 _lotteryFundSharedPercent
    ) external onlyOperator {
        require(_treasuryFund != address(0), "Treasury should be non-zero address");
        require(_teamFund != address(0), "Treasury should be non-zero address");
        require(_lotteryFund != address(0), "Lottery should be non-zero address");

        require(_treasuryFundSharedPercent < 10000, "Treasury share rate should be less than 10000");
        require(_teamFundSharedPercent < 10000, "Team share rate should be less than 10000");
        require(_lotteryFundSharedPercent < 10000, "Lottery share rate should be less than 10000");

        treasuryFund = _treasuryFund;
        treasuryFundSharedPercent = _treasuryFundSharedPercent;
        teamFund = _teamFund;
        teamFundSharedPercent = _teamFundSharedPercent;
        lotteryFund = _lotteryFund;
        lotteryFundSharedPercent = _lotteryFundSharedPercent;
    }

    function addExcludedFromTotalSupply(address _account) external onlyOperator returns (bool) {
        for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
            if (excludedFromTotalSupply[entryId] == _account) {
                return false;
            }
        }

        excludedFromTotalSupply.push(_account);
        return true;
    }

    function removeExcludedFromTotalSupply(address _account) external onlyOperator returns (bool) {
        uint index;
        bool isExist = false;
        for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
            if (excludedFromTotalSupply[entryId] == _account) {
                index = entryId;
                isExist = true;
            }
        }

        if (isExist) {
            require(index < excludedFromTotalSupply.length, "index out of bound");
    
            excludedFromTotalSupply[index] = excludedFromTotalSupply[excludedFromTotalSupply.length - 1];
            excludedFromTotalSupply.pop();
            return true;
        } 

        return false;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateCRSPrice() internal {
        try IOracle(oracle).update() {} catch {}
    }

    function getCRSCirculatingSupply() public view returns (uint256) {
        uint256 totalSupply = IERC20(crystal).totalSupply();
        uint256 balanceExcluded = 0;
        for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
            balanceExcluded = balanceExcluded.add(IERC20(crystal).balanceOf(excludedFromTotalSupply[entryId]));
        }
        return totalSupply.sub(balanceExcluded);
    }

    function _sendToBoardroom(uint256 _amount) internal {
        IBasisAsset(crystal).mint(address(this), _amount);

        uint256 _treasuryFundSharedAmount = 0;
        if (treasuryFundSharedPercent > 0) {
            _treasuryFundSharedAmount = _amount.mul(treasuryFundSharedPercent).div(10000);
            IERC20(crystal).transfer(treasuryFund, _treasuryFundSharedAmount);
            emit TreasuryFunded(block.timestamp, _treasuryFundSharedAmount);
        }

        uint256 _teamFundSharedAmount = 0;
        if (teamFundSharedPercent > 0) {
            _teamFundSharedAmount = _amount.mul(teamFundSharedPercent).div(10000);
            IERC20(crystal).transfer(teamFund, _teamFundSharedAmount);
            emit TeamFunded(block.timestamp, _teamFundSharedAmount);
        }

        uint256 _lotteryFundSharedAmount = 0;
        if (lotteryFundSharedPercent > 0) {
            _lotteryFundSharedAmount = _amount.mul(lotteryFundSharedPercent).div(10000);
            IERC20(crystal).transfer(lotteryFund, _lotteryFundSharedAmount);
            emit LotteryFunded(block.timestamp, _lotteryFundSharedAmount);
        }

        _amount = _amount.sub(_treasuryFundSharedAmount).sub(_teamFundSharedAmount).sub(_lotteryFundSharedAmount);

        IERC20(crystal).safeApprove(synergyARK, 0);
        IERC20(crystal).safeApprove(synergyARK, _amount);
        ISynergyARK(synergyARK).allocateSeigniorage(_amount);
        emit ARKFunded(block.timestamp, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _crystalSupply) internal view returns (uint256) {
        for (uint8 tierId = 0; tierId < 2; tierId++) {
            if (_crystalSupply < supplyTiers[tierId]) {
                return maxExpansionTiers[tierId];
            }
        }

        uint256 supply =  supplyTiers[1];
        uint256 expansionPercent = maxExpansionTiers[1];
        while (_crystalSupply < supply) {
            supply = supply.mul(125).div(100);
            expansionPercent = expansionPercent.mul(90).div(100);
        }
        return expansionPercent;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updateCRSPrice();
        previousEpochCRSPrice = getCRSPrice();
        uint256 crystalSupply = getCRSCirculatingSupply().sub(seigniorageSaved);
        if (epoch < bootstrapEpochs || isBoostEnabled) {
            // 21 first epochs and over bootstrap threashold with 4.5% expansion
            _sendToBoardroom(crystalSupply.mul(bootstrapSupplyExpansionPercent).div(10000));
        } else {
            if (previousEpochCRSPrice > crystalPriceOne) {
                // Expansion ($CRS Price > 1 $BUSD): there is some seigniorage to be allocated
                maxSupplyExpansionPercent = _calculateMaxSupplyExpansionPercent(crystalSupply);
                _sendToBoardroom(crystalSupply.mul(maxSupplyExpansionPercent).div(10000));
            }
        }
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(crystal), "Shouldn't drain $CRS from Treasury");
        require(address(_token) != address(diamond), "Shouldn't drain $DIA from Treasury");
        _token.safeTransfer(_to, _amount);
    }

    function ARKSetOperator(address _operator) external onlyOperator {
        Operator(synergyARK).transferOperator(_operator);
    }

    function ARKSetLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
        ISynergyARK(synergyARK).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function ARKAllocateSeigniorage(uint256 amount) external onlyOperator {
        ISynergyARK(synergyARK).allocateSeigniorage(amount);
    }

    function ARKGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        ISynergyARK(synergyARK).governanceRecoverUnsupported(_token, _amount, _to);
    }
}