// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IRewardsStrategy} from "../interfaces/IRewardsStrategy.sol";

contract DefaultRewardsStrategy is IRewardsStrategy, Ownable {
    uint256 public constant PERCENTAGE_FACTOR = 1e4;

    uint256 internal _nftShare;

    constructor(uint256 nftShare_) Ownable() {
        _nftShare = nftShare_;
    }

    function setNftRewardsShare(uint256 nftShare_) public onlyOwner {
        require(nftShare_ < PERCENTAGE_FACTOR, "DRS: nft share is too high");
        _nftShare = nftShare_;
    }

    function getNftRewardsShare() public view override returns (uint256 nftShare) {
        return _nftShare;
    }
}