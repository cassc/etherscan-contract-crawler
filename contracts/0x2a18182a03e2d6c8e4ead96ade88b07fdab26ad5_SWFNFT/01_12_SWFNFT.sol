// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


contract SWFNFT is Ownable, ERC721A, ERC2981, ReentrancyGuard{
    using Strings for uint256;


    string public baseExtension = '.json';
    bool private allowApproveAll = false;
    uint256 public collectionSize;
    uint maxArrayLength = 50;
    address private creator;
    uint96 public royaltyFee;
 
    

    mapping(address => bool) private _approvedMarketplaces;
    


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initContractURI,
        uint256 _collectionSize,
        uint96 _royaltyFee,
        address _creator
        
    ) ERC721A(_name, _symbol){

       
        collectionSize = _collectionSize;
        setBaseURI(_initBaseURI);
        setContractURI(_initContractURI);
       
        creator = _creator;
        _setDefaultRoyalty(_creator, _royaltyFee);

        
    }


    function setCollectionSize(uint256 _newCollectionSize) public onlyOwner{
        require(_newCollectionSize <= 500,'New Collection size is more than 500');
        collectionSize = _newCollectionSize;

    }

    function transferContractOwnership(address _newOwner) public onlyOwner{
       transferOwnership(_newOwner);
    }

    function setCreator(address _newCreator) public onlyOwner{
        require(_newCreator != address(0));
        creator = _newCreator;
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= collectionSize, 'Too many already minted');

        _safeMint(msg.sender, quantity);
    }

    //bulktransfers
    function sendNft(address[] memory _to, uint256[] memory _id) public onlyOwner{
        require(_to.length <= maxArrayLength,"array length limit higher than expected");
        require(_to.length == _id.length,"array length doesn't match");
       

        for (uint8 i = 0; i < _to.length; i++){
            safeTransferFrom(msg.sender,_to[i],_id[i]);
        }
       

    }

    //marketplace
   

    function setApprovalForAll(address operator, bool approved) public  virtual override(ERC721A) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public virtual override(ERC721A) {
        super.approve(operator, tokenId);
    }
 

    // // metadata URI


    string private _baseTokenURI;
     string private _baseContarctURI;


    function contractURI() public view returns (string memory) {
        return _baseContarctURI;
    }
    function setContractURI(string memory _newContractURI) public onlyOwner{
        _baseContarctURI = _newContractURI;

    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : '';
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }


  // ERC2981 overrides
    function setDefaultRoyalty(uint96 feeNumerator) public onlyOwner  {
       _setDefaultRoyalty(creator,feeNumerator);
    }
  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {

    return super.supportsInterface(interfaceId) || interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.;
  }

  function setApprovedMarketplaceActive(address marketplaceAddress, bool approveMarket) public onlyOwner {
    _approvedMarketplaces[marketplaceAddress] = approveMarket;
  }

  function isApprovedForAll(address owner, address operator) override(ERC721A) public view returns (bool) {
      if (_approvedMarketplaces[operator]) {
          return true;
      }
      return super.isApprovedForAll(owner, operator);
  }

    //burn 
    function burnToken(uint256 _tokenId) public onlyOwner{
        _burn(_tokenId,true);
    }

}