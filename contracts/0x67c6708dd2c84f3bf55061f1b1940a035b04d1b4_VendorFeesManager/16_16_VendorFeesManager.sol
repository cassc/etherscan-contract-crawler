// SPDX-License-Identifier: No License
/**
 * @title Vendor Factory Contract
 * @author JeffX, 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "./interfaces/IPoolFactory.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IErrors.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract VendorFeesManager is
    IErrors,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    event ChangeFee(address _pool, uint48 _feeRate, uint256 _type);

    IPoolFactory public factory;
    mapping(address => uint256) public rateFunction;    // 1 for constant, 2 annualized fee rate
    mapping(address => uint48) public feeRates;         // Fee rate for the pool, annual or decreasing

    /* ========== CONSTANT VARIABLES ========== */
    uint256 private constant HUNDRED_PERCENT = 100_0000;
    uint48 private constant SECONDS_IN_YEAR = 31_536_000;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice                 Sets the address of the factory
    /// @param _factory         Address of the Vendor Pool Factory
    function initialize(IPoolFactory _factory) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        if (address(_factory) == address(0)) revert ZeroAddress();
        factory = _factory;
    }

    /// @notice                 During deployment of pool sets fee details
    /// @param _pool            Address of pool
    /// @param _feeRate         Rate value
    /// @param _type            Type of the fee: 1 for constant, 2 annualized
    function setPoolFees(
        address _pool,
        uint48 _feeRate,
        uint256 _type
    ) external {
        if (_type < 1 || _type > 2) revert InvalidType();
        uint256 rateType = rateFunction[_pool];
        if (rateType != 0 && rateType != _type) revert InvalidType();
        if (!factory.pools(_pool)) revert NotAPool(); // Make sure we are setting the fee for a pool deployed by VendorFactory
        if (
            msg.sender == address(factory) ||
            ILendingPool(_pool).owner() == msg.sender
        ) {
            feeRates[_pool] = _feeRate;
            rateFunction[_pool] = _type;
            emit ChangeFee(_pool, _feeRate, _type);
        } else {
            revert NoPermission();
        }
    }

    /// @notice                  Returns the fee for a pool for a given amount
    /// @param _pool             Address of pool
    /// @param _rawPayoutAmount  Raw amount of payout tokens before fee
    function getFee(address _pool, uint256 _rawPayoutAmount)
        external
        view
        returns (uint256)
    {
        if (!factory.pools(_pool)) revert NotAPool();
        ILendingPool pool = ILendingPool(_pool);
        if (block.timestamp > pool.expiry()) revert PoolClosed();

        if (rateFunction[_pool] == 2) {
            return
                (_rawPayoutAmount * getCurrentRate(address(_pool))) /
                HUNDRED_PERCENT;
        }

        return (_rawPayoutAmount * feeRates[_pool]) / HUNDRED_PERCENT;
    }

    ///@notice                  Get the fee rate in % of the given pool 1% = 10000
    ///@param _pool             That we would like to get the rate of
    function getCurrentRate(address _pool) public view returns (uint48) {
        if (ILendingPool(_pool).expiry() <= block.timestamp) return 0;
        if (block.timestamp > 2**48 - 1) revert InvalidExpiry();
        if (rateFunction[_pool] == 2) {
            return
                (feeRates[_pool] *
                    uint48((ILendingPool(_pool).expiry() - block.timestamp))) /
                SECONDS_IN_YEAR;
        }
        return feeRates[_pool];
    }

    /* ========== UPGRADES ========== */
    ///@notice                  Contract version for history
    ///@return                  Contract version
    function version() external pure returns (uint256) {
        return 1;
    }

    ///@notice                  Pre-upgrade checks
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}