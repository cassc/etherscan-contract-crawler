// SPDX-License-Identifier: MIT

// Shylock NFT

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "contracts/DefaultOperatorFilterer.sol";

contract Shylock is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer, Pausable{
    using SafeMath for uint256;
    using Strings for uint256;

    // uint256 mint variables
    uint256 public maxSupply = 6969;
    uint256 public wlMintPrice = 0.0098 ether;
    uint256 public mintPrice = 0.0142 ether;
    uint256 public wlMaxMint = 5;
    uint256 public publicMaxMint = 5;
    uint256 public freeMax = 1;

    address public constant w1 = 0x19F8663ffB234f4062FC7E3ef13b01B46D7E7b4B;
    address public constant w2 = 0xfeE7FB9aF402DCcc3F4b3A07461b8dc08768c425;

    //base uri, base extension
    string public baseExtension = ".json";
    string public baseURI = "https://bafybeihtwnlsicusgnohgeirsmjw6e5k5p4miostko27ldujvobptzcajq.ipfs.nftstorage.link/";

    // merkle root
    bytes32 public root = 0x478ffb28c2470f25a1b78d6917dedeca5cd5184725b66b48b473d2f71f88cc38;

    // booleans for if mint is enabled
    bool public publicMintEnabled = false;
    bool public wlMintEnabled = false;
    uint256 public filter = 1000;

    // mappings to keep track of # of minted tokens per user
    mapping(address => uint256) public totalWlMint;
    mapping(address => uint256) public totalFreeMints;
    

   
    constructor (
       
        ) ERC721A("SHYLOCK", "SLK") {

    }
    

    function airdrop(address[] calldata _address, uint256 _amount) external onlyOwner nonReentrant {

        require(totalSupply() + _amount <= maxSupply, "Error: max supply reached");

        for (uint i = 0; i < _address.length; i++) {
            _safeMint(_address[i], _amount);
        }
    }

    // Whitelist mint that requires merkle proof; user receives 1 free 
    function whitelistMint(uint256 _quantity, bytes32[] memory proof) external payable whenNotPaused nonReentrant {
        
        if (totalFreeMints[msg.sender] == 0 && freeMax <= filter) {
            require(freeMax <= filter, "No more free left!");
            require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of whitelist");
            require(wlMintEnabled, "Whitelist mint is currently paused");
            require(totalSupply() + _quantity <= maxSupply, "Error: max supply reached");
            require((totalWlMint[msg.sender] + _quantity) <= wlMaxMint, "Error: Cannot mint");
            require(msg.value >= ((_quantity * wlMintPrice) - wlMintPrice), "Not enough ether sent");

            totalFreeMints[msg.sender] += 1;
            freeMax += 1;
            totalWlMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);

        } else {
            require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of whitelist");
            require(wlMintEnabled, "Whitelist mint is currently paused");
            require(totalSupply() + _quantity <= maxSupply, "Error: max supply reached");
            require((totalWlMint[msg.sender] + _quantity) <= wlMaxMint, "Error: Cannot mint");
            require(msg.value >= (_quantity * wlMintPrice), "Not enough ether sent");

            totalWlMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);

        }
    }

    // verify merkle proof with a buf2hex(keccak256(address)) or keccak256(abi.encodePacked(address))
    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns(bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    

    function publicMint(uint256 _quantity) external payable whenNotPaused nonReentrant {
        require(_quantity <= publicMaxMint, "Cannot mint more");
        require(publicMintEnabled, "Public mint is currently paused");
        require(msg.value >= (_quantity * mintPrice), "Not enough ether sent");
        require(totalSupply() + _quantity <= maxSupply, "Error: max supply reached");

        _safeMint(msg.sender, _quantity);
    }

    

    // returns the baseuri of collection, private
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // override _statTokenId() from erc721a to start tokenId at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // return tokenUri given the tokenId

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
        : "";
        
    }

    // owner updates and functions

    function togglePublicMint() external onlyOwner nonReentrant{
        publicMintEnabled = !publicMintEnabled;
    }

    function toggleWlMint() external onlyOwner nonReentrant{
        wlMintEnabled = !wlMintEnabled;
    }

    function enableBothMints() external onlyOwner nonReentrant{
        wlMintEnabled = true;
        publicMintEnabled = true;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner nonReentrant{
    mintPrice = _mintPrice;
    }

    function setFilter(uint256 _filter) external onlyOwner nonReentrant{
    filter = _filter;
    }

    function setWlPrice(uint256 _wlMintPrice) external onlyOwner nonReentrant{
    wlMintPrice = _wlMintPrice;
    }

    function setmaxWMint(uint256 _wlMaxMint) external onlyOwner nonReentrant{
    wlMaxMint = _wlMaxMint;
    }

     function setmaxPublicMint(uint256 _publicMaxMint) external onlyOwner nonReentrant{
    publicMaxMint = _publicMaxMint;
    }
  
    function pause() public onlyOwner nonReentrant{ 
        _pause();
    }

    function unpause() public onlyOwner nonReentrant{
        _unpause();
    }

    function setBaseURI(string memory _newURI) public onlyOwner nonReentrant{
        baseURI = _newURI;
    }

    function setRoot(bytes32 _root) public onlyOwner nonReentrant {
        root = _root;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner nonReentrant {
        maxSupply = _maxSupply;
    }

      function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(w1, ((balance * 15) / 100)); // 15%
        _withdraw(w2, ((balance * 85) / 100)); // 85%
 
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    /////////////////////////////
    // OPENSEA FILTER REGISTRY 
    /////////////////////////////

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