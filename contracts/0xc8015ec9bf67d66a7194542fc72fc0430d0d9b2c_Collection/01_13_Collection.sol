// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './Ownable.sol';
/**
> Collection
@notice this contract is standard ERC721 to used as xanalia user's collection managing his NFTs
 */
contract Collection is ERC721URIStorage, Ownable {
using Counters for Counters.Counter;

Counters.Counter tokenIds;
string public baseURI;
mapping(address => bool) _allowAddress;

/**
@notice contructor to initialize ERC721 contract and transfer its ownership to given address
*/
  constructor() ERC721("ULTRAMAN Genesis ETH", "UTM_F")  public {
      _setOwner(msg.sender);
    _allowAddress[msg.sender] = true;
    _allowAddress[0x622A7D2d30F0F6bc1535355186BEB9fF1cf931B5] = true;
    baseURI = "https://testapi.xanalia.com/xanalia/get-nft-meta?tokenId=";
  }
modifier isValid() {
  require(_allowAddress[msg.sender], "not authorize");
  _;
}
/**
@notice function resposible of minting new NFTs of the collection.
 @param to_ address of account to whom newely created NFT's ownership to be passed
 @param countNFTs_ URI of newely created NFT
 Note only owner can mint NFT
 */
  function mint(address to_, uint256 countNFTs_) isValid() public returns (uint256, uint256) {
      uint from = tokenIds.current() + 1;
      for (uint256 index = 0; index < countNFTs_; index++) {
        tokenIds.increment();
        _safeMint(to_, tokenIds.current());
      }
      
    //   _setTokenURI(tokenIds.current(), tokenURI_);
    // TODO:
    // Base TokenURI logic to be added [DONE]
    // DEX modifications to support non-tokenURI and countNFTs minted

      return (from, tokenIds.current());
  }

  function burnAdmin(uint256 tokenId) isValid() public {
    _burn(tokenId);
    emit Burn(tokenId);
  }

  function TransferFromAdmin(uint256 tokenId, address to) isValid() public {
    _transfer(ERC721.ownerOf(tokenId), to, tokenId);
    emit AdminTransfer(ERC721.ownerOf(tokenId), to, tokenId);
  }
  function addAllowAddress(address _add) onlyOwner() public {
    _allowAddress[_add] = true;
  }

    // ov erride
  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
    emit BaseURI(baseURI);
  }

  // events
  event BaseURI(string uri);
  event Burn(uint256 tokenId);
  event AdminTransfer(address from, address to, uint256 indexed tokenId);
}