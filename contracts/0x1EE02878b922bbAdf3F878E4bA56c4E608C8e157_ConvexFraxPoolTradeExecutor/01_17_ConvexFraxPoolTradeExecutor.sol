//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../BaseTradeExecutor.sol";
import {ConvexPositionHandler} from "./ConvexPositionHandler.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title ConvexTradeExecutor
/// @author PradeepSelva
/// @notice A contract to execute strategy's trade, on Convex (frax)
contract ConvexFraxPoolTradeExecutor is
    BaseTradeExecutor,
    ConvexPositionHandler,
    ReentrancyGuard
{
    /// @notice event emitted when harvester is updated
    event UpdatedHarvester(
        address indexed oldHandler,
        address indexed newHandler
    );
    /// @notice event emitted when slippage is updated
    event UpdatedSlippage(
        uint256 indexed oldSlippage,
        uint256 indexed newSlippage
    );

    /// @notice creates a new ConvexTradeExecutor with required state
    /// @param _harvester address of harvester
    /// @param _vault address of vault
    constructor(address _harvester, address _vault) BaseTradeExecutor(_vault) {
        ConvexPositionHandler._configHandler(
            _harvester,
            BaseTradeExecutor.vaultWantToken()
        );
    }

    /*///////////////////////////////////////////////////////////////
                         VIEW FUNCTONS
  //////////////////////////////////////////////////////////////*/
    /// @notice This gives the total funds in the contract in terms of want token
    /// @return totalBalance Total balance of contract in want token
    /// @return blockNumber Current block number
    function totalFunds() public view override returns (uint256, uint256) {
        return ConvexPositionHandler.positionInWantToken();
    }

    /*///////////////////////////////////////////////////////////////
                    STATE MODIFICATION FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /// @notice Keeper function to set max accepted slippage of swaps
    /// @param _slippage Max accepted slippage during harvesting
    function setSlippage(uint256 _slippage) external onlyGovernance {
        uint256 oldSlippage = ConvexPositionHandler.maxSlippage;

        ConvexPositionHandler._setSlippage(_slippage);
        emit UpdatedSlippage(oldSlippage, _slippage);
    }

    /// @notice Governance function to set how position value should be calculated, i.e using virtual price or calc withdraw
    /// @param _useVirtualPriceForPosValue bool signifying if virtual price should be used to calculate position value
    function setUseVirtualPriceForPosValue(bool _useVirtualPriceForPosValue)
        external
        onlyGovernance
    {
        ConvexPositionHandler._setUseVirtualPriceForPosValue(
            _useVirtualPriceForPosValue
        );
    }

    /// @param _harvester address of harvester
    function setHandler(address _harvester) external onlyGovernance {
        address oldHarvester = address(ConvexPositionHandler.harvester);

        ConvexPositionHandler._configHandler(_harvester, vaultWantToken());
        emit UpdatedHarvester(oldHarvester, _harvester);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT / WITHDRAW FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /// @notice To deposit into the Curve Pool
    /// @dev Converts USDC to lp tokens via Curve
    /// @param _data Encoded AmountParams as _data with USDC amount
    function _initateDeposit(bytes calldata _data) internal override {
        ConvexPositionHandler._deposit(_data);
        BaseTradeExecutor.confirmDeposit();
    }

    /// @notice To withdraw from ConvexHandler
    /// @dev  Converts Curve Lp Tokens  back to USDC.
    ///  @param _data Encoded WithdrawParams as _data with USDC token amount
    function _initiateWithdraw(bytes calldata _data) internal override {
        ConvexPositionHandler._withdraw(_data);
        BaseTradeExecutor.confirmWithdraw();
    }

    /// @notice Functionlity to execute after deposit is completed
    /// @dev This is not required in ConvexTradeExecutor, hence empty. This follows the BaseTradeExecutor interface
    function _confirmDeposit() internal override {}

    /// @notice Functionlity to execute after withdraw is completed
    /// @dev This is not required in ConvexTradeExecutor, hence empty. This follows the BaseTradeExecutor interface
    function _confirmWithdraw() internal override {}

    /*///////////////////////////////////////////////////////////////
                    OPEN / CLOSE FUNCTIONS
  //////////////////////////////////////////////////////////////*/

    /// @notice To open staking position in Convex
    /// @dev stakes the specified Curve Lp Tokens into Convex's UST3-Wormhole pool
    /// @param _data Encoded AmountParams as _data with LP Token amount
    function openPosition(bytes calldata _data) public onlyKeeper nonReentrant {
        ConvexPositionHandler._openPosition(_data);
    }

    /// @notice To close Convex Staking Position
    /// @dev Unstakes from Convex position and gives back them as Curve Lp Tokens along with rewards like CRV, CVX.
    /// @param _data Encoded AmountParams as _data with LP token amount
    function closePosition(bytes calldata _data)
        public
        onlyKeeper
        nonReentrant
    {
        ConvexPositionHandler._closePosition(_data);
    }

    /*///////////////////////////////////////////////////////////////
                    REWARDS FUNCTION
   //////////////////////////////////////////////////////////////*/
    /// @notice To claim rewards from Convex Staking position
    /// @dev Claims Convex Staking position rewards, and converts them to wantToken i.e., USDC.
    /// @param _data is not needed here (empty param, to satisfy interface)
    function claimRewards(bytes calldata _data) public onlyKeeper nonReentrant {
        ConvexPositionHandler._claimRewards(_data);
    }
}