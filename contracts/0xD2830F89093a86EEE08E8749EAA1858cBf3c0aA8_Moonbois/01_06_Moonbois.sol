pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Moonbois is ERC721A, Ownable {
  uint256 constant MINT_PRICE = 0.0095 ether;
  uint256 constant MINT_QUANTITY_PER_TRANSACTION = 10;

  bytes32 public merkletreeRoot; 
  uint256 public maxSupply;
  string tokenBaseUri;

  bool public maxBooty = false;
  bool public publicMaxBooty = false;

  constructor(uint256 _maxSupply) ERC721A("Moonbois", "Moonbois") {
    maxSupply = _maxSupply;
  }

  function canMaxBooty(bytes32[] calldata _merkleProof) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    return MerkleProof.verify(_merkleProof, merkletreeRoot, leaf); 
  }

  function mint(bytes32[] calldata _merkleProof) external payable {
    require(maxBooty, "Not time for MAX BOOTY");
    if (!publicMaxBooty) {
      require(canMaxBooty(_merkleProof), "You weren't ready for max booty");
    }
    require(balanceOf(_msgSender()) == 0, "You got booty already");
    require(msg.value >= MINT_PRICE, "Need more booty");
    require(totalSupply() + MINT_QUANTITY_PER_TRANSACTION < maxSupply, "We are out of booties");

    _mint(_msgSender(), MINT_QUANTITY_PER_TRANSACTION);
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

  function setMerkletreeRoot(bytes32 _merkletreeRoot) external onlyOwner {
    merkletreeRoot = _merkletreeRoot;
  }

  function flipMaxBooty() external onlyOwner {
    maxBooty = !maxBooty;
  }

  function flipPublicMaxBooty() external onlyOwner {
    publicMaxBooty = !publicMaxBooty;
  }

  function withdraw() external onlyOwner {
    require(payable(owner()).send(address(this).balance), "Withdraw unsuccessful");
  }
}