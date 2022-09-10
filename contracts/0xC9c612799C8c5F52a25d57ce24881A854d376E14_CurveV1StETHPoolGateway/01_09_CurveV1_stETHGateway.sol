// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { IWETH } from "../../interfaces/external/IWETH.sol";
import { N_COINS, ICurvePool2Assets } from "../../integrations/curve/ICurvePool_2.sol";
import { ICurvePoolStETH } from "../../integrations/curve/ICurvePoolStETH.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// EXCEPTIONS
import { ZeroAddressException, NotImplementedException } from "../../interfaces/IErrors.sol";

/// @title CurveV1StETHPoolGateway
/// @dev This is connector contract to connect creditAccounts and Curve stETH pool
/// it converts WETH to ETH and vice versa for operational purposes
contract CurveV1StETHPoolGateway is ICurvePool2Assets {
    using SafeERC20 for IERC20;

    /// @dev Address of the token with index 0 (WETH)
    address public immutable token0;

    /// @dev Address of the token with index 1 (stETH)
    address public immutable token1;

    /// @dev Curve ETH/stETH pool address
    address public immutable pool;

    /// @dev Curve steCRV LP token
    address public immutable lp_token;

    /// @dev Constructor
    /// @param _weth WETH address
    /// @param _steth stETH address
    /// @param _pool Address of the ETH/stETH Curve pool
    constructor(
        address _weth,
        address _steth,
        address _pool
    ) {
        if (_weth == address(0) || _steth == address(0) || _pool == address(0))
            revert ZeroAddressException();

        token0 = _weth;
        token1 = _steth;
        pool = _pool;

        lp_token = ICurvePoolStETH(_pool).lp_token();
        IERC20(token1).approve(pool, type(uint256).max);
    }

    /// @dev Implements logic allowing CA's to call `exchange` on a pool with plain ETH
    /// - If i == 0, transfers WETH from sender, unwraps it, calls pool's `exchange`
    /// function and sends all resulting stETH to sender
    /// - If i == 1, transfers stETH from sender, calls pool's `exchange` function,
    /// wraps ETH and sends WETH to sender
    /// @param i Index of the input coin
    /// @param j Index of the output coin
    /// @param dx The amount of input coin to swap in
    /// @param min_dy The minimal amount of output coin to receive
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external {
        if (i == 0 && j == 1) {
            IERC20(token0).safeTransferFrom(msg.sender, address(this), dx);
            IWETH(token0).withdraw(dx);
            ICurvePoolStETH(pool).exchange{ value: dx }(i, j, dx, min_dy);
            _transferAllTokensOf(token1);
        } else if (i == 1 && j == 0) {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), dx);
            ICurvePoolStETH(pool).exchange(i, j, dx, min_dy);

            IWETH(token0).deposit{ value: address(this).balance }();

            _transferAllTokensOf(token0);
        } else {
            revert("Incorrect i,j parameters");
        }
    }

    /// @dev Implements logic allowing CA's to call `add_liquidity` on a pool with plain ETH
    /// - If amounts[0] > 0, transfers WETH from sender and unwraps it
    /// - If amounts[1] > 1, transfers stETH from sender
    /// - Calls `add_liquidity`, passing amounts[0] as value
    /// wraps ETH and sends WETH to sender
    /// @param amounts Amounts of coins to deposit
    /// @param min_mint_amount Minimal amount of LP token to receive
    function add_liquidity(
        uint256[N_COINS] calldata amounts,
        uint256 min_mint_amount
    ) external {
        if (amounts[0] > 0) {
            IERC20(token0).safeTransferFrom(
                msg.sender,
                address(this),
                amounts[0]
            );
            IWETH(token0).withdraw(amounts[0]);
        }

        if (amounts[1] > 0) {
            IERC20(token1).safeTransferFrom(
                msg.sender,
                address(this),
                amounts[1]
            );
        }

        ICurvePoolStETH(pool).add_liquidity{ value: amounts[0] }(
            amounts,
            min_mint_amount
        );

        _transferAllTokensOf(lp_token);
    }

    /// @dev Implements logic allowing CA's to call `remove_liquidity` on a pool with plain ETH
    /// - Transfers the LP token from sender
    /// - Calls `remove_liquidity`
    /// - Wraps received ETH
    /// - Sends WETH and stETH to sender
    /// @param amount Amounts of LP token to burn
    /// @param min_amounts Minimal amounts of tokens to receive
    function remove_liquidity(
        uint256 amount,
        uint256[N_COINS] calldata min_amounts
    ) external {
        IERC20(lp_token).safeTransferFrom(msg.sender, address(this), amount);

        ICurvePoolStETH(pool).remove_liquidity(amount, min_amounts);

        IWETH(token0).deposit{ value: address(this).balance }();

        _transferAllTokensOf(token0);

        _transferAllTokensOf(token1);
    }

    /// @dev Implements logic allowing CA's to call `remove_liquidity_one_coin` on a pool with plain ETH
    /// - Transfers the LP token from sender
    /// - Calls `remove_liquidity_one_coin`
    /// - If i == 0, wraps ETH and transfers WETH to sender
    /// - If i == 1, transfers stETH to sender
    /// @param _token_amount Amount of LP token to burn
    /// @param i Index of the withdrawn coin
    /// @param min_amount Minimal amount of withdrawn coin to receive
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external override {
        IERC20(lp_token).safeTransferFrom(
            msg.sender,
            address(this),
            _token_amount
        );

        ICurvePoolStETH(pool).remove_liquidity_one_coin(
            _token_amount,
            i,
            min_amount
        );

        if (i == 0) {
            IWETH(token0).deposit{ value: address(this).balance }();
            _transferAllTokensOf(token0);
        } else {
            _transferAllTokensOf(token1);
        }
    }

    /// @dev Implements logic allowing CA's to call `remove_liquidity_imbalance` on a pool with plain ETH
    /// - Transfers the LP token from sender
    /// - Calls `remove_liquidity_imbalance`
    /// - If amounts[0] > 0, wraps ETH and transfers WETH to sender
    /// - If amounts[1] > 0, transfers stETH to sender
    /// @param amounts Amounts of coins to receive
    /// @param max_burn_amount Maximal amount of LP token to burn
    function remove_liquidity_imbalance(
        uint256[N_COINS] calldata amounts,
        uint256 max_burn_amount
    ) external {
        IERC20(lp_token).safeTransferFrom(
            msg.sender,
            address(this),
            max_burn_amount
        );

        ICurvePoolStETH(pool).remove_liquidity_imbalance(
            amounts,
            max_burn_amount
        );

        if (amounts[0] > 1) {
            IWETH(token0).deposit{ value: address(this).balance }();

            uint256 balance = IERC20(token0).balanceOf(address(this));
            if (balance > 1) {
                unchecked {
                    IERC20(token0).safeTransfer(msg.sender, balance - 1);
                }
            }
        }
        if (amounts[1] > 1) {
            uint256 balance = IERC20(token1).balanceOf(address(this));
            if (balance > 1) {
                unchecked {
                    IERC20(token1).safeTransfer(msg.sender, balance - 1);
                }
            }
        }

        _transferAllTokensOf(lp_token);
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function exchange_underlying(
        int128,
        int128,
        uint256,
        uint256
    ) external pure override {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_dy_underlying(
        int128,
        int128,
        uint256
    ) external pure override returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Returns the amount of coin j received by swapping dx of coin i
    /// @param i Index of the input coin
    /// @param j Index of the output coin
    /// @param dx Amount of coin i to be swapped in
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePoolStETH(pool).get_dy(i, j, dx);
    }

    /// @dev Returns the price of the pool's LP token
    function get_virtual_price() external view override returns (uint256) {
        return ICurvePoolStETH(pool).get_virtual_price();
    }

    /// @dev Returns the pool's LP token
    function token() external view returns (address) {
        return lp_token;
    }

    /// @dev Returns the address of coin i
    function coins(uint256 i) public view returns (address) {
        if (i == 0) {
            return token0;
        } else {
            return token1;
        }
    }

    /// @dev Returns the address of coin i
    function coins(int128 i) external view returns (address) {
        return coins(uint256(uint128(i)));
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function underlying_coins(uint256) external pure returns (address) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function underlying_coins(int128) external pure returns (address) {
        revert NotImplementedException();
    }

    /// @dev Returns the pool's balance of coin i
    function balances(uint256 i) external view returns (uint256) {
        return ICurvePoolStETH(pool).balances(i);
    }

    /// @dev Returns the pool's balance of coin i
    function balances(int128 i) external view returns (uint256) {
        return ICurvePoolStETH(pool).balances(uint256(uint128(i)));
    }

    /// @dev Returns the current amplification parameter
    function A() external view returns (uint256) {
        return ICurvePoolStETH(pool).A();
    }

    /// @dev Returns the current amplification parameter scaled
    function A_precise() external view returns (uint256) {
        return ICurvePoolStETH(pool).A_precise();
    }

    /// @dev Returns the amount of coin withdrawn when using remove_liquidity_one_coin
    /// @param _burn_amount Amount of LP token to be burnt
    /// @param i Index of a coin to receive
    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256)
    {
        return ICurvePoolStETH(pool).calc_withdraw_one_coin(_burn_amount, i);
    }

    /// @dev Returns the amount of coin that belongs to the admin
    /// @param i Index of a coin
    function admin_balances(uint256 i) external view returns (uint256) {
        return ICurvePoolStETH(pool).admin_balances(i);
    }

    /// @dev Returns the admin of a pool
    function admin() external view returns (address) {
        return ICurvePoolStETH(pool).admin();
    }

    /// @dev Returns the fee amount
    function fee() external view returns (uint256) {
        return ICurvePoolStETH(pool).fee();
    }

    /// @dev Returns the percentage of the fee claimed by the admin
    function admin_fee() external view returns (uint256) {
        return ICurvePoolStETH(pool).admin_fee();
    }

    /// @dev Returns the block in which the pool was last interacted with
    function block_timestamp_last() external view returns (uint256) {
        return ICurvePoolStETH(pool).block_timestamp_last();
    }

    /// @dev Returns the initial A during ramping
    function initial_A() external view returns (uint256) {
        return ICurvePoolStETH(pool).initial_A();
    }

    /// @dev Returns the final A during ramping
    function future_A() external view returns (uint256) {
        return ICurvePoolStETH(pool).future_A();
    }

    /// @dev Returns the ramping start time
    function initial_A_time() external view returns (uint256) {
        return ICurvePoolStETH(pool).initial_A_time();
    }

    /// @dev Returns the ramping end time
    function future_A_time() external view returns (uint256) {
        return ICurvePoolStETH(pool).future_A_time();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function name() external pure returns (string memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function symbol() external pure returns (string memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function decimals() external pure returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function balanceOf(address) external pure returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function allowance(address, address) external pure returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function totalSupply() external pure returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Calculates the amount of LP token minted or burned based on added/removed coin amounts
    /// @param _amounts Amounts of coins to be added or removed from the pool
    /// @param _is_deposit Whether the tokens are added or removed
    function calc_token_amount(
        uint256[N_COINS] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256) {
        return ICurvePoolStETH(pool).calc_token_amount(_amounts, _is_deposit);
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_twap_balances(
        uint256[N_COINS] calldata,
        uint256[N_COINS] calldata,
        uint256
    ) external pure returns (uint256[N_COINS] memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_balances() external pure returns (uint256[N_COINS] memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_previous_balances()
        external
        pure
        returns (uint256[N_COINS] memory)
    {
        revert NotImplementedException();
    }

    /// @dev Not implemented, since the stETH pool does not have this function
    function get_price_cumulative_last()
        external
        pure
        returns (uint256[N_COINS] memory)
    {
        revert NotImplementedException();
    }

    receive() external payable {}

    /// @dev Transfers the current balance of a token to sender (minus 1 for gas savings)
    /// @param _token Token to transfer
    function _transferAllTokensOf(address _token) internal {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 1) {
            unchecked {
                IERC20(_token).safeTransfer(msg.sender, balance - 1);
            }
        }
    }
}