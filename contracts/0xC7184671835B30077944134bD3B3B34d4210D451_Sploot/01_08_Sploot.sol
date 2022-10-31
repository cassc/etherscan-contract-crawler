// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";

/*
 $$$$$$\  $$$$$$$\  $$\       $$$$$$\   $$$$$$\ $$$$$$$$\ 
$$  __$$\ $$  __$$\ $$ |     $$  __$$\ $$  __$$\\__$$  __|
$$ /  \__|$$ |  $$ |$$ |     $$ /  $$ |$$ /  $$ |  $$ |   
\$$$$$$\  $$$$$$$  |$$ |     $$ |  $$ |$$ |  $$ |  $$ |   
 \____$$\ $$  ____/ $$ |     $$ |  $$ |$$ |  $$ |  $$ |   
$$\   $$ |$$ |      $$ |     $$ |  $$ |$$ |  $$ |  $$ |   
\$$$$$$  |$$ |      $$$$$$$$\ $$$$$$  | $$$$$$  |  $$ |   
 \______/ \__|      \________|\______/  \______/   \__|  

What is worth more, art or life?          
*/

// Contract by @beeble_xyz
// Thanks to Dittos and Devotion for the inspiration for some of this contract

contract Sploot is ERC721A, Ownable {

  // Checks if your address has minted
  mapping(address => bool) public addressHasMinted;

  // Tracks the splootId to the URI
  mapping(uint => string) public splootmation;

  // Contract address -> token id -> bool
  mapping(address => mapping(uint => bool)) public addressTokensplootted;

  bytes4 private ERC721InterfaceId = 0x80ac58cd;
  bytes4 private ERC1155MetadataInterfaceId = 0x0e89341c;

  uint public price = 0.025 ether;
  uint public wlprice = 0.02 ether;
  uint public splootCount;
  uint public constant MAX_SUPPLY = 333;

  string public _baseTokenURI;
  bytes32 private merkleRoot;


  bool mintEnabled;
  bool wlmintEnabled;
  bool splootEnabled;
  mapping(address => uint256) public wlClaimed;
  mapping(address => uint256) public mintClaimed;

  address public withdrawAddress = 0x9482dD08C6324e1AB0E65009A04499005c1530DA;

  // Errors

  error AlreadyMinted();
  error Alreadysplootted();
  error MintClosed();
  error MintedOut();
  error NoContracts();
  error MuseumSecurity();
  error WrongPrice();

  // Events

  event Setter(uint indexed splootId, address indexed usingContractNFT, uint indexed tokenId);

  // Constructor

  constructor() ERC721A("SPLOOT by De la Dondi", "SPLOOT") {
    _mint(msg.sender, 1);
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

  function hasTokenBeensplootted(address _contractAddress, uint _tokenId) view public returns (bool){
    return addressTokensplootted[_contractAddress][_tokenId];
  }

  // Once someone sploots an NFT, you can't sploot that same NFT again
  function sploot(uint splootId, address usingContractNFT, uint usingTokenId) external {
    // Security is everywhere, no splootting...yet.
    if (splootEnabled == false) revert MuseumSecurity();

    // Prevents a token from being re-splootted
    if (hasTokenBeensplootted(usingContractNFT, usingTokenId)) revert Alreadysplootted();

    require(ownerOf(splootId) == msg.sender, "Not your sploot");

    // ERC-721 check
    if (ERC165Checker.supportsInterface(usingContractNFT, ERC721InterfaceId)) {
      (bool success, bytes memory bytesUri) = usingContractNFT.call(
        abi.encodeWithSignature("tokenURI(uint256)", usingTokenId)
      );

      require(success, "Error getting tokenURI data");

      string memory uri = abi.decode(bytesUri, (string));

      splootmation[splootId] = uri;
      addressTokensplootted[usingContractNFT][usingTokenId] = true;
      unchecked { ++splootCount; }

      emit Setter(splootId, usingContractNFT, usingTokenId);

    // ERC-1155 check
    } else if (ERC165Checker.supportsInterface(usingContractNFT,ERC1155MetadataInterfaceId)) {
      (bool success, bytes memory bytesUri) = usingContractNFT.call(
        abi.encodeWithSignature("uri(uint256)", usingTokenId)
      );

      require(success, "Error getting URI data");
      string memory uri = abi.decode(bytesUri, (string));

      splootmation[splootId] = uri;
      addressTokensplootted[usingContractNFT][usingTokenId] = true;
      unchecked { ++splootCount; }

      emit Setter(splootId, usingContractNFT, usingTokenId);

    // Punks check
    } else if (usingContractNFT == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
      string memory uri = string.concat('punk ', toString(usingTokenId));

      splootmation[splootId] = uri;
      addressTokensplootted[usingContractNFT][usingTokenId] = true;
      unchecked { ++splootCount; }

      emit Setter(splootId, usingContractNFT, usingTokenId);

    } else {
      revert("Not an ERC-721 or ERC-1155");
    }
  }

  // Retrieved from OpenZeppelin's Strings.sol
  function toString(uint value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
        return "0";
    }
    uint temp = value;
    uint digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
  }

  function promoMint(address _to, uint _count) external onlyOwner {
    if (totalSupply() + _count > MAX_SUPPLY) revert MintedOut();
    _mint(_to, _count);
  }

  function _startTokenId() internal view virtual override returns (uint) {
    return 0;
  }

  // Setters

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    _baseTokenURI = _baseURI;
  }

  function setMintOpen(bool _val) external onlyOwner {
    mintEnabled = _val;
  }

  function setWLMintOpen(bool _val) external onlyOwner {
    wlmintEnabled = _val;
  }

  function setsplootOpen(bool _val) external onlyOwner {
    splootEnabled = _val;
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