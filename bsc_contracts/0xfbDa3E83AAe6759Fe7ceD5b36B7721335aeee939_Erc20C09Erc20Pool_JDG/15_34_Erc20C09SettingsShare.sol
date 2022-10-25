// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09SettingsShare is
Ownable
{
    uint256 public constant shareMax = 1000;

    uint256 public shareMarketing;
    uint256 public shareLper;
    uint256 public shareHolder;
    uint256 public shareLiquidity;
    uint256 public shareBurn;

    uint256 internal shareTotal;

    function setShare(
        uint256 shareMarketing_,
        uint256 shareLper_,
        uint256 shareHolder_,
        uint256 shareLiquidity_,
        uint256 shareBurn_
    )
    public
    onlyOwner
    {
        shareMarketing = shareMarketing_;
        shareLper = shareLper_;
        shareHolder = shareHolder_;
        shareLiquidity = shareLiquidity_;
        shareBurn = shareBurn_;
        shareTotal = shareMarketing_ + shareLper_ + shareHolder_ + shareLiquidity_ + shareBurn_;

        require(shareTotal <= shareMax, "wrong value");
    }
}