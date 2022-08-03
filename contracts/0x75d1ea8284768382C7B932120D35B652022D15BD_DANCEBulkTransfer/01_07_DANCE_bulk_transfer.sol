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

contract DANCEBulkTransfer is Ownable{

    IERC20F private _dance;

    constructor(address tokenAddress){
        _dance = IERC20F(tokenAddress);
    }

    function bulkTransfer(address[] memory toAdresses, uint256 amount) external onlyOwner{
        for (uint256 i = 0; i < toAdresses.length; i++) {
            _dance.transferNoFee(toAdresses[i], amount);
        }
    }

    function bulkTransferFrom(address from, address[] memory toAdresses, uint256 amount) external onlyOwner{
        for (uint256 i = 0; i < toAdresses.length; i++) {
            _dance.transferFromNoFee(from, toAdresses[i], amount);
        }
    }
}