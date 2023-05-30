// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ERC721A.sol";
 
contract RabbitHole is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

    using Strings for uint256;

    uint256 public maxSupply = 500;
    uint256 private pricePublic = 0.01 ether;
    uint256 public maxPerTxPublic = 10;
    uint256 public qtyWithGlasses = 50;
    
    string public ipfsHTML = "QmTqyERzsgSQWeVd8LrascY7PEE9ocYMCtHhHu84CkwJ8s"; 
    
    bool public paused = false;

    mapping (uint => string) public hashes;
    mapping (uint => string) public cids;
        
    event Minted(address caller);

    constructor() ERC721A("Rabbit Hole", "RABBITHOLE") {}
    
    function mint(string memory _hash, string memory _cid) external payable nonReentrant{
        require(!paused, "Minting is paused");
        uint256 supply = totalSupply();
        require(supply + 1 <= maxSupply, "Sorry, not enough left!");
        require(msg.value >= pricePublic, "Sorry, not enough amount sent!"); 
        
        _safeMint(msg.sender, 1);

        hashes[supply] = _hash;
        cids[supply] = _cid;

        emit Minted(msg.sender);
    }
    
    function remaining() public view returns(uint256){
        uint256 left = maxSupply - totalSupply();
        return left;
    }
    
    function getPricePublic() public view returns (uint256){
        return pricePublic;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory glasses = tokenId < qtyWithGlasses ? 'true' : 'false';
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Rabbit Hole", "description": "", "image": "ipfs://', cids[tokenId], '/thumb.png", "animation_url": "ipfs://', ipfsHTML, '/?hash=', hashes[tokenId],'&glasses=', glasses, '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
    
    function getOwners() public view returns(address[] memory){
        uint totalSupply = totalSupply();
        address[] memory owners = new address[](totalSupply);
        for(uint256 i = 0; i < totalSupply; i++){
            owners[i] = ownerOf(i);
        }
        return owners;
    }

    // ADMIN FUNCTIONS

    function preMintWithGlasses(uint256 _qty, string[] memory _hashes) public onlyOwner {
        require(_qty <= qtyWithGlasses, "Too many glasses");
        require(_qty == _hashes.length, "Hashes length mismatch");
        for(uint256 i = 0; i < _qty; i++){
            hashes[totalSupply()] = _hashes[i];
        }
        _safeMint(msg.sender, _qty);
    }
    
    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    function closeMinting() public onlyOwner {
        uint256 supply = totalSupply();
        maxSupply = supply;
    }
    
    function setPricePublic(uint256 _newPrice) public onlyOwner {
        pricePublic = _newPrice;
    }
    
    function setMaxPerTxPublic(uint256 _newMax) public onlyOwner {
        maxPerTxPublic = _newMax;
    }

    function setQtyWithGlasses(uint256 _newQty) public onlyOwner {
        qtyWithGlasses = _newQty;
    }

    function setIPFSHTML(string memory _newIPFS) public onlyOwner {
        ipfsHTML = _newIPFS;
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(msg.sender).send(balance));
    }

    function updateTokenCid(uint256 _tokenId, string memory _cid) public onlyOwner {
        cids[_tokenId] = _cid;
    }


    // royalties overrides
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId, data);
    }

    receive() external payable {}
    
}