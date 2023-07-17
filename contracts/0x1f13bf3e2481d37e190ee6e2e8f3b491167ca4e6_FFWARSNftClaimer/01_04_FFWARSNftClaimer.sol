// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "contracts/lib/IMintableNft.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract FFWARSNftClaimer {
    IMintableNft public nft;
    IERC721 public fft;
    IERC721 public nfCheese;

    mapping(uint256 => bool) _claimedFft;
    mapping(uint256 => bool) _claimedNfCheese;

    constructor(
        address nftAddress,
        address fftAddress,
        address nfCheeseAddress
    ) {
        nft = IMintableNft(nftAddress);
        fft = IERC721(fftAddress);
        nfCheese = IERC721(nfCheeseAddress);
    }

    function claimFft(uint256[] calldata tokenId) external {
        for (uint256 i = 0; i < tokenId.length; ++i) {
            _claimFft(tokenId[i]);
        }
    }

    function claimNfCheese(uint256[] calldata tokenId) external {
        for (uint256 i = 0; i < tokenId.length; ++i) {
            _claimNfCheese(tokenId[i]);
        }
    }

    function _claimFft(uint256 tokenId) internal {
        require(
            fft.ownerOf(tokenId) == msg.sender,
            "only owner of nft can claim"
        );
        require(!_claimedFft[tokenId], "already claimed");
        _claimedFft[tokenId] = true;
        nft.mint(msg.sender);
    }

    function _claimNfCheese(uint256 tokenId) internal {
        require(
            nfCheese.ownerOf(tokenId) == msg.sender,
            "only owner of nft can claim"
        );
        require(!_claimedNfCheese[tokenId], "already claimed");
        _claimedNfCheese[tokenId] = true;
        nft.mint(msg.sender);
        nft.mint(msg.sender);
    }

    function fftClaimed(uint256 tokenId) external view returns (bool) {
        return _claimedFft[tokenId];
    }

    function nfCheeseClaimed(uint256 tokenId) external view returns (bool) {
        return _claimedNfCheese[tokenId];
    }
}