// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IManagers.sol";

contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    IManagers managers;

    uint256 private _totalShares;
    uint256 private _totalReleased;

    // developer share %10
    uint256 private _developerShare = 1000;
    address private _developerAddress;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address managersAddress_, address developerAddress_, address[] memory payees_, uint256[] memory shares_) payable {
        managers = IManagers(managersAddress_);
        _developerAddress = developerAddress_; 
        _udateShares(payees_, shares_);
    }

    modifier onlyManager() {
        require(managers.isManager(msg.sender), "ONLY MANAGERS: Not authorized");
        _;
    }

    function _udateShares(address[] memory newPayees_, uint256[] memory newShares_) private {
        require(newPayees_.length == newShares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(newPayees_.length > 0, "PaymentSplitter: no payees");
        // clear old share data
        _totalShares = 0;
        for (uint256 i = 0; i < _payees.length; i++) {
            _shares[_payees[i]] = 0;
        }
        delete _payees;

        // create new shares
        _addPayee(_developerAddress, _developerShare);
        for (uint256 i = 0; i < newPayees_.length; i++) {
            _addPayee(newPayees_[i], newShares_[i]);
        }
        require(_totalShares == 10000, "PaymentSplitter: totalShare most be 100 percent");
    }

    function updateManagers(address _managers) public onlyManager {
        string memory _title = "Update managers";
        bytes memory _encodedValues = abi.encode(_managers);
        managers.approveTopic(_title, _encodedValues);
        if (managers.isApproved(_title, _encodedValues)) {
            managers = IManagers(_managers);
            managers.deleteTopic(_title);
        }
    }

    function updateShares(address[] memory newPayees_, uint256[] memory newShares_) public onlyManager {
        string memory _title = "Update share rates";
        bytes memory _encodedValues = abi.encode(newPayees_, newShares_);
        managers.approveTopic(_title, _encodedValues);
        if (managers.isApproved(_title, _encodedValues)) {
            _udateShares(newPayees_, newShares_);
            managers.deleteTopic(_title);
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
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
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
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(account, totalReceived, released(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual onlyManager {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        string memory _title = "release eth";
        bytes memory _encodedValues = abi.encode(account);
        managers.approveTopic(_title, _encodedValues);
        if (managers.isApproved(_title, _encodedValues)) {
            _released[account] += payment;
            _totalReleased += payment;

            Address.sendValue(account, payment);
            managers.deleteTopic(_title);
            emit PaymentReleased(account, payment);
        }
    }

    /**
     * @dev Triggers a transfer to `payee accounts` for the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function releaseAll() public virtual onlyManager {
        string memory _title = "releaseAll eth";
        bytes memory _encodedValues = abi.encode(_title);
        managers.approveTopic(_title, _encodedValues);
        if (managers.isApproved(_title, _encodedValues)) {
            for (uint256 i = 0; i < _payees.length; i++) {
                address account = _payees[i];
                if (account != _developerAddress) {
                    uint256 payment = releasable(account);
                    if (payment > 0) {
                        _released[account] += payment;
                        _totalReleased += payment;

                        payable(account).transfer(payment);
                        emit PaymentReleased(account, payment);
                    }
                }
            }
            managers.deleteTopic(_title);
        }
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual onlyManager {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        string memory _title = "release token";
        bytes memory _encodedValues = abi.encode(address(token), account);
        managers.approveTopic(_title, _encodedValues);
        if (managers.isApproved(_title, _encodedValues)) {
            _erc20Released[token][account] += payment;
            _erc20TotalReleased[token] += payment;

            SafeERC20.safeTransfer(token, account, payment);
            managers.deleteTopic(_title);
            emit ERC20PaymentReleased(token, account, payment);
        }
    }

    /**
     * @dev Triggers a transfer to `payee accounts` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function releaseAll(IERC20 token) public virtual onlyManager {
        string memory _title = "releaseAll token";
        bytes memory _encodedValues = abi.encode(address(token));
        managers.approveTopic(_title, _encodedValues);
        if (managers.isApproved(_title, _encodedValues)) {
            for (uint256 i = 0; i < _payees.length; i++) {
                address account = _payees[i];
                if (account != _developerAddress) {
                    uint256 payment = releasable(token, account);
                    _erc20Released[token][account] += payment;
                    _erc20TotalReleased[token] += payment;

                    SafeERC20.safeTransfer(token, account, payment);
                    emit ERC20PaymentReleased(token, account, payment);
                }
            }
            managers.deleteTopic(_title);
        }
    }

    function developerRelease(address payable account) public virtual {
        require(_developerAddress == _msgSender(), "PaymentSplitter: developer only");
        require(_developerAddress == account, "PaymentSplitter: developer only");
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    function developerRelease(IERC20 token, address account) public virtual {
        require(_developerAddress == _msgSender(), "PaymentSplitter: developer only");
        require(_developerAddress == account, "PaymentSplitter: developer only");
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    function transferDeveloperOwnership(address newOwner) public virtual {
        require(_developerAddress == _msgSender(), "PaymentSplitter: developer only");
        require(newOwner != address(0), "PaymentSplitter: new owner is the zero address");
        _developerAddress = newOwner;
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