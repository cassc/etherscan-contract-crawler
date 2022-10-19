// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

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
contract GrimaceSplitter is Context {
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    uint256 private _shares; // All nfts have equal share
    mapping(uint256 => uint256) private _released; // How much each NFT has claimed
    uint256 private _payees; // Total amount of nfts registered

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(uint256 => uint256)) private _erc20Released;  // How much each NFT has claimed

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     */
    constructor() payable {
        _shares = 1;
        _payees = 1000;
        _totalShares = 1000;
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
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(uint256 tokenId) public view returns (uint256) {
        return _released[tokenId];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, uint256 tokenId) public view returns (uint256) {
        return _erc20Released[token][tokenId];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(uint256 tokenId) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(totalReceived, released(tokenId));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, uint256 tokenId) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(totalReceived, released(token, tokenId));
    }

    function releasableAll(IERC20[] memory tokens, uint256[] memory tokenIds) public view returns (uint256) {
        uint256 totalReleasable;
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            for (uint j = 0; j < tokenIds.length; j++) {
                uint256 tokenId = tokenIds[j];
                uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
                totalReleasable += _pendingPayment(totalReceived, released(token, tokenId));
            }
        }
        return totalReleasable;
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(uint256[] memory tokenIds) internal {
        uint256 payment;
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenPayment =  releasable(tokenIds[i]);
            payment += tokenPayment;
            unchecked {
                _released[tokenIds[i]] += tokenPayment;
            }
        }

        require(payment != 0, "PaymentSplitter: account is not due payment");

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        _totalReleased += payment;

        Address.sendValue(payable(msg.sender), payment);
        emit PaymentReleased(msg.sender, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20[] memory tokens, uint256[] memory tokenIds) internal {
        uint256 totalPayment;
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            uint256 payment;
            for (uint j = 0; j < tokenIds.length; j++) {
                uint256 tokenPayment = releasable(token, tokenIds[j]);
                payment += tokenPayment;
                unchecked {
                    _erc20Released[token][tokenIds[j]] += tokenPayment;
                }
            }
            totalPayment += payment;

            // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
            // If "_erc20TotalReleased[token] += payment" does not overflow, then "_erc20Released[token][account] += payment"
            // cannot overflow.
            if (payment > 0) {
                _erc20TotalReleased[token] += payment;
                SafeERC20.safeTransfer(token, msg.sender, payment);
                emit ERC20PaymentReleased(token, msg.sender, payment);
            }
        }              
        require(totalPayment != 0, "PaymentSplitter: account is not due payment");  
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares) / _totalShares - alreadyReleased;
    }

    function _setShares(uint256 newShares) internal {
        _shares = newShares;
    }

    function _setPayees(uint256 newPayees) internal {
        _payees = newPayees;
    }

    function _setTotalShares(uint256 newShares) internal {
        _totalShares = newShares;
    }
}