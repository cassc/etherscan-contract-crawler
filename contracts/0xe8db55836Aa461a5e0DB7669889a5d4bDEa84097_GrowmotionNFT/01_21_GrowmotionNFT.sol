// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "library/contracts/access/CouponWhitelist.sol";
import "library/contracts/token/ERC721MaxSupplyBurnable.sol";

contract GrowmotionNFT is ERC721MaxSupplyBurnable, CouponWhitelist {
  constructor(
    address couponSigner_
  )
    ERC721MaxSupplyBurnable("GrowmotionNFT", "GM", 10420, "https://nft-api.growmotion.com/meta/")
    CouponWhitelist(couponSigner_)
  {}

  function mintWhitelist(
    uint256 mintAmount_,
    uint256 maxMintAmount_,
    bytes calldata signature_
  ) external isWhitelisted(mintAmount_, maxMintAmount_, signature_) {
    for (uint256 i = 0; i < mintAmount_; ++i) {
      _safeMint(msg.sender);
    }
  }

  function burnAdmin(uint256 tokenId_) external onlyOwner {
    ERC721._burn(tokenId_);
  }

  function transferAdmin(address from_, address to_, uint256 tokenId_) external onlyOwner {
    ERC721._safeTransfer(from_, to_, tokenId_, new bytes(1));
  }
}