pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract ShadesOfYou is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;
    bool public saleActive = false;
    bool public allowListSaleActive = false;

    string public PROVENANCE;

    uint256 public constant MAX_DEV_RESERVE = 50;
    uint256 public constant TOKEN_LIMIT = 7000;
    uint256 public MAX_ALLOW_LIST_MINT = 5;
    uint256 public MAX_PER_ADDRESS = 20;
    uint256 public TOKEN_PRICE = 0.05 ether;
    
    bytes32 private _allowListRoot;
    mapping(address => uint256) private _allowListClaimed;

    constructor() ERC721A("ShadesOfYou", "SOY", 10, TOKEN_LIMIT) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mintAllowList(uint256 numTokens, bytes32[] calldata proof) external payable callerIsUser {
        uint256 ts = totalSupply();
        require(_verify(_leaf(msg.sender), proof), "Address is not on allowlist");
        require(allowListSaleActive, "The pre-sale is not active");
        require(_allowListClaimed[msg.sender].add(numTokens) <= MAX_ALLOW_LIST_MINT, "Purchase would exceed max pre-sale tokens");
        require(ts.add(numTokens) <= TOKEN_LIMIT, "Purchase would exceed max tokens");
        require(msg.value == TOKEN_PRICE.mul(numTokens), "Ether value sent is not the required price");

        _allowListClaimed[msg.sender] = _allowListClaimed[msg.sender].add(numTokens);
        _safeMint(msg.sender, numTokens);
    }

    function mint(uint256 quantity) external payable callerIsUser {
        uint256 ts = totalSupply();
        require(saleActive, "The sale is not active");
        require(quantity <= MAX_PER_ADDRESS, "Invalid number of tokens");
        require(ts.add(quantity) <= TOKEN_LIMIT, "Purchase would exceed max tokens");
        require(
          numberMinted(msg.sender) + quantity <= MAX_PER_ADDRESS,
          "can not mint this many"
        );
        require(msg.value == TOKEN_PRICE.mul(quantity), "Ether value sent is not the required price");

        _safeMint(msg.sender, quantity);
    }

    // OWNER ONLY
    function reserve(uint256 quantity) external onlyOwner {
      require(
        totalSupply() + quantity <= MAX_DEV_RESERVE,
        "too many already minted before dev mint"
      );
      require(
        quantity % maxBatchSize == 0,
        "can only mint a multiple of the maxBatchSize"
      );
      uint256 numChunks = quantity / maxBatchSize;
      for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchSize);
      }
    }

    function setMaxAllowList(uint256 newMax) public onlyOwner {
        MAX_ALLOW_LIST_MINT = newMax;
    }

    function setMaxPerWallet(uint256 newMax) public onlyOwner {
        MAX_PER_ADDRESS = newMax;
    }

    function setMintCost(uint256 newCost) public onlyOwner {
        require(newCost > 0, "price must be greater than zero");
        TOKEN_PRICE = newCost;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function flipSaleActive() public onlyOwner {
        saleActive = !saleActive;
    }

    function flipAllowListSaleActive() public onlyOwner {
        allowListSaleActive = !allowListSaleActive;
    }

    function setAllowListRoot(bytes32 _root) public onlyOwner {
        _allowListRoot = _root;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    // INTERNAL

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
      external
      view
      returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 _leafNode, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, _allowListRoot, _leafNode);
    }
}