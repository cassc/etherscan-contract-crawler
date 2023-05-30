pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "../XToken.sol";

contract UltimateLoanLock {
    XToken public xLEXE;

    struct account {
        uint256 balance;
        uint256 blockNumber;
    }

    mapping(address => account) public accounts;
    address public ultimateLoan;
    address public admin;
    address private pendingAdmin;

    function lock(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero!");
        require(
            accounts[msg.sender].balance == 0,
            "You need to unlock your tokens before you can lock again"
        );
        bool transferStatus = xLEXE.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(transferStatus, "Transfer failed!");
        accounts[msg.sender] = account(amount, block.number);
    }

    function unlock() external {
        uint256 balance = accounts[msg.sender].balance;
        require(balance > 0, "Can't unlock nothing");
        delete accounts[msg.sender];
        bool transferStatus = xLEXE.transfer(msg.sender, balance);

        require(transferStatus, "Transaction failed!");
    }

    function unlockUser(address user, uint256 loanValue) external {
        address ultimateLoan_ = ultimateLoan;
        require(msg.sender == ultimateLoan_, "Not authorized");
        uint256 balance = accounts[user].balance;
        require(balance > 0, "Can't unlock nothing");
        require(balance >= loanValue, "Not enough tokens!");
        delete accounts[user];

        bool transferStatus = xLEXE.transfer(ultimateLoan_, loanValue);
        require(transferStatus, "Transaction failed!");

        transferStatus = xLEXE.transfer(user, balance - loanValue);
        require(transferStatus, "Transaction failed!");
    }

    function _setUltimateLoan(address _ultimateLoan) public {
        require(msg.sender == admin, "Only admin can set UL addreses!");
        ultimateLoan = _ultimateLoan;
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     */
    function _setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "Only admin can set pending admin!");

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     */
    function _acceptAdmin() public {
        require(
            msg.sender == pendingAdmin,
            "only pending admin can accept to be new admin"
        );

        // Store admin with value pendingAdmin
        admin = pendingAdmin;
    }

    constructor(address _xLEXE) public {
        xLEXE = XToken(_xLEXE);
        admin = msg.sender;
    }
}