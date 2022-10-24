// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract GMMSplitter is Context, Pausable, Ownable {
    event PayeeAdded(address account, uint256 shares);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    IERC20 public tokenRelease;

    uint256 private _totalShares;
    uint256 private _erc20TotalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _erc20Released;
    mapping(address => bool) public _addressCanClaim;
    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(IERC20 token) payable {
        // Setting the main token to release, useful for changeAddress only
        tokenRelease = token;
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased() public view returns (uint256) {
        return _erc20TotalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(address account) public view returns (uint256) {
        return _erc20Released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = tokenRelease.balanceOf(address(this)) + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(address account) public virtual whenNotPaused {
        require(_addressCanClaim[account], "This address cannot claim, contact Gamium Team if that's a mistake");
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = tokenRelease.balanceOf(address(this)) + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[account] += payment;
        _erc20TotalReleased += payment;

        SafeERC20.safeTransfer(tokenRelease, account, payment);
        emit ERC20PaymentReleased(tokenRelease, account, payment);
    }

    /**
     * @dev Only call before any payees claims. Constructor does not allow long list.
     */
    function setPayees(address[] memory payees, uint256[] memory shares_) public onlyOwner {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev Change address in case one of the payees got hacked.
     */
    function changeAddress(address _prev, address _new) public onlyOwner {
        require(_shares[_prev] > 0, "PaymentSplitter: prev account has no shares");
        require(_shares[_new] == 0, "PaymentSplitter: new account has shares");

        _payees.push(_new);
        _shares[_new] =  _shares[_prev];
        _shares[_prev] = 0;

        _erc20Released[_new] += _erc20Released[_prev];

        _addressCanClaim[_new] = _addressCanClaim[_prev];
        _addressCanClaim[_prev] = false;
    }

    /**
     * @dev Set claiming status for addresses.
     */
    function setClaimingStatus(address[] memory payees, bool status) public onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            _addressCanClaim[payees[i]] = status;
        }
    }

    /**
    * @dev Transfer all held by the contract to the owner.
    */
    function reclaimETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
    * @dev Transfer all ERC20 of tokenContract held by contract to the owner in case of hackings.
    */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
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
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
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
}