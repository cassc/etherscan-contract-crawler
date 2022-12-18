pragma solidity 0.8.9;

import {Denominations} from "chainlink/Denominations.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {IEscrow} from "../../interfaces/IEscrow.sol";
import {IOracle} from "../../interfaces/IOracle.sol";
import {ILineOfCredit} from "../../interfaces/ILineOfCredit.sol";
import {CreditLib} from "../../utils/CreditLib.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {EscrowState, EscrowLib} from "../../utils/EscrowLib.sol";

/**
 * @title  - Debt DAO Escrow
 * @author - James Senegalli
 * @notice - Ownable contract that allows someone to deposit ERC20 and ERC4626 tokens as collateral to back a Line of Credit
 */
contract Escrow is IEscrow, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EscrowLib for EscrowState;

    // the minimum value of the collateral in relation to the outstanding debt e.g. 10% of outstanding debt
    uint32 public immutable minimumCollateralRatio;

    // Stakeholders and contracts used in Escrow
    address public immutable oracle;
    // borrower on line contract
    address public immutable borrower;

    // all data around terms for collateral and current deposits
    EscrowState private state;

    /**
      * @notice           - Initiates immutable terms for a Line of Credit agreement related to collateral requirements
      * @param _minimumCollateralRatio - In bps, 3 decimals. Cratio threshold where liquidations begin. see Escrow.isLiquidatable()
      * @param _oracle    - address to call for collateral token prices
      * @param _line      - Initial owner of Escrow contract. May be non-Line contract at construction before transferring to a Line.
                          - also is the oracle providing current total outstanding debt value.
      * @param _borrower  - borrower on the _line contract. Cannot pull from _line because _line might not be a Line at construction.
    */
    constructor(uint32 _minimumCollateralRatio, address _oracle, address _line, address _borrower) {
        minimumCollateralRatio = _minimumCollateralRatio;
        oracle = _oracle;
        borrower = _borrower;
        state.line = _line;
    }

    /**
     * @notice the current controller of the Escrow contract.
     */
    function line() external view override returns (address) {
        return state.line;
    }

    /**
     * @notice - Checks Line's outstanding debt value and current Escrow collateral value to compute collateral ratio and checks that against minimum.
     * @return isLiquidatable - returns true if Escrow.getCollateralRatio is lower than minimumCollateralRatio else false
     */
    function isLiquidatable() external returns (bool) {
        return state.isLiquidatable(oracle, minimumCollateralRatio);
    }

    /**
     * @notice - Allows current owner to transfer ownership to another address
     * @dev    - Used if we setup Escrow before Line exists. Line has no way to interface with this function so once transfered `line` is set forever
     * @return didUpdate - if function successfully executed or not
     */
    function updateLine(address _line) external returns (bool) {
        return state.updateLine(_line);
    }

    /**
     * @notice add collateral to your position
     * @dev requires that the token deposited by the depositor has been enabled by `line.Arbiter`
     * @dev - callable by anyone
     * @param amount - the amount of collateral to add
     * @param token - the token address of the deposited token
     * @return - the updated cratio
     */
    function addCollateral(uint256 amount, address token) external payable nonReentrant returns (uint256) {
        return state.addCollateral(oracle, amount, token);
    }

    /**
     * @notice - allows  the lines arbiter to  enable thdeposits of an asset
     *        - gives  better risk segmentation forlenders
     * @dev - whitelisting protects against malicious 4626 tokens and DoS attacks
     *       - only need to allow once. Can not disable collateral once enabled.
     * @param token - the token to all borrow to deposit as collateral
     */
    function enableCollateral(address token) external returns (bool) {
        return state.enableCollateral(oracle, token);
    }

    /**
     * @notice remove collateral from your position. Must remain above min collateral ratio
     * @dev callable by `borrower`
     * @dev updates cratio
     * @param amount - the amount of collateral to release
     * @param token - the token address to withdraw
     * @param to - who should receive the funds
     * @return - the updated cratio
     */
    function releaseCollateral(uint256 amount, address token, address to) external nonReentrant returns (uint256) {
        return state.releaseCollateral(borrower, oracle, minimumCollateralRatio, amount, token, to);
    }

    /**
     * @notice calculates the cratio
     * @dev callable by anyone
     * @return - the calculated cratio
     */
    function getCollateralRatio() external returns (uint256) {
        return state.getCollateralRatio(oracle);
    }

    /**
     * @notice calculates the collateral value in USD to 8 decimals
     * @dev callable by anyone
     * @return - the calculated collateral value to 8 decimals
     */
    function getCollateralValue() external returns (uint256) {
        return state.getCollateralValue(oracle);
    }

    /**
     * @notice liquidates borrowers collateral by token and amount
     *         line can liquidate at anytime based off other covenants besides cratio
     * @dev requires that the cratio is at or below the liquidation threshold
     * @dev callable by `line`
     * @param amount - the amount of tokens to liquidate
     * @param token - the address of the token to draw funds from
     * @param to - the address to receive the funds
     * @return - true if successful
     */
    function liquidate(uint256 amount, address token, address to) external nonReentrant returns (bool) {
        return state.liquidate(amount, token, to);
    }
}