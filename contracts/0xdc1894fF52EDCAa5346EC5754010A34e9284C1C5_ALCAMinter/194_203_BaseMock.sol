// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/PublicStaking.sol";
import "contracts/ALCA.sol";

abstract contract BaseMock {
    PublicStaking public publicStaking;
    ALCA public alca;

    receive() external payable virtual {}

    function setTokens(ALCA alca_, PublicStaking stakeNFT_) public {
        publicStaking = stakeNFT_;
        alca = alca_;
    }

    function mint(uint256 amount_) public returns (uint256) {
        return publicStaking.mint(amount_);
    }

    function mintTo(address to_, uint256 amount_, uint256 duration_) public returns (uint256) {
        return publicStaking.mintTo(to_, amount_, duration_);
    }

    function burn(uint256 tokenID) public returns (uint256, uint256) {
        return publicStaking.burn(tokenID);
    }

    function burnTo(address to_, uint256 tokenID) public returns (uint256, uint256) {
        return publicStaking.burnTo(to_, tokenID);
    }

    function approve(address who, uint256 amount_) public returns (bool) {
        return alca.approve(who, amount_);
    }

    function depositToken(uint256 amount_) public {
        publicStaking.depositToken(42, amount_);
    }

    function depositEth(uint256 amount_) public {
        publicStaking.depositEth{value: amount_}(42);
    }

    function collectToken(uint256 tokenID_) public returns (uint256 payout) {
        return publicStaking.collectToken(tokenID_);
    }

    function collectEth(uint256 tokenID_) public returns (uint256 payout) {
        return publicStaking.collectEth(tokenID_);
    }

    function approveNFT(address to, uint256 tokenID_) public {
        return publicStaking.approve(to, tokenID_);
    }

    function setApprovalForAll(address to, bool approve_) public {
        return publicStaking.setApprovalForAll(to, approve_);
    }

    function transferFrom(address from, address to, uint256 tokenID_) public {
        return publicStaking.transferFrom(from, to, tokenID_);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID_,
        bytes calldata data
    ) public {
        return publicStaking.safeTransferFrom(from, to, tokenID_, data);
    }

    function lockWithdraw(uint256 tokenID, uint256 lockDuration) public returns (uint256) {
        return publicStaking.lockWithdraw(tokenID, lockDuration);
    }
}