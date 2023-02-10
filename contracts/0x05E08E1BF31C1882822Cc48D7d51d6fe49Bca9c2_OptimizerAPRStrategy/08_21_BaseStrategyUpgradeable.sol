// SPDX-License-Identifier: GPL-3.0

/*
                  *                                                  █                              
                *****                                               ▓▓▓                             
                  *                                               ▓▓▓▓▓▓▓                         
                                   *            ///.           ▓▓▓▓▓▓▓▓▓▓▓▓▓                       
                                 *****        ////////            ▓▓▓▓▓▓▓                          
                                   *       /////////////            ▓▓▓                             
                     ▓▓                  //////////////////          █         ▓▓                   
                   ▓▓  ▓▓             ///////////////////////                ▓▓   ▓▓                
                ▓▓       ▓▓        ////////////////////////////           ▓▓        ▓▓              
              ▓▓            ▓▓    /////////▓▓▓///////▓▓▓/////////       ▓▓             ▓▓            
           ▓▓                 ,////////////////////////////////////// ▓▓                 ▓▓         
        ▓▓                  //////////////////////////////////////////                     ▓▓      
      ▓▓                  //////////////////////▓▓▓▓/////////////////////                          
                       ,////////////////////////////////////////////////////                        
                    .//////////////////////////////////////////////////////////                     
                     .//////////////////////////██.,//////////////////////////█                     
                       .//////////////////////████..,./////////////////////██                       
                        ...////////////////███████.....,.////////////////███                        
                          ,.,////////////████████ ........,///////////████                          
                            .,.,//////█████████      ,.......///////████                            
                               ,..//████████           ........./████                               
                                 ..,██████                .....,███                                 
                                    .██                     ,.,█                                    
                                                                                                    
                                                                                                    
                                                                                                    
               ▓▓            ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓               ▓▓▓▓▓▓▓▓▓▓          
             ▓▓▓▓▓▓          ▓▓▓    ▓▓▓       ▓▓▓               ▓▓               ▓▓   ▓▓▓▓         
           ▓▓▓    ▓▓▓        ▓▓▓    ▓▓▓       ▓▓▓    ▓▓▓        ▓▓               ▓▓▓▓▓             
          ▓▓▓        ▓▓      ▓▓▓    ▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓          
*/

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./BaseStrategyEvents.sol";

/// @title BaseStrategyUpgradeable
/// @author Forked from https://github.com/yearn/yearn-managers/blob/master/contracts/BaseStrategy.sol
/// @notice `BaseStrategyUpgradeable` implements all of the required functionalities to interoperate
/// with the `PoolManager` Contract.
/// @dev This contract should be inherited and the abstract methods implemented to adapt the `Strategy`
/// to the particular needs it has to create a return.
abstract contract BaseStrategyUpgradeable is BaseStrategyEvents, AccessControlAngleUpgradeable {
    using SafeERC20 for IERC20;

    uint256 public constant BASE = 10**18;
    uint256 public constant SECONDS_PER_YEAR = 31556952;

    /// @notice Role for `PoolManager` only - keccak256("POOLMANAGER_ROLE")
    bytes32 public constant POOLMANAGER_ROLE = 0x5916f72c85af4ac6f7e34636ecc97619c4b2085da099a5d28f3e58436cfbe562;
    /// @notice Role for guardians and governors - keccak256("GUARDIAN_ROLE")
    bytes32 public constant GUARDIAN_ROLE = 0x55435dd261a4b9b3364963f7738a7a662ad9c84396d64be3365284bb7f0a5041;
    /// @notice Role for keepers - keccak256("KEEPER_ROLE")
    bytes32 public constant KEEPER_ROLE = 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab;

    // ================================= REFERENCES ================================

    /// @notice See note on `setEmergencyExit()`
    bool public emergencyExit;

    /// @notice Reference to the protocol's collateral `PoolManager`
    IPoolManager public poolManager;

    /// @notice Reference to the ERC20 farmed by this strategy
    IERC20 public want;

    /// @notice Base of the ERC20 token farmed by this strategy
    uint256 public wantBase;

    // ================================= PARAMETERS ================================

    /// @notice Use this to adjust the threshold at which running a debt causes a
    /// harvest trigger. See `setDebtThreshold()` for more details
    uint256 public debtThreshold;

    uint256[46] private __gapBaseStrategy;

    // ================================ CONSTRUCTOR ================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Constructor of the `BaseStrategyUpgradeable`
    /// @param _poolManager Address of the `PoolManager` lending collateral to this strategy
    /// @param governor Governor address of the protocol
    /// @param guardian Address of the guardian
    function _initialize(
        address _poolManager,
        address governor,
        address guardian,
        address[] memory keepers
    ) internal initializer {
        poolManager = IPoolManager(_poolManager);
        want = IERC20(poolManager.token());
        wantBase = 10**(IERC20Metadata(address(want)).decimals());
        if (guardian == address(0) || governor == address(0) || governor == guardian) revert ZeroAddress();
        // AccessControl
        // Governor is guardian so no need for a governor role
        _setupRole(GUARDIAN_ROLE, guardian);
        _setupRole(GUARDIAN_ROLE, governor);
        _setupRole(POOLMANAGER_ROLE, address(_poolManager));
        _setRoleAdmin(POOLMANAGER_ROLE, POOLMANAGER_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, POOLMANAGER_ROLE);

        // Initializing roles first
        uint256 keepersLength = keepers.length;
        for (uint256 i; i < keepersLength; ++i) {
            if (keepers[i] == address(0)) revert ZeroAddress();
            _setupRole(KEEPER_ROLE, keepers[i]);
        }
        _setRoleAdmin(KEEPER_ROLE, GUARDIAN_ROLE);

        debtThreshold = 100 * BASE;
        emergencyExit = false;
        // Give `PoolManager` unlimited access (might save gas)
        want.safeIncreaseAllowance(address(poolManager), type(uint256).max);
    }

    // =============================== CORE FUNCTIONS ==============================

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting
    /// the Strategy's position.
    function harvest() external {
        _report();
        // Check if free returns are left, and re-invest them
        _adjustPosition();
    }

    /// @notice Same as the function above with a `data` parameter to help adjust the position
    /// @dev Since this function is permissionless, strategy implementations should be made
    /// to remain safe regardless of the data that is passed in the call
    function harvest(bytes memory data) external virtual {
        _report();
        _adjustPosition(data);
    }

    /// @notice Same as above with a `borrowInit` parameter to help in case of the convergence of the `adjustPosition`
    /// method
    function harvest(uint256 borrowInit) external onlyRole(KEEPER_ROLE) {
        _report();
        _adjustPosition(borrowInit);
    }

    /// @notice Withdraws `_amountNeeded` to `poolManager`.
    /// @param _amountNeeded How much `want` to withdraw.
    /// @return amountFreed How much `want` withdrawn.
    /// @return _loss Any realized losses
    /// @dev This may only be called by the `PoolManager`
    function withdraw(uint256 _amountNeeded)
        external
        onlyRole(POOLMANAGER_ROLE)
        returns (uint256 amountFreed, uint256 _loss)
    {
        // Liquidate as much as possible `want` (up to `_amountNeeded`)
        (amountFreed, _loss) = _liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    // =============================== VIEW FUNCTIONS ==============================

    /// @notice Provides an accurate estimate for the total amount of assets
    /// (principle + return) that this Strategy is currently managing,
    /// denominated in terms of `want` tokens.
    /// This total should be "realizable" e.g. the total value that could
    /// *actually* be obtained from this Strategy if it were to divest its
    /// entire position based on current on-chain conditions.
    /// @return The estimated total assets in this Strategy.
    /// @dev Care must be taken in using this function, since it relies on external
    /// systems, which could be manipulated by the attacker to give an inflated
    /// (or reduced) value produced by this function, based on current on-chain
    /// conditions (e.g. this function is possible to influence through
    /// flashloan attacks, oracle manipulations, or other DeFi attack
    /// mechanisms).
    function estimatedTotalAssets() public view virtual returns (uint256);

    /// @notice Provides an indication of whether this strategy is currently "active"
    /// in that it is managing an active position, or will manage a position in
    /// the future. This should correlate to `harvest()` activity, so that Harvest
    /// events can be tracked externally by indexing agents.
    /// @return True if the strategy is actively managing a position.
    function isActive() public view returns (bool) {
        return estimatedTotalAssets() != 0;
    }

    // ============================= INTERNAL FUNCTIONS ============================

    /// @notice Prepares the Strategy to return, recognizing any profits or losses
    /// @dev In the rare case the Strategy is in emergency shutdown, this will exit
    /// the Strategy's position.
    /// @dev  When `_report()` is called, the Strategy reports to the Manager (via
    /// `poolManager.report()`), so in some cases `harvest()` must be called in order
    /// to take in profits, to borrow newly available funds from the Manager, or
    /// otherwise adjust its position. In other cases `harvest()` must be
    /// called to report to the Manager on the Strategy's position, especially if
    /// any losses have occurred.
    /// @dev As keepers may directly profit from this function, there may be front-running problems with miners bots,
    /// we may have to put an access control logic for this function to only allow white-listed addresses to act
    /// as keepers for the protocol
    function _report() internal {
        uint256 profit;
        uint256 loss;
        uint256 debtOutstanding = poolManager.debtOutstanding();
        uint256 debtPayment;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 amountFreed = _liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding - amountFreed;
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed - debtOutstanding;
            }
            debtPayment = debtOutstanding - loss;
        } else {
            // Free up returns for Manager to pull
            (profit, loss, debtPayment) = _prepareReturn(debtOutstanding);
        }
        emit Harvested(profit, loss, debtPayment, debtOutstanding);

        // Allows Manager to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Manager.
        poolManager.report(profit, loss, debtPayment);
    }

    /// @notice Performs any Strategy unwinding or other calls necessary to capture the
    /// "free return" this Strategy has generated since the last time its core
    /// position(s) were adjusted. Examples include unwrapping extra rewards.
    /// This call is only used during "normal operation" of a Strategy, and
    /// should be optimized to minimize losses as much as possible.
    ///
    /// This method returns any realized profits and/or realized losses
    /// incurred, and should return the total amounts of profits/losses/debt
    /// payments (in `want` tokens) for the Manager's accounting (e.g.
    /// `want.balanceOf(this) >= _debtPayment + _profit`).
    ///
    /// `_debtOutstanding` will be 0 if the Strategy is not past the configured
    /// debt limit, otherwise its value will be how far past the debt limit
    /// the Strategy is. The Strategy's debt limit is configured in the Manager.
    ///
    /// NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
    ///       It is okay for it to be less than `_debtOutstanding`, as that
    ///       should only used as a guide for how much is left to pay back.
    ///       Payments should be made to minimize loss from slippage, debt,
    ///       withdrawal fees, etc.
    ///
    /// See `poolManager.debtOutstanding()`.
    function _prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    /// @notice Performs any adjustments to the core position(s) of this Strategy given
    /// what change the Manager made in the "investable capital" available to the
    /// Strategy. Note that all "free capital" in the Strategy after the report
    /// was made is available for reinvestment. Also note that this number
    /// could be 0, and you should handle that scenario accordingly.
    function _adjustPosition() internal virtual;

    /// @notice same as _adjustPosition but with an initial parameter
    function _adjustPosition(uint256) internal virtual;

    /// @notice same as _adjustPosition but with permissionless parameters
    function _adjustPosition(bytes memory) internal virtual {
        _adjustPosition();
    }

    /// @notice Liquidates up to `_amountNeeded` of `want` of this strategy's positions,
    /// irregardless of slippage. Any excess will be re-invested with `_adjustPosition()`.
    /// This function should return the amount of `want` tokens made available by the
    /// liquidation. If there is a difference between them, `_loss` indicates whether the
    /// difference is due to a realized loss, or if there is some other situation at play
    /// (e.g. locked funds) where the amount made available is less than what is needed.
    ///
    /// NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
    function _liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 _liquidatedAmount, uint256 _loss);

    /// @notice Liquidates everything and returns the amount that got freed.
    /// This function is used during emergency exit instead of `_prepareReturn()` to
    /// liquidate all of the Strategy's positions back to the Manager.
    function _liquidateAllPositions() internal virtual returns (uint256 _amountFreed);

    /// @notice Override this to add all tokens/tokenized positions this contract
    /// manages on a *persistent* basis (e.g. not just for swapping back to
    /// want ephemerally).
    ///
    /// NOTE: Do *not* include `want`, already included in `sweep` below.
    ///
    /// Example:
    /// ```
    ///    function _protectedTokens() internal override view returns (address[] memory) {
    ///      address[] memory protected = new address[](3);
    ///      protected[0] = tokenA;
    ///      protected[1] = tokenB;
    ///      protected[2] = tokenC;
    ///      return protected;
    ///    }
    /// ```
    function _protectedTokens() internal view virtual returns (address[] memory);

    // ================================= GOVERNANCE ================================

    /// @notice Activates emergency exit. Once activated, the Strategy will exit its
    /// position upon the next harvest, depositing all funds into the Manager as
    /// quickly as is reasonable given on-chain conditions.
    /// @dev This may only be called by the `PoolManager`, because when calling this the `PoolManager` should at the same
    /// time update the debt ratio
    /// @dev This function can only be called once by the `PoolManager` contract
    /// @dev See `poolManager.setEmergencyExit()` and `harvest()` for further details.
    function setEmergencyExit() external onlyRole(POOLMANAGER_ROLE) {
        emergencyExit = true;
        emit EmergencyExitActivated();
    }

    /// @notice Sets how far the Strategy can go into loss without a harvest and report
    /// being required.
    /// @param _debtThreshold How big of a loss this Strategy may carry without
    /// @dev By default this is 0, meaning any losses would cause a harvest which
    /// will subsequently report the loss to the Manager for tracking.
    function setDebtThreshold(uint256 _debtThreshold) external onlyRole(GUARDIAN_ROLE) {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    /// @notice Removes tokens from this Strategy that are not the type of tokens
    /// managed by this Strategy. This may be used in case of accidentally
    /// sending the wrong kind of token to this Strategy.
    ///
    /// Tokens will be sent to `governance()`.
    ///
    /// This will fail if an attempt is made to sweep `want`, or any tokens
    /// that are protected by this Strategy.
    ///
    /// This may only be called by governance.
    /// @param _token The token to transfer out of this `PoolManager`.
    /// @param to Address to send the tokens to.
    /// @dev
    /// Implement `_protectedTokens()` to specify any additional tokens that
    /// should be protected from sweeping in addition to `want`.
    function sweep(address _token, address to) external onlyRole(GUARDIAN_ROLE) {
        if (_token == address(want)) revert InvalidToken();

        address[] memory __protectedTokens = _protectedTokens();
        uint256 protectedTokensLength = __protectedTokens.length;
        for (uint256 i; i < protectedTokensLength; ++i)
            // In the strategy we use so far, the only protectedToken is the want token
            // and this has been checked above
            if (_token == __protectedTokens[i]) revert InvalidToken();

        IERC20(_token).safeTransfer(to, IERC20(_token).balanceOf(address(this)));
    }

    // ============================= MANAGER FUNCTIONS =============================

    /// @notice Adds a new guardian address and echoes the change to the contracts
    /// that interact with this collateral `PoolManager`
    /// @param _guardian New guardian address
    /// @dev This internal function has to be put in this file because Access Control is not defined
    /// in PoolManagerInternal
    function addGuardian(address _guardian) external virtual;

    /// @notice Revokes the guardian role and propagates the change to other contracts
    /// @param guardian Old guardian address to revoke
    function revokeGuardian(address guardian) external virtual;
}