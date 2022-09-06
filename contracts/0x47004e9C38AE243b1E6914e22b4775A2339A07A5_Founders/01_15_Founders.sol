// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Founders is ERC721, IERC2981, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private currentTokenId;
  uint public mintPrice;
  bool public closed = false;
  uint public constant MAX_SUPPLY = 500;
  string public metadataURI;
  mapping(address => uint) seedMintWhitelist;
  uint256 public whiteListStartTime;
  uint256 public whiteListEndTime;

  // This could be more sophisticated and flexible, but alas...
  uint totalWhitelistedTokens = 203;

  constructor(uint256 _mintPrice, string memory _metadataURI, uint256 _whitelistStartTime, uint256 _whitelistEndTime) ERC721("RockGardenFounders", "RG_FOUNDERS") {
      mintPrice = _mintPrice;
      metadataURI = _metadataURI;
      whiteListStartTime = _whitelistStartTime;
      whiteListEndTime = _whitelistEndTime;

      seedMintWhitelist[address(0x2176d43a3f6D840479A8eD3d5F299a173D6C7107)] = 50;
      seedMintWhitelist[address(0x5eA1D56D0ddE1cA5B50c277275855F69edEfA169)] = 20;
      seedMintWhitelist[address(0x002A99690aB1989b7971dB28cD4a7673e1E6f495)] = 20;
      seedMintWhitelist[address(0x18aD111b2584b55093B5b4cbcE9374C3a0e8cFeD)] = 2;
      seedMintWhitelist[address(0x77115B8435BDB2B67b2e83583deAB3885F5B5751)] = 2;
      seedMintWhitelist[address(0x61341CbEde33e71ed0FA8cBe4De846f91d141910)] = 10;
      seedMintWhitelist[address(0xB88fB48b463B2F37d8DBD36266FAd7D995CaFa77)] = 1;
      seedMintWhitelist[address(0x83B0490B1276f071EBBdfB1015231C1C89FcfDfd)] = 5;
      seedMintWhitelist[address(0x92492DB1DE4F5e54dAC955667425A1D500FC19A0)] = 3;
      seedMintWhitelist[address(0xFEa8A3e1C24ffDC2daB206c1d42700C4b9671EfB)] = 5;
      seedMintWhitelist[address(0x17E31bf839acB700e0F584797574A2C1FDe46d0b)] = 5;
      seedMintWhitelist[address(0xfC4740a68e256856A07074640d9B161Cfdd2e3f3)] = 5;
      seedMintWhitelist[address(0x41e852c0713B1D810B413224488713773afa7953)] = 1;
      seedMintWhitelist[address(0x684Ce5C03c922504a1f976d3c3EC6f8492A5cDA9)] = 2;
      seedMintWhitelist[address(0x70ec905ac28eE8bA90652c615c11462eB2d13428)] = 5;
      seedMintWhitelist[address(0xd7c318E9F9129239F6bA4E10994137113dcF6244)] = 5;
      seedMintWhitelist[address(0xeC7100ABDbCf922f975148C6516BC95696cA0eF6)] = 5;
      seedMintWhitelist[address(0x9B7061023cD42263448d48c48572507F19F39b78)] = 2;
      seedMintWhitelist[address(0xA4Fcf064131DB228CFa72bfb64F0f50b940538Fc)] = 2;
      seedMintWhitelist[address(0xC7f17EC88E1cb1945a546723ecAf91c1aAA22096)] = 10;
      seedMintWhitelist[address(0x933f1Bd0E485d171AB0E08E0B3Da0b717E6877a7)] = 2;
      seedMintWhitelist[address(0x3E415cBd89D9C5F0e7476E0F3E7dfe984d0f9Fef)] = 10;
      seedMintWhitelist[address(0xbef1048d4Fa25f9c7Ff94ceFF1C0FF702fEbF11A)] = 4;
      seedMintWhitelist[address(0x7c88DF0FC154d7cFd19489E948775195A5649058)] = 2;
      seedMintWhitelist[address(0x5763542e5De5f524037B6c90623d00E0D6099BdE)] = 5;
      seedMintWhitelist[address(0x68f8Ef1792689006D7C1495fFA0C6E05f8fdf1eb)] = 5;
      seedMintWhitelist[address(0xFEa8A3e1C24ffDC2daB206c1d42700C4b9671EfB)] = 10;
      seedMintWhitelist[address(0x665498C14F80647D2A57a1F54Eee4Aaa9920fAe8)] = 4;
      seedMintWhitelist[address(0xfAE5C3456911FFFF033d0D99ca19b81d157D6c2F)] = 1;
  }

  function close() public onlyOwner {
    _close();
  }

  function _close() internal {
    closed = true;
  }

  function withdraw() public onlyOwner {
    bool sent = payable(owner()).send(address(this).balance);
    require(sent, 'Send failed');
  }

  function _useWhitelistedTokens (address _address) internal {
    uint _qty = seedMintWhitelist[_address];
    totalWhitelistedTokens -= _qty;
    seedMintWhitelist[_address] = 0;
  }

  function mint(uint _qty) public payable nonReentrant {
    require (!closed, 'Minting has been closed.');

    uint allowedQty = tokensAvailableForAddress(msg.sender);
    _useWhitelistedTokens(msg.sender);

    require (_qty <= allowedQty, string.concat('Requested _qty exceeds allowed maximum for this address: ', Strings.toString(allowedQty)));
    require (msg.value == mintPrice * _qty, string.concat("Incorrect ETH amount. Price per token is ", Strings.toString(mintPrice), ' wei'));

    for (uint i = 0; i < _qty; i++) {
      currentTokenId.increment();
      _safeMint(msg.sender, currentTokenId.current());
    }

    if (currentTokenId.current() >= MAX_SUPPLY) {
      _close();
    }
  }

  function tokensAvailableForAddress(address _address) public view returns(uint) {
    // All zeroes before we start
    if (block.timestamp < whiteListStartTime) {
      return 0;
    }

    // After whitelist period ends, any address can purchase totalRemainingTokens();
    if (block.timestamp > whiteListEndTime) {
      return totalRemainingTokens();
    }

    // Last case, we're in the whitelist period
    return seedMintWhitelist[_address] + remainingPublicTokens();
  }

  function totalRemainingTokens() public view returns (uint) {
    return MAX_SUPPLY - currentTokenId.current();
  }

  function remainingPublicTokens() public view returns (uint) {
    if (block.timestamp > whiteListEndTime) {
    	return totalRemainingTokens();
    }

    return totalRemainingTokens() - totalWhitelistedTokens;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require (_exists(_tokenId), 'Invalid tokenId. Token does not exist.');

    return metadataURI;
  }

  function setMetadataURI(string calldata _newMetadataURI) public onlyOwner {
    metadataURI = _newMetadataURI;
  }

  // ERC165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // IERC2981
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256) {
    _tokenId; // silence compiler warnings for unused _tokenId
    return (owner(), _salePrice / 10);
  }
}