// SPDX-License-Identifier: MIT
pragma abicoder v2;
pragma solidity =0.7.6;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lock is Ownable {
    mapping(uint256 => uint256) public locked;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    constructor() {
        nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    }

    function lockLiquidity(uint256 _id) public {
        require(locked[_id] == 0, "token already locked");
        require(nonfungiblePositionManager.ownerOf(_id) == msg.sender, "not your token");
        nonfungiblePositionManager.safeTransferFrom(msg.sender, address(this), _id);
        locked[_id] = block.timestamp + 12 weeks;
    }

    function releaseNFT(uint256 _id) public onlyOwner {
        require(locked[_id] > 0, "token not locked");
        require(locked[_id] <= block.timestamp, "token still locked");

        nonfungiblePositionManager.safeTransferFrom(address(this), msg.sender, _id);
        locked[_id] = 0;
    }

    function claimFees(uint256 _id) public onlyOwner {
        require(locked[_id] > 0, "token not locked");
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: _id,
            recipient: msg.sender,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        nonfungiblePositionManager.collect(params);
    }

    // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        return this.onERC721Received.selector;
    }
}