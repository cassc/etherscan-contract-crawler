// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// Libraries
import "../utils/libraries/Math.sol";

// Interfaces
import "../utils/Interfaces/IBasisAsset.sol";
import "../utils/Interfaces/IBoardroom.sol";
import "../utils/Interfaces/IOracle.sol";

contract Treasury is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    /* ========= CONSTANT VARIABLES ======== */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public constant PERIOD = 6 hours;

    // core components
    address public radiance;
    address public stars;
    address public glow;

    address public lpBoardroom;
    address public sasBoardroom;
    address public oracle;

    /* ========== STATE VARIABLES ========== */

    // epoch
    uint256 public startTime;
    uint256 public epoch;
    uint256 public epochSupplyContractionLeft;

    // exclusions from total supply
    address[] public excludedFromTotalSupply;

    // price
    uint256 public radiancePriceOne;
    uint256 public radiancePriceCeiling;

    uint256 public seigniorageSaved;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxSupplyContractionPercent;
    uint256 public maxDebtRatioPercent;

    uint256 public bondSupplyExpansionPercent;

    address public daoFund;

    /* =================== Added variables =================== */
    uint256 public previousEpochradiancePrice;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public mintingFactorForPayingDebt; // print extra radiance during debt phase

    // BONDS //
    event BoughtBonds(
        address indexed from,
        uint256 radianceAmount,
        uint256 bondAmount
    );

    event RedeemecBonds(
        address indexed from,
        uint256 radianceAmount,
        uint256 bondAmount
    );

    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);

    function initialize(
        address _radiance,
        address _stars,
        address _glow,
        address _oracle,
        address _lpBoardroom,
        address _sasBoardroom,
        address _daoFund,
        uint256 _startTime
    ) public initializer {
        __ReentrancyGuard_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        epoch = 0;
        epochSupplyContractionLeft = 0;
        radiance = _radiance;
        stars = _stars;
        glow = _glow;

        oracle = _oracle;
        lpBoardroom = _lpBoardroom;
        sasBoardroom = _sasBoardroom;
        daoFund = _daoFund;

        startTime = _startTime;

        radiancePriceOne = 10**18;
        radiancePriceCeiling = radiancePriceOne.mul(101).div(100);

        // Dynamic max expansion percent
        supplyTiers = [
            0 ether,
            100000 ether,
            250000 ether,
            500000 ether,
            1000000 ether,
            50000000 ether,
            100000000 ether,
            200000000 ether,
            500000000 ether
        ];
        maxExpansionTiers = [400, 300, 200, 100, 50, 50, 50, 50, 50];

        maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for boardroom
        maxSupplyContractionPercent = 100; // Upto 1.0% supply for contraction (to burn RADIANCE and mint GLOW)
        maxDebtRatioPercent = 2500; // Up to 25% supply of GLOW to purchase

        premiumThreshold = 110; // Above $1.10
        maxPremiumRate = 1e18; // Maximum x2 Radiance Value

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20Upgradeable(radiance).balanceOf(address(this));
    }

    modifier checkCondition() {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch() {
        require(
            block.timestamp >= nextEpochPoint(),
            "Treasury: not opened yet"
        );

        _;

        epoch = epoch.add(1);
        epochSupplyContractionLeft = (getRadiancePrice() > radiancePriceCeiling)
            ? 0
            : getRadianceCirculatingSupply()
                .mul(maxSupplyContractionPercent)
                .div(10000);
    }

    modifier checkOperator() {
        require(
            IBasisAsset(radiance).hasRole(
                keccak256("OPERATOR_ROLE"),
                address(this)
            ) &&
                IBasisAsset(stars).hasRole(
                    keccak256("OPERATOR_ROLE"),
                    address(this)
                ) &&
                IBasisAsset(glow).hasRole(
                    keccak256("OPERATOR_ROLE"),
                    address(this)
                ) &&
                IBoardroom(lpBoardroom).hasRole(
                    keccak256("OPERATOR_ROLE"),
                    address(this)
                ) &&
                IBoardroom(sasBoardroom).hasRole(
                    keccak256("OPERATOR_ROLE"),
                    address(this)
                ),
            "Treasury: need more permission"
        );

        _;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getRadiancePrice() public view returns (uint256 radiancePrice) {
        try IOracle(oracle).consult(radiance, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert(
                "Treasury: failed to consult radiance price from the oracle"
            );
        }
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function getRadianceCirculatingSupply() public view returns (uint256) {
        IERC20Upgradeable radianceErc20 = IERC20Upgradeable(radiance);
        uint256 totalSupply = radianceErc20.totalSupply();
        uint256 balanceExcluded = 0;
        for (
            uint8 entryId = 0;
            entryId < excludedFromTotalSupply.length;
            ++entryId
        ) {
            balanceExcluded = balanceExcluded.add(
                radianceErc20.balanceOf(excludedFromTotalSupply[entryId])
            );
        }
        return totalSupply.sub(balanceExcluded);
    }

    function getBurnableRadianceLeft()
        public
        view
        returns (uint256 _burnableradianceLeft)
    {
        uint256 _radiancePrice = getRadiancePrice();
        if (_radiancePrice <= radiancePriceOne) {
            uint256 _radianceSupply = getRadianceCirculatingSupply();

            uint256 _bondMaxSupply = _radianceSupply
                .mul(maxDebtRatioPercent)
                .div(10000);

            uint256 _bondSupply = IERC20Upgradeable(glow).totalSupply();

            if (_bondMaxSupply > _bondSupply) {
                uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint256 _maxBurnableradiance = _maxMintableBond
                    .mul(_radiancePrice)
                    .div(1e18);
                _burnableradianceLeft = Math.min(
                    epochSupplyContractionLeft,
                    _maxBurnableradiance
                );
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _radiancePrice = getRadiancePrice();
        if (_radiancePrice > radiancePriceCeiling) {
            uint256 _radiancePricePremiumThreshold = radiancePriceOne
                .mul(premiumThreshold)
                .div(100);
            if (_radiancePrice >= _radiancePricePremiumThreshold) {
                //Price > 1.10

                uint256 _percentOver = _radiancePrice.sub(
                    _radiancePricePremiumThreshold
                );

                if (_percentOver > maxPremiumRate) {
                    _percentOver = 1e18;
                }

                _rate = (((_radiancePrice * _percentOver) / 1e18) +
                    _radiancePrice);
            } else {
                // no premium bonus
                _rate = radiancePriceOne;
            }
        }
    }

    function getRedeemableBonds()
        public
        view
        returns (uint256 _redeemableBonds)
    {
        uint256 _radiancePrice = getRadiancePrice();
        if (_radiancePrice > radiancePriceCeiling) {
            uint256 _totalradiance = IERC20Upgradeable(radiance).balanceOf(
                address(this)
            );
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalradiance.mul(1e18).div(_rate);
            }
        }
    }

    function getBondDiscountRate() public view returns (uint256 _rate) {
        uint256 _radiancePrice = getRadiancePrice();
        if (_radiancePrice <= radiancePriceOne) {
            if (discountPercent == 0) {
                // no discount
                _rate = radiancePriceOne;
            } else {
                uint256 _bondAmount = radiancePriceOne.mul(1e18).div(
                    _radiancePrice
                ); // to burn 1 radiance
                uint256 _discountAmount = _bondAmount
                    .sub(radiancePriceOne)
                    .mul(discountPercent)
                    .div(10000);
                _rate = radiancePriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    // Only Operator
    function setLPBoardroom(address _boardroom)
        external
        onlyRole(OPERATOR_ROLE)
    {
        lpBoardroom = _boardroom;
    }

    function updateStartTime(uint256 _newTime) public onlyRole(OPERATOR_ROLE) {
        startTime = _newTime;
    }

    function setSasBoardroom(address _boardroom)
        external
        onlyRole(OPERATOR_ROLE)
    {
        sasBoardroom = _boardroom;
    }

    function setradianceOracle(address _oracle)
        external
        onlyRole(OPERATOR_ROLE)
    {
        oracle = _oracle;
    }

    function setradiancePriceCeiling(uint256 _radiancePriceCeiling)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(
            _radiancePriceCeiling >= radiancePriceOne &&
                _radiancePriceCeiling <= radiancePriceOne.mul(120).div(100),
            "out of range"
        ); // [$1.0, $1.2]
        radiancePriceCeiling = _radiancePriceCeiling;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(
            _maxSupplyExpansionPercent >= 10 &&
                _maxSupplyExpansionPercent <= 1000,
            "_maxSupplyExpansionPercent: out of range"
        ); // [0.1%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value)
        external
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < 8) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value)
        external
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        require(_index >= 0, "Index has to be higher than 0");
        require(_index < 9, "Index has to be lower than count of tiers");
        require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(
            _bondDepletionFloorPercent >= 500 &&
                _bondDepletionFloorPercent <= 10000,
            "out of range"
        ); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(
        uint256 _maxSupplyContractionPercent
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            _maxSupplyContractionPercent >= 100 &&
                _maxSupplyContractionPercent <= 1500,
            "out of range"
        ); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(
            _maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000,
            "out of range"
        ); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    // Possibly Delete
    function setMaxDiscountRate(uint256 _maxDiscountRate)
        external
        onlyRole(OPERATOR_ROLE)
    {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate)
        external
        onlyRole(OPERATOR_ROLE)
    {
        maxPremiumRate = _maxPremiumRate;
    }

    // Possibly Delete
    function setDiscountPercent(uint256 _discountPercent)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(
            _premiumThreshold >= radiancePriceCeiling,
            "_premiumThreshold exceeds radiancePriceCeiling"
        );
        require(
            _premiumThreshold <= 150,
            "_premiumThreshold is higher than 1.5"
        );
        premiumThreshold = _premiumThreshold;
    }

    function setMintingFactorForPayingDebt(uint256 _mintingFactorForPayingDebt)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(
            _mintingFactorForPayingDebt >= 10000 &&
                _mintingFactorForPayingDebt <= 20000,
            "_mintingFactorForPayingDebt: out of range"
        ); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    function setBondSupplyExpansionPercent(uint256 _bondSupplyExpansionPercent)
        external
        onlyRole(OPERATOR_ROLE)
    {
        bondSupplyExpansionPercent = _bondSupplyExpansionPercent;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateradiancePrice() internal {
        try IOracle(oracle).update() {} catch {}
    }

    function buyBonds(uint256 _radianceAmount, uint256 targetPrice)
        external
        checkCondition
        nonReentrant
    {
        require(
            _radianceAmount > 0,
            "Treasury: cannot purchase bonds with zero amount"
        );

        uint256 radiancePrice = getRadiancePrice();

        require(radiancePrice == targetPrice, "Treasury: radiance price moved");
        require(
            radiancePrice < radiancePriceOne, // price < $1
            "Treasury: radiancePrice not eligible for bond purchase"
        );

        require(
            _radianceAmount <= epochSupplyContractionLeft,
            "Treasury: not enough bond left to purchase"
        );

        uint256 _rate = getBondDiscountRate();

        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _bondAmount = _radianceAmount.mul(_rate).div(1e18);
        uint256 radianceSupply = getRadianceCirculatingSupply();
        uint256 newBondSupply = IERC20Upgradeable(glow).totalSupply().add(
            _bondAmount
        );
        require(
            newBondSupply <= radianceSupply.mul(maxDebtRatioPercent).div(10000),
            "over max debt ratio"
        );

        IBasisAsset(radiance).burnFrom(msg.sender, _radianceAmount);
        IBasisAsset(glow).mint(msg.sender, _bondAmount);

        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(
            _radianceAmount
        );
        _updateradiancePrice();

        emit BoughtBonds(msg.sender, _radianceAmount, _bondAmount);
    }

    function redeemBonds(uint256 _bondAmount, uint256 targetPrice)
        external
        checkCondition
        nonReentrant
    {
        require(
            _bondAmount > 0,
            "Treasury: cannot redeem bonds with zero amount"
        );

        uint256 radiancePrice = getRadiancePrice();
        require(radiancePrice == targetPrice, "Treasury: radiance price moved");
        require(
            radiancePrice > radiancePriceCeiling, // price > $1.01
            "Treasury: radiancePrice not eligible for bond redemption"
        );

        uint256 _rate = getBondPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint256 _radianceAmount = _bondAmount.mul(_rate).div(1e18);
        require(
            IERC20Upgradeable(radiance).balanceOf(address(this)) >=
                _radianceAmount,
            "Treasury: treasury has no more budget"
        );

        seigniorageSaved = seigniorageSaved.sub(
            Math.min(seigniorageSaved, _radianceAmount)
        );

        IBasisAsset(glow).burnFrom(msg.sender, _bondAmount);
        IERC20Upgradeable(radiance).safeTransfer(msg.sender, _radianceAmount);

        _updateradiancePrice();

        emit RedeemecBonds(msg.sender, _radianceAmount, _bondAmount);
    }

    function _sendToLPBoardroom(uint256 _amount) internal {
        IBasisAsset(radiance).mint(address(this), _amount);

        IERC20Upgradeable(radiance).safeApprove(lpBoardroom, 0);
        IERC20Upgradeable(radiance).safeApprove(lpBoardroom, _amount);
        IBoardroom(lpBoardroom).allocateSeigniorage(_amount);
        emit BoardroomFunded(block.timestamp, _amount);
    }

    function _sendToSaSBoardroom(uint256 _amount) internal {
        IBasisAsset(radiance).mint(address(this), _amount);

        IERC20Upgradeable(radiance).safeApprove(sasBoardroom, 0);
        IERC20Upgradeable(radiance).safeApprove(sasBoardroom, _amount);
        IBoardroom(sasBoardroom).allocateSeigniorage(_amount);
        emit BoardroomFunded(block.timestamp, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _radianceSupply)
        internal
        returns (uint256)
    {
        for (uint8 tierId = 8; tierId >= 0; --tierId) {
            if (_radianceSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function allocateSeigniorage()
        external
        checkCondition
        checkEpoch
        checkOperator
        nonReentrant
    {
        _updateradiancePrice();
        previousEpochradiancePrice = getRadiancePrice();
        uint256 radianceSupply = getRadianceCirculatingSupply().sub(
            seigniorageSaved
        );

        if (previousEpochradiancePrice > radiancePriceCeiling) {
            // Expansion ($radiance Price > 1 BUSD): there is some seigniorage to be allocated
            uint256 bondSupply = IERC20Upgradeable(glow).totalSupply();
            uint256 _percentage = previousEpochradiancePrice
                .sub(radiancePriceOne)
                .div(10);
            uint256 _savedForBond;
            uint256 _savedForBoardroom;
            uint256 _mse = _calculateMaxSupplyExpansionPercent(radianceSupply)
                .mul(1e14);
            if (_percentage > _mse) {
                _percentage = _mse;
            }
            if (
                seigniorageSaved >=
                bondSupply.mul(bondDepletionFloorPercent).div(10000)
            ) {
                // saved enough to pay debt, mint as usual rate
                _savedForBoardroom = radianceSupply.mul(_percentage).div(1e18);
            } else {
                // have not saved enough to pay debt, mint more
                uint256 _seigniorage = radianceSupply.mul(_percentage).div(
                    1e18
                );
                _savedForBoardroom = _seigniorage
                    .mul(seigniorageExpansionFloorPercent)
                    .div(10000);
                _savedForBond = _seigniorage.sub(_savedForBoardroom);
                if (mintingFactorForPayingDebt > 0) {
                    _savedForBond = _savedForBond
                        .mul(mintingFactorForPayingDebt)
                        .div(10000);
                }
            }
            if (_savedForBoardroom > 0) {
                uint256 savedForLP = (_savedForBoardroom * 85) / 100;
                uint256 savedForSaS = _savedForBoardroom - savedForLP;
                _sendToLPBoardroom(savedForLP);
                _sendToSaSBoardroom(savedForSaS);
            }
            if (_savedForBond > 0) {
                seigniorageSaved = seigniorageSaved.add(_savedForBond);
                IBasisAsset(radiance).mint(address(this), _savedForBond);
                emit TreasuryFunded(block.timestamp, _savedForBond);
            }
        }
    }
}