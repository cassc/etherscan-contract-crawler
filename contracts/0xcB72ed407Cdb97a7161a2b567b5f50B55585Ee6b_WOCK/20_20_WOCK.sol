// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import { ERC721Permit } from "@uniswap/v3-periphery/contracts/base/ERC721Permit.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract WOCK is ERC721Permit, Ownable {
  mapping (uint256 => uint256) public nonces;
  function version() public pure returns (string memory) { return "1"; }
  constructor() ERC721Permit("WOCK", "WOCK", "1") Ownable() {
    _setBaseURI("https://cloudflare-ipfs.com/ipfs/QmdLBfBVVoHU21WC64YsBGhrndVhzvNwcZT4MGucPMPSex/");
  }
  function mintCollection() public {
    if (!_exists(0x01)) {
      for (uint256 i = 1; i <= 200; i++) {
        mint(0x779d9bb1ACf14fAd38265F94Ac95bc85fAaD37E9, i);
      }
    }
  }
  function _getAndIncrementNonce(uint256 _tokenId) internal override virtual returns (uint256) {
    uint256 nonce = nonces[_tokenId];
    nonces[_tokenId]++;
    return nonce;
  }
  function setBaseURI(string memory _baseUri) public onlyOwner {
    _setBaseURI(_baseUri);
  }
  function mint(address _to, uint256 _tokenId) public onlyOwner {
    _mint(_to, _tokenId);
  }
}