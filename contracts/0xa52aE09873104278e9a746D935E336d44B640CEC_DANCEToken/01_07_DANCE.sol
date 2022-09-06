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

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20F.sol";

contract DANCEToken is Ownable, ERC20F{

    constructor(
        uint256 fee_,
        uint256 feedivider_,
        address danceSplitter_,
        address[] memory initAddresses_,
        uint256[] memory initAmounts_
    ) ERC20F("DANCE", "DANCE", fee_, feedivider_, danceSplitter_) {
        require(initAddresses_.length == initAmounts_.length, "lengths of initAddresses and initAmounts do not match");
        uint256 totalSupply = 0;
        for (uint256 i = 0; i < initAmounts_.length; i++) {
            totalSupply += initAmounts_[i];
        }
        require(totalSupply <= type(uint96).max, "total supply too large");
        // initial distribution
        for (uint256 i = 0; i < initAddresses_.length; i++) {
            _mint(initAddresses_[i], initAmounts_[i]);
            _setNoFeeAddress(initAddresses_[i], true);
        }
    }

    /* External Functions */

    function setFee(uint256 fee_, uint256 divider_) external onlyOwner {
        _setFee(fee_, divider_);
    }

    function setNoFeeAddress(address account, bool value) external onlyOwner {
        _setNoFeeAddress(account, value);
    }
}