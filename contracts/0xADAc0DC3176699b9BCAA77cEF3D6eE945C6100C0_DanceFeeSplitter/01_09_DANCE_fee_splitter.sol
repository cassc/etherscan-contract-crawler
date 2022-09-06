// SPDX-License-Identifier: MIT
/***
 *                                                                 .';:c:,.
 *                   ;0NNNNNNX.  lNNNNNNK;       .XNNNNN.     .:d0XWWWWWWWWXOo'
 *                 lXWWWWWWWWO   XWWWWWWWWO.     :WWWWWK    ;0WWWWWWWWWWWWWWWWWK,
 *              .dNWWWWWWWWWWc  ,WWWWWWWWWWNo    kWWWWWo  .0WWWWWNkc,...;oXWWXxc.
 *            ,kWWWWWWXWWWWWW.  dWWWWWXNWWWWWX; .NWWWWW.  KWWWWW0.         ;.
 *          :KWWWWWNd.lWWWWWO   XWWWWW:.xWWWWWWOdWWWWW0  cWWWWWW.
 *        lXWWWWWXl.  0WWWWW:  ,WWWWWN   '0WWWWWWWWWWWl  oWWWWWW;         :,
 *     .dNWWWWW0;    'WWWWWN.  xWWWWWx     :XWWWWWWWWW.  .NWWWWWWkc,'';ckNWWNOc.
 *   'kWWWWWWx'      oWWWWWk   NWWWWW,       oWWWWWWW0    '0WWWWWWWWWWWWWWWWWO;
 * .d000000o.        k00000;  ,00000k         .x00000:      .lkKNWWWWWWNKko;.
 *                                                               .,;;'.
 */
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FeeSplitter.sol";
import "./IERC20F.sol";

contract DanceFeeSplitter is Ownable, FeeSplitter{
    event TransferredTokens(address from, address to, uint256 amount);

    IERC20F internal _dance;

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _released;
    mapping(address => uint256) private _shares;

    address[] private _payees;

    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "payees and shares length mismatch");
        require(payees.length > 0, "no payees");
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    modifier onlyShareHolder() {
        require(_shares[msg.sender] > 0, "Sender is not share holder");
        _;
    }

    /* External Functions */

    function withdraw(IERC20 token) external onlyOwner {
        // Function for withdrawing any funds that get into the contract by accident
        require(token != _dance, "Cannot withdraw DANCE");
        uint256 amount = token.balanceOf(msg.sender);
        if(amount > 0){
            SafeERC20.safeTransfer(token, msg.sender, amount);
        }
        amount = address(this).balance;
        if(amount > 0){
            Address.sendValue(payable(msg.sender), amount);
        }
    }

    function setRewardToken(address tokenAddress) external onlyOwner {
        require(_dance == IERC20F(address(0)), "dance token is already set");
        require(tokenAddress != address(0), "dance token cannot be 0 address");
        _dance = IERC20F(tokenAddress);
    }

    /* Public Functions */

    function proxySend(address to, uint256 amount) public onlyShareHolder {
        require(amount != 0, "Amount can't be 0");
        require(amount < balanceOf(msg.sender), "Trying to send more than available");
        _released[msg.sender] += amount;
        _totalReleased += amount;
        _dance.transferNoFee(to, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 totalReceived = _dance.balanceOf(address(this)) + totalReleased();
        return (totalReceived * _shares[account]) / _totalShares - released(account);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /* Private Functions */

    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "account is the zero address");
        require(shares_ > 0, "shares are 0");
        require(_shares[account] == 0, "account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
    }
}