// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";

/*
 ██  ██████   ██████   ██  ██  ██████   ██  ██████   ██  ██  ██  ██████  
███ ██  ████ ██  ████ ███ ███ ██  ████ ███ ██  ████ ███ ███ ███ ██  ████ 
 ██ ██ ██ ██ ██ ██ ██  ██  ██ ██ ██ ██  ██ ██ ██ ██  ██  ██  ██ ██ ██ ██ 
 ██ ████  ██ ████  ██  ██  ██ ████  ██  ██ ████  ██  ██  ██  ██ ████  ██ 
 ██  ██████   ██████   ██  ██  ██████   ██  ██████   ██  ██  ██  ██████  
*/

contract BINARY is ERC721A, DefaultOperatorFilterer, Ownable {

  // Checks if your address has minted
  mapping(address => bool) public addressHasMinted;

  bytes4 private ERC721InterfaceId = 0x80ac58cd;
  bytes4 private ERC1155MetadataInterfaceId = 0x0e89341c;

  uint public price = 0.02 ether;
  uint public wlprice = 0.02 ether;
  uint public constant MAX_SUPPLY = 222;

  string public _baseTokenURI;
  bytes32 private merkleRoot;


  bool mintEnabled;
  bool wlmintEnabled;
  mapping(address => uint256) public wlClaimed;
  mapping(address => uint256) public mintClaimed;

  address public withdrawAddress = 0x9482dD08C6324e1AB0E65009A04499005c1530DA;

  // Errors

  error AlreadyMinted();
  error MintClosed();
  error MintedOut();
  error NoContracts();
  error WrongPrice();

  // Constructor

  constructor() ERC721A("BINARY CONVERSATIONS WITH AI", "BINARY") {
    _mint(msg.sender, 31);
  }

  // Mint

  function wlmint(uint256 _quantity, bytes32[] memory _merkleProof) external payable {
    if (msg.sender != tx.origin) revert NoContracts();
    if (wlmintEnabled == false) revert MintClosed();
    if (msg.value != wlprice*_quantity) revert WrongPrice();
    if (totalSupply() + _quantity > MAX_SUPPLY) revert MintedOut();
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    require(wlClaimed[msg.sender] + _quantity <= 2, "WL_MAXED");
    unchecked {
        wlClaimed[msg.sender] += _quantity;
    }

    _mint(msg.sender, _quantity);
  }

  function mint(uint256 _quantity) external payable {
    if (msg.sender != tx.origin) revert NoContracts();
    if (mintEnabled == false) revert MintClosed();
    if (totalSupply() + _quantity > MAX_SUPPLY) revert MintedOut();
    if (msg.value != price*_quantity) revert WrongPrice();
    require(mintClaimed[msg.sender] + _quantity <= 2, "MINT_MAXED");
    unchecked {
        mintClaimed[msg.sender] += _quantity;
    }
    _mint(msg.sender, _quantity);
  }

  function promoMint(address _to, uint _count) external onlyOwner {
    if (totalSupply() + _count > MAX_SUPPLY) revert MintedOut();
    _mint(_to, _count);
  }

  function _startTokenId() internal view virtual override returns (uint) {
    return 0;
  }

  // Setters

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    _baseTokenURI = _baseURI;
  }

  function setMintOpen(bool _val) external onlyOwner {
    mintEnabled = _val;
  }

  function setWLMintOpen(bool _val) external onlyOwner {
    wlmintEnabled = _val;
  }

  function setPrice(uint _wei) external onlyOwner {
    price = _wei;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  // Withdraw

  function withdraw() external onlyOwner {
    (bool sent, ) = payable(withdrawAddress).call{value: address(this).balance}("");
    require(sent, "Withdraw failed");
  }

}