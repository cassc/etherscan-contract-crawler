// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context, Ownable {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event Reset(address[] payees, uint256[] shares);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    uint256 private _version;

    mapping(bytes32 => uint256) private _shares;
    mapping(bytes32 => uint256) private _released;
    address[] private _payees;

    mapping(bytes32 => uint256) private _erc20TotalReleased;
    mapping(bytes32 => mapping(bytes32 => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
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

    /**
     * @dev Reset the contract to a fresh state, equivalent to re-running the constructor.
     *      WARNING: Ensure that all existing funds have been released to payees, accumulated funds 
     *               will be lost otherwise.
     */
    function reset(address[] memory payees, uint256[] memory shares_) external onlyOwner {
        _version++;

        delete _totalShares;
        delete _totalReleased;
        delete _payees;

        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }

        emit Reset(payees, shares_);
    } 

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleasedEther() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleasedErc20(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[_IERC20Key(token)];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[_addressKey(account)];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function releasedEther(address account) public view returns (uint256) {
        return _released[_addressKey(account)];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function releasedErc20(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[_IERC20Key(token)][_addressKey(account)];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasableEther(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleasedEther();
        return _pendingPayment(account, totalReceived, releasedEther(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasableErc20(IERC20 token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleasedErc20(token);
        return _pendingPayment(account, totalReceived, releasedErc20(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function releaseEther(address payable account) public virtual {
        require(_shares[_addressKey(account)] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasableEther(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[_addressKey(account)] += payment" cannot overflow.
        _totalReleased += payment;
        unchecked {
            _released[_addressKey(account)] += payment;
        }

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function releaseErc20(IERC20 token, address account) public virtual {
        require(_shares[_addressKey(account)] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasableErc20(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _erc20TotalReleased[_IERC20Key(token)] is the sum of all values in _erc20Released[_IERC20Key(token)].
        // If "_erc20TotalReleased[_IERC20Key(token)] += payment" does not overflow, 
        // then "_erc20Released[_IERC20Key(token)][_addressKey(account)] += payment" cannot overflow.
        _erc20TotalReleased[_IERC20Key(token)] += payment;
        unchecked {
            _erc20Released[_IERC20Key(token)][_addressKey(account)] += payment;
        }

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev Triggers a release of release-able Ether to each account.
     */
    function releaseAllEther() public virtual {
        uint256 payeesLength = _payees.length;
        for (uint256 i = 0; i < payeesLength; i++) {
            address payable account = payable(_payees[i]);

            // Does not rely on existing release function to avoid failing 
            // if _shares[_addressKey(account)] == 0 or payment == 0
            if (_shares[_addressKey(account)] > 0) {
                uint256 payment = releasableEther(account);
                if (payment != 0) {
                    // _totalReleased is the sum of all values in _released.
                    // If "_totalReleased += payment" does not overflow, then 
                    // "_released[_addressKey(account)] += payment" cannot overflow.
                    _totalReleased += payment;
                    unchecked {
                        _released[_addressKey(account)] += payment;
                    }

                    Address.sendValue(account, payment);
                    emit PaymentReleased(account, payment);
                }
            }
        } 
    }

    /**
     * @dev Triggers a release of release-able token to each account.
     */
    function releaseAllErc20(IERC20 token) public virtual {
        uint256 payeesLength = _payees.length;
        for (uint256 i = 0; i < payeesLength; i++) {
            address account = _payees[i];

            // Does not rely on existing release function to avoid failing 
            // if _shares[_addressKey(account)] == 0 or payment == 0
            if (_shares[_addressKey(account)] > 0) {
                uint256 payment = releasableErc20(token, account);
                if (payment != 0) {
                    // _erc20TotalReleased[_IERC20Key(token)] is the sum of all values in _erc20Released[_IERC20Key(token)].
                    // If "_erc20TotalReleased[_IERC20Key(token)] += payment" does not overflow, 
                    // then "_erc20Released[_IERC20Key(token)][_addressKey(account)] += payment"
                    // cannot overflow.
                    _erc20TotalReleased[_IERC20Key(token)] += payment;
                    unchecked {
                        _erc20Released[_IERC20Key(token)][_addressKey(account)] += payment;
                    }

                    SafeERC20.safeTransfer(token, account, payment);
                    emit ERC20PaymentReleased(token, account, payment);
                }
            }
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
        return (totalReceived * _shares[_addressKey(account)]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[_addressKey(account)] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[_addressKey(account)] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev Return the key for the address indexed mappings based on the current version
     */
    function _addressKey(address _address) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_version, _address));
    }

    /**
     * @dev Return the key for the IERC20 indexed mappings based on the current version
     */
    function _IERC20Key(IERC20 _IERC20) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_version, _IERC20));
    }
}