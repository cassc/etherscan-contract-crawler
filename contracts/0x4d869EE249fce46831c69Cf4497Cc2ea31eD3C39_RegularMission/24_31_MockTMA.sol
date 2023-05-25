// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../Locker/StakingCollection.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockTMA is ERC721, Ownable, StakingCollection {
    constructor() ERC721("TMAs", "TMAs") {}

    uint256 public totalSupply = 0;
    mapping(uint256 => uint256) public power;

    function mint(uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply + i + 1);
        }

        totalSupply += amount;
    }

    function setLocker(address value) external override onlyOwner {
        _setLocker(value);
    }

    // For Lock
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotStaking(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotStaking(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override whenNotStaking(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}