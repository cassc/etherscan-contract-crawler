// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract Rumpelcrew is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_MINT_PER_TRANSACTION = 10;
    uint256 public constant RUMPEL_LIST_PRICE = 0.069 ether;
    uint256 public constant PUBLIC_SALE_PRICE = 0.087 ether;
    uint256 public constant PRESALE_MAX_MINT = 3;
    uint256 public MAX_SUPPLY = 4321;

    uint32 public rumpelListStartTime = 1652178840;
    uint32 public publicSaleStartTime = 1652265240;
    uint32 public publicSaleEndTime = 1652870040;

    bytes32 public rumpelListRoot;

    string private _baseTokenURI = "https://rumpelcrew.mypinata.cloud/ipfs/QmQi1nxcRUqVHrrqStEUpADYQLA8g1zDoZvCeD7SJXLKS4/";

    constructor() ERC721A("Rumpel crew", "RUMPEL") {}

    modifier callerIsUser() {
      require(tx.origin == msg.sender, "Caller is another contract");
      _;
    }

    function setRoot(uint256 root) external onlyOwner {
      rumpelListRoot = bytes32(root);
    }

    function presaleMint(uint256 quantity, bytes32[] memory rumpelListProof) external payable callerIsUser {
      require(block.timestamp >= rumpelListStartTime && block.timestamp < publicSaleStartTime, "Sale not active");
      bytes32 rumpelListLeaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(rumpelListProof, rumpelListRoot, rumpelListLeaf), "Not on Rumpel list");
      require(totalSupply() + quantity <= MAX_SUPPLY, "Rumpels sold out");
      require(numberMinted(msg.sender) + quantity <= PRESALE_MAX_MINT, "Cannot mint more than 3 during Rumpel list sale");
      require(msg.value == RUMPEL_LIST_PRICE * quantity, "Insufficient payment");
      _safeMint(msg.sender, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
      require(block.timestamp >= publicSaleStartTime && block.timestamp < publicSaleEndTime, "Sale not active");
      require(totalSupply() + quantity <= MAX_SUPPLY, "Rumpels sold out");
      require(quantity <= MAX_MINT_PER_TRANSACTION, "Minting too many in transaction");
      require(msg.value == PUBLIC_SALE_PRICE * quantity, "Insufficient payment");
      _safeMint(msg.sender, quantity);
    }

    function setPublicSaleEnd(uint32 timestamp) external onlyOwner {
      publicSaleEndTime = timestamp;
    }

    bool public changedSupply;

    function setMaxSupply(uint256 supply) external onlyOwner {
      require(!changedSupply, "Already done");
      MAX_SUPPLY = supply;
      changedSupply = true;
    }

    bool public uriLocked;

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
      require(!uriLocked, "Metadata locked");
      _baseTokenURI = baseURI;
    }
  
    function lockMetadata() external onlyOwner {
      uriLocked = true;
    }

    bool public teamMinted;

    //123 for team
    function teamMint() external onlyOwner {
      require(!teamMinted, "Already done");

      for (uint256 i = 0; i < 12; i++) {
        _safeMint(msg.sender, 10);
      }
      _safeMint(msg.sender, 3);
      teamMinted = true;
    }

    bool public airdropped;

    function airdrop(address[] calldata addresses, uint256[] calldata amount) external onlyOwner {
      require(!airdropped, "Already done");
      for(uint256 i = 0; i < addresses.length; i++){
        _safeMint(addresses[i], amount[i]);
      }
      airdropped = true;
    }

    function withdraw() external onlyOwner nonReentrant {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed");
    }
}