//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract PaperCompatibleContract is 
    ERC721,
    ERC721Enumerable,
    Ownable, 
    ERC721Royalty,
    DefaultOperatorFilterer
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string public uriPrefix;
    string public contractURI;
    uint public maxSupply;
    uint public startsAt;
    uint public startPrice;
    uint public floorPrice;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint _startsAt, string memory _uriPrefix, string memory _contractURI) ERC721("Chromesthesia: Ascend", "CA")  {
        maxSupply = 200;
        uriPrefix = _uriPrefix;
        contractURI = _contractURI;
        
        // Auction Variables
        startsAt = _startsAt;
        startPrice = 0.5 ether;
        floorPrice = 0.05 ether;
    }

    function isLive() public view returns (bool) {
        return block.timestamp >= startsAt;
    }

    function price() public view returns(uint){
        uint half_life_increment = 600;
        uint secs_btwn_linear_decay = 150;
        uint elapsed = block.timestamp - startsAt;
        uint half_life_period = elapsed / half_life_increment;
        // this is necessary to avoid potential overflows. startPrice/2^20 should never be below floor price
        if(half_life_period > 20) return floorPrice;
        uint half_life_price = startPrice / (2 ** half_life_period);

        uint linear_period = elapsed % half_life_increment / secs_btwn_linear_decay;
        uint next_drop = half_life_price / 2;
        uint linear_discount = next_drop * secs_btwn_linear_decay * linear_period / half_life_increment;
        uint current_price = half_life_price - linear_discount;

        return Math.max(floorPrice,current_price);
    }

    function remainingSupply() public view returns(uint) {
        uint256 tokenId = _tokenIdCounter.current();
        return Math.max(0, maxSupply-tokenId);
    }
    
    function safeMint(address _to, uint quantity) private
    {
        for (uint i = 0; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(_to, tokenId);
        }
    }

    function publicMint(address _to)
        external
        payable
    {
        require(isLive(), "Not live");
        require(msg.value >= price(),"Insufficient funds");
        require(remainingSupply() > 0, "Collection is sold out");
        safeMint(_to, 1);
    }

    function adminMint(address _to, uint quantity)
        external
        payable
        onlyOwner
    {
        require(remainingSupply() >= quantity, "Collection is sold out");
        safeMint(_to, quantity);
    }
    
    function getClaimIneligibilityReason() external view returns (string memory) {		
        if (isLive() == false) {		
            return "Token is not available for minting yet";		
        } else if (remainingSupply() < 1) {		
            return "Not enough supply";		
        }
        return "";		
    }

    /*
     * Set secondary market royalties using the EIP2981 standard
     * Royalties will be sent to the supplied `reciever` address
     * The royalty is calcuated feeNumerator / 10000
     * A 5% royalty, would use a feeNumerator of 500 (500/10000=.05)
     */
    function setRoyalties(address reciever, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(reciever, feeNumerator);
    }

    function setStartsAt(uint256 _startsAt) public onlyOwner {
        startsAt = _startsAt;
    }

    function setUriPrefix(string memory _prefix) public onlyOwner {		
         uriPrefix = _prefix;
     }

    function withdraw(address payable _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "failure");
    }
 
    function tokenURI(uint256 _tokenId) public view virtual override (ERC721) returns (string memory) {
        require(_exists(_tokenId),"query for nonexistent token");
        return string.concat(uriPrefix,Strings.toString(_tokenId));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721,ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // The following functions are required by OpenSea Operator Filter (https://github.com/ProjectOpenSea/operator-filter-registry)
    function setApprovalForAll(address operator, bool approved) public override(ERC721,IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721,IERC721) onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}