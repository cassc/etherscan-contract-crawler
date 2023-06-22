// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

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
 */
abstract contract TokenPaymentSplitter is Context {
  using SafeMath for uint256;

    event PaymentReleased(address to, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    uint256 private _mainWalletShare;
    uint256 private _numOfInvestTokens;

    uint256 private _mainWalletToken = 123456789;
    // 200 ETH
    uint256 private _minMainShare = 200000000000000000000; 

    mapping(uint256 => uint256) private _released;

    address internal mainWallet = 0xB92484327FA91593bcAd2072bA37E18B7db58178;

    constructor(uint256 mainWalletShare, uint256 numOfInvestTokens) payable {
        _mainWalletShare = mainWalletShare;
        _numOfInvestTokens = numOfInvestTokens;
        _totalShares = mainWalletShare + numOfInvestTokens;
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
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(uint256 tokenId) public view returns (uint256) {
        return _released[tokenId];
    }

    function amountDueToToken(uint256 tokenId) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + _totalReleased;

        if (totalReceived <= _minMainShare) {
            if (tokenId == _mainWalletToken){
                return address(this).balance;
            }
            else {
                return 0;
            }
        }

        totalReceived = SafeMath.sub(totalReceived, _minMainShare, "negative");
        uint256 shares = tokenId == _mainWalletToken ? _mainWalletShare : 1;
        uint256 payment = SafeMath.div(totalReceived, _totalShares, "divisino by zero") * shares;
        if (tokenId == _mainWalletToken) {
            payment = payment + _minMainShare;
        }
        payment = SafeMath.sub(payment, _released[tokenId], "substract");
        return payment;
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(uint256 tokenId) public virtual {
        require(tokenId == _mainWalletToken || tokenId < _numOfInvestTokens, "PaymentSplitter: account has no shares");
        require(_authorizedToToken(tokenId), "PaymentSplitter: sender not approved to manage the token.");

        uint256 payment = amountDueToToken(tokenId);

        require(payment != 0, "PaymentSplitter: account is not due payment");
        address account = tokenId == _mainWalletToken ? mainWallet : ownerOf(tokenId);

        _released[tokenId] = _released[tokenId] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(payable(account), payment);
        emit PaymentReleased(account, payment); 
    }

    function _authorizedToToken(uint256 tokenId) private view returns (bool){
        return _msgSender() == owner() || _isApprovedOrOwner(_msgSender(), tokenId);
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool);
    function owner() public view virtual returns (address);


}