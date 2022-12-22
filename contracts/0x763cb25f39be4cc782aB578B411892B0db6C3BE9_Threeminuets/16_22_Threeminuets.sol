// SPDX-License-Identifier: UNLICENSED

// ************************************************************************************ //
//                                                                                    
//                    ■                  ■                    ■      ■  ■■■■■■ ■■■■■■■■
//                                       ■                    ■■     ■  ■         ■    
//  ■■■   ■ ■■■ ■■■   ■  ■ ■■■   ■    ■ ■■■■  ■■■■    ■■■     ■ ■    ■  ■         ■    
// ■   ■  ■■  ■■   ■  ■  ■■  ■■  ■    ■  ■   ■    ■  ■        ■  ■   ■  ■         ■    
//     ■  ■   ■■   ■  ■  ■    ■  ■    ■  ■   ■    ■  ■        ■  ■■  ■  ■■■■■     ■    
//     ■  ■   ■■   ■  ■  ■    ■  ■    ■  ■  ■■■■■■■   ■■■     ■   ■  ■  ■         ■    
//   ■■   ■   ■■   ■  ■  ■    ■  ■    ■  ■   ■           ■    ■    ■ ■  ■         ■    
//     ■  ■   ■■   ■  ■  ■    ■  ■   ■■  ■   ■    ■      ■    ■     ■■  ■         ■    
//     ■  ■   ■■   ■  ■  ■    ■   ■■■ ■   ■■  ■■■■   ■■■■     ■      ■  ■         ■    
// ■   ■                                                                               
//  ■■■
//
//
// Special Products
// P5.js
// P5.sound.js
// Freefont/DigitalNormal-xO6j.otf(https://www.fontspace.com/digital-font-f17797)
//
//
// ************************************************************************************ //

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "rarible/royalties/contracts/LibPart.sol";
import "rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "hardhat/console.sol";

contract Threeminuets is ERC721Enumerable, Ownable, RoyaltiesV2Impl {
    bool public paused = false;

    string public baseTokenURI;

    uint256 public cost = 0.01 ether;
    uint256 public maxSupply = 180;
    uint256 public maxMintAmount = 1;

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(string memory baseURI) ERC721 ("3minuets", "3MN") {
        setBaseURI(baseURI);
    }
    function reserveNFTs() public onlyOwner {
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(10) < maxSupply);
        for (uint i = 0; i < 10; i++) {
            _mintSingleNFT();
        }
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    function getTotalNFTsMintedSoFar() public view returns(uint256) {
              return _tokenIds.current();
    }
    function mintNFTs(uint256 _count) public payable {
        uint totalMinted = _tokenIds.current();
            require(!paused);
            require(totalMinted.add(_count) <= maxSupply, "Not enough NFTs left!");
        require(_count >0 && _count <= maxMintAmount, "Cannot mint specified number of NFTs.");
        require(msg.value >= cost.mul(_count), "Not enough ether to purchase NFTs.");
            _mintSingleNFT();
        }
    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }
  function walletOfOwner(address _owner)
    external view returns (uint[] memory)
      {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](ownerTokenCount);
    for (uint256 i = 0; i < ownerTokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }
  //set the max amount an address can mint
  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  //pause the contract and do not allow any more minting
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
  //configure royalties for Rariable
  function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }
    //configure royalties for Mintable using the ERC2981 standard
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      //use the same royalties that were saved for Rariable
      LibPart.Part[] memory _royalties = royalties[_tokenId];
      if(_royalties.length > 0) {
        return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
      }
      return (address(0), 0);
    }
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
          return true;
        }
        return super.supportsInterface(interfaceId);
    }
}