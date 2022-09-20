// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @author narghev dactyleth

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/interfaces/IERC721A.sol";

contract HappyCamperStaking is Ownable {
    IERC721A public originalContract;
    bool public stakingActive = true;

    struct StakedInfo {
        address owner;
        uint256 stakedAt;
        uint256 tokenId;
    }

    mapping(uint256 => StakedInfo) public tokenStakedInfo;
    uint256 public stakedCount = 0;

    constructor(address originalContract_) {
        originalContract = IERC721A(originalContract_);
    }

    function stake(uint256[] memory tokenIds) external {
        require(stakingActive, "Staking not active");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            originalContract.transferFrom(msg.sender, address(this), tokenId);
            tokenStakedInfo[tokenId] = StakedInfo(
                msg.sender,
                uint256(block.timestamp),
                tokenId
            );
        }
        stakedCount += tokenIds.length;
    }

    function unstake(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakedInfo memory info = tokenStakedInfo[tokenId];
            require(info.owner == msg.sender, "Only owner can unstake");
            delete tokenStakedInfo[tokenId];
            originalContract.transferFrom(address(this), msg.sender, tokenId);
        }
        stakedCount -= tokenIds.length;
    }

    function setStakingActive(bool stakingActive_) external onlyOwner {
        stakingActive = stakingActive_;
    }

    function setOriginalContract(address originalContract_) external onlyOwner {
        originalContract = IERC721A(originalContract_);
    }

    function balanceOf(address owner_) public view returns (uint256) {
        uint256 supply = originalContract.totalSupply();
        uint256 count = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (tokenStakedInfo[tokenId].owner == owner_) {
                count++;
            }
        }
        return count;
    }

    function snapshot() public view returns (StakedInfo[] memory) {
        uint256 supply = originalContract.totalSupply();
        StakedInfo[] memory currentState = new StakedInfo[](stakedCount);
        uint256 count = 0;

        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            StakedInfo memory info = tokenStakedInfo[tokenId];
            if (info.owner != address(0)) {
                currentState[count] = info;
                count++;
            }
        }
        return currentState;
    }

    function walletOfOwner(address owner_)
        public
        view
        returns (StakedInfo[] memory)
    {
        uint256 supply = originalContract.totalSupply();
        uint256 balance = balanceOf(owner_);
        StakedInfo[] memory tokens = new StakedInfo[](balance);
        uint256 count = 0;

        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            StakedInfo memory token = tokenStakedInfo[tokenId];
            if (token.owner == owner_) {
                tokens[count] = token;
                count++;
            }
        }
        return tokens;
    }
}