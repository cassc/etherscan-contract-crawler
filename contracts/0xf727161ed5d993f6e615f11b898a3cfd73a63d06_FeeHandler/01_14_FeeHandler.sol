// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IUniswapV2Router02 } from "./interfaces/IUniswapV2Router02.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PaymentSplitter } from "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/**
 * @title   Victory Impact Fee Handler
 * @notice  Split, distribute, and liquidate transfer tax proceeds
 * @dev     This contract MUST be tax exempted in the VIC token to correctly handle VIC-denominated token releases
 * @author  Tuxedo Development
 * @custom:developer    BowTiedPickle
 * @custom:developer    0xGusMcCrae
 */
contract FeeHandler is PaymentSplitter, AccessControl {
    /// @notice LIQUIDATOR_ROLE represents the role required to liquidate VIC
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

    /// @notice DISTRIBUTOR_ROLE represents the role required to distribute VIC
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    /// @notice Victory Impact Token address
    address public immutable vicAddress;

    /// @notice Address of wrapped native gas token
    address public immutable WETH;

    /// @notice Dex router
    IUniswapV2Router02 public immutable uniswapV2Router;

    /// @notice Stablecoin address
    address public immutable stablecoin;

    /// @notice Number of beneficiaries
    uint256 public immutable payeeCount;

    /**
     * @param   _owner              the address to grant DEFAULT_ADMIN_ROLE
     * @param   _liquidator         the address to grant LIQUIDATOR_ROLE
     * @param   _distributor        the address to grant DISTRIBUTOR_ROLE
     * @param   _vicAddress         the address of the VIC token
     * @param   _uniswapV2Router    the address of the Uniswap V2 Router
     * @param   _stablecoin         the address of the desired stablecoin to be paid out
     * @param   _beneficiaries      array of beneficiary addresses
     * @param   _shares             array of share sizes per respective beneficiary. Does not need to sum to any specific number. Must be same length as _beneficiaries
     */
    constructor(
        address _owner,
        address _liquidator,
        address _distributor,
        address _vicAddress,
        IUniswapV2Router02 _uniswapV2Router,
        address _stablecoin,
        address[] memory _beneficiaries,
        uint256[] memory _shares
    ) PaymentSplitter(_beneficiaries, _shares) {
        require(
            _owner != address(0) &&
                _liquidator != address(0) &&
                _distributor != address(0) &&
                _vicAddress != address(0) &&
                address(_uniswapV2Router) != address(0) &&
                _stablecoin != address(0),
            "FeeHandler: Zero address"
        );

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(LIQUIDATOR_ROLE, _liquidator);
        _grantRole(DISTRIBUTOR_ROLE, _distributor);

        vicAddress = _vicAddress;
        uniswapV2Router = _uniswapV2Router;
        stablecoin = _stablecoin;
        WETH = uniswapV2Router.WETH();
        payeeCount = _beneficiaries.length;
    }

    // ---------- Liquidation ----------

    /**
     * @notice  Convert collected VIC fees to ETH
     * @param   amountIn        the amount of VIC to exchange for ETH
     * @param   amountOutMin    the minimum amount of ETH to receive from the swap, in wei
     */
    function liquificationToEth(uint256 amountIn, uint256 amountOutMin) external onlyRole(LIQUIDATOR_ROLE) {
        // Approve token spend
        IERC20(vicAddress).approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](2);
        path[0] = vicAddress;
        path[1] = WETH;

        // Execute swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this), // to
            block.timestamp // deadline
        );
    }

    /**
     * @notice  Convert collected VIC fees to stablecoin
     * @param   amountIn        the amount of VIC to exchange for stablecoin
     * @param   amountOutMin    the minimum amount of stablecoins to receive from the swap, in units of the stablecoin
     */
    function liquificationToStable(uint256 amountIn, uint256 amountOutMin) external onlyRole(LIQUIDATOR_ROLE) {
        // Approve token spend
        IERC20(vicAddress).approve(address(uniswapV2Router), amountIn);

        address[] memory path = new address[](3);
        path[0] = vicAddress;
        path[1] = WETH;
        path[2] = stablecoin;

        // Execute swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this), // to
            block.timestamp // deadline
        );
    }

    // ---------- Release ----------

    /**
     * @notice  Convenience function to claim accrued ETH and stablecoin proceeds
     * @param   _recipient   the address of the beneficiary to disburse funds to
     */
    function withdraw(address _recipient) external {
        uint256 ethPayment = releasable(_recipient);
        uint256 stablecoinPayment = releasable(IERC20(stablecoin), _recipient);

        require(ethPayment != 0 || stablecoinPayment != 0, "FeeHandler: No releasable funds for recipient");

        if (ethPayment != 0) {
            release(payable(_recipient));
        }
        if (stablecoinPayment != 0) {
            release(IERC20(stablecoin), _recipient);
        }
    }

    /**
     * @dev     All VIC must be released at once to avoid doubledipping if an account withdraws then the remaining VIC is liquidated
     * @inheritdoc  PaymentSplitter
     */
    function release(IERC20 token, address account) public override {
        if (address(token) == vicAddress) {
            _checkRole(DISTRIBUTOR_ROLE);
            for (uint256 i; i < payeeCount; ) {
                super.release(IERC20(vicAddress), payee(i));
                unchecked {
                    ++i;
                }
            }
        } else {
            super.release(token, account);
        }
    }
}