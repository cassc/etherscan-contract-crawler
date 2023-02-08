// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract E4CThornHolder is ERC721Holder {

    address public nft;

    mapping(uint256 => address) public originalOwner;

    mapping(uint256 => uint256) private _accStakingTime;
    mapping(uint256 => uint256) private _lastStakingTime;

    event Staked(address indexed user, uint256 tokenId);
    event Withdrawn(address indexed user, uint256 tokenId);

    constructor(address _nft) {
        nft = _nft;
    }

    function unstake(uint256 tokenId) external {
        require(originalOwner[tokenId] != address(0), "The contract doesn't hold the specific token");
        require(originalOwner[tokenId] == msg.sender, "You're not the owner");
        uint256 stakingDuration = block.timestamp - _lastStakingTime[tokenId];
        uint256 accStakingTime = _accStakingTime[tokenId] + stakingDuration;
        _accStakingTime[tokenId] = accStakingTime;

        IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);
        originalOwner[tokenId] = address(0);

        emit Withdrawn(msg.sender, tokenId);
    }

    function totalStakingTime(uint256 tokenId) external view returns (uint256) {
        if (originalOwner[tokenId] == address(0)) {
            return _accStakingTime[tokenId];
        }

        return block.timestamp - _lastStakingTime[tokenId] + _accStakingTime[tokenId];
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes memory
    ) public override returns (bytes4) {
        require(msg.sender == nft, "Not acceptable NFT");

        originalOwner[tokenId] = from;
        _lastStakingTime[tokenId] = block.timestamp;

        emit Staked(from, tokenId);

        return this.onERC721Received.selector;
    }
}