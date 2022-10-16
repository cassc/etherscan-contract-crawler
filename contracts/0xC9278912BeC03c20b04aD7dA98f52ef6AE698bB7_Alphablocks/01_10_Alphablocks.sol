// SPDX-License-Identifier: MIT
 
pragma solidity >=0.8.9 <0.9.0;
 
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
 
/**                                                                 
 
░█████╗░██╗░░░░░██████╗░██╗░░██╗░█████╗░██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗░██████╗
██╔══██╗██║░░░░░██╔══██╗██║░░██║██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██╔════╝
███████║██║░░░░░██████╔╝███████║███████║██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░╚█████╗░
██╔══██║██║░░░░░██╔═══╝░██╔══██║██╔══██║██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░░╚═══██╗
██║░░██║███████╗██║░░░░░██║░░██║██║░░██║██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗██████╔╝
╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝╚═════╝░
                                                                                                                                                                                                                 
*/
 
contract Alphablocks is ERC721A, Ownable, ReentrancyGuard {
 
  using Strings for uint256;
 
  bytes32 public merkleRoot;
  mapping(address => bool) public freeMintClaimed;
 
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  uint256 public maxSupply;
  bool public freeMintEnabled = false;
  
  
 
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _uriPrefix,
    uint256 _maxSupply
  ) ERC721A(_tokenName, _tokenSymbol){
    maxSupply = _maxSupply;
    uriPrefix = _uriPrefix;
  }
 
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount == 1, "Invalid mint amount!");
    require(totalSupply() + 1 <= maxSupply, "Max supply exceeded!");
    _;
  }
 
  function freeMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    // Verify freemint requirements
    require(freeMintEnabled, "The free mint is not enabled!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
    require(!freeMintClaimed[_msgSender()], "Address already claimed!");
 
    freeMintClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }
 
 function internalMint(uint256 _teamAmount) external onlyOwner  {
    require(totalSupply() + _teamAmount <= maxSupply, "Max supply exceeded!");
    _safeMint(_msgSender(), _teamAmount);
  }
 
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  } 

 function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
 
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }
 
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
 
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }
 
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }
 
  function setFreeMintEnabled(bool _state) public onlyOwner {
    freeMintEnabled = _state;
  }
 
  function withdraw() public onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }
 
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}