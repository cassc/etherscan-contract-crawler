pragma solidity ^0.8.10;

import "./AccountantInterfaces.sol";
import "../ExponentialNoError.sol";
import "../ErrorReporter.sol";
import "../Treasury/TreasuryInterfaces.sol";

contract AccountantDelegate is
    AccountantInterface,
    ExponentialNoError,
    TokenErrorReporter,
    ComptrollerErrorReporter,
    AccountantErrors
{
    /**
     * @notice Method used to initialize the contract during delegator contructor
     * @param cnoteAddress_ The address of the CNoteDelegator
     * @param noteAddress_ The address of the note contract
     * @param comptrollerAddress_ The address of the comptroller contract
     */
    function initialize(
        address treasury_,
        address cnoteAddress_,
        address noteAddress_,
        address comptrollerAddress_
    )
        external
    {
        //AccountantDelegate can only be initialized once
        if (msg.sender != admin) {
            revert SenderNotAdmin(msg.sender);
        }

        if (
            address(treasury)
                != address(0)
                || address(note)
                != address(0)
                || address(cnote)
                != address(0)
        ) {
            revert AccountantInitializedAgain();
        }

        treasury = treasury_; // set the current treasury address (address of TreasuryDelegator)
        address[] memory MarketEntered = new address[](1); // first entry into lending market
        MarketEntered[0] = cnoteAddress_;

        comptroller = ComptrollerInterface(comptrollerAddress_);
        note = Note(noteAddress_);
        cnote = CNote(cnoteAddress_);

        uint256[] memory err = comptroller.enterMarkets(MarketEntered); // check if market entry returns without error
        if (err[0] != 0) {
            revert ErrorMarketEntering(err[0]);
        }
        emit AcctInit(cnoteAddress_);

        note.approve(cnoteAddress_, type(uint256).max); // approve lending market, to transferFrom Accountant as needed
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) external override {
        // Check caller = admin
        require(
            msg.sender == admin, "TreasuryDelegator:_setPendingAdmin: admin only"
        );

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() external override {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0), msg.sender cannot == address(0)
        require(
            msg.sender == pendingAdmin,
            "TreasuryDelegator:_acceptAdmin: pending admin only"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    /**
     * @notice Method to supply markets
     * @param amount the amount to supply
     * @return uint error code from CNote mint()
     */
    function supplyMarket(uint256 amount)
        external
        override
        returns (uint256)
    {
        if (msg.sender != address(cnote)) {
            revert SenderNotCNote(address(cnote));
        }
        uint256 err = cnote.mint(amount);
        emit AcctSupplied(amount, uint256(err));
        return err;
    }

    /**
     * @notice Method to redeem account CNote from lending market
     * @param amount Amount to redeem (Note)
     * @return uint Amount of cnote redeemed (amount * exchange rate)
     */
    function redeemMarket(uint256 amount)
        external
        override
        returns (uint256)
    {
        if (msg.sender != address(cnote)) {
            revert SenderNotCNote(address(cnote));
        }
        emit AcctRedeemed(amount);
        return cnote.redeemUnderlying(amount); // redeem the amount of Note calculated via current CNote exchange rate
    }

    /**
     * @notice Method to sweep interest earned from accountant depositing note in lending market to the treasury
     */
    function sweepInterest() external override {
        if (msg.sender != admin) {
            revert SenderNotAdmin(msg.sender);
        }
        //Total balance of Treasury => Note + CNote Balance,
        Exp memory exRate = Exp({mantissa: cnote.exchangeRateStored()}); //used stored interest rates in determining amount to sweep

        //underflow impossible
        uint256 noteDiff =
            sub_(note.totalSupply(), note.balanceOf(address(this))); //Note deficit in Accountant
        uint256 cNoteBal = cnote.balanceOf(address(this)); //current cNote Balance
        uint256 cNoteAmt = mul_(cNoteBal, exRate); // cNote Balance converted to Note

        require(
            cNoteAmt >= noteDiff,
            "AccountantDelegate::sweepInterest:Error calculating interest to sweep"
        );

        uint256 amtToSweep = sub_(cNoteAmt, noteDiff); // amount to sweep in Note,
        uint256 cNoteToSweep = div_(amtToSweep, exRate); // amount of cNote to sweep = amtToSweep(Note) / exRate

        cNoteToSweep = cNoteToSweep > cNoteBal ? cNoteBal : cNoteToSweep;
        bool success = cnote.transfer(treasury, amtToSweep);
        if (!success) {
            revert SweepError(treasury, amtToSweep); //handles if transfer of tokens is not successful
        }

        TreasuryInterface Treas = TreasuryInterface(treasury);
        Treas.redeem(address(cnote), amtToSweep);
    }
}