// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
   _____________________
  /                 `   \
  |  .-----------.  |   |-----.
  |  |           |  |   |-=---|
  |  | ChiptosX. |  |   |-----|
  |  |           |  |   |-----|
  |  |           |  |   |-----|
  |  `-----------'  |   |-----'/\
   \________________/___'     /  \
      /                      / / /
     / //               //  / / /
    /                      / / /
   / _/_/_/_/_/_/_/_/_/_/ /   /
  / _/_/_/_/_/_/_/_/_/_/ /   /
 / _/_/_/_______/_/_/_/ / __/
/______________________/ /    
\______________________\/
*/
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract ChiptosX is ERC721A, Ownable {
    string public PROVENANCE;
    string private _baseURIextended;

    bool public freeIsActive = true;
    bool public isChipListActive = true;
    bool public preSaleIsActive;
    bool public saleIsActive;

    uint256 public constant MAX_SUPPLY = 7680;
    uint256 public MAX_PUBLIC_MINT = 3;
    uint256 public PRICE_PER_TOKEN = 0.088 ether;

    bytes32 public chipListMerkleRoot;

    mapping(address => uint8) public usedAddresses;
    mapping(address => uint8) private _chipHolderFreeList;
    mapping(address => uint8) private _chipHolderPreList;

    constructor() ERC721A("ChiptosX", "ChiptosX") {
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

//Read Functions
    function numFreeAvailableToMint(address addr) external view returns (uint8) {
        return _chipHolderFreeList[addr];
    }

    function numHolderAvailableToMint(address addr) external view returns (uint8) {
        return _chipHolderPreList[addr];
    }

    function numMinted(address addr) external view returns (uint8) {
        return usedAddresses[addr];
    }
    
    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return _baseURIextended;
    }
    
// Holder Free
    function holderFree(uint8 numberOfTokens) external payable callerIsUser{
        uint256 ts = totalSupply();
        require(freeIsActive, "Free Mint is not active");
        require(numberOfTokens <= _chipHolderFreeList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

        _chipHolderFreeList[msg.sender] -= numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

//HolderPresale
    function holderPresale(uint8 numberOfTokens) external payable callerIsUser{
        uint256 ts = totalSupply();
        require(isChipListActive, "Holder PreSale is not active");
        require(numberOfTokens <= _chipHolderPreList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _chipHolderPreList[msg.sender] -= numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

//PreSale
 function presaleMint(bytes32[] calldata merkleProof, uint8 count)
    external
    payable
    callerIsUser
  {
   require(
      MerkleProof.verify(
        merkleProof,
        chipListMerkleRoot,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Address not in the presale"
    );
    uint256 ts = totalSupply();
    require(preSaleIsActive, "Chiplist is not active");
    require(msg.value >= PRICE_PER_TOKEN * count, "Ether value sent is below the price");
    require(usedAddresses[msg.sender] + count <= 2, "max per wallet reached");
    require(count > 0 && count <= 2, "You can mint min 1, maximum 2 NFTs");
    require(ts + count <= MAX_SUPPLY, "Cannot exceeds max supply");

    usedAddresses[msg.sender] += count;

    _safeMint(msg.sender, count);
  }

//Public Mint
    function publicMint(uint numberOfTokens) public payable callerIsUser{
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _safeMint(msg.sender, numberOfTokens);
    }

//Dev Mint
    function reserve(uint256 n) public onlyOwner {
        uint256 ts = totalSupply();
        require(n + ts <= MAX_SUPPLY);
        _safeMint(msg.sender, n);
    }

//Setters    

    function setChipHolderList(address[] calldata addresses, uint8 numHolderFreeAllowedToMint, uint8 numAllowedToMint) external onlyOwner callerIsUser{
        for (uint256 i = 0; i < addresses.length; i++) {
            _chipHolderFreeList[addresses[i]] = numHolderFreeAllowedToMint;
            _chipHolderPreList[addresses[i]] = numAllowedToMint;
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setfreeState(bool newState) public onlyOwner {
        freeIsActive = newState;
    }

    function setIsChipListActive(bool _isChipListActive) external onlyOwner {
        isChipListActive = _isChipListActive;
    }

    function setPreSaleActive(bool newState) external onlyOwner {
        preSaleIsActive = newState;
    }

    function setPrice(uint256 price) external onlyOwner {
        PRICE_PER_TOKEN = price;
    }

    function setQpTX(uint256 qx) external onlyOwner {
        MAX_PUBLIC_MINT = qx;
    }

    function setChipListMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    chipListMerkleRoot = _merkleRoot;
    }

    /**
     * Withdraw Ether
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}