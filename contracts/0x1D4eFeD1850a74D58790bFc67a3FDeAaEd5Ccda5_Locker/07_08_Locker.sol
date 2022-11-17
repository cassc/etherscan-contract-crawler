// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILocker.sol";
import "hardhat/console.sol"; // TODO: del

contract Locker is Ownable, ILocker {
    mapping(uint256 => uint256) private unlockTime; // unlock time of each NFT
    IERC20 public wcfErc20Token;
    IERC721 public wcfNft;
    uint256 public erc20HoldingsRequirement; // number of WCF ERC20 tokens that a user must hold to be able to lock

    event Locked(
        address indexed from, //TODO check indexing
        uint256 indexed tokenId,
        uint256 timePeriod,
        uint8 matchId,
        uint8 result
    );

    constructor(address wcfErc20TokenAddress, address wcfNftAddress) {
        wcfErc20Token = IERC20(wcfErc20TokenAddress);
        wcfNft = IERC721(wcfNftAddress);
    }

    function lock(
        uint256 tokenId,
        uint256 unlockTime_,
        uint8 matchId,
        uint8 result
    ) external {
        require(wcfNft.ownerOf(tokenId) == msg.sender, "!tokenOwner");
        require(!isLocked(tokenId), "NFT locked");
        require(
            wcfErc20Token.balanceOf(msg.sender) >= erc20HoldingsRequirement,
            "HoldingNotEnoughERC20"
        );
        require(block.timestamp < unlockTime_, "locktime<0");

        unlockTime[tokenId] = unlockTime_;
        emit Locked(msg.sender, tokenId, unlockTime_, matchId, result);
    }

    function isLocked(uint256 tokenId) public view returns (bool) {
        return block.timestamp < unlockTime[tokenId];
    }

    function setErc20HoldingsRequirement(uint256 erc20HoldingsRequirement_)
        external
        onlyOwner
    {
        erc20HoldingsRequirement = erc20HoldingsRequirement_;
    }
}