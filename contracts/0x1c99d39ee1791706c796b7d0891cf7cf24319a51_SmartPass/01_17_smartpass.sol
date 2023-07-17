pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SmartPass is ERC721A, ERC2981, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using Strings for uint256;

  uint256 public maxSupply = 200;
  bool public mintIsActive = false;

  bytes32 public merkleRoot;

  mapping(address => bool) public mintedAddress;

  string public _baseTokenURI;

  constructor() ERC721A("FOUNDSmartPass", "FOUNDPASS") {}

  function merkleMint(bytes32[] calldata _merkleProof) external payable {
    require(mintIsActive, "Not open for minting.");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof.");
    require(totalSupply() + 1 <= maxSupply, "Minted Out!");
    require(mintedAddress[msg.sender] == false, "Can only mint 1 per wallet.");
    mintedAddress[msg.sender] = true;
    _safeMint(msg.sender, 1);
  }

  // dev mint
  function devMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= maxSupply, "Can't mint that many");
    _safeMint(msg.sender, quantity);
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setMintState(bool newState) external onlyOwner {
    mintIsActive = newState;
  }

  function mintState() public view returns (bool) {
    return mintIsActive;
  }

  function setMerkleRootOne(bytes32 newMerkleRoot) external onlyOwner {
    merkleRoot = newMerkleRoot;
  }

  function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setRoyalties(address _recipient, uint96 _amount) external onlyOwner {
      _setDefaultRoyalty(_recipient, _amount);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
      // IERC165: 0x01ffc9a7, IERC721: 0x80ac58cd, IERC721Metadata: 0x5b5e139f, IERC29081: 0x2a55205a
      return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /* Opensea Operator Filter Registry */
     function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}