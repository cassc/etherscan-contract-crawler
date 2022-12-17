// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

/*
  ShadesOfYou the ShadyVerse collection
*/
contract ShadyVerse is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    bool public allowListSaleActive = false;
    bool public saleActive = false;

    string public PROVENANCE;

    uint256 public constant TOTAL_TOKEN_LIMIT = 5000;
    uint256 public STAGE_TOKEN_LIMIT = 1000;
    uint256 public MAX_ALLOW_LIST_MINT = 5;
    uint256 public MINT_STAGE = 1;
    uint256 public MAX_PER_ADDRESS = 4;
    uint256 public TOKEN_PRICE = 0;

    bytes32 private _allowListRoot;
    struct BaseURI {
        uint256 lastTokenId;
        string uri;
    }
    BaseURI[] private _baseURIs;
    string private _placeholderBaseTokenURI;
    mapping(uint256 => mapping(address => uint256)) private _allowListClaimedMap;

    constructor() ERC721A("ShadyVerse", "SVSOY", 50, TOTAL_TOKEN_LIMIT) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mintAllowList(bytes32[] calldata proof, uint256 quantity) external callerIsUser nonReentrant {
        uint256 ts = totalSupply();
        require(quantity <= MAX_ALLOW_LIST_MINT, "Too much to mint");
        require(_verify(_leaf(msg.sender), proof), "Address is not on allowlist");
        require(allowListSaleActive, "The sale is not active");
        require(_allowListClaimedMap[MINT_STAGE][msg.sender].add(quantity) <= MAX_ALLOW_LIST_MINT, "Purchase would exceed max tokens allocated");
        require(ts.add(quantity) <= STAGE_TOKEN_LIMIT, "Purchase would exceed max tokens per this stage");
        require(ts.add(quantity) <= TOTAL_TOKEN_LIMIT, "Purchase would exceed max tokens");

        _allowListClaimedMap[MINT_STAGE][msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    // In case of any possible future sales
    function mint(uint256 quantity) external payable callerIsUser nonReentrant {
        uint256 ts = totalSupply();
        require(saleActive, "The sale is not active");
        require(quantity <= MAX_PER_ADDRESS, "Invalid number of tokens");
        require(ts.add(quantity) <= STAGE_TOKEN_LIMIT, "Purchase would exceed max tokens");
        require(msg.value == TOKEN_PRICE.mul(quantity), "Ether value sent is not the required price");

        _safeMint(msg.sender, quantity);
    }

    // OWNER ONLY
    function reserve(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    function setMintStage(uint256 stage) public onlyOwner {
        MINT_STAGE = stage;
    }

    function setStageLImit(uint256 limit) public onlyOwner {
        STAGE_TOKEN_LIMIT = limit;
    }

    function setMaxAllow(uint256 max) public onlyOwner {
        MAX_ALLOW_LIST_MINT = max;
    }

    function setMaxPerTransaction(uint256 max) public onlyOwner {
        MAX_PER_ADDRESS = max;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function flipAllowListSaleActive() public onlyOwner {
        allowListSaleActive = !allowListSaleActive;
    }

    function setAllowListRoot(bytes32 _root) public onlyOwner {
        _allowListRoot = _root;
    }

    function setMintCost(uint256 newCost) public onlyOwner {
        TOKEN_PRICE = newCost;
    }

    function flipSaleActive() public onlyOwner {
        saleActive = !saleActive;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }
    // INTERNAL

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
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

      string memory baseURI = _baseURIForToken(tokenId);
      return
        bytes(baseURI).length > 0
          ? string(abi.encodePacked(baseURI, tokenId.toString()))
          : "";
    }

    function _baseURIForToken(uint256 tokenId) internal view returns (string memory) {
        for (uint256 i = 0; i < _baseURIs.length;) {
          if (tokenId <= _baseURIs[i].lastTokenId) {
              return _baseURIs[i].uri;
          }
          unchecked { ++i; }
        }
        return _placeholderBaseTokenURI;
    }

    function setBaseURI(string calldata baseURI, uint256 lastTokenId) external onlyOwner {
        _baseURIs.push(BaseURI(lastTokenId, baseURI));
    }

    function replaceBaseURI(string calldata baseURI, uint256 lastTokenId, uint256 index) external onlyOwner {
        _baseURIs[index] = BaseURI(lastTokenId, baseURI);
    }

    function setBasePlaceholderURI(string calldata baseURI) external onlyOwner {
        _placeholderBaseTokenURI = baseURI;
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