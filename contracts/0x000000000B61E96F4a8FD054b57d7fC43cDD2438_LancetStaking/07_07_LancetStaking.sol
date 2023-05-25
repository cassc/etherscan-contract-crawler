// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract LancetStaking is Ownable,Pausable,ReentrancyGuard{
    uint256 public stakingStartAt;
    uint256 public stakingEndAt;
    IERC721 public lancetPass;

    mapping(address => uint256) public ownedToken;

    event Staking(address indexed owner,uint256 indexed startTimestamp,uint256 indexed endTimestamp,uint256 tokenId);

    constructor (){
        stakingStartAt = 1682604000;
        stakingEndAt = 1686319200;
        lancetPass = IERC721(0x00000000000881D280439988781F743E8cDd1fdF);
    }

    function staking(uint256 tokenId)whenNotPaused nonReentrant external {
        require(block.timestamp >= stakingStartAt,"Staking Not Open");
        require(block.timestamp <= stakingEndAt,"Staking Not Open");
        require(ownedToken[msg.sender] == 0,"Already Staking");
        lancetPass.transferFrom(msg.sender,address(this),tokenId);
        ownedToken[msg.sender] = tokenId;
        emit Staking(msg.sender,block.timestamp,stakingEndAt,tokenId);
    }

    function stakingTokenWithdraw() whenNotPaused nonReentrant external{
        require(block.timestamp >= stakingEndAt,"Cannot withdraw");
        require(ownedToken[msg.sender] != 0,"Haven't Pass In Staking");
        lancetPass.transferFrom(address(this),msg.sender,ownedToken[msg.sender]);
        ownedToken[msg.sender] = 0;
    }

    function setStakingTimestamp(uint256 startAt,uint256 endAt) onlyOwner external{
        stakingStartAt = startAt;
        stakingEndAt = endAt;
    }

    function setLancetPassAddress(address lancetPassAddress) onlyOwner external{
        lancetPass = IERC721(lancetPassAddress);
    }

    function pause() onlyOwner external{
        _pause();
    }

    function unpause() onlyOwner external{
        _unpause();
    }
}