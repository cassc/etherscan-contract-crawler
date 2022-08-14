// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;
pragma abicoder v2;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IVault} from "../interfaces/IVault.sol";
import {IVaultMath} from "../interfaces/IVaultMath.sol";
import {IVaultTreasury} from "../interfaces/IVaultTreasury.sol";
import {IVaultStorage} from "../interfaces/IVaultStorage.sol";

import {SharedEvents} from "../libraries/SharedEvents.sol";
import {Constants} from "../libraries/Constants.sol";
import {PRBMathUD60x18} from "../libraries/math/PRBMathUD60x18.sol";
import {Faucet} from "../libraries/Faucet.sol";

import {VaultAuction} from "./VaultAuction.sol";

/**
 * Error
 * C0: Paused
 * C1: Amount ETH min
 * C2: Amount USDC min
 * C3: Amount oSQTH min
 * C4: Cap is reached
 * C5: Shares to withdraw is zero
 * C6: No liquidity
 * C7: Amount of ETH is smaller when amountEthMin
 * C8: Amount of USDC is smaller when amountUsdcMin
 * C9: Amount of OSQTH is smaller when amountOsqthMin
 * C10: Time rebalance not allowed
 * C11: Price rebalance not allowed
 * C12: Not a vault
 * C13: Not a vault math
 * C14: Not a keeper
 * C15: Not a governance
 * C16: Zero amount
 * C17: Wrong address
 * C18: Int overflow
 * C19: Max TWAP Deviation
 * C20: Wrong pool
 * C21: Less than the minimum in rebalancing
 */

contract Vault is IVault, IERC20, ERC20, ReentrancyGuard, Faucet {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice strategy constructor
     */
    constructor() ERC20("Liqui Hedgehog ", "Hedgehog") {}

    /**
    @notice deposit tokens in proportion to the vault's holding
    @param amountEth ETH amount to deposit
    @param amountUsdc USDC amount to deposit
    @param amountOsqth oSQTH amount to deposit 
    @param to receiver address
    @param amountEthMin revert if resulting amount of ETH is smaller than this
    @param amountUsdcMin revert if resulting amount of USDC is smaller than this
    @param amountOsqthMin revert if resulting amount of oSQTH is smaller than this
    @return shares minted shares
    */
    function deposit(
        uint256 amountEth,
        uint256 amountUsdc,
        uint256 amountOsqth,
        address to,
        uint256 amountEthMin,
        uint256 amountUsdcMin,
        uint256 amountOsqthMin
    ) external override nonReentrant notPaused returns (uint256) {
        require(amountEth > 0, "C16");
        require(to != address(0) && to != address(this), "C17");

        //Poke positions so vault's current holdings are up to date
        IVaultTreasury(vaultTreasury).pokeEthUsdc();
        IVaultTreasury(vaultTreasury).pokeEthOsqth();

        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            (uint256 ethPrice, ) = IVaultMath(vaultMath).getPrices();

            IVaultStorage(vaultStorage).setParamsBeforeDeposit(
                block.timestamp,
                IVaultMath(vaultMath).getIV(),
                ethPrice
            );
        }

        //Calculate shares to mint
        (uint256 _shares, uint256 _amountEth, uint256 _amountUsdc, uint256 _amountOsqth) = calcSharesAndAmounts(
            amountEth,
            amountUsdc,
            amountOsqth,
            _totalSupply,
            false
        );

        require(_amountEth >= amountEthMin, "C1");
        require(_amountUsdc >= amountUsdcMin, "C2");
        require(_amountOsqth >= amountOsqthMin, "C3");

        //Pull in tokens
        if (_amountEth > 0) Constants.weth.transferFrom(msg.sender, vaultTreasury, _amountEth);
        if (_amountUsdc > 0) Constants.usdc.transferFrom(msg.sender, vaultTreasury, _amountUsdc);
        if (_amountOsqth > 0) Constants.osqth.transferFrom(msg.sender, vaultTreasury, _amountOsqth);

        //Mint shares to user
        _mint(to, _shares);
        //Check deposit cap
        require(totalSupply() <= IVaultStorage(vaultStorage).cap(), "C4");

        emit SharedEvents.Deposit(to, _shares);
        return _shares;
    }

    /**
    @notice withdraws tokens in proportion to the vault's holdings.
    @dev provide strategy tokens, returns set of wETH, USDC, and oSQTH
    @param shares shares burned by sender
    @param amountEthMin revert if resulting amount of wETH is smaller than this
    @param amountUsdcMin revert if resulting amount of USDC is smaller than this
    @param amountOsqthMin revert if resulting amount of oSQTH is smaller than this
    */
    function withdraw(
        uint256 shares,
        uint256 amountEthMin,
        uint256 amountUsdcMin,
        uint256 amountOsqthMin
    ) external override nonReentrant {
        require(shares > 0, "C5");

        uint256 _totalSupply = totalSupply();

        //Burn shares
        _burn(msg.sender, shares);

        //withdraw user share of tokens from lp positions in the current proportion
        (uint256 amountUsdc, uint256 amountEth0) = IVaultMath(vaultMath).burnLiquidityShare(
            Constants.poolEthUsdc,
            IVaultStorage(vaultStorage).orderEthUsdcLower(),
            IVaultStorage(vaultStorage).orderEthUsdcUpper(),
            shares,
            _totalSupply
        );

        (uint256 amountEth1, uint256 amountOsqth) = IVaultMath(vaultMath).burnLiquidityShare(
            Constants.poolEthOsqth,
            IVaultStorage(vaultStorage).orderOsqthEthLower(),
            IVaultStorage(vaultStorage).orderOsqthEthUpper(),
            shares,
            _totalSupply
        );

        uint256 amountEth = amountEth0 + amountEth1;

        require(amountEth != 0 || amountUsdc != 0 || amountOsqth != 0, "C6");

        require(amountEth >= amountEthMin, "C7");
        require(amountUsdc >= amountUsdcMin, "C8");
        require(amountOsqth >= amountOsqthMin, "C9");

        //send tokens to user
        if (amountEth > 0) IVaultTreasury(vaultTreasury).transfer(Constants.weth, msg.sender, amountEth);
        if (amountUsdc > 0) IVaultTreasury(vaultTreasury).transfer(Constants.usdc, msg.sender, amountUsdc);
        if (amountOsqth > 0) IVaultTreasury(vaultTreasury).transfer(Constants.osqth, msg.sender, amountOsqth);

        emit SharedEvents.Withdraw(msg.sender, shares, amountEth, amountUsdc, amountOsqth);
    }

    /**
     * @notice Used to collect accumulated protocol fees.
     * @param amountEth amount of wETH to withdraw
     * @param amountUsdc amount of USDC to withdraw
     * @param amountOsqth amount of oSQTH to withdraw
     * @param to recipient address
     */
    function collectProtocol(
        uint256 amountEth,
        uint256 amountUsdc,
        uint256 amountOsqth,
        address to
    ) external nonReentrant onlyGovernance {
        IVaultStorage(vaultStorage).updateAccruedFees(amountEth, amountUsdc, amountOsqth);

        if (amountUsdc > 0) IVaultTreasury(vaultTreasury).transfer(Constants.usdc, to, amountUsdc);
        if (amountEth > 0) IVaultTreasury(vaultTreasury).transfer(Constants.weth, to, amountEth);
        if (amountOsqth > 0) IVaultTreasury(vaultTreasury).transfer(Constants.osqth, to, amountOsqth);
    }

    /**
     * @notice Calculate shares and token amounts for deposit
     * @param _amountEth desired amount of wETH to deposit
     * @param _amountUsdc desired amount of USDC to deposit
     * @param _amountOsqth desired amount of oSQTH to deposit
     * @return shares to mint
     * @return ethToDeposit required amount of wETH to deposit
     * @return usdcToDeposit required amount of USDC to deposit
     * @return osqthToDeposit required amount of oSQTH to deposit
     */
    function calcSharesAndAmounts(
        uint256 _amountEth,
        uint256 _amountUsdc,
        uint256 _amountOsqth,
        uint256 _totalSupply,
        bool _isFlash
    )
        public
        view
        override
        returns (
            uint256 shares,
            uint256 ethToDeposit,
            uint256 usdcToDeposit,
            uint256 osqthToDeposit
        )
    {
        //Get current prices
        (uint256 ethUsdcPrice, uint256 osqthEthPrice) = IVaultMath(vaultMath).getPrices();

        uint256 depositorValue = _isFlash
            ? _amountEth
            : IVaultMath(vaultMath).getValue(_amountEth, _amountUsdc, _amountOsqth, ethUsdcPrice, osqthEthPrice);

        if (_totalSupply == 0) {
            //deposit in a 50% eth, 25% usdc, and 25% osqth proportion
            shares = depositorValue;
            ethToDeposit = depositorValue.mul(5e17);
            usdcToDeposit = depositorValue.mul(25e16).mul(ethUsdcPrice).div(uint256(1e30));
            osqthToDeposit = depositorValue.mul(25e16).div(osqthEthPrice);
        } else {
            //Get total amounts of token balances
            (uint256 ethAmount, uint256 usdcAmount, uint256 osqthAmount) = IVaultMath(vaultMath).getTotalAmounts();

            uint256 totalValue = IVaultMath(vaultMath).getValue(
                ethAmount,
                usdcAmount,
                osqthAmount,
                ethUsdcPrice,
                osqthEthPrice
            );

            uint256 ratio = depositorValue.div(totalValue);

            shares = _totalSupply.mul(ratio);
            ethToDeposit = ethAmount.mul(ratio);
            usdcToDeposit = usdcAmount.mul(ratio);
            osqthToDeposit = osqthAmount.mul(ratio);
        }
    }
}