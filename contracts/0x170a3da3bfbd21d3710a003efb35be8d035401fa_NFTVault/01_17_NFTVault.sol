// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/IStableCoin.sol";
import "../interfaces/INFTValueProvider.sol";

/// @title NFT lending vault
/// @notice This contracts allows users to borrow PUSD using NFTs as collateral.
/// The floor price of the NFT collection is fetched using a chainlink oracle, while some other more valuable traits
/// can have an higher price set by the DAO. Users can also increase the price (and thus the borrow limit) of their
/// NFT by submitting a governance proposal. If the proposal is approved the user can lock a percentage of the new price
/// worth of JPEG to make it effective
contract NFTVault is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IStableCoin;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    error InvalidNFT(uint256 nftIndex);
    error InvalidRate(Rate rate);
    error InvalidNFTType(bytes32 nftType);
    error InvalidUnlockTime(uint256 unlockTime);
    error InvalidAmount(uint256 amount);
    error InvalidPosition(uint256 nftIndex);
    error PositionLiquidated(uint256 nftIndex);
    error Unauthorized();
    error DebtCapReached();
    error InvalidInsuranceMode();
    error NoDebt();
    error NonZeroDebt(uint256 debtAmount);
    error PositionInsuranceExpired(uint256 nftIndex);
    error PositionInsuranceNotExpired(uint256 nftIndex);
    error ZeroAddress();
    error InvalidOracleResults();
    error UnknownAction(uint8 action);

    event PositionOpened(address indexed owner, uint256 indexed index);
    event Borrowed(
        address indexed owner,
        uint256 indexed index,
        uint256 amount
    );
    event Repaid(address indexed owner, uint256 indexed index, uint256 amount);
    event PositionClosed(address indexed owner, uint256 indexed index);
    event Liquidated(
        address indexed liquidator,
        address indexed owner,
        uint256 indexed index,
        bool insured
    );
    event Repurchased(address indexed owner, uint256 indexed index);
    event InsuranceExpired(address indexed owner, uint256 indexed index);

    enum BorrowType {
        NOT_CONFIRMED,
        NON_INSURANCE,
        USE_INSURANCE
    }

    struct Position {
        BorrowType borrowType;
        uint256 debtPrincipal;
        uint256 debtPortion;
        uint256 debtAmountForRepurchase;
        uint256 liquidatedAt;
        address liquidator;
    }

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    /// @custom:oz-renamed-from JPEGLock
    struct Unused13 {
        address owner;
        uint256 unlockAt;
        uint256 lockedValue;
    }

    struct VaultSettings {
        Rate debtInterestApr;
        /// @custom:oz-renamed-from creditLimitRate
        Rate unused15;
        /// @custom:oz-renamed-from liquidationLimitRate
        Rate unused16;
        /// @custom:oz-renamed-from cigStakedCreditLimitRate
        Rate unused17;
        /// @custom:oz-renamed-from cigStakedLiquidationLimitRate
        Rate unused18;
        /// @custom:oz-renamed-from valueIncreaseLockRate
        Rate unused12;
        Rate organizationFeeRate;
        Rate insurancePurchaseRate;
        Rate insuranceLiquidationPenaltyRate;
        uint256 insuranceRepurchaseTimeLimit;
        uint256 borrowAmountCap;
    }

    bytes32 private constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 private constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    bytes32 private constant SETTER_ROLE = keccak256("SETTER_ROLE");

    //accrue required
    uint8 private constant ACTION_BORROW = 0;
    uint8 private constant ACTION_REPAY = 1;
    uint8 private constant ACTION_CLOSE_POSITION = 2;
    uint8 private constant ACTION_LIQUIDATE = 3;
    //no accrue required
    uint8 private constant ACTION_REPURCHASE = 100;
    uint8 private constant ACTION_CLAIM_NFT = 101;

    IStableCoin public stablecoin;
    /// @notice Chainlink ETH/USD price feed
    IAggregatorV3Interface public ethAggregator;
    /// @notice The JPEG trait boost locker contract
    /// @custom:oz-renamed-from jpegOracle
    INFTValueProvider public nftValueProvider;
    /// @custom:oz-retyped-from IAggregatorV3Interface
    /// @custom:oz-renamed-from floorOracle
    address private unused8;
    /// @custom:oz-retyped-from IAggregatorV3Interface
    /// @custom:oz-renamed-from fallbackOracle
    address private unused9;
    /// @custom:oz-retyped-from IERC20Upgradeable
    /// @custom:oz-renamed-from jpeg
    address private unused3; //Unused after upgrade
    /// @custom:oz-renamed-from cigStaking
    address public unused14;
    IERC721Upgradeable public nftContract;

    /// @custom:oz-renamed-from daoFloorOverride
    bool private unused10;
    /// @custom:oz-renamed-from useFallbackOracle
    bool private unused11;
    /// @notice Total outstanding debt
    uint256 public totalDebtAmount;
    /// @dev Last time debt was accrued. See {accrue} for more info
    uint256 private totalDebtAccruedAt;
    uint256 public totalFeeCollected;
    uint256 private totalDebtPortion;

    VaultSettings public settings;

    /// @dev Keeps track of all the NFTs used as collateral for positions
    EnumerableSetUpgradeable.UintSet private positionIndexes;

    mapping(uint256 => Position) public positions;
    mapping(uint256 => address) public positionOwner;
    /// @custom:oz-renamed-from nftTypeValueETH
    mapping(bytes32 => uint256) private unused1; //unused after upgrade
    /// @custom:oz-renamed-from nftValueETH
    mapping(uint256 => uint256) private unused2; //unused after upgrade
    /// @custom:oz-renamed-from nftTypes
    mapping(uint256 => bytes32) private unused4; //unused after upgrade

    /// @custom:oz-renamed-from overriddenFloorValueETH
    uint256 private unused5;
    /// @custom:oz-renamed-from minJPEGToLock
    uint256 private unused6;
    /// @custom:oz-renamed-from nftTypeValueMultiplier
    mapping(bytes32 => Rate) private unused7;
    /// @custom:oz-renamed-from lockPositions
    mapping(uint256 => Unused13) private unused13;

    /// @dev Checks if the provided NFT index is valid
    /// @param nftIndex The index to check
    modifier validNFTIndex(uint256 nftIndex) {
        //The standard OZ ERC721 implementation of ownerOf reverts on a non existing nft isntead of returning address(0)
        if (nftContract.ownerOf(nftIndex) == address(0))
            revert InvalidNFT(nftIndex);
        _;
    }

    /// @notice This function is only called once during deployment of the proxy contract. It's not called after upgrades.
    /// @param _stablecoin PUSD address
    /// @param _nftContract The NFT contract address. It could also be the address of an helper contract
    /// if the target NFT isn't an ERC721 (CryptoPunks as an example)
    /// @param _ethAggregator Chainlink ETH/USD price feed address
    /// @param _settings Initial settings used by the contract
    function initialize(
        IStableCoin _stablecoin,
        IERC721Upgradeable _nftContract,
        INFTValueProvider _nftValueProvider,
        IAggregatorV3Interface _ethAggregator,
        VaultSettings calldata _settings
    ) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _setupRole(DAO_ROLE, msg.sender);
        _setRoleAdmin(LIQUIDATOR_ROLE, DAO_ROLE);
        _setRoleAdmin(SETTER_ROLE, DAO_ROLE);
        _setRoleAdmin(DAO_ROLE, DAO_ROLE);

        _validateRateBelowOne(_settings.debtInterestApr);
        _validateRateBelowOne(_settings.organizationFeeRate);
        _validateRateBelowOne(_settings.insurancePurchaseRate);
        _validateRateBelowOne(_settings.insuranceLiquidationPenaltyRate);

        stablecoin = _stablecoin;
        ethAggregator = _ethAggregator;
        nftContract = _nftContract;
        nftValueProvider = _nftValueProvider;

        settings = _settings;
    }

    /// @notice Returns the number of open positions
    /// @return The number of open positions
    function totalPositions() external view returns (uint256) {
        return positionIndexes.length();
    }

    /// @notice Returns all open position NFT indexes
    /// @return The open position NFT indexes
    function openPositionsIndexes() external view returns (uint256[] memory) {
        return positionIndexes.values();
    }

    /// @param _nftIndex The NFT to return the credit limit of
    /// @return The PUSD credit limit of the NFT at index `_nftIndex`.
    function getCreditLimit(address _owner, uint256 _nftIndex) external view returns (uint256) {
        return _getCreditLimit(_owner, _nftIndex);
    }

    /// @param _nftIndex The NFT to return the liquidation limit of
    /// @return The PUSD liquidation limit of the NFT at index `_nftIndex`.
    function getLiquidationLimit(address _owner, uint256 _nftIndex)
        public
        view
        returns (uint256)
    {
        return _getLiquidationLimit(_owner, _nftIndex);
    }

    /// @param _nftIndex The NFT to check
    /// @return Whether the NFT at index `_nftIndex` is liquidatable.
    function isLiquidatable(uint256 _nftIndex) external view returns (bool) {
        Position storage position = positions[_nftIndex];
        if (position.borrowType == BorrowType.NOT_CONFIRMED) return false;
        if (position.liquidatedAt > 0) return false;

        uint256 principal = position.debtPrincipal;
        return
            principal + getDebtInterest(_nftIndex) >=
            getLiquidationLimit(positionOwner[_nftIndex], _nftIndex);
    }

    /// @param _nftIndex The NFT to check
    /// @return The PUSD debt interest accumulated by the NFT at index `_nftIndex`.
    function getDebtInterest(uint256 _nftIndex) public view returns (uint256) {
        Position storage position = positions[_nftIndex];
        uint256 principal = position.debtPrincipal;
        uint256 debt = position.liquidatedAt != 0
            ? position.debtAmountForRepurchase
            : _calculateDebt(
                totalDebtAmount + _calculateAdditionalInterest(),
                position.debtPortion,
                totalDebtPortion
            );

        //_calculateDebt is prone to rounding errors that may cause
        //the calculated debt amount to be 1 or 2 units less than
        //the debt principal if no time has elapsed in between the first borrow
        //and the _calculateDebt call.
        if (principal > debt) debt = principal;

        unchecked {
            return debt - principal;
        }
    }

    /// @dev The {accrue} function updates the contract's state by calculating
    /// the additional interest accrued since the last state update
    function accrue() public {
        uint256 additionalInterest = _calculateAdditionalInterest();

        totalDebtAccruedAt = block.timestamp;

        totalDebtAmount += additionalInterest;
        totalFeeCollected += additionalInterest;
    }

    /// @notice Allows to execute multiple actions in a single transaction.
    /// @param _actions The actions to execute.
    /// @param _datas The abi encoded parameters for the actions to execute.
    function doActions(uint8[] calldata _actions, bytes[] calldata _datas)
        external
        nonReentrant
    {
        if (_actions.length != _datas.length) revert();
        bool accrueCalled;
        for (uint256 i; i < _actions.length; ++i) {
            uint8 action = _actions[i];
            if (!accrueCalled && action < 100) {
                accrue();
                accrueCalled = true;
            }

            if (action == ACTION_BORROW) {
                (uint256 nftIndex, uint256 amount, bool useInsurance) = abi
                    .decode(_datas[i], (uint256, uint256, bool));
                _borrow(nftIndex, amount, useInsurance);
            } else if (action == ACTION_REPAY) {
                (uint256 nftIndex, uint256 amount) = abi.decode(
                    _datas[i],
                    (uint256, uint256)
                );
                _repay(nftIndex, amount);
            } else if (action == ACTION_CLOSE_POSITION) {
                uint256 nftIndex = abi.decode(_datas[i], (uint256));
                _closePosition(nftIndex);
            } else if (action == ACTION_LIQUIDATE) {
                (uint256 nftIndex, address recipient) = abi.decode(
                    _datas[i],
                    (uint256, address)
                );
                _liquidate(nftIndex, recipient);
            } else if (action == ACTION_REPURCHASE) {
                uint256 nftIndex = abi.decode(_datas[i], (uint256));
                _repurchase(nftIndex);
            } else if (action == ACTION_CLAIM_NFT) {
                (uint256 nftIndex, address recipient) = abi.decode(
                    _datas[i],
                    (uint256, address)
                );
                _claimExpiredInsuranceNFT(nftIndex, recipient);
            } else {
                revert UnknownAction(action);
            }
        }
    }

    /// @notice Allows users to open positions and borrow using an NFT
    /// @dev emits a {Borrowed} event
    /// @param _nftIndex The index of the NFT to be used as collateral
    /// @param _amount The amount of PUSD to be borrowed. Note that the user will receive less than the amount requested,
    /// the borrow fee and insurance automatically get removed from the amount borrowed
    /// @param _useInsurance Whereter to open an insured position. In case the position has already been opened previously,
    /// this parameter needs to match the previous insurance mode. To change insurance mode, a user needs to close and reopen the position
    function borrow(
        uint256 _nftIndex,
        uint256 _amount,
        bool _useInsurance
    ) external nonReentrant {
        accrue();
        _borrow(_nftIndex, _amount, _useInsurance);
    }

    /// @notice Allows users to repay a portion/all of their debt. Note that since interest increases every second,
    /// a user wanting to repay all of their debt should repay for an amount greater than their current debt to account for the
    /// additional interest while the repay transaction is pending, the contract will only take what's necessary to repay all the debt
    /// @dev Emits a {Repaid} event
    /// @param _nftIndex The NFT used as collateral for the position
    /// @param _amount The amount of debt to repay. If greater than the position's outstanding debt, only the amount necessary to repay all the debt will be taken
    function repay(uint256 _nftIndex, uint256 _amount) external nonReentrant {
        accrue();
        _repay(_nftIndex, _amount);
    }

    /// @notice Allows a user to close a position and get their collateral back, if the position's outstanding debt is 0
    /// @dev Emits a {PositionClosed} event
    /// @param _nftIndex The index of the NFT used as collateral
    function closePosition(uint256 _nftIndex) external nonReentrant {
        accrue();
        _closePosition(_nftIndex);
    }

    /// @notice Allows members of the `LIQUIDATOR_ROLE` to liquidate a position. Positions can only be liquidated
    /// once their debt amount exceeds the minimum liquidation debt to collateral value rate.
    /// In order to liquidate a position, the liquidator needs to repay the user's outstanding debt.
    /// If the position is not insured, it's closed immediately and the collateral is sent to `_recipient`.
    /// If the position is insured, the position remains open (interest doesn't increase) and the owner of the position has a certain amount of time
    /// (`insuranceRepurchaseTimeLimit`) to fully repay the liquidator and pay an additional liquidation fee (`insuranceLiquidationPenaltyRate`), if this
    /// is done in time the user gets back their collateral and their position is automatically closed. If the user doesn't repurchase their collateral
    /// before the time limit passes, the liquidator can claim the liquidated NFT and the position is closed
    /// @dev Emits a {Liquidated} event
    /// @param _nftIndex The NFT to liquidate
    /// @param _recipient The address to send the NFT to
    function liquidate(uint256 _nftIndex, address _recipient)
        external
        nonReentrant
    {
        accrue();
        _liquidate(_nftIndex, _recipient);
    }

    /// @notice Allows liquidated users who purchased insurance to repurchase their collateral within the time limit
    /// defined with the `insuranceRepurchaseTimeLimit`. The user needs to pay the liquidator the total amount of debt
    /// the position had at the time of liquidation, plus an insurance liquidation fee defined with `insuranceLiquidationPenaltyRate`
    /// @dev Emits a {Repurchased} event
    /// @param _nftIndex The NFT to repurchase
    function repurchase(uint256 _nftIndex) external nonReentrant {
        _repurchase(_nftIndex);
    }

    /// @notice Allows the liquidator who liquidated the insured position with NFT at index `_nftIndex` to claim the position's collateral
    /// after the time period defined with `insuranceRepurchaseTimeLimit` has expired and the position owner has not repurchased the collateral.
    /// @dev Emits an {InsuranceExpired} event
    /// @param _nftIndex The NFT to claim
    /// @param _recipient The address to send the NFT to
    function claimExpiredInsuranceNFT(uint256 _nftIndex, address _recipient)
        external
        nonReentrant
    {
        _claimExpiredInsuranceNFT(_nftIndex, _recipient);
    }

    /// @notice Allows the DAO to collect interest and fees before they are repaid
    function collect() external nonReentrant onlyRole(DAO_ROLE) {
        accrue();
        stablecoin.mint(msg.sender, totalFeeCollected);
        totalFeeCollected = 0;
    }

    /// @notice Allows the DAO to withdraw _amount of an ERC20
    function rescueToken(IERC20Upgradeable _token, uint256 _amount)
        external
        nonReentrant
        onlyRole(DAO_ROLE)
    {
        _token.safeTransfer(msg.sender, _amount);
    }

    /// @notice Allows the setter contract to change fields in the `VaultSettings` struct.
    /// @dev Validation and single field setting is handled by an external contract with the
    /// `SETTER_ROLE`. This was done to reduce the contract's size.
    function setSettings(VaultSettings calldata _settings)
        external
        onlyRole(SETTER_ROLE)
    {
        settings = _settings;
    }

    /// @dev Opens a position
    /// Emits a {PositionOpened} event
    /// @param _owner The owner of the position to open
    /// @param _nftIndex The NFT used as collateral for the position
    function _openPosition(address _owner, uint256 _nftIndex) internal {
        positionOwner[_nftIndex] = _owner;
        positionIndexes.add(_nftIndex);

        nftContract.transferFrom(_owner, address(this), _nftIndex);

        emit PositionOpened(_owner, _nftIndex);
    }

    /// @dev See {borrow}
    function _borrow(
        uint256 _nftIndex,
        uint256 _amount,
        bool _useInsurance
    ) internal validNFTIndex(_nftIndex) {
        address owner = positionOwner[_nftIndex];
        if (owner != msg.sender && owner != address(0)) revert Unauthorized();

        if (_amount == 0) revert InvalidAmount(_amount);

        if (totalDebtAmount + _amount > settings.borrowAmountCap)
            revert DebtCapReached();

        Position storage position = positions[_nftIndex];
        if (position.liquidatedAt != 0) revert PositionLiquidated(_nftIndex);

        BorrowType borrowType = position.borrowType;
        BorrowType targetBorrowType = _useInsurance
            ? BorrowType.USE_INSURANCE
            : BorrowType.NON_INSURANCE;

        if (borrowType == BorrowType.NOT_CONFIRMED)
            position.borrowType = targetBorrowType;
        else if (borrowType != targetBorrowType) revert InvalidInsuranceMode();

        uint256 creditLimit = _getCreditLimit(msg.sender, _nftIndex);
        uint256 debtAmount = _getDebtAmount(_nftIndex);
        if (debtAmount + _amount > creditLimit) revert InvalidAmount(_amount);

        //calculate the borrow fee
        uint256 organizationFee = (_amount *
            settings.organizationFeeRate.numerator) /
            settings.organizationFeeRate.denominator;

        uint256 feeAmount = organizationFee;
        //if the position is insured, calculate the insurance fee
        if (targetBorrowType == BorrowType.USE_INSURANCE) {
            feeAmount +=
                (_amount * settings.insurancePurchaseRate.numerator) /
                settings.insurancePurchaseRate.denominator;
        }
        totalFeeCollected += feeAmount;

        uint256 debtPortion = totalDebtPortion;
        // update debt portion
        if (debtPortion == 0) {
            totalDebtPortion = _amount;
            position.debtPortion = _amount;
        } else {
            uint256 plusPortion = (debtPortion * _amount) / totalDebtAmount;
            totalDebtPortion = debtPortion + plusPortion;
            position.debtPortion += plusPortion;
        }
        position.debtPrincipal += _amount;
        totalDebtAmount += _amount;

        if (positionOwner[_nftIndex] == address(0)) {
            _openPosition(msg.sender, _nftIndex);
        }

        //subtract the fee from the amount borrowed
        stablecoin.mint(msg.sender, _amount - feeAmount);

        emit Borrowed(msg.sender, _nftIndex, _amount);
    }

    /// @dev See {repay}
    function _repay(uint256 _nftIndex, uint256 _amount)
        internal
        validNFTIndex(_nftIndex)
    {
        if (msg.sender != positionOwner[_nftIndex]) revert Unauthorized();

        if (_amount == 0) revert InvalidAmount(_amount);

        Position storage position = positions[_nftIndex];
        if (position.liquidatedAt > 0) revert PositionLiquidated(_nftIndex);

        uint256 debtAmount = _getDebtAmount(_nftIndex);
        if (debtAmount == 0) revert NoDebt();

        uint256 debtPrincipal = position.debtPrincipal;
        uint256 debtInterest = debtAmount - debtPrincipal;

        _amount = _amount > debtAmount ? debtAmount : _amount;

        // burn all payment, the interest is sent to the DAO using the {collect} function
        stablecoin.burnFrom(msg.sender, _amount);

        uint256 paidPrincipal;

        unchecked {
            paidPrincipal = _amount > debtInterest ? _amount - debtInterest : 0;
        }

        uint256 totalPortion = totalDebtPortion;
        uint256 totalDebt = totalDebtAmount;
        uint256 minusPortion = paidPrincipal == debtPrincipal
            ? position.debtPortion
            : (totalPortion * _amount) / totalDebt;

        totalDebtPortion = totalPortion - minusPortion;
        position.debtPortion -= minusPortion;
        position.debtPrincipal -= paidPrincipal;
        totalDebtAmount = totalDebt - _amount;

        emit Repaid(msg.sender, _nftIndex, _amount);
    }

    /// @dev See {closePosition}
    function _closePosition(uint256 _nftIndex)
        internal
        validNFTIndex(_nftIndex)
    {
        if (msg.sender != positionOwner[_nftIndex]) revert Unauthorized();
        if (positions[_nftIndex].liquidatedAt > 0)
            revert PositionLiquidated(_nftIndex);
        uint256 debt = _getDebtAmount(_nftIndex);
        if (debt > 0) revert NonZeroDebt(debt);

        positionOwner[_nftIndex] = address(0);
        delete positions[_nftIndex];
        positionIndexes.remove(_nftIndex);

        // transfer nft back to owner if nft was deposited
        if (nftContract.ownerOf(_nftIndex) == address(this)) {
            nftContract.safeTransferFrom(address(this), msg.sender, _nftIndex);
        }

        emit PositionClosed(msg.sender, _nftIndex);
    }

    /// @dev See {liquidate}
    function _liquidate(uint256 _nftIndex, address _recipient)
        internal
        onlyRole(LIQUIDATOR_ROLE)
        validNFTIndex(_nftIndex)
    {
        address posOwner = positionOwner[_nftIndex];
        if (posOwner == address(0)) revert InvalidPosition(_nftIndex);

        Position storage position = positions[_nftIndex];
        if (position.liquidatedAt > 0) revert PositionLiquidated(_nftIndex);

        uint256 debtAmount = _getDebtAmount(_nftIndex);
        if (debtAmount < _getLiquidationLimit(posOwner, _nftIndex))
            revert InvalidPosition(_nftIndex);

        // burn all payment
        stablecoin.burnFrom(msg.sender, debtAmount);

        // update debt portion
        totalDebtPortion -= position.debtPortion;
        totalDebtAmount -= debtAmount;
        position.debtPortion = 0;

        bool insured = position.borrowType == BorrowType.USE_INSURANCE;
        if (insured) {
            position.debtAmountForRepurchase = debtAmount;
            position.liquidatedAt = block.timestamp;
            position.liquidator = msg.sender;
        } else {
            // transfer nft to liquidator
            positionOwner[_nftIndex] = address(0);
            delete positions[_nftIndex];
            positionIndexes.remove(_nftIndex);
            nftContract.transferFrom(address(this), _recipient, _nftIndex);
        }

        emit Liquidated(msg.sender, posOwner, _nftIndex, insured);
    }

    /// @dev See {repurchase}
    function _repurchase(uint256 _nftIndex) internal validNFTIndex(_nftIndex) {
        Position memory position = positions[_nftIndex];
        if (msg.sender != positionOwner[_nftIndex]) revert Unauthorized();
        if (position.liquidatedAt == 0) revert InvalidPosition(_nftIndex);
        if (position.borrowType != BorrowType.USE_INSURANCE)
            revert InvalidPosition(_nftIndex);
        if (
            block.timestamp >=
            position.liquidatedAt + settings.insuranceRepurchaseTimeLimit
        ) revert PositionInsuranceExpired(_nftIndex);

        uint256 debtAmount = position.debtAmountForRepurchase;
        uint256 penalty = (debtAmount *
            settings.insuranceLiquidationPenaltyRate.numerator) /
            settings.insuranceLiquidationPenaltyRate.denominator;

        // transfer nft to user
        positionOwner[_nftIndex] = address(0);
        delete positions[_nftIndex];
        positionIndexes.remove(_nftIndex);

        // transfer payment to liquidator
        stablecoin.safeTransferFrom(
            msg.sender,
            position.liquidator,
            debtAmount + penalty
        );

        nftContract.safeTransferFrom(address(this), msg.sender, _nftIndex);

        emit Repurchased(msg.sender, _nftIndex);
    }

    /// @dev See {claimExpiredInsuranceNFT}
    function _claimExpiredInsuranceNFT(uint256 _nftIndex, address _recipient)
        internal
        validNFTIndex(_nftIndex)
    {
        if (_recipient == address(0)) revert ZeroAddress();
        Position memory position = positions[_nftIndex];
        address owner = positionOwner[_nftIndex];
        if (owner == address(0)) revert InvalidPosition(_nftIndex);
        if (position.liquidatedAt == 0) revert InvalidPosition(_nftIndex);
        if (
            position.liquidatedAt + settings.insuranceRepurchaseTimeLimit >
            block.timestamp
        ) revert PositionInsuranceNotExpired(_nftIndex);
        if (position.liquidator != msg.sender) revert Unauthorized();

        positionOwner[_nftIndex] = address(0);
        delete positions[_nftIndex];
        positionIndexes.remove(_nftIndex);

        nftContract.transferFrom(address(this), _recipient, _nftIndex);

        emit InsuranceExpired(owner, _nftIndex);
    }

    /// @dev Returns the credit limit of an NFT
    /// @param _owner The owner of the NFT
    /// @param _nftIndex The NFT to return credit limit of
    /// @return The NFT credit limit
    function _getCreditLimit(address _owner, uint256 _nftIndex)
        internal
        view
        returns (uint256)
    {
        uint256 creditLimitETH = nftValueProvider.getCreditLimitETH(_owner, _nftIndex);
        return _ethToUSD(creditLimitETH);
    }

    /// @dev Returns the minimum amount of debt necessary to liquidate an NFT
    /// @param _owner The owner of the NFT
    /// @param _nftIndex The index of the NFT
    /// @return The minimum amount of debt to liquidate the NFT
    function _getLiquidationLimit(address _owner, uint256 _nftIndex)
        internal
        view
        returns (uint256)
    {
        uint256 liquidationLimitETH = nftValueProvider.getLiquidationLimitETH(_owner, _nftIndex);
        return _ethToUSD(liquidationLimitETH);
    }

    /// @dev Calculates current outstanding debt of an NFT
    /// @param _nftIndex The NFT to calculate the outstanding debt of
    /// @return The outstanding debt value
    function _getDebtAmount(uint256 _nftIndex) internal view returns (uint256) {
        uint256 calculatedDebt = _calculateDebt(
            totalDebtAmount,
            positions[_nftIndex].debtPortion,
            totalDebtPortion
        );

        uint256 principal = positions[_nftIndex].debtPrincipal;

        //_calculateDebt is prone to rounding errors that may cause
        //the calculated debt amount to be 1 or 2 units less than
        //the debt principal when the accrue() function isn't called
        //in between the first borrow and the _calculateDebt call.
        return principal > calculatedDebt ? principal : calculatedDebt;
    }

    /// @dev Calculates the total debt of a position given the global debt, the user's portion of the debt and the total user portions
    /// @param total The global outstanding debt
    /// @param userPortion The user's portion of debt
    /// @param totalPortion The total user portions of debt
    /// @return The outstanding debt of the position
    function _calculateDebt(
        uint256 total,
        uint256 userPortion,
        uint256 totalPortion
    ) internal pure returns (uint256) {
        return totalPortion == 0 ? 0 : (total * userPortion) / totalPortion;
    }

    /// @dev Calculates the additional global interest since last time the contract's state was updated by calling {accrue}
    /// @return The additional interest value
    function _calculateAdditionalInterest() internal view returns (uint256) {
        // Number of seconds since {accrue} was called
        uint256 elapsedTime = block.timestamp - totalDebtAccruedAt;
        if (elapsedTime == 0) {
            return 0;
        }

        uint256 totalDebt = totalDebtAmount;
        if (totalDebt == 0) {
            return 0;
        }

        // Accrue interest
        return
            (elapsedTime * totalDebt * settings.debtInterestApr.numerator) /
            settings.debtInterestApr.denominator /
            365 days;
    }

    /// @dev Converts an ETH value in USD
    function _ethToUSD(uint256 _ethValue) internal view returns (uint256) {
        return (_ethValue * _normalizeAggregatorAnswer(ethAggregator)) / 1 ether;
    }

    /// @dev Fetches and converts to 18 decimals precision the latest answer of a Chainlink aggregator
    /// @param aggregator The aggregator to fetch the answer from
    /// @return The latest aggregator answer, normalized
    function _normalizeAggregatorAnswer(IAggregatorV3Interface aggregator)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , uint256 timestamp, ) = aggregator.latestRoundData();

        if (answer == 0 || timestamp == 0) revert InvalidOracleResults();

        uint8 decimals = aggregator.decimals();

        unchecked {
            //converts the answer to have 18 decimals
            return
                decimals > 18
                    ? uint256(answer) / 10**(decimals - 18)
                    : uint256(answer) * 10**(18 - decimals);
        }
    }

    /// @dev Validates a rate. The denominator must be greater than zero and greater than or equal to the numerator.
    /// @param _rate The rate to validate
    function _validateRateBelowOne(Rate memory _rate) internal pure {
        if (_rate.denominator == 0 || _rate.denominator < _rate.numerator)
            revert InvalidRate(_rate);
    }
}