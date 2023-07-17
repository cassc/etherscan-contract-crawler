// SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A/ERC721A.sol";
import "./libraries/MerkleProof.sol";

contract TheIndiansNFT is ERC721A, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;
  Counters.Counter private _tokenId;

  string public collectionName;
  string public collectionSymbol;
  string private _customBaseURI;
  bytes32 private merkleRoot;
  uint256 constant public MAX_NFTS = 3333;
  uint256 constant public MAX_MINT_QUANTITY = 1;
  uint256 constant public NFT_PRICE = 0 ether;
  uint256 constant public MAX_PUBLIC_MINT = 1;
  uint256 constant public WHITELIST_SALE_PRICE = 0 ether;
  uint256 constant public WHITELIST_MAX_MINT = 1;
  uint256 public constant TEAM_MINT_AMOUNT = 80;
  address private curryAddress;

  bool public publicSale;
  bool public whiteListSale;
  bool public teamMinted;

  mapping(bytes32 => bool) private usedNonces;
  mapping(address => bool) public totalPublicMint;
  mapping(address => bool) public totalWhitelistMint;

  constructor() ERC721A("The Indians NFT", "TI") {
  }

  modifier callerIsUser() {
        require(tx.origin == msg.sender, "The Indians :: Cannot be called by a contract");
        _;
    }

  function mint(uint256 _nonce, uint256 quantity) external payable callerIsUser{
    require(publicSale, "The Indians :: Too soon mint.");
    require(quantity <= MAX_MINT_QUANTITY, "The Indians :: Too many Mint");
    require((quantity * NFT_PRICE)  <= msg.value, "The Indians :: you are see the price");
    require(totalPublicMint[msg.sender] == false, "The Indians :: Already minted!");
    uint256 currentSupply = totalSupply();
    require((currentSupply +quantity) <= MAX_NFTS, "The Indians :: Beyond Max Supply");
    bytes32 txid = getTransferHash(msg.sender, _nonce);
    require(!usedNonces[txid], "Reused Nonce");
    usedNonces[txid] = true;
    totalPublicMint[msg.sender] = true;

    _safeMint(msg.sender, quantity);

    }

  function whitelistMint(uint256 _nonce, bytes32[] calldata _merkleProof, uint256 quantity) external payable callerIsUser{
    require(whiteListSale, "The Indians :: Too soon mint.");
    require((totalSupply() + quantity) <= MAX_NFTS, "The Indians :: Beyond Max Supply");
    require(quantity <= MAX_MINT_QUANTITY, "The Indians :: Too many Mint");
    require(totalWhitelistMint[msg.sender] == false, "The Indians :: Already minted!");
    require(msg.value >= (WHITELIST_SALE_PRICE * quantity), "The Indians :: you are see the price");
    bytes32 txid = getTransferHash(msg.sender, _nonce);
    require(!usedNonces[txid], "Reused Nonce");
    //create leaf node
    bytes32 sender = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "The Indians :: You are not having the whitelisted");
    usedNonces[txid] = true;
    totalWhitelistMint[msg.sender] = true;

    _safeMint(msg.sender, quantity);
    }

  function teamMint() external onlyOwner{
        require(!teamMinted, "The Indians :: team sirs already mint");
        teamMinted = true;
        _safeMint(msg.sender, TEAM_MINT_AMOUNT);
    }

  function hashMessage(uint256 _nonce) internal view returns(bytes32 _hash) {
      _hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(msg.sender, _nonce))));
  }

  function getTokenMaxSupply() public pure returns(uint256){
    return MAX_NFTS;
  }

  /**
   * To change the starting tokenId, please override this function.
   */
  function _startTokenId() internal pure override returns (uint256) {
      return 1;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

      return string(abi.encodePacked(_customBaseURI, tokenId.toString()));
  }

  function getTransferHash(address _to, uint256 _nonce) public pure returns (bytes32 txHash) {
        return keccak256(abi.encodePacked(_to, _nonce));
    }

  function updateCustomBaseURI(string memory customBaseURI) public onlyOwner {
        _customBaseURI = customBaseURI;
    }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

  function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

  function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

  function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

  function cookCurry(address ingredients) external onlyOwner{
        curryAddress = ingredients;
    }

  function curryExplode(uint256 tokenId) external view{
        IERC721(curryAddress).ownerOf(tokenId);
    }

  function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

  function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}