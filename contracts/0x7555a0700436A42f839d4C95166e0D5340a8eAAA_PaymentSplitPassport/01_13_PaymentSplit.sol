// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "hardhat/console.sol";
//access control
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PaymentSplitPassport is Context, AccessControl, Ownable {
    //defining the access roles
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant BALANCE_ROLE = keccak256("BALANCE_ROLE");

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    //event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;
    bool _newPayeesOpen = true;
    mapping(address=>bool) testPayment;
    uint testPaymentCount = 0; 

    //mapping(IERC20 => uint256) private _erc20TotalReleased;
    //mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_, address admin) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(UPDATER_ROLE, msg.sender);
        _setupRole(BALANCE_ROLE, msg.sender);
    }

    function addUpdater(address updater)external onlyRole(UPDATER_ROLE){
        _grantRole(UPDATER_ROLE, updater);
    }

    function addBalancer(address balancer)external onlyRole(UPDATER_ROLE){
        _grantRole(BALANCE_ROLE, balancer);
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function getBalance()external view returns(uint256){
        return address(this).balance;
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    // /**
    //  * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
    //  * contract.
    //  */
    // function totalReleased(IERC20 token) public view returns (uint256) {
    //     return _erc20TotalReleased[token];
    // }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) external view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    // /**
    //  * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
    //  * IERC20 contract.
    //  */
    // function released(IERC20 token, address account) public view returns (uint256) {
    //     return _erc20Released[token][account];
    // }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_newPayeesOpen == false);
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }
    

    /**
     * @dev Triggers a transfer to all `accounts` in the list of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
     function releaseAll()public onlyRole(BALANCE_ROLE){
        require(_newPayeesOpen == false);
         for(uint i; i < _payees.length; i++){
             address account = _payees[i];
             release(payable(account));
         }
     }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        uint256 amount = (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
        return amount;
    }   


    /**
    *@dev close the contract for new payees
    *@notice added to protect against new payees causing payment underflow errors 
     */
     function closeNewPayees()external onlyRole(UPDATER_ROLE){
        _newPayeesOpen = false;
     }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function addPayee(address account, uint256 shares_)public onlyRole(UPDATER_ROLE){
        require(_newPayeesOpen, "Closed for new payees");
        _addPayee(account, shares_);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    function testRelease(address payable toAc)external onlyRole(UPDATER_ROLE){
        require(address(this).balance > 0.01 ether, "Not enough balance");
        require(testPaymentCount < 6, "max tests passed");
        require(testPayment[toAc]==false, "Already tested");
        Address.sendValue(toAc, 0.01 ether);
        testPayment[toAc] = true;
        testPaymentCount += 1;
    }
}



// /**
    //  * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
    //  * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
    //  * contract.
    //  */
    // function release(IERC20 token, address account) public virtual {
    //     require(_shares[account] > 0, "PaymentSplitter: account has no shares");

    //     uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
    //     uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

    //     require(payment != 0, "PaymentSplitter: account is not due payment");

    //     _erc20Released[token][account] += payment;
    //     _erc20TotalReleased[token] += payment;

    //     SafeERC20.safeTransfer(token, account, payment);
    //     emit ERC20PaymentReleased(token, account, payment);
    // }