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

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

import "./interfaces/external/uniswap/IUniswapRouter.sol";
import "./interfaces/external/IWETH9.sol";
import "./interfaces/ICoreBorrow.sol";
import "./interfaces/ILiquidityGauge.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/IVaultManager.sol";

// ============================== STRUCTS AND ENUM =============================

/// @notice Action types
enum ActionType {
    transfer,
    wrapNative,
    unwrapNative,
    sweep,
    sweepNative,
    uniswapV3,
    oneInch,
    claimRewards,
    gaugeDeposit,
    borrower,
    swapper,
    mint4626,
    deposit4626,
    redeem4626,
    withdraw4626,
    // Deprecated
    prepareRedeemSavingsRate,
    // Deprecated
    claimRedeemSavingsRate,
    swapIn,
    swapOut,
    claimWeeklyInterest,
    withdraw,
    // Deprecated
    mint,
    deposit,
    // Deprecated
    openPerpetual,
    // Deprecated
    addToPerpetual,
    veANGLEDeposit,
    claimRewardsWithPerps
}

/// @notice Data needed to get permits
struct PermitType {
    address token;
    address owner;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/// @notice Data to grant permit to the router for a vault
struct PermitVaultManagerType {
    address vaultManager;
    address owner;
    bool approved;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/// @title BaseRouter
/// @author Angle Core Team
/// @notice Base contract that Angle router contracts on different chains should override
/// @dev Router contracts are designed to facilitate the composition of actions on the different modules of the protocol
abstract contract BaseRouter is Initializable {
    using SafeERC20 for IERC20;

    // ================================= REFERENCES ================================

    /// @notice Core address handling access control
    ICoreBorrow public core;
    /// @notice Address of the router used for swaps
    IUniswapV3Router public uniswapV3Router;
    /// @notice Address of 1Inch router used for swaps
    address public oneInch;

    uint256[47] private __gap;

    // ============================== EVENTS / ERRORS ==============================

    error IncompatibleLengths();
    error InvalidReturnMessage();
    error NotApprovedOrOwner();
    error NotGovernor();
    error NotGovernorOrGuardian();
    error TooSmallAmountOut();
    error TransferFailed();
    error ZeroAddress();

    /// @notice Deploys the router contract on a chain
    function initializeRouter(address _core, address _uniswapRouter, address _oneInch) public initializer {
        if (_core == address(0)) revert ZeroAddress();
        core = ICoreBorrow(_core);
        uniswapV3Router = IUniswapV3Router(_uniswapRouter);
        oneInch = _oneInch;
    }

    constructor() initializer {}

    // =========================== ROUTER FUNCTIONALITIES ==========================

    /// @notice Allows composable calls to different functions within the protocol
    /// @param paramsPermit Array of params `PermitType` used to do a 1 tx to approve the router on each token (can be done once by
    /// setting high approved amounts) which supports the `permit` standard. Users willing to interact with the contract
    /// with tokens that do not support permit should approve the contract for these tokens prior to interacting with it
    /// @param actions List of actions to be performed by the router (in order of execution)
    /// @param data Array of encoded data for each of the actions performed in this mixer. This is where the bytes-encoded parameters
    /// for a given action are stored
    /// @dev With this function, users can specify paths to swap tokens to the desired token of their choice. Yet the protocol
    /// does not verify the payload given and cannot check that the swap performed by users actually gives the desired
    /// out token: in this case funds may be made accessible to anyone on this contract if the concerned users
    /// do not perform a sweep action on these tokens
    function mixer(
        PermitType[] memory paramsPermit,
        ActionType[] calldata actions,
        bytes[] calldata data
    ) public payable virtual {
        // If all tokens have already been approved, there's no need for this step
        uint256 permitsLength = paramsPermit.length;
        for (uint256 i; i < permitsLength; ++i) {
            IERC20Permit(paramsPermit[i].token).permit(
                paramsPermit[i].owner,
                address(this),
                paramsPermit[i].value,
                paramsPermit[i].deadline,
                paramsPermit[i].v,
                paramsPermit[i].r,
                paramsPermit[i].s
            );
        }
        // Performing actions one after the others
        uint256 actionsLength = actions.length;
        for (uint256 i; i < actionsLength; ++i) {
            if (actions[i] == ActionType.transfer) {
                (address inToken, address receiver, uint256 amount) = abi.decode(data[i], (address, address, uint256));
                if (amount == type(uint256).max) amount = IERC20(inToken).balanceOf(msg.sender);
                IERC20(inToken).safeTransferFrom(msg.sender, receiver, amount);
            } else if (actions[i] == ActionType.wrapNative) {
                _wrapNative();
            } else if (actions[i] == ActionType.unwrapNative) {
                (uint256 minAmountOut, address to) = abi.decode(data[i], (uint256, address));
                _unwrapNative(minAmountOut, to);
            } else if (actions[i] == ActionType.sweep) {
                (address tokenOut, uint256 minAmountOut, address to) = abi.decode(data[i], (address, uint256, address));
                _sweep(tokenOut, minAmountOut, to);
            } else if (actions[i] == ActionType.sweepNative) {
                uint256 routerBalance = address(this).balance;
                if (routerBalance != 0) _safeTransferNative(msg.sender, routerBalance);
            } else if (actions[i] == ActionType.uniswapV3) {
                (address inToken, uint256 amount, uint256 minAmountOut, bytes memory path) = abi.decode(
                    data[i],
                    (address, uint256, uint256, bytes)
                );
                _swapOnUniswapV3(IERC20(inToken), amount, minAmountOut, path);
            } else if (actions[i] == ActionType.oneInch) {
                (address inToken, uint256 minAmountOut, bytes memory payload) = abi.decode(
                    data[i],
                    (address, uint256, bytes)
                );
                _swapOn1Inch(IERC20(inToken), minAmountOut, payload);
            } else if (actions[i] == ActionType.claimRewards) {
                (address user, address[] memory claimLiquidityGauges) = abi.decode(data[i], (address, address[]));
                _claimRewards(user, claimLiquidityGauges);
            } else if (actions[i] == ActionType.gaugeDeposit) {
                (address user, uint256 amount, address gauge, bool shouldClaimRewards) = abi.decode(
                    data[i],
                    (address, uint256, address, bool)
                );
                _gaugeDeposit(user, amount, ILiquidityGauge(gauge), shouldClaimRewards);
            } else if (actions[i] == ActionType.borrower) {
                (
                    address collateral,
                    address vaultManager,
                    address to,
                    address who,
                    ActionBorrowType[] memory actionsBorrow,
                    bytes[] memory dataBorrow,
                    bytes memory repayData
                ) = abi.decode(data[i], (address, address, address, address, ActionBorrowType[], bytes[], bytes));
                dataBorrow = _parseVaultIDs(actionsBorrow, dataBorrow, vaultManager, collateral);
                _changeAllowance(IERC20(collateral), address(vaultManager), type(uint256).max);
                _angleBorrower(vaultManager, actionsBorrow, dataBorrow, to, who, repayData);
            } else if (actions[i] == ActionType.swapper) {
                (
                    ISwapper swapperContract,
                    IERC20 inToken,
                    IERC20 outToken,
                    address outTokenRecipient,
                    uint256 outTokenOwed,
                    uint256 inTokenObtained,
                    bytes memory payload
                ) = abi.decode(data[i], (ISwapper, IERC20, IERC20, address, uint256, uint256, bytes));
                _swapper(swapperContract, inToken, outToken, outTokenRecipient, outTokenOwed, inTokenObtained, payload);
            } else if (actions[i] == ActionType.mint4626) {
                (IERC20 token, IERC4626 savingsRate, uint256 shares, address to, uint256 maxAmountIn) = abi.decode(
                    data[i],
                    (IERC20, IERC4626, uint256, address, uint256)
                );
                _changeAllowance(token, address(savingsRate), type(uint256).max);
                _mint4626(savingsRate, shares, to, maxAmountIn);
            } else if (actions[i] == ActionType.deposit4626) {
                (IERC20 token, IERC4626 savingsRate, uint256 amount, address to, uint256 minSharesOut) = abi.decode(
                    data[i],
                    (IERC20, IERC4626, uint256, address, uint256)
                );
                _changeAllowance(token, address(savingsRate), type(uint256).max);
                _deposit4626(savingsRate, amount, to, minSharesOut);
            } else if (actions[i] == ActionType.redeem4626) {
                (IERC4626 savingsRate, uint256 shares, address to, uint256 minAmountOut) = abi.decode(
                    data[i],
                    (IERC4626, uint256, address, uint256)
                );
                _redeem4626(savingsRate, shares, to, minAmountOut);
            } else if (actions[i] == ActionType.withdraw4626) {
                (IERC4626 savingsRate, uint256 amount, address to, uint256 maxSharesOut) = abi.decode(
                    data[i],
                    (IERC4626, uint256, address, uint256)
                );
                _withdraw4626(savingsRate, amount, to, maxSharesOut);
            } else {
                _chainSpecificAction(actions[i], data[i]);
            }
        }
    }

    /// @notice Wrapper built on top of the base `mixer` function to grant approval to a `VaultManager` contract before performing
    /// actions and then revoking this approval after these actions
    /// @param paramsPermitVaultManager Parameters to sign permit to give allowance to the router for a `VaultManager` contract
    /// @dev In `paramsPermitVaultManager`, the signatures for granting approvals must be given first before the signatures
    /// to revoke approvals
    /// @dev The router contract has been built to be safe to keep approvals as you cannot take an action on a vault you are not
    /// approved for, but people wary about their approvals may want to grant it before immediately revoking it, although this
    /// is just an option
    function mixerVaultManagerPermit(
        PermitVaultManagerType[] memory paramsPermitVaultManager,
        PermitType[] memory paramsPermit,
        ActionType[] calldata actions,
        bytes[] calldata data
    ) external payable virtual {
        uint256 permitVaultManagerLength = paramsPermitVaultManager.length;
        for (uint256 i; i < permitVaultManagerLength; ++i) {
            if (paramsPermitVaultManager[i].approved) {
                IVaultManagerFunctions(paramsPermitVaultManager[i].vaultManager).permit(
                    paramsPermitVaultManager[i].owner,
                    address(this),
                    true,
                    paramsPermitVaultManager[i].deadline,
                    paramsPermitVaultManager[i].v,
                    paramsPermitVaultManager[i].r,
                    paramsPermitVaultManager[i].s
                );
            } else break;
        }
        mixer(paramsPermit, actions, data);
        // Storing the index at which starting the iteration for revoking approvals in a variable would make the stack
        // too deep
        for (uint256 i; i < permitVaultManagerLength; ++i) {
            if (!paramsPermitVaultManager[i].approved) {
                IVaultManagerFunctions(paramsPermitVaultManager[i].vaultManager).permit(
                    paramsPermitVaultManager[i].owner,
                    address(this),
                    false,
                    paramsPermitVaultManager[i].deadline,
                    paramsPermitVaultManager[i].v,
                    paramsPermitVaultManager[i].r,
                    paramsPermitVaultManager[i].s
                );
            }
        }
    }

    receive() external payable {}

    // ===================== INTERNAL ACTION-RELATED FUNCTIONS =====================

    /// @notice Wraps the native token of a chain to its wrapped version
    /// @dev It can be used for ETH to wETH or MATIC to wMATIC
    /// @dev The amount to wrap is to be specified in the `msg.value`
    function _wrapNative() internal virtual returns (uint256) {
        _getNativeWrapper().deposit{ value: msg.value }();
        return msg.value;
    }

    /// @notice Unwraps the wrapped version of a token to the native chain token
    /// @dev It can be used for wETH to ETH or wMATIC to MATIC
    function _unwrapNative(uint256 minAmountOut, address to) internal virtual returns (uint256 amount) {
        amount = _getNativeWrapper().balanceOf(address(this));
        _slippageCheck(amount, minAmountOut);
        if (amount != 0) {
            _getNativeWrapper().withdraw(amount);
            _safeTransferNative(to, amount);
        }
        return amount;
    }

    /// @notice Internal version of the `claimRewards` function
    /// @dev If the caller wants to send the rewards to another account than `gaugeUser`, it first needs to
    /// call `set_rewards_receiver(otherAccount)` on each `liquidityGauge`
    function _claimRewards(address gaugeUser, address[] memory liquidityGauges) internal virtual {
        uint256 gaugesLength = liquidityGauges.length;
        for (uint256 i; i < gaugesLength; ++i) {
            ILiquidityGauge(liquidityGauges[i]).claim_rewards(gaugeUser);
        }
    }

    /// @notice Allows to compose actions on a `VaultManager` (Angle Protocol Borrowing module)
    /// @param vaultManager Address of the vault to perform actions on
    /// @param actionsBorrow Actions type to perform on the vaultManager
    /// @param dataBorrow Data needed for each actions
    /// @param to Address to send the funds to
    /// @param who Swapper address to handle repayments
    /// @param repayData Bytes to use at the discretion of the `msg.sender`
    function _angleBorrower(
        address vaultManager,
        ActionBorrowType[] memory actionsBorrow,
        bytes[] memory dataBorrow,
        address to,
        address who,
        bytes memory repayData
    ) internal virtual returns (PaymentData memory paymentData) {
        return IVaultManagerFunctions(vaultManager).angle(actionsBorrow, dataBorrow, msg.sender, to, who, repayData);
    }

    /// @notice Allows to deposit tokens into a gauge
    /// @param user Address on behalf of which deposits should be made in the gauge
    /// @param amount Amount to stake
    /// @param gauge Liquidity gauge to stake in
    /// @param shouldClaimRewards Whether to claim or not previously accumulated rewards
    /// @dev You should be cautious on who will receive the rewards (if `shouldClaimRewards` is true)
    /// @dev The function will revert if the gauge has not already been approved by the contract
    function _gaugeDeposit(
        address user,
        uint256 amount,
        ILiquidityGauge gauge,
        bool shouldClaimRewards
    ) internal virtual {
        gauge.deposit(amount, user, shouldClaimRewards);
    }

    /// @notice Sweeps tokens from the router contract
    /// @param tokenOut Token to sweep
    /// @param minAmountOut Minimum amount of tokens to recover
    /// @param to Address to which tokens should be sent
    function _sweep(address tokenOut, uint256 minAmountOut, address to) internal virtual {
        uint256 balanceToken = IERC20(tokenOut).balanceOf(address(this));
        _slippageCheck(balanceToken, minAmountOut);
        if (balanceToken != 0) {
            IERC20(tokenOut).safeTransfer(to, balanceToken);
        }
    }

    /// @notice Uses an external swapper
    /// @param swapper Contracts implementing the logic of the swap
    /// @param inToken Token used to do the swap
    /// @param outToken Token wanted
    /// @param outTokenRecipient Address who should have at the end of the swap at least `outTokenOwed`
    /// @param outTokenOwed Minimal amount for the `outTokenRecipient`
    /// @param inTokenObtained Amount of `inToken` used for the swap
    /// @param data Additional info for the specific swapper
    function _swapper(
        ISwapper swapper,
        IERC20 inToken,
        IERC20 outToken,
        address outTokenRecipient,
        uint256 outTokenOwed,
        uint256 inTokenObtained,
        bytes memory data
    ) internal {
        swapper.swap(inToken, outToken, outTokenRecipient, outTokenOwed, inTokenObtained, data);
    }

    /// @notice Allows to swap between tokens via UniswapV3 (if there is a path)
    /// @param inToken Token used as entrance of the swap
    /// @param amount Amount of in token to swap
    /// @param minAmountOut Minimum amount of outToken accepted for the swap to happen
    /// @param path Bytes representing the path to swap your input token to the accepted collateral
    function _swapOnUniswapV3(
        IERC20 inToken,
        uint256 amount,
        uint256 minAmountOut,
        bytes memory path
    ) internal returns (uint256 amountOut) {
        // Approve transfer to the `uniswapV3Router`
        // Since this router is supposed to be a trusted contract, we can leave the allowance to the token
        address uniRouter = address(uniswapV3Router);
        _changeAllowance(IERC20(inToken), uniRouter, type(uint256).max);
        amountOut = IUniswapV3Router(uniRouter).exactInput(
            ExactInputParams(path, address(this), block.timestamp, amount, minAmountOut)
        );
    }

    /// @notice Swaps an inToken to another token via 1Inch Router
    /// @param payload Bytes needed for 1Inch router to process the swap
    /// @dev The `payload` given is expected to be obtained from 1Inch API
    function _swapOn1Inch(
        IERC20 inToken,
        uint256 minAmountOut,
        bytes memory payload
    ) internal returns (uint256 amountOut) {
        // Approve transfer to the `oneInch` address
        // Since this router is supposed to be a trusted contract, we can leave the allowance to the token
        address oneInchRouter = oneInch;
        _changeAllowance(IERC20(inToken), oneInchRouter, type(uint256).max);
        //solhint-disable-next-line
        (bool success, bytes memory result) = oneInchRouter.call(payload);
        if (!success) _revertBytes(result);

        amountOut = abi.decode(result, (uint256));
        _slippageCheck(amountOut, minAmountOut);
    }

    /// @notice Mints `shares` from an ERC4626 contract
    /// @param savingsRate ERC4626 to mint shares from
    /// @param shares Amount of shares to mint from the contract
    /// @param to Address to which shares should be sent
    /// @param maxAmountIn Max amount of assets used to mint
    /// @return amountIn Amount of assets used to mint by `to`
    function _mint4626(
        IERC4626 savingsRate,
        uint256 shares,
        address to,
        uint256 maxAmountIn
    ) internal returns (uint256 amountIn) {
        _slippageCheck(maxAmountIn, (amountIn = savingsRate.mint(shares, to)));
    }

    /// @notice Deposits `amount` to an ERC4626 contract
    /// @param savingsRate The ERC4626 to deposit assets to
    /// @param amount Amount of assets to deposit
    /// @param to Address to which shares should be sent
    /// @param minSharesOut Minimum amount of shares that `to` should received
    /// @return sharesOut Amount of shares received by `to`
    function _deposit4626(
        IERC4626 savingsRate,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) internal returns (uint256 sharesOut) {
        _slippageCheck(sharesOut = savingsRate.deposit(amount, to), minSharesOut);
    }

    /// @notice Withdraws `amount` from an ERC4626 contract
    /// @param savingsRate ERC4626 to withdraw assets from
    /// @param amount Amount of assets to withdraw
    /// @param to Destination of assets
    /// @param maxSharesOut Maximum amount of shares that should be burnt in the operation
    /// @return sharesOut Amount of shares burnt
    function _withdraw4626(
        IERC4626 savingsRate,
        uint256 amount,
        address to,
        uint256 maxSharesOut
    ) internal returns (uint256 sharesOut) {
        _slippageCheck(maxSharesOut, sharesOut = savingsRate.withdraw(amount, to, msg.sender));
    }

    /// @notice Redeems `shares` from an ERC4626 contract
    /// @param savingsRate ERC4626 to redeem shares from
    /// @param shares Amount of shares to redeem
    /// @param to Destination of assets
    /// @param minAmountOut Minimum amount of assets that `to` should receive in the redemption process
    /// @return amountOut Amount of assets received by `to`
    function _redeem4626(
        IERC4626 savingsRate,
        uint256 shares,
        address to,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut) {
        _slippageCheck(amountOut = savingsRate.redeem(shares, to, msg.sender), minAmountOut);
    }

    /// @notice Allows to perform some specific actions for a chain
    function _chainSpecificAction(ActionType action, bytes calldata data) internal virtual {}

    // ======================= VIRTUAL FUNCTIONS TO OVERRIDE =======================

    /// @notice Gets the official wrapper of the native token on a chain (like wETH on Ethereum)
    function _getNativeWrapper() internal pure virtual returns (IWETH9);

    // ============================ GOVERNANCE FUNCTION ============================

    /// @notice Checks whether the `msg.sender` has the governor role or the guardian role
    modifier onlyGovernorOrGuardian() {
        if (!core.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        _;
    }

    /// @notice Sets a new `core` contract
    function setCore(ICoreBorrow _core) external {
        if (!core.isGovernor(msg.sender) || !_core.isGovernor(msg.sender)) revert NotGovernor();
        core = ICoreBorrow(_core);
    }

    /// @notice Changes allowances for different tokens
    /// @param tokens Addresses of the tokens to allow
    /// @param spenders Addresses to allow transfer
    /// @param amounts Amounts to allow
    function changeAllowance(
        IERC20[] calldata tokens,
        address[] calldata spenders,
        uint256[] calldata amounts
    ) external onlyGovernorOrGuardian {
        uint256 tokensLength = tokens.length;
        if (tokensLength != spenders.length || tokensLength != amounts.length) revert IncompatibleLengths();
        for (uint256 i; i < tokensLength; ++i) {
            _changeAllowance(tokens[i], spenders[i], amounts[i]);
        }
    }

    /// @notice Sets a new router variable
    function setRouter(address router, uint8 who) external onlyGovernorOrGuardian {
        if (router == address(0)) revert ZeroAddress();
        if (who == 0) uniswapV3Router = IUniswapV3Router(router);
        else oneInch = router;
    }

    // ========================= INTERNAL UTILITY FUNCTIONS ========================

    /// @notice Changes allowance of this contract for a given token
    /// @param token Address of the token to change allowance
    /// @param spender Address to change the allowance of
    /// @param amount Amount allowed
    function _changeAllowance(IERC20 token, address spender, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        // In case `currentAllowance < type(uint256).max / 2` and we want to increase it:
        // Do nothing (to handle tokens that need reapprovals to 0 and save gas)
        if (currentAllowance < amount && currentAllowance < type(uint256).max / 2) {
            token.safeIncreaseAllowance(spender, amount - currentAllowance);
        } else if (currentAllowance > amount) {
            token.safeDecreaseAllowance(spender, currentAllowance - amount);
        }
    }

    /// @notice Transfer amount of the native token to the `to` address
    /// @dev Forked from Solmate: https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol
    function _safeTransferNative(address to, uint256 amount) internal {
        bool success;
        //solhint-disable-next-line
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!success) revert TransferFailed();
    }

    /// @notice Parses the actions submitted to the router contract to interact with a `VaultManager` and makes sure that
    /// the calling address is well approved for all the vaults with which it is interacting
    /// @dev If such check was not made, we could end up in a situation where an address has given an approval for all its
    /// vaults to the router contract, and another address takes advantage of this to instruct actions on these other vaults
    /// to the router: it is hence super important for the router to pay attention to the fact that the addresses interacting
    /// with a vault are approved for this vault
    function _parseVaultIDs(
        ActionBorrowType[] memory actionsBorrow,
        bytes[] memory dataBorrow,
        address vaultManager,
        address collateral
    ) internal view returns (bytes[] memory) {
        uint256 actionsBorrowLength = actionsBorrow.length;
        uint256[] memory vaultIDsToCheckOwnershipOf = new uint256[](actionsBorrowLength);
        bool createVaultAction;
        uint256 lastVaultID;
        uint256 vaultIDLength;
        for (uint256 i; i < actionsBorrowLength; ++i) {
            uint256 vaultID;
            // If there is a `createVault` action, the router should not worry about looking at
            // next vaultIDs given equal to 0
            if (actionsBorrow[i] == ActionBorrowType.createVault) {
                createVaultAction = true;
                continue;
                // If the action is a `addCollateral` action, we should check whether a max amount was given to end up adding
                // as collateral the full contract balance
            } else if (actionsBorrow[i] == ActionBorrowType.addCollateral) {
                uint256 amount;
                (vaultID, amount) = abi.decode(dataBorrow[i], (uint256, uint256));
                if (amount == type(uint256).max)
                    dataBorrow[i] = abi.encode(vaultID, IERC20(collateral).balanceOf(address(this)));
                continue;
                // There are different ways depending on the action to find the `vaultID` to parse
            } else if (
                actionsBorrow[i] == ActionBorrowType.removeCollateral || actionsBorrow[i] == ActionBorrowType.borrow
            ) {
                (vaultID, ) = abi.decode(dataBorrow[i], (uint256, uint256));
            } else if (actionsBorrow[i] == ActionBorrowType.closeVault) {
                vaultID = abi.decode(dataBorrow[i], (uint256));
            } else if (actionsBorrow[i] == ActionBorrowType.getDebtIn) {
                (vaultID, , , ) = abi.decode(dataBorrow[i], (uint256, address, uint256, uint256));
            } else continue;
            // If we need to add a null `vaultID`, we look at the `vaultIDCount` in the `VaultManager`
            // if there has not been any specific action
            if (vaultID == 0) {
                if (createVaultAction) {
                    continue;
                } else {
                    // If we haven't stored the last `vaultID`, we need to fetch it
                    if (lastVaultID == 0) {
                        lastVaultID = IVaultManagerStorage(vaultManager).vaultIDCount();
                    }
                    vaultID = lastVaultID;
                }
            }

            // Check if this `vaultID` has already been verified
            for (uint256 j; j < vaultIDLength; ++j) {
                if (vaultIDsToCheckOwnershipOf[j] == vaultID) {
                    // If yes, we continue to the next iteration
                    continue;
                }
            }
            // Verify this new `vaultID` and add it to the list
            if (!IVaultManagerFunctions(vaultManager).isApprovedOrOwner(msg.sender, vaultID)) {
                revert NotApprovedOrOwner();
            }
            vaultIDsToCheckOwnershipOf[vaultIDLength] = vaultID;
            vaultIDLength += 1;
        }
        return dataBorrow;
    }

    /// @notice Checks whether the amount obtained during a swap is not too small
    function _slippageCheck(uint256 amount, uint256 thresholdAmount) internal pure {
        if (amount < thresholdAmount) revert TooSmallAmountOut();
    }

    /// @notice Internal function used for error handling
    function _revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length != 0) {
            //solhint-disable-next-line
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }
        revert InvalidReturnMessage();
    }
}