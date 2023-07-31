// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/test-org2222/Line-Of-Credit/blog/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

import {Denominations} from "chainlink/Denominations.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {ILineOfCredit} from "../interfaces/ILineOfCredit.sol";
import {IEscrow} from "../interfaces/IEscrow.sol";
import {CreditLib} from "../utils/CreditLib.sol";
import {LineLib} from "../utils/LineLib.sol";

struct EscrowState {
    address line;
    address[] collateralTokens;
    /// if lenders allow token as collateral. ensures uniqueness in collateralTokens
    mapping(address => bool) enabled;
    /// tokens used as collateral (must be able to value with oracle)
    mapping(address => IEscrow.Deposit) deposited;
}

library EscrowLib {
    using SafeERC20 for IERC20;

    // return if have collateral but no debt
    uint256 constant MAX_INT = type(uint256).max;

    /**
     * @notice updates the cratio according to the collateral value vs line value
     * @dev calls accrue interest on the line contract to update the latest interest payable
     * @param oracle - address to call for collateral token prices
     * @return cratio - the updated collateral ratio in 4 decimals
     */
    function _getLatestCollateralRatio(EscrowState storage self, address oracle) public returns (uint256) {
        (uint256 principal, uint256 interest) = ILineOfCredit(self.line).updateOutstandingDebt();
        uint256 debtValue = principal + interest;
        uint256 collateralValue = _getCollateralValue(self, oracle);
        if (debtValue == 0) return MAX_INT;
        if (collateralValue == 0) return 0;

        uint256 _numerator = collateralValue * 10 ** 5; // scale to 4 decimals
        return ((_numerator / debtValue) + 5) / 10;
    }

    /**
     * @notice - Iterates over all enabled tokens and calculates the USD value of all deposited collateral
     * @param oracle - address to call for collateral token prices
     * @return totalCollateralValue - the collateral's USD value in 8 decimals
     */
    function _getCollateralValue(EscrowState storage self, address oracle) public returns (uint256) {
        uint256 collateralValue;
        // gas savings
        uint256 length = self.collateralTokens.length;
        IOracle o = IOracle(oracle);
        IEscrow.Deposit memory d;
        for (uint256 i; i < length; ++i) {
            address token = self.collateralTokens[i];
            d = self.deposited[token];
            // new var so we don't override original deposit amount for 4626 tokens
            uint256 deposit = d.amount;
            if (deposit != 0) {
                if (d.isERC4626) {
                    // this conversion could shift, hence it is best to get it each time
                    (bool success, bytes memory assetAmount) = token.call(
                        abi.encodeWithSignature("previewRedeem(uint256)", deposit)
                    );
                    if (!success) continue;
                    deposit = abi.decode(assetAmount, (uint256));
                }
                collateralValue += CreditLib.calculateValue(o.getLatestAnswer(d.asset), deposit, d.assetDecimals);
            }
        }

        return collateralValue;
    }

    /** see Escrow.addCollateral */
    function addCollateral(
        EscrowState storage self,
        address oracle,
        uint256 amount,
        address token
    ) external returns (uint256) {
        if (amount == 0) {
            revert InvalidZeroAmount();
        }
        if (!self.enabled[token]) {
            revert InvalidCollateral();
        }

        LineLib.receiveTokenOrETH(token, msg.sender, amount);

        self.deposited[token].amount += amount;

        emit AddCollateral(token, amount);

        return _getLatestCollateralRatio(self, oracle);
    }

    /** see Escrow.enableCollateral */
    function enableCollateral(EscrowState storage self, address oracle, address token) external returns (bool) {
        if (msg.sender != ILineOfCredit(self.line).arbiter()) {
            revert ArbiterOnly();
        }
        if (token == address(0) || token == Denominations.ETH) {
            revert EthSupportDisabled();
        }

        bool isEnabled = self.enabled[token];
        IEscrow.Deposit memory deposit = self.deposited[token]; // gas savings
        if (!isEnabled) {
            (bool passed, bytes memory tokenAddrBytes) = token.call(abi.encodeWithSignature("asset()"));

            bool is4626 = tokenAddrBytes.length != 0 && passed;
            deposit.isERC4626 = is4626;

            // if 4626 save the underlying token to use for oracle pricing
            deposit.asset = !is4626 ? token : abi.decode(tokenAddrBytes, (address));

            int256 price = IOracle(oracle).getLatestAnswer(deposit.asset);
            if (price <= 0) {
                revert InvalidCollateral();
            }

            (bool successDecimals, bytes memory decimalBytes) = deposit.asset.call(
                abi.encodeWithSignature("decimals()")
            );

            if (!successDecimals || decimalBytes.length == 0) {
                revert InvalidTokenDecimals();
            }
            deposit.assetDecimals = abi.decode(decimalBytes, (uint8));

            // update collateral settings
            self.enabled[token] = true;
            self.deposited[token] = deposit;
            self.collateralTokens.push(token);
            emit EnableCollateral(deposit.asset);
        }

        return true;
    }

    /** see Escrow.releaseCollateral */
    function releaseCollateral(
        EscrowState storage self,
        address borrower,
        address oracle,
        uint256 minimumCollateralRatio,
        uint256 amount,
        address token,
        address to
    ) external returns (uint256) {
        if (amount == 0) {
            revert InvalidZeroAmount();
        }
        if (msg.sender != borrower) {
            revert CallerAccessDenied();
        }
        if (self.deposited[token].amount < amount) {
            revert InvalidCollateral();
        }
        self.deposited[token].amount -= amount;

        LineLib.sendOutTokenOrETH(token, to, amount);

        uint256 cratio = _getLatestCollateralRatio(self, oracle);
        // fail if reduces cratio below min
        // but allow borrower to always withdraw if fully repaid
        if (
            cratio < minimumCollateralRatio && // if undercollateralized, revert;
            ILineOfCredit(self.line).status() != LineLib.STATUS.REPAID // if repaid, skip;
        ) {
            revert UnderCollateralized();
        }

        emit RemoveCollateral(token, amount);

        return cratio;
    }

    /** see Escrow.getCollateralRatio */
    function getCollateralRatio(EscrowState storage self, address oracle) external returns (uint256) {
        return _getLatestCollateralRatio(self, oracle);
    }

    /** see Escrow.getCollateralValue */
    function getCollateralValue(EscrowState storage self, address oracle) external returns (uint256) {
        return _getCollateralValue(self, oracle);
    }

    /** see Escrow.liquidate */
    function liquidate(EscrowState storage self, uint256 amount, address token, address to) external returns (bool) {
        if (amount == 0) {
            revert InvalidZeroAmount();
        }

        if (msg.sender != self.line) {
            revert CallerAccessDenied();
        }
        if (self.deposited[token].amount < amount) {
            revert InvalidCollateral();
        }

        self.deposited[token].amount -= amount;

        LineLib.sendOutTokenOrETH(token, to, amount);

        return true;
    }

    /** see Escrow.isLiquidatable */
    function isLiquidatable(
        EscrowState storage self,
        address oracle,
        uint256 minimumCollateralRatio
    ) external returns (bool) {
        return _getLatestCollateralRatio(self, oracle) < minimumCollateralRatio;
    }

    /** see Escrow.updateLine */
    function updateLine(EscrowState storage self, address _line) external returns (bool) {
        require(msg.sender == self.line);
        self.line = _line;
        return true;
    }

    event AddCollateral(address indexed token, uint256 indexed amount);

    event RemoveCollateral(address indexed token, uint256 indexed amount);

    event EnableCollateral(address indexed token);

    event Liquidate(address indexed token, uint256 indexed amount);

    error ArbiterOnly();

    error InvalidZeroAmount();

    error InvalidCollateral();

    error EthSupportDisabled();

    error CallerAccessDenied();

    error UnderCollateralized();

    error NotLiquidatable();

    error InvalidTokenDecimals();
}