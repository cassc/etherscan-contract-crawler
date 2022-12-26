// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/*
* Big thanks to all the Genesis Holders from MOOW! <3
*/

contract GenesisMOO is ERC721AQueryable, ERC2981, Ownable, ReentrancyGuard {
  event PermanentURI(string _value, uint256 indexed _id);

  string private tokenName = 'Genesis MOO';
  string private tokenSymbol = 'GMOO';
  string private uriPrefix = 'ipfs://QmXcZg9FFw875apVxZoFkbah973j9NZQU6tDNwS5gZFQ2h/';
  string private uriSuffix = '.json';

  uint96 private royalty = 1000;

  address[29] private MOOWERS = [
    0xF4cb3a8F9A2E54B4D32D7836da09A1a31832163b,
    0xBf230CB4E02b9E5c336D1BFA89ea90Ec0D2048bD,
    0x2420B67A2255c88547deb24778B9faaa24b83bAE,
    0x9E9E0C0B7F000096DbD50B3EAc7A11bFB5D75bec,
    0xd0F0847328F183B10742f126f39bDbf6242E8250,
    0x4be4bdE1976B8a31395e92d7da423DE311015B5F,
    0x4be4bdE1976B8a31395e92d7da423DE311015B5F,
    0xf77fC2A227b0AF0440CbA5Ed6D0E7518a73cc7b2,
    0xa619555561219586FF5aeF95868C0B8695FE4bC5,
    0xfb00eC596C93585835c76E7F0Be6e18a3ef8038c,
    0xab70EC596df5cC14181B53890E9DA85A5773bD83,
    0xea9BcF96d92B5A1bdCa6184Ee44808C9A3e19b22,
    0xa1F386b1C8A61369873e0Ba718A9AeCfA25529bA,
    0x4be4bdE1976B8a31395e92d7da423DE311015B5F,
    0x0858c9B4D473b3FE1A64910B75d24091148c6281,
    0x5E864D3d1E9C663af23dE6b340cE547B192d80b8,
    0xfe1e97767939091Bc07cc82b865D23Eb0dC4473C,
    0xb06B093DA7ceAE1d6b482d4478227ac0C376aa80,
    0x4a012C59AC8808d9cbE1871c190202060e41F5AA,
    0xCE75584C49c4b5A3d232c16230a384497f91019E,
    0xB50d8453Ebd6d2FF2Af82Ac124379b4b40a21571,
    0xD1908dA667632fca40B497a06E86cAD9705cD2A6,
    0x5f084F2572EC085b1A7f2b8FF9ec2b26505F1450,
    0x4be4bdE1976B8a31395e92d7da423DE311015B5F,
    0x4be4bdE1976B8a31395e92d7da423DE311015B5F,
    0x4be4bdE1976B8a31395e92d7da423DE311015B5F,
    0x4be4bdE1976B8a31395e92d7da423DE311015B5F,
    0x4be4bdE1976B8a31395e92d7da423DE311015B5F,
    0x646a81A6dBf0665ff6A4f4Ce1311755d6A9CdB5f
  ];

  uint256 public maxSupply = 29;

  constructor() ERC721A(tokenName, tokenSymbol) {
    for (uint256 tokenId = 1; tokenId <= maxSupply; tokenId++) {
      _safeMint(MOOWERS[tokenId - 1], 1);
      emit PermanentURI(_tokenURI(tokenId), tokenId);
    }
    _setDefaultRoyalty(msg.sender, royalty);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    return _tokenURI(_tokenId);
  }

  function _tokenURI(uint256 _tokenId) private view returns (string memory) {
    return string(abi.encodePacked(uriPrefix, _toString(_tokenId), uriSuffix));
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}('');
    require(success, 'Transfer Failed');
  }
}