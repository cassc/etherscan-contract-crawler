pragma solidity ^0.8.9;

import {Denominations} from "chainlink/Denominations.sol";
import {LineOfCredit} from "./LineOfCredit.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {CreditLib} from "../../utils/CreditLib.sol";
import {SpigotedLineLib} from "../../utils/SpigotedLineLib.sol";
import {MutualConsent} from "../../utils/MutualConsent.sol";
import {ISpigot} from "../../interfaces/ISpigot.sol";
import {ISpigotedLine} from "../../interfaces/ISpigotedLine.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

/**
  * @title  - Debt DAO Spigoted Line of Credit
  * @author - Kiba Gateaux
  * @notice - The SpigotedLine is a LineofCredit contract with additional functionality for integrating with a Spigot.
            - allows Borrower or Lender to repay debt using collateralized revenue streams
  * @dev    -  Inherits LineOfCredit functionality
 */
contract SpigotedLine is ISpigotedLine, LineOfCredit {
    using SafeERC20 for IERC20;

    /// see Spigot
    ISpigot public immutable spigot;

    /// @notice exchange aggregator (mainly 0x router) to trade revenue tokens from a Spigot for credit tokens owed to lenders
    address payable public immutable swapTarget;

    /// @notice % of revenue tokens to take from Spigot if the Line of Credit  is healthy. 0 decimals
    uint8 public immutable defaultRevenueSplit;

    /**
     * @notice - excess unsold revenue claimed from Spigot to be sold later or excess credit tokens bought from revenue but not yet used to repay debt
     *         - needed because the Line of Credit might have the same token being lent/borrower as being bought/sold so need to separate accounting.
     * @dev    - private variable so other Line modules do not interfer with Spigot functionality
     */
    mapping(address => uint256) private unusedTokens;

    /**
     * @notice - The SpigotedLine is a LineofCredit contract with additional functionality for integrating with a Spigot.
               - allows Borrower or Lender to repay debt using collateralized revenue streams
     * @param oracle_ - price oracle to use for getting all token values
     * @param arbiter_ - neutral party with some special priviliges on behalf of borrower and lender
     * @param borrower_ - the debitor for all credit positions in this contract
     * @param spigot_ - Spigot smart contract that is owned by this Line
     * @param swapTarget_ - 0x protocol exchange address to send calldata for trades to exchange revenue tokens for credit tokens
     * @param ttl_ - time to live for line of credit contract across all lenders set at deployment in order to set the term/expiry date
     * @param defaultRevenueSplit_ - The % of Revenue Tokens that the Spigot escrows for debt repayment if the Line is healthy. 
     */
    constructor(
        address oracle_,
        address arbiter_,
        address borrower_,
        address spigot_,
        address payable swapTarget_,
        uint256 ttl_,
        uint8 defaultRevenueSplit_
    ) LineOfCredit(oracle_, arbiter_, borrower_, ttl_) {
        require(defaultRevenueSplit_ <= SpigotedLineLib.MAX_SPLIT);

        spigot = ISpigot(spigot_);
        defaultRevenueSplit = defaultRevenueSplit_;
        swapTarget = swapTarget_;
    }

    /**
     * see LineOfCredit._init and Securedline.init
     * @notice requires this Line is owner of the Escrowed collateral else Line will not init
     */
    function _init() internal virtual override(LineOfCredit) returns (LineLib.STATUS) {
        if (spigot.owner() != address(this)) return LineLib.STATUS.UNINITIALIZED;
        return LineOfCredit._init();
    }

    function unused(address token) external view returns (uint256) {
        return unusedTokens[token];
    }

    /**
     * see SecuredLine.declareInsolvent
     * @notice requires Spigot contract itselgf to be transfered to Arbiter and sold off to a 3rd party before declaring insolvent
     *(@dev priviliegad internal function.
     * @return isInsolvent - if Spigot contract is currently insolvent or not
     */
    function _canDeclareInsolvent() internal virtual override returns (bool) {
        return SpigotedLineLib.canDeclareInsolvent(address(spigot), arbiter);
    }

    /// see ISpigotedLine.claimAndRepay
    function claimAndRepay(
        address claimToken,
        bytes calldata zeroExTradeData
    ) external whileBorrowing nonReentrant returns (uint256) {
        bytes32 id = ids[0];
        Credit memory credit = _accrue(credits[id], id);

        if (msg.sender != arbiter) {
            revert CallerAccessDenied();
        }

        uint256 newTokens = claimToken == credit.token
            ? spigot.claimOwnerTokens(claimToken) // same asset. dont trade
            : _claimAndTrade(claimToken, credit.token, zeroExTradeData); // trade revenue token for debt obligation

        uint256 repaid = newTokens + unusedTokens[credit.token];
        uint256 debt = credit.interestAccrued + credit.principal;

        // cap payment to debt value
        if (repaid > debt) repaid = debt;

        // update reserves based on usage
        if (repaid > newTokens) {
            // using bought + unused to repay line
            unusedTokens[credit.token] -= repaid - newTokens;
        } else {
            // high revenue and bought more than we need
            unusedTokens[credit.token] += newTokens - repaid;
        }

        credits[id] = _repay(credit, id, repaid);

        emit RevenuePayment(claimToken, repaid);

        return newTokens;
    }

    /// see ISpigotedLine.useAndRepay
    function useAndRepay(uint256 amount) external whileBorrowing returns (bool) {
        bytes32 id = ids[0];
        Credit memory credit = credits[id];

        if (msg.sender != borrower && msg.sender != credit.lender) {
            revert CallerAccessDenied();
        }

        if (amount > unusedTokens[credit.token]) {
            revert ReservesOverdrawn(unusedTokens[credit.token]);
        }

        // reduce reserves before _repay calls token to prevent reentrancy
        unusedTokens[credit.token] -= amount;

        credits[id] = _repay(_accrue(credit, id), id, amount);

        emit RevenuePayment(credit.token, amount);

        return true;
    }

    /// see ISpigotedLine.claimAndTrade
    function claimAndTrade(
        address claimToken,
        bytes calldata zeroExTradeData
    ) external whileBorrowing nonReentrant returns (uint256) {
        if (msg.sender != arbiter) {
            revert CallerAccessDenied();
        }

        address targetToken = credits[ids[0]].token;
        uint256 newTokens = claimToken == targetToken
            ? spigot.claimOwnerTokens(claimToken) // same asset. dont trade
            : _claimAndTrade(claimToken, targetToken, zeroExTradeData); // trade revenue token for debt obligation

        // add bought tokens to unused balance
        unusedTokens[targetToken] += newTokens;
        return newTokens;
    }

    /**
     * @notice  - Claims revenue tokens escrowed in Spigot and trades them for credit tokens.
     *          - MUST trade all available claim tokens to target credit token.
     *          - Excess credit tokens not used to repay dent are stored in `unused`
     * @dev     - priviliged internal function
     * @param claimToken - The revenue token escrowed in the Spigot to sell in trade
     * @param targetToken - The credit token that needs to be bought in order to pat down debt. Always `credits[ids[0]].token`
     * @param zeroExTradeData - 0x API data to use in trade to sell `claimToken` for target
     *
     * @return - amount of target tokens bought
     */
    function _claimAndTrade(
        address claimToken,
        address targetToken,
        bytes calldata zeroExTradeData
    ) internal returns (uint256) {
        (uint256 tokensBought, uint256 totalUnused) = SpigotedLineLib.claimAndTrade(
            claimToken,
            targetToken,
            swapTarget,
            address(spigot),
            unusedTokens[claimToken],
            zeroExTradeData
        );

        // we dont use revenue after this so can store now
        unusedTokens[claimToken] = totalUnused;
        return tokensBought;
    }

    //  SPIGOT OWNER FUNCTIONS

    /// see ISpigotedLine.updateOwnerSplit
    function updateOwnerSplit(address revenueContract) external returns (bool) {
        return
            SpigotedLineLib.updateSplit(
                address(spigot),
                revenueContract,
                _updateStatus(_healthcheck()),
                defaultRevenueSplit
            );
    }

    /// see ISpigotedLine.addSpigot
    function addSpigot(address revenueContract, ISpigot.Setting calldata setting) external returns (bool) {
        if (msg.sender != arbiter) {
            revert CallerAccessDenied();
        }
        return spigot.addSpigot(revenueContract, setting);
    }

    /// see ISpigotedLine.updateWhitelist
    function updateWhitelist(bytes4 func, bool allowed) external returns (bool) {
        if (msg.sender != arbiter) {
            revert CallerAccessDenied();
        }
        return spigot.updateWhitelistedFunction(func, allowed);
    }

    /// see ISpigotedLine.releaseSpigot
    function releaseSpigot(address to) external returns (bool) {
        return SpigotedLineLib.releaseSpigot(address(spigot), _updateStatus(_healthcheck()), borrower, arbiter, to);
    }

    /// see ISpigotedLine.sweep
    function sweep(address to, address token) external nonReentrant returns (uint256) {
        uint256 amount = unusedTokens[token];
        delete unusedTokens[token];

        bool success = SpigotedLineLib.sweep(to, token, amount, _updateStatus(_healthcheck()), borrower, arbiter);

        return success ? amount : 0;
    }

    // allow claiming/trading in ETH
    receive() external payable {}
}