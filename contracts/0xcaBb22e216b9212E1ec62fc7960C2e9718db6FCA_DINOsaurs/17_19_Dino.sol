//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract DinoNFT is ERC721, Ownable, ERC2981 {
    using Strings for uint256;
    
    address public qualifiedMinter;
    address private hatcher;
    uint private idToHatch;
    string public baseURI;
    string public baseExtension = ".json";
    uint totalMinted;

    mapping(uint => address) public idToHatchee;
    mapping(address => uint) lastOriginAccess;

    constructor(
      address _royaltyWallet
    )
    ERC721("The DINOsaurs","Dinos")
    {
      _setDefaultRoyalty(_royaltyWallet, 500);
    }

    function setQualifiedMinter(address minter) public onlyOwner
    {
        qualifiedMinter = minter;
    }
  
        //override to make royalties and 721 get along
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function indexHatcher(address _hatcher, uint _idToHatch) public
    {
        require(msg.sender == qualifiedMinter, "not qualified.");
        hatcher = _hatcher;
        idToHatch = _idToHatch;

        idToHatchee[idToHatch] = hatcher;
        hatchEgg(hatcher, idToHatch);
        
    }

    function hatchEgg(address _receiver, uint _id) internal
    {
        _safeMint(_receiver, _id);
        totalMinted++;
        emit TokenIssued(_id, _receiver);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();

    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  
  function _baseURI() internal view virtual override returns (string memory)
  {
    return baseURI;
  }

  function setBaseURI(string memory _newbaseURI) public onlyOwner
  {
    baseURI = _newbaseURI;
  }

  function metaMint() public onlyOwner
  {
    _safeMint(msg.sender, 10001);
  }

  event TokenIssued(
      uint256 tokenID,
      address hatcher
  );

}