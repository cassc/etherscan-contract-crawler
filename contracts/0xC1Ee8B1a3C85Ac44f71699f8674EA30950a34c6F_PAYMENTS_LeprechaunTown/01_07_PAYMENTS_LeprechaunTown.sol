// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

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
contract PAYMENTS_LeprechaunTown is Context, Ownable {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event EmergencyWithdraw(address account, uint256 amount);
    event EmergencyWithdraw_ERC20(IERC20 indexed token, address account, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

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
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
    * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
    * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
    * contract.
    */
    function release_ERC20(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
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

    /**
    * @dev Modify existing payee address in the contract.
    * @param addressIndex The index of the old address of the payee to modify.
    * @param newAddress The new address of the payee.
    */
    function _modifyPayee(uint256 addressIndex, address newAddress) public onlyOwner {
        address oldAddress = _payees[addressIndex];
        uint256 shareAmount = _shares[oldAddress];
        
        _payees[addressIndex] = newAddress;
        _shares[newAddress] = shareAmount;

        delete _shares[oldAddress];
    }

    /**
    * @dev Adjust the amount of shares held by an account.
    */
    function adjustShares(address account, uint256 shares_) public onlyOwner {
        require(checkPayee(account), "PaymentSplitter: account must be a payee");
        _totalShares = (_totalShares - _shares[account]) + shares_;
        _shares[account] = shares_;
    }

    function checkPayee(address account) private view returns(bool){
        for (uint256 i = 0; i < _payees.length; i++) {
            if(_payees[i] == account){
                return true;
            }
        }
        return false;
    }

    /**
    * @dev The contract modifier / developer's website.
    */
    function contractDev() public pure returns(string memory){
        string memory dev = unicode"🐸 HalfSuperShop.com 🐸";
        return dev;
    }

    /**
    * @dev Pays all payees their share of ETH
    */
    function releaseForAll() public virtual{
        for (uint256 i = 0; i < _payees.length; i++) {
            address payable account = payable(_payees[i]);
            uint256 payment = releasable(account);
            if(payment != 0){
                release(account);
            }
            else{
                //address already released their share
            }
        }
    }

    /**
    * @dev Pays all payees their share of an ERC20 token
    */
    function releaseForAll_ERC20(IERC20 token) public virtual{
        for (uint256 i = 0; i < _payees.length; i++) {
            address payable account = payable(_payees[i]);
            uint256 payment = releasable(token, account);
            if(payment != 0){
                release_ERC20(token, account);
            }
            else{
                //address already released their share
            }
        }
    }

    /**
    * @dev Completely Resets Splitter and withdrawls any remaining ETH.
    * NOTE: Any remaining ERC20 tokens will need to be manually withdrawn.
    */
    function resetSplit(address[] memory payees, uint256[] memory shares_) external payable onlyOwner{
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        //reset everything
        for (uint256 i = 0; i < _payees.length; i++) {
            delete _shares[_payees[i]];
            delete _released[_payees[i]];
        }
        delete _payees;
        delete _totalShares;
        delete _totalReleased;

        //add new data
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }

        if (address(this).balance != 0){
            emergencyWithdraw();
        }
    }

    /**
    * @dev Only use with project leaders approval to withdraw all ETH
    * NOTE: This is to be used only if any funds are stuck within the contract.
    */
    function emergencyWithdraw() public onlyOwner {
        uint256 payment = address(this).balance;
        payable(msg.sender).transfer(address(this).balance);
        emit EmergencyWithdraw(msg.sender, payment);
    }

    /**
    * @dev Only use with project leaders approval to withdraw the ERC20 tokens
    */
    function emergencyWithdraw_ERC20(IERC20 token, uint256 _amount) public onlyOwner {
        _erc20TotalReleased[token] = 0;
        SafeERC20.safeTransfer(token, msg.sender, _amount);
        emit EmergencyWithdraw_ERC20(token, msg.sender, _amount);
    }
}

/**
    [
    "0x1BA3fe6311131A67d97f20162522490c3648F6e2",
    "0x8AD965846A836EBd3d43AB2cA2e16ed65a5Bf258",
    "0xec3601d8063a0c1ad3734fc8d6dc52ea26bcedda",
    "0xA4E9865BE4f6b79C23D3A62fA92f01cBf3e82311",
    "0x461a7093cBcf0B33A1b0D70fd141D2DbfC0e2D50"
    ]

    [
    20,
    20,
    15,
    15,
    30
    ]

    payees[0] = 0x1BA3fe6311131A67d97f20162522490c3648F6e2; //Dev
    payees[1] = 0x8AD965846A836EBd3d43AB2cA2e16ed65a5Bf258; //PL
    payees[2] = 0xec3601d8063a0c1ad3734fc8d6dc52ea26bcedda; //AMB1
    payees[3] = 0xA4E9865BE4f6b79C23D3A62fA92f01cBf3e82311; //AMB2
    payees[4] = 0x461a7093cBcf0B33A1b0D70fd141D2DbfC0e2D50; //Treasury

*/