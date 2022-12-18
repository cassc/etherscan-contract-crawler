pragma solidity 0.8.9;
import {Denominations} from "chainlink/Denominations.sol";
import {ILineOfCredit} from "../interfaces/ILineOfCredit.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IInterestRateCredit} from "../interfaces/IInterestRateCredit.sol";
import {ILineOfCredit} from "../interfaces/ILineOfCredit.sol";
import {LineLib} from "./LineLib.sol";

/**
 * @title Debt DAO Line of Credit Library
 * @author Kiba Gateaux
 * @notice Core logic and variables to be reused across all Debt DAO Marketplace Line of Credit contracts
 */
library CreditLib {
    event AddCredit(address indexed lender, address indexed token, uint256 indexed deposit, bytes32 id);

    /// @notice Emits data re Lender removes funds (principal) - there is no corresponding function, just withdraw()
    event WithdrawDeposit(bytes32 indexed id, uint256 indexed amount);

    /// @notice Emits data re Lender withdraws interest - there is no corresponding function, just withdraw()
    // Bob - consider changing event name to WithdrawInterest
    event WithdrawProfit(bytes32 indexed id, uint256 indexed amount);

    /// @notice After accrueInterest runs, emits the amount of interest added to a Borrower's outstanding balance of interest due
    // but not yet repaid to the Line of Credit contract
    event InterestAccrued(bytes32 indexed id, uint256 indexed amount);

    // Borrower Events

    event Borrow(bytes32 indexed id, uint256 indexed amount);
    // Emits notice that a Borrower has drawn down an amount on a credit line

    event RepayInterest(bytes32 indexed id, uint256 indexed amount);
    /** Emits that a Borrower has repaid an amount of interest 
  (N.B. results in an increase in interestRepaid, i.e. interest not yet withdrawn by a Lender). There is no corresponding function
  */

    event RepayPrincipal(bytes32 indexed id, uint256 indexed amount);
    // Emits that a Borrower has repaid an amount of principal - there is no corresponding function

    error NoTokenPrice();

    error PositionExists();

    error RepayAmountExceedsDebt(uint256 totalAvailable);

    /**
     * @dev          - Creates a deterministic hash id for a credit line provided by a single Lender for a given token on a Line of Credit facility
     * @param line   - The Line of Credit facility concerned
     * @param lender - The address managing the credit line concerned
     * @param token  - The token being lent out on the credit line concerned
     * @return id
     */
    function computeId(address line, address lender, address token) external pure returns (bytes32) {
        return keccak256(abi.encode(line, lender, token));
    }

    // getOutstandingDebt() is called by updateOutstandingDebt()
    function getOutstandingDebt(
        ILineOfCredit.Credit memory credit,
        bytes32 id,
        address oracle,
        address interestRate
    ) external returns (ILineOfCredit.Credit memory c, uint256 principal, uint256 interest) {
        c = accrue(credit, id, interestRate);

        int256 price = IOracle(oracle).getLatestAnswer(c.token);

        principal = calculateValue(price, c.principal, c.decimals);
        interest = calculateValue(price, c.interestAccrued, c.decimals);

        return (c, principal, interest);
    }

    /**
    * @notice         - Calculates value of tokens.  Used for calculating the USD value of principal and of interest during getOutstandingDebt()
    * @dev            - Assumes Oracle returns answers in USD with 1e8 decimals
                      - If price < 0 then we treat it as 0.
    * @param price    - The Oracle price of the asset. 8 decimals
    * @param amount   - The amount of tokens being valued.
    * @param decimals - Token decimals to remove for USD price
    * @return         - The total USD value of the amount of tokens being valued in 8 decimals 
    */
    function calculateValue(int price, uint256 amount, uint8 decimals) public pure returns (uint256) {
        return price <= 0 ? 0 : (amount * uint(price)) / (1 * 10 ** decimals);
    }

    /**
     * see ILineOfCredit._createCredit
     * @notice called by LineOfCredit._createCredit during every repayment function
     * @param oracle - interset rate contract used by line that will calculate interest owed
     */
    function create(
        bytes32 id,
        uint256 amount,
        address lender,
        address token,
        address oracle
    ) external returns (ILineOfCredit.Credit memory credit) {
        int price = IOracle(oracle).getLatestAnswer(token);
        if (price <= 0) {
            revert NoTokenPrice();
        }

        uint8 decimals;
        if (token == Denominations.ETH) {
            decimals = 18;
        } else {
            (bool passed, bytes memory result) = token.call(abi.encodeWithSignature("decimals()"));
            decimals = !passed ? 18 : abi.decode(result, (uint8));
        }

        credit = ILineOfCredit.Credit({
            lender: lender,
            token: token,
            decimals: decimals,
            deposit: amount,
            principal: 0,
            interestAccrued: 0,
            interestRepaid: 0,
            isOpen: true
        });

        emit AddCredit(lender, token, amount, id);

        return credit;
    }

    /**
     * see ILineOfCredit._repay
     * @notice called by LineOfCredit._repay during every repayment function
     * @param credit - The lender position being repaid
     */
    function repay(
        ILineOfCredit.Credit memory credit,
        bytes32 id,
        uint256 amount
    ) external returns (ILineOfCredit.Credit memory) {
        unchecked {
            if (amount > credit.principal + credit.interestAccrued) {
                revert RepayAmountExceedsDebt(credit.principal + credit.interestAccrued);
            }

            if (amount <= credit.interestAccrued) {
                credit.interestAccrued -= amount;
                credit.interestRepaid += amount;
                emit RepayInterest(id, amount);
                return credit;
            } else {
                require(credit.isOpen);
                uint256 interest = credit.interestAccrued;
                uint256 principalPayment = amount - interest;

                // update individual credit line denominated in token
                credit.principal -= principalPayment;
                credit.interestRepaid += interest;
                credit.interestAccrued = 0;

                emit RepayInterest(id, interest);
                emit RepayPrincipal(id, principalPayment);

                return credit;
            }
        }
    }

    /**
     * see ILineOfCredit.withdraw
     * @notice called by LineOfCredit.withdraw during every repayment function
     * @param credit - The lender position that is being bwithdrawn from
     */
    function withdraw(
        ILineOfCredit.Credit memory credit,
        bytes32 id,
        uint256 amount
    ) external returns (ILineOfCredit.Credit memory) {
        unchecked {
            if (amount > credit.deposit - credit.principal + credit.interestRepaid) {
                revert ILineOfCredit.NoLiquidity();
            }

            if (amount > credit.interestRepaid) {
                uint256 interest = credit.interestRepaid;
                amount -= interest;

                credit.deposit -= amount;
                credit.interestRepaid = 0;

                // emit events before seeting to 0
                emit WithdrawDeposit(id, amount);
                emit WithdrawProfit(id, interest);

                return credit;
            } else {
                credit.interestRepaid -= amount;
                emit WithdrawProfit(id, amount);
                return credit;
            }
        }
    }

    /**
     * see ILineOfCredit._accrue
     * @notice called by LineOfCredit._accrue during every repayment function
     * @param interest - interset rate contract used by line that will calculate interest owed
     */
    function accrue(
        ILineOfCredit.Credit memory credit,
        bytes32 id,
        address interest
    ) public returns (ILineOfCredit.Credit memory) {
        unchecked {
            // interest will almost always be less than deposit
            // low risk of overflow unless extremely high interest rate

            // get token demoninated interest accrued
            uint256 accruedToken = IInterestRateCredit(interest).accrueInterest(id, credit.principal, credit.deposit);

            // update credit line balance
            credit.interestAccrued += accruedToken;

            emit InterestAccrued(id, accruedToken);
            return credit;
        }
    }
}