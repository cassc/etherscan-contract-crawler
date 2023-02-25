// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {ERC20} from "ERC20.sol";
import {FixedPointMathLib} from "FixedPointMathLib.sol";
import {SafeTransferLib} from "SafeTransferLib.sol";
import {IGRouter} from "IGRouter.sol";
import {ICurve3Pool} from "ICurve3Pool.sol";
import {RouterOracle} from "RouterOracle.sol";
import {AllowedPermit} from "AllowedPermit.sol";
import {ERC4626} from "ERC4626.sol";
import {Errors} from "Errors.sol";
import {GVault} from "GVault.sol";
import {GTranche} from "GTranche.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title GRouter
/// @notice Handles deposits and withdrawals from the three supported stablecoins
/// DAI, USDC and USDT into Gro Protocol
/// @dev The legacy deposit and withdrawal flows are for old integrations and
/// should be avoided for new integrations as they are less gas efficient.
contract GRouter is IGRouter {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint8 public constant N_COINS = 3; // number of underlying tokens in curve pool

    GTranche public immutable tranche;
    GVault public immutable vaultToken;
    RouterOracle public immutable routerOracle;
    ICurve3Pool public immutable threePool;
    ERC20 public immutable threeCrv;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogDeposit(
        address indexed sender,
        uint256 tokenAmount,
        uint256 tokenIndex,
        bool tranche,
        uint256 trancheAmount,
        uint256 calcAmount
    );

    event LogLegacyDeposit(
        address indexed sender,
        uint256[N_COINS] tokenAmounts,
        bool tranche,
        uint256 trancheAmount,
        uint256 calcAmount
    );

    event LogWithdrawal(
        address indexed sender,
        uint256 tokenAmount,
        uint256 tokenIndex,
        bool tranche,
        uint256 calcAmount
    );

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR / GETTERS
    //////////////////////////////////////////////////////////////*/

    constructor(
        GTranche _GTranche,
        GVault _vaultToken,
        RouterOracle _routerOracle,
        ICurve3Pool _threePool,
        ERC20 _threeCrv
    ) {
        tranche = _GTranche;
        vaultToken = _vaultToken;
        routerOracle = _routerOracle;
        threePool = _threePool;
        threeCrv = _threeCrv;

        // Approve contracts for max amounts to reduce gas
        threeCrv.approve(address(_vaultToken), type(uint256).max);
        threeCrv.approve(address(_threePool), type(uint256).max);
        ERC20(address(_vaultToken)).safeApprove(
            address(_GTranche),
            type(uint256).max
        );
        // Approve Stables for 3pool
        ERC20(routerOracle.getToken(0)).safeApprove(
            address(_threePool),
            type(uint256).max
        );
        ERC20(routerOracle.getToken(1)).safeApprove(
            address(_threePool),
            type(uint256).max
        );
        ERC20(routerOracle.getToken(2)).safeApprove(
            address(_threePool),
            type(uint256).max
        );

        // Approve GTokens for Tranche
        ERC20(address(tranche.getTrancheToken(false))).safeApprove(
            address(_GTranche),
            type(uint256).max
        );
        ERC20(address(tranche.getTrancheToken(true))).safeApprove(
            address(_GTranche),
            type(uint256).max
        );
    }

    /// @notice Helper Function to get correct input for curve 'add_liquidity' function
    /// @param _amount the amount of stablecoin with the correct decimals
    /// @param _index the index of the stable corresponding to DAI, USDC and USDT respectively
    /// @return array of length three with the corresponding stablecoin amount
    function getAmounts(uint256 _amount, uint256 _index)
        internal
        pure
        returns (uint256[N_COINS] memory)
    {
        if (_index == 0) {
            return [_amount, 0, 0];
        } else if (_index == 1) {
            return [0, _amount, 0];
        } else {
            return [0, 0, _amount];
        }
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/ WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit supported stablecoin into either junior or senior tranches of gro protocol
    /// assumes the user has pre-approved the stablecoin for the GRouter
    /// @param _amount the amount of stablecoin being deposited with the correct decimals
    /// @param _token_index index of deposit token 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tranche tokens expected in return
    /// @return amount Returns $ value of tranche tokens minted
    function deposit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) external returns (uint256 amount) {
        if (_amount == 0) {
            revert Errors.AmountIsZero();
        }
        amount = depositIntoTrancheForCaller(
            _amount,
            _token_index,
            _tranche,
            _minAmount
        );
    }

    /// @notice Deposit supported stablecoin into either junior or senior tranches of gro protocol
    /// with the permit pattern so user doesn't need pre-approve the token, this supports USDC only
    /// from our supported stables
    /// @param _amount the amount of stablecoin being deposited with the correct decimals
    /// @param _token_index index of deposit 1 - USDC, USDC SUPPORT ONLY
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tranche tokens expected in return
    /// @param deadline The time at which this expires (unix time)
    /// @param v v of the signature
    /// @param r r of the signature
    /// @param s s of the signature
    /// @return amount Returns $ value of tranche tokens minted
    function depositWithPermit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount) {
        if (_amount == 0) {
            revert Errors.AmountIsZero();
        }
        ERC20 token = ERC20(routerOracle.getToken(_token_index));
        token.permit(msg.sender, address(this), _amount, deadline, v, r, s);
        amount = depositIntoTrancheForCaller(
            _amount,
            _token_index,
            _tranche,
            _minAmount
        );
    }

    /// @notice Deposit supported stablecoin into either junior or senior tranches of gro protocol
    /// with the permit pattern so user doesn't need pre-approve the token, this supports DAI only
    /// from our supported stables
    /// @param _amount the amount of stablecoin being deposited with the correct decimals
    /// @param _token_index index of deposit 0 - DAI, DAI SUPPORT ONLY
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tranche tokens expected in return
    /// @param deadline The time at which this expires (unix time)
    /// @param nonce nonce value for permit
    /// @param v v of the signature
    /// @param r r of the signature
    /// @param s s of the signature
    /// @return amount Returns $ value of tranche tokens minted
    function depositWithAllowedPermit(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amount) {
        if (_amount == 0) {
            revert Errors.AmountIsZero();
        }
        AllowedPermit token = AllowedPermit(
            routerOracle.getToken(_token_index)
        );
        token.permit(msg.sender, address(this), nonce, deadline, true, v, r, s);
        amount = depositIntoTrancheForCaller(
            _amount,
            _token_index,
            _tranche,
            _minAmount
        );
    }

    /// @notice Withdraw stablecoins by burning equivalent amount of tranche tokens
    /// @param _amount the amount of tranche tokens being withdrawn with the correct decimals
    /// @param _token_index index of deposit token 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tokens expected in return
    /// @return  amount Returns $ value of tranche tokens burned
    function withdraw(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) external returns (uint256 amount) {
        if (_amount == 0) {
            revert Errors.AmountIsZero();
        }
        amount = withdrawFromTrancheForCaller(
            _amount,
            _token_index,
            _tranche,
            _minAmount
        );
    }

    /*//////////////////////////////////////////////////////////////
                    LEGACY DEPOSIT/ WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Legacy deposit for the senior tranche token
    /// @param inAmounts amount of stables being deposited as an array of length 3 with the
    /// following indexes corresponding to the following stables 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _minAmount minimum amount of tranche token received
    /// @param _referral not used in updated protocol just use zero address
    function depositPwrd(
        uint256[N_COINS] memory inAmounts,
        uint256 _minAmount,
        address _referral
    ) external {
        uint256 amount = legacyDepositIntoTrancheForCaller(inAmounts, true);
        if (amount < _minAmount) {
            revert Errors.LTMinAmountExpected();
        }
    }

    /// @notice Legacy deposit for the junior tranche token
    /// @param inAmounts amount of stables being deposited as an array of length 3 with the
    /// following indexes corresponding to the following stables 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _minAmount minimum amount of tranche token received
    /// @param _referral not used in updated protocol just use zero address
    function depositGvt(
        uint256[N_COINS] memory inAmounts,
        uint256 _minAmount,
        address _referral
    ) external {
        uint256 amount = legacyDepositIntoTrancheForCaller(inAmounts, false);
        if (amount < _minAmount) {
            revert Errors.LTMinAmountExpected();
        }
    }

    /// @notice Explain to an end user what this does
    /// @param pwrd false for junior (gvt) and true for senior tranche (pwrd)
    /// @param index index of deposit token you wish to withdraw in 0 - DAI, 1 - USDC, 2 -USDT
    /// @param lpAmount the amount of tranche tokens being withdrawn with the correct decimals
    /// @param _minAmount minimum mount of token received
    function withdrawByStablecoin(
        bool pwrd,
        uint256 index,
        uint256 lpAmount,
        uint256 _minAmount
    ) external {
        if (lpAmount == 0) {
            revert Errors.AmountIsZero();
        }
        uint256 amount = withdrawFromTrancheForCaller(lpAmount, index, pwrd, 0);
        if (amount < _minAmount) {
            revert Errors.LTMinAmountExpected();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            HOOKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Helper Function to deposit users funds into the tranche
    /// @param _amount the amount of tranche tokens being deposited with the correct decimals
    /// @param _token_index index of deposit token 0 - DAI, 1 - USDC, 2 - USDT, 3+ - 3Crv
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tranche tokens expected in return
    /// @return amount Returns $ value of tranche tokens minted
    function depositIntoTrancheForCaller(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) internal returns (uint256 amount) {
        // pull token from user assume pre-approved
        ERC20(routerOracle.getToken(_token_index)).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        uint256 depositAmount;
        if (_token_index < 3) {
            // swap for 3crv
            threePool.add_liquidity(getAmounts(_amount, _token_index), 0);

            // check 3crv amount received
            depositAmount = threeCrv.balanceOf(address(this));
        } else {
            // depositing 3crv
            depositAmount = _amount;
        }

        // deposit into GVault
        uint256 shareAmount = vaultToken.deposit(depositAmount, address(this));

        // deposit into Tranche
        // index is zero for ETH mainnet as there is just one yield token
        uint256 trancheAmount;
        (trancheAmount, amount) = tranche.deposit(
            shareAmount,
            0,
            _tranche,
            msg.sender
        );
        if (amount < _minAmount) {
            revert Errors.LTMinAmountExpected();
        }

        emit LogDeposit(
            msg.sender,
            _amount,
            _token_index,
            _tranche,
            trancheAmount,
            amount
        );
    }

    /// @notice Helper Function to deposit users funds into the tranche for legacy functions
    /// @param inAmounts amount of stables being deposited as an array of length 3 with the
    /// following indexes corresponding to the following stables 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _tranche false for junior and true for senior tranche
    /// @return amount Returns $ value of tranche tokens minted
    function legacyDepositIntoTrancheForCaller(
        uint256[N_COINS] memory inAmounts,
        bool _tranche
    ) internal returns (uint256 amount) {
        // swap each stable into 3crv
        for (uint256 index; index < N_COINS; index++) {
            // skip loop if amount zero for index
            if (inAmounts[index] == 0) {
                continue;
            }
            // pull token from user assume pre-approved
            ERC20(routerOracle.getToken(index)).safeTransferFrom(
                msg.sender,
                address(this),
                inAmounts[index]
            );
        }

        // swap for 3crv we do minAmount check in parent function
        threePool.add_liquidity(inAmounts, 0);

        // check 3crv amount received
        uint256 depositAmount = threeCrv.balanceOf(address(this));

        // deposit into GVault
        uint256 shareAmount = vaultToken.deposit(depositAmount, address(this));

        // deposit into Tranche
        // index is zero for ETH mainnet as there is just one yield token
        uint256 trancheAmount;
        (trancheAmount, amount) = tranche.deposit(
            shareAmount,
            0,
            _tranche,
            msg.sender
        );

        emit LogLegacyDeposit(
            msg.sender,
            inAmounts,
            _tranche,
            trancheAmount,
            amount
        );
    }

    /// @notice helper function to withdraw stablecoins by burning equivalent amount of tranche tokens
    /// @param _amount the amount of tranche tokens being withdrawn with the correct decimals
    /// @param _token_index index of deposit token 0 - DAI, 1 - USDC, 2 -USDT
    /// @param _tranche false for junior and true for senior tranche
    /// @param _minAmount min amount of tranche tokens expected in return
    /// @return amount Returns $ value of tranche tokens burned
    function withdrawFromTrancheForCaller(
        uint256 _amount,
        uint256 _token_index,
        bool _tranche,
        uint256 _minAmount
    ) internal returns (uint256 amount) {
        ERC20(address(tranche.getTrancheToken(_tranche))).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        // withdraw from tranche
        // index is zero for ETH mainnet as there is just one yield token
        // returns usd value of withdrawal
        (uint256 vaultTokenBalance, ) = tranche.withdraw(
            _amount,
            0,
            _tranche,
            address(this)
        );

        // withdraw underlying from GVault
        uint256 underlying = vaultToken.redeem(
            vaultTokenBalance,
            address(this),
            address(this)
        );

        ERC20 stableToken = ERC20(routerOracle.getToken(_token_index));
        if (_token_index < 3) {
            // remove liquidity from 3crv to get desired stable from curve
            threePool.remove_liquidity_one_coin(
                underlying,
                int128(uint128(_token_index)), //value should always be 0,1,2
                0
            );

            amount = stableToken.balanceOf(address(this));
        } else {
            amount = underlying;
        }

        if (amount < _minAmount) {
            revert Errors.LTMinAmountExpected();
        }

        // send stable to user
        stableToken.safeTransfer(msg.sender, amount);

        emit LogWithdrawal(msg.sender, _amount, _token_index, _tranche, amount);
    }
}