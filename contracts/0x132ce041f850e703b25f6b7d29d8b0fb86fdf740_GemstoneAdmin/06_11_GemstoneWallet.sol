// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./INFT.sol";

contract GemstoneWallet is IERC721Receiver {
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    address private _wallet;
    address private _owner;
    INFT.GemstoneTypes private _tier;
    uint256[] private _tokenIds;

    constructor(address wallet, INFT.GemstoneTypes tier) {
        _wallet = wallet;
        _tier = tier;
        _owner = address(msg.sender);
    }

    function claim(address nftContract) external {
        require(msg.sender == _owner, "Only owner can claim");
        INFT nft = INFT(nftContract);
        nft.claim();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            if (INFT(nftContract).tierByToken(tokenId) == _tier) {
                nft.safeTransferFrom(address(this), _wallet, tokenId);
            } else {
                nft.safeTransferFrom(address(this), burnAddress, tokenId);
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        _tokenIds.push(tokenId);
        return this.onERC721Received.selector;
    }
}