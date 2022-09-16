// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "./libraries/BP.sol";
import "./libraries/AUMCalculationLibrary.sol";

import "./interfaces/IIndex.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IIndexFactory.sol";
import "./interfaces/IIndexRegistry.sol";

/// @title Fee pool
/// @notice Responsible for index fee management logic and accumulation
contract FeePool is IFeePool, UUPSUpgradeable, ReentrancyGuardUpgradeable, ERC165Upgradeable {
    using Address for address;
    using SafeERC20 for IERC20;
    using ERC165CheckerUpgradeable for address;

    /// @notice 10% in base point format
    uint public constant MAX_FEE_IN_BP = 1000;

    /// @notice 10% in AUM Scaled units
    uint public constant MAX_AUM_FEE = 1000000003340960040392850629;

    /// @notice Index factory role
    bytes32 internal constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    /// @notice Role allows configure fee related data/components
    bytes32 internal constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    /// @inheritdoc IFeePool
    mapping(address => uint) public override totalSharesOf;
    /// @inheritdoc IFeePool
    mapping(address => mapping(address => uint)) public override shareOf;

    /// @inheritdoc IFeePool
    mapping(address => uint16) public override mintingFeeInBPOf;
    /// @inheritdoc IFeePool
    mapping(address => uint16) public override burningFeeInBPOf;
    /// @inheritdoc IFeePool
    mapping(address => uint) public override AUMScaledPerSecondsRateOf;

    /// @notice Withdrawable amounts for accounts from indexes
    mapping(address => mapping(address => uint)) internal withdrawableOf;
    /// @notice Accumulated rewards for accounts from indexes
    mapping(address => mapping(address => uint)) internal lastAccumulatedTokenPerTotalSupplyInBaseOf;
    /// @notice Accumulated index rewards per total supply
    mapping(address => uint) internal accumulatedTokenPerTotalSupplyInBaseOf;
    /// @notice Index token balances
    mapping(address => uint) internal lastTokenBalanceOf;

    /// @notice Index registry address
    address internal registry;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "FeePool: FORBIDDEN");
        _;
    }

    /// @notice Checks if provided value is lower than 10% in base point format
    modifier isValidFee(uint16 _value) {
        require(_value <= MAX_FEE_IN_BP, "FeePool: INVALID");
        _;
    }

    /// @notice Accumulates account rewards per index
    modifier accumulateRewards(address _index, address _account) {
        if (_index.code.length != 0) {
            IIndexFactory(IIndex(_index).factory()).withdrawToFeePool(_index);
        }

        uint _totalShares = totalSharesOf[_index];
        if (_totalShares != 0) {
            uint tokenIncrease = IERC20(_index).balanceOf(address(this)) - lastTokenBalanceOf[_index];
            if (tokenIncrease != 0) {
                unchecked {
                    // overflow is desired
                    accumulatedTokenPerTotalSupplyInBaseOf[_index] +=
                        (tokenIncrease * BP.DECIMAL_FACTOR) /
                        _totalShares;
                }
            }
        }

        _accumulateAccountRewards(_index, _account);
        _;

        if (_totalShares != 0) {
            lastTokenBalanceOf[_index] = IERC20(_index).balanceOf(address(this));
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IFeePool
    function initialize(address _registry) external override initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "FeePool: INTERFACE");

        __ERC165_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        registry = _registry;
    }

    /// @inheritdoc IFeePool
    function initializeIndex(
        address _index,
        uint16 _mintingFeeInBP,
        uint16 _burningFeeInBP,
        uint _AUMScaledPerSecondsRate,
        MintBurnInfo[] calldata _mintInfo
    ) external override onlyRole(FACTORY_ROLE) {
        mintingFeeInBPOf[_index] = _mintingFeeInBP;
        burningFeeInBPOf[_index] = _burningFeeInBP;
        AUMScaledPerSecondsRateOf[_index] = _AUMScaledPerSecondsRate;

        _mintMultiple(_index, _mintInfo);

        emit SetMintingFeeInBP(msg.sender, _index, _mintingFeeInBP);
        emit SetBurningFeeInBP(msg.sender, _index, _burningFeeInBP);
        emit SetAUMScaledPerSecondsRate(msg.sender, _index, _AUMScaledPerSecondsRate);
    }

    /// @inheritdoc IFeePool
    function setMintingFeeInBP(address _index, uint16 _mintingFeeInBP)
        external
        override
        isValidFee(_mintingFeeInBP)
        onlyRole(FEE_MANAGER_ROLE)
    {
        mintingFeeInBPOf[_index] = _mintingFeeInBP;
        emit SetMintingFeeInBP(msg.sender, _index, _mintingFeeInBP);
    }

    /// @inheritdoc IFeePool
    function setBurningFeeInBP(address _index, uint16 _burningFeeInBP)
        external
        override
        isValidFee(_burningFeeInBP)
        onlyRole(FEE_MANAGER_ROLE)
    {
        burningFeeInBPOf[_index] = _burningFeeInBP;
        emit SetBurningFeeInBP(msg.sender, _index, _burningFeeInBP);
    }

    /// @inheritdoc IFeePool
    function setAUMScaledPerSecondsRate(address _index, uint _AUMScaledPerSecondsRate)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
    {
        require(_AUMScaledPerSecondsRate <= MAX_AUM_FEE, "FeePool: INVALID");
        require(_AUMScaledPerSecondsRate >= AUMCalculationLibrary.RATE_SCALE_BASE, "FeePool: INVALID");

        AUMScaledPerSecondsRateOf[_index] = _AUMScaledPerSecondsRate;
        emit SetAUMScaledPerSecondsRate(msg.sender, _index, _AUMScaledPerSecondsRate);
    }

    /// @inheritdoc IFeePool
    function withdraw(address _index) external override nonReentrant {
        _withdraw(_index, msg.sender, msg.sender);
    }

    /// @inheritdoc IFeePool
    function withdrawPlatformFeeOf(address _index, address _recipient)
        external
        override
        nonReentrant
        onlyRole(FEE_MANAGER_ROLE)
    {
        _withdraw(_index, _index, _recipient);
    }

    /// @inheritdoc IFeePool
    function burn(address _index, MintBurnInfo calldata _burnInfo) external override onlyRole(FEE_MANAGER_ROLE) {
        _burn(_index, _burnInfo.recipient, _burnInfo.share);
    }

    /// @inheritdoc IFeePool
    function mint(address _index, MintBurnInfo calldata _mintInfo) external override onlyRole(FEE_MANAGER_ROLE) {
        _mint(_index, _mintInfo.recipient, _mintInfo.share);
    }

    /// @inheritdoc IFeePool
    function burnMultiple(address _index, MintBurnInfo[] calldata _burnInfo)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
    {
        uint infosCount = _burnInfo.length;
        for (uint i; i < infosCount; ) {
            MintBurnInfo memory info = _burnInfo[i];
            _burn(_index, info.recipient, info.share);

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IFeePool
    function mintMultiple(address _index, MintBurnInfo[] calldata _mintInfo)
        external
        override
        onlyRole(FEE_MANAGER_ROLE)
    {
        _mintMultiple(_index, _mintInfo);
    }

    /// @inheritdoc IFeePool
    function withdrawableAmountOf(address _index, address _account) external view override returns (uint) {
        uint _currentBalance = IERC20(_index).balanceOf(address(this)) +
            IERC20(_index).balanceOf(IIndex(_index).factory());
        uint _accumulatedTokenPerTotalSupplyInBase = accumulatedTokenPerTotalSupplyInBaseOf[_index];
        uint _totalShares = totalSharesOf[_index];
        if (_totalShares != 0) {
            uint tokenIncrease = _currentBalance - lastTokenBalanceOf[_index];
            if (tokenIncrease != 0) {
                unchecked {
                    // overflow is desired
                    _accumulatedTokenPerTotalSupplyInBase += (tokenIncrease * BP.DECIMAL_FACTOR) / _totalShares;
                }
            }
        }

        uint _lastAccumulatedTokenPerTotalSupplyInBase = shareOf[_index][_account] == 0
            ? _accumulatedTokenPerTotalSupplyInBase
            : lastAccumulatedTokenPerTotalSupplyInBaseOf[_index][_account];
        uint accumulatedTokenPerTotalSupplyInBaseIncrease;
        unchecked {
            // overflow is desired
            accumulatedTokenPerTotalSupplyInBaseIncrease =
                _accumulatedTokenPerTotalSupplyInBase -
                _lastAccumulatedTokenPerTotalSupplyInBase;
        }
        uint increase = (shareOf[_index][_account] * accumulatedTokenPerTotalSupplyInBaseIncrease) / BP.DECIMAL_FACTOR;

        return increase + withdrawableOf[_index][_account];
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IFeePool).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Accumulates account rewards per index
    function _accumulateAccountRewards(address _index, address _account) internal {
        uint _lastAccumulatedTokenPerTotalSupplyInBase = shareOf[_index][_account] == 0
            ? accumulatedTokenPerTotalSupplyInBaseOf[_index]
            : lastAccumulatedTokenPerTotalSupplyInBaseOf[_index][_account];

        uint accumulatedTokenPerTotalSupplyInBaseIncrease;
        unchecked {
            // overflow is desired
            accumulatedTokenPerTotalSupplyInBaseIncrease =
                accumulatedTokenPerTotalSupplyInBaseOf[_index] -
                _lastAccumulatedTokenPerTotalSupplyInBase;
        }

        if (accumulatedTokenPerTotalSupplyInBaseIncrease != 0) {
            uint increase = (shareOf[_index][_account] * accumulatedTokenPerTotalSupplyInBaseIncrease) /
                BP.DECIMAL_FACTOR;
            if (increase != 0) {
                withdrawableOf[_index][_account] += increase;
            }
        }

        lastAccumulatedTokenPerTotalSupplyInBaseOf[_index][_account] = accumulatedTokenPerTotalSupplyInBaseOf[_index];
    }

    function _mintMultiple(address _index, MintBurnInfo[] calldata _mintInfo) internal {
        uint infosCount = _mintInfo.length;
        for (uint i; i < infosCount; ) {
            MintBurnInfo memory info = _mintInfo[i];
            _mint(_index, info.recipient, info.share);

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Withdraws balance from `_src` address and transfers to `_recipient` within the given index
    /// @param _index Index to withdraw
    /// @param _src Source address
    /// @param _recipient Recipient address
    function _withdraw(
        address _index,
        address _src,
        address _recipient
    ) internal accumulateRewards(_index, _src) {
        uint amount = withdrawableOf[_index][_src];
        if (amount != 0) {
            withdrawableOf[_index][_src] = 0;
            IERC20(_index).safeTransfer(_recipient, amount);

            emit Withdraw(_index, _recipient, amount);
        }
    }

    /// @notice Mints shares for `_recipient` address within the given index
    /// @param _index Index to mint fee pool's shares for
    /// @param _recipient Recipient address
    /// @param _share Shares amount to mint
    function _mint(
        address _index,
        address _recipient,
        uint _share
    ) internal accumulateRewards(_index, _recipient) {
        shareOf[_index][_recipient] += _share;
        totalSharesOf[_index] += _share;

        emit Mint(_index, _recipient, _share);
    }

    /// @notice Burns shares for `_recipient` address within the given index
    /// @param _index Index to burn fee pool's shares for
    /// @param _recipient Recipient address
    /// @param _share Shares amount to burn
    function _burn(
        address _index,
        address _recipient,
        uint _share
    ) internal accumulateRewards(_index, _recipient) {
        shareOf[_index][_recipient] -= _share;
        totalSharesOf[_index] -= _share;

        emit Burn(_index, _recipient, _share);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override onlyRole(FEE_MANAGER_ROLE) {
        require(_newImpl.supportsInterface(type(IFeePool).interfaceId), "FeePool: INTERFACE");
    }

    uint256[40] private __gap;
}