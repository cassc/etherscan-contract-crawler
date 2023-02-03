// SPDX-License-Identifier: No License
/**
 * @title Vendor Factory Contract
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/ILendingPool.sol";
import "./interfaces/ILicenseEngine.sol";
import "./interfaces/IFeesManager.sol";
import "./interfaces/IErrors.sol";

contract PoolFactory is
    IErrors,
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    IStructs
{
    /* ========== EVENTS ========== */
    event DeployPool(
        address _poolAddress,
        address _deployer,
        uint256 _mintRatio,
        address _colToken,
        address _lendToken,
        uint48 _protocolFee,
        uint48 _protocolColFee,
        uint48 _expiry,
        address[] _borrowers
    );

    /* ========== CONSTANT VARIABLES ========== */
    uint256 private constant HUNDRED_PERCENT = 100_0000;

    /* ========== STATE VARIABLES ========== */
    IFeesManager public feesManager;
    address public poolImplementationAddress;   // Current pool implementation
    address public rollBackImplementation;      // The previous pool implementation. Required due to the way LendingPool UUPS upgrades.
    address public oracle;
    ILicenseEngine public licenseEngine;
    address public treasury;
    uint48 public protocolFee;                  // 1% = 1000000 Rate that we charge the lenders profits
    uint48 public protocolColFee;               // Percent of defaulted collateral we take from the lenders pool
    mapping(address => bool) public allowList;  // List of tokens allowed to be used in the pool
    mapping(address => bool) public pools;
    mapping(address => bool) public pausedPools;
    bool public allowUpgrade;
    bool public fullStop;
    address public firstResponder;
    address public owner;

    address private _grantedOwner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice                 Initialize the factory
    /// @param _implementation  Implementation of the lending pool
    /// @param _oracle          Oracle address that will be referenced by pools when deciding on whether to allow borrowing.
    /// @param _feesManager     Address of contract that calculates pool fees
    /// @param _licenseEngine   Address of the contract that manages the licenses and discounts
    /// @param _protocolFee     Fee that vendor will take of interest made and defaulted collateral. // Subject to be split in 2 different fees
    /// @param _treasury        Vendor fees will be sent to this address
    /// @param _allowList       Tokens that can be used in new pools.
    function initialize(
        address _implementation,
        address _oracle,
        address _licenseEngine,
        address _feesManager,
        uint48 _protocolFee,
        uint48 _protocolColFee,
        address _treasury,
        address[] calldata _allowList,
        address _firstResponder
    ) external initializer {
        __UUPSUpgradeable_init();
        __Pausable_init();
        if (
            _implementation == address(0) ||
            _oracle == address(0) ||
            _licenseEngine == address(0) ||
            _feesManager == address(0) ||
            _treasury == address(0) ||
            _firstResponder == address(0)
        ) revert ZeroAddress();
        owner = msg.sender;
        poolImplementationAddress = _implementation;
        rollBackImplementation = _implementation;
        oracle = _oracle;
        licenseEngine = ILicenseEngine(_licenseEngine);
        feesManager = IFeesManager(_feesManager);
        protocolFee = _protocolFee;
        protocolColFee = _protocolColFee;
        treasury = _treasury;
        firstResponder = _firstResponder;
        for (uint256 i = 0; i < _allowList.length; ++i) {
            allowList[_allowList[i]] = true;
        }
    }

    /// @notice                 Deploy a new lending pool as a minimal proxy
    /// @param _mintRatio       Mint ratio for the pool. See docs for more info
    /// @param _colToken        Collateral token
    /// @param _lendToken       Token that will be lent out
    /// @param _feeRate         Interest that will be due on expiry by borrowers.
    /// @param _type            Type of interest rate charged by the lender
    /// @param _expiry          Pool's expiration date
    /// @return                 Address of the new pool
    function deployPool(
        uint256 _mintRatio,
        address _colToken,
        address _lendToken,
        uint48 _feeRate,
        uint256 _type,
        uint48 _expiry,
        address[] calldata _borrowers,
        uint256 _undercollateralized,
        uint256 _licenseId
    ) external whenNotPaused returns (address) {
        if (!allowList[_lendToken]) revert LendTokenNotSupported();
        if (!allowList[_colToken]) revert ColTokenNotSupported();
        if (_colToken == _lendToken) revert InvalidTokenPair();
        if (_mintRatio == 0) revert MintRatio0();
        if (_expiry < block.timestamp + 24 hours) revert InvalidExpiry();
        if (_feeRate > HUNDRED_PERCENT) revert FeeTooLarge();
        if (_undercollateralized < 0 || _undercollateralized > 1)
            revert InvalidType();

        return
            _initializePool(
                UserPoolData(
                    _mintRatio,
                    _colToken,
                    _lendToken,
                    _feeRate,
                    _type,
                    _expiry,
                    _borrowers,
                    _undercollateralized,
                    _licenseId
                )
            );
    }

    /// @notice                 Internal logic for pool deployment
    /// @dev                    UserPoolData is added to bypass the stack limit requirement
    /// @param poolData         All of the user supplied parameters
    /// @return                 Address of the new pool
    function _initializePool(UserPoolData memory poolData)
        private
        returns (address)
    {
        address lendingPool = address(
            new ERC1967Proxy(poolImplementationAddress, "")
        );

        (uint48 discountValue, uint48 discountColValue) = licenseDiscount(
            poolData._licenseId
        );
        uint48 hundredPercent = uint48(HUNDRED_PERCENT);
        ILendingPool(lendingPool).initialize(
            Data(
                msg.sender,
                poolData._mintRatio,
                poolData._colToken,
                poolData._lendToken,
                poolData._expiry,
                poolData._borrowers,
                (protocolFee * (hundredPercent - discountValue)) /
                    hundredPercent,
                (protocolColFee * (hundredPercent - discountColValue)) /
                    hundredPercent,
                address(feesManager),
                oracle,
                address(this),
                poolData._undercollateralized
            )
        );

        // This emit should come before setting the fee for the graph purposes.
        emit DeployPool(
            lendingPool,
            msg.sender,
            poolData._mintRatio,
            poolData._colToken,
            poolData._lendToken,
            (protocolFee * (hundredPercent - discountValue)) / hundredPercent,
            (protocolColFee * (hundredPercent - discountColValue)) /
                hundredPercent,
            poolData._expiry,
            poolData._borrowers
        );

        pools[lendingPool] = true; // Register the pool before setting the fee, since FeeManager is checking if pool created by Factory
        feesManager.setPoolFees(lendingPool, poolData._feeRate, poolData._type);

        return lendingPool;
    }

    /* ========== SETTERS ========== */
    /// @notice                 Update the lending pool implementation address
    function setImplementation(address _implementation) external {
        onlyOwner();
        rollBackImplementation = poolImplementationAddress;
        poolImplementationAddress = _implementation;
    }

    /// @notice                 Update the lending pool downgrade implementation address
    function setRollbackImplementation(address _implementation) external {
        onlyOwner();
        rollBackImplementation = _implementation;
    }

    /// @notice                 Update the oracle address
    function setOracle(address _oracle) external {
        onlyOwner();
        oracle = _oracle;
    }

    /// @notice                 Update treasury address
    function setTreasury(address _treasury) external {
        onlyOwner();
        treasury = _treasury;
    }

    /// @notice                 Update treasury address
    function setFeesManager(address _feesManager) external {
        onlyOwner();
        feesManager = IFeesManager(_feesManager);
    }

    /// @notice                 Update treasury address
    function setLicenseEngine(address _licenseEngine) external {
        onlyOwner();
        licenseEngine = ILicenseEngine(_licenseEngine);
    }

    /// @notice                 Update VENDOR fee
    function setProtocolFee(uint48 _protocolFee) external {
        onlyOwner();
        protocolFee = _protocolFee;
    }

    /// @notice                 Add or remove collateral from the allow list
    function setCollateralAllowList(address _col, bool _allowed) public {
        onlyOwner();
        allowList[_col] = _allowed;
    }

    /// @notice                 Update the first responder
    function setFirstResponder(address _newResponder) external {
        onlyOwner();
        firstResponder = _newResponder;
    }

    /* ========== UTILITY ========== */
    ///@notice                  Pause the factory contract
    function setPause(bool _paused) public {
        onlyOwnerORFirstResponder();
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @notice                 This function will now accept the license id that pool deployer has provided and will validate it.
    /// @dev                    If license is valid and has a valid discount associated with it, then such discount will be returned.
    /// @param _licenseId       Id of the license
    /// @return                 Discount amounts for a given license (lendDiscount, colDiscount) as percents
    function licenseDiscount(uint256 _licenseId)
        private
        returns (uint48, uint48)
    {
        if (
            !licenseEngine.exists(_licenseId) ||
            msg.sender != licenseEngine.ownerOf(_licenseId)
        ) {
            return (0, 0);
        } else {
            (
                uint256 maxCount,
                uint256 curCount,
                uint48 discount,
                uint48 colDiscount,
                uint48 expiry
            ) = licenseEngine.licenses(_licenseId);
            if (block.timestamp < expiry && curCount + 1 <= maxCount) {
                if (discount > HUNDRED_PERCENT || colDiscount > HUNDRED_PERCENT)
                    revert DiscountTooLarge();
                licenseEngine.incrementCurrentPoolCount(_licenseId);
                return (discount, colDiscount);
            }
        }
        return (0, 0);
    }

    ///@notice                  Pause/unpause all of the pools deployed by this factory
    function setFullStop(bool _paused) external {
        onlyOwnerORFirstResponder();
        fullStop = _paused;
    }

    ///@notice                  Pause/unpause a specific pool deployed by this factory
    function setPoolStop(address _pool, bool _paused) external {
        onlyOwnerORFirstResponder();
        pausedPools[_pool] = _paused;
    }

    ///@notice                  Check if specific pool is paused by Vendor
    function isPaused(address _pool) external view returns (bool) {
        return fullStop || pausedPools[_pool];
    }

    ///@notice                  First step in a process of changing the owner
    function grantOwnership(address newOwner) public virtual {
        onlyOwner();
        _grantedOwner = newOwner;
    }

    ///@notice                  Second step in a process of changing the owner
    function claimOwnership() public virtual {
        if (_grantedOwner != msg.sender) revert NotGranted();
        owner = _grantedOwner;
        _grantedOwner = address(0);
    }

    /* ========== MODIFIERS ========== */
    ///@notice                  Owner of the factory (Vendor)
    function onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }

    ///@notice                  Owner or first responder, just in case we have access to one of them faster
    function onlyOwnerORFirstResponder() private view {
        if (msg.sender != firstResponder && msg.sender != owner)
            revert NotAuthorized();
    }

    /* ========== UPGRADES ========== */
    ///@notice                  Contract version for history
    ///@return                  Contract version
    function version() external pure returns (uint256) {
        return 1;
    }

    ///@notice                  Allows lenders to update the implementation of their pools or extend expiry
    function setAllowUpgrade(bool _allowed) external {
        onlyOwner();
        allowUpgrade = _allowed;
    }

    ///@notice                  Pre-upgrade checks
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        whenNotPaused
    {
        onlyOwner();
    }
}