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
    event ApprovedMinter(address indexed _minter);
    event RevokedMinter(address indexed _minter);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string public uriPrefix;
    string public contractURI;
    string public projectCode;
    uint public maxSupply;
    uint public startsAt;
    uint public startPrice;
    uint public floorPrice;
    uint public halfLifeIncrement;
    uint public secsBetweenLinearDecay;
    mapping (address => bool) public approvedToMint;
    mapping(uint => string) tokenSeedMap;

    constructor(uint _startsAt, string memory _uriPrefix, string memory _contractURI)
        ERC721("Strands of Solitude by William Mapan", "STRANDS")
    {
        startsAt = _startsAt;
        uriPrefix = _uriPrefix;
        contractURI = _contractURI;

        maxSupply = 400;
        startPrice = 8 ether;
        floorPrice = 2 ether;
        halfLifeIncrement = 1200;
        secsBetweenLinearDecay = 150;
    }

    function priceAt(uint timestamp) public view returns(uint){
        uint elapsed = timestamp - startsAt;
        uint half_life_period = elapsed / halfLifeIncrement;
        
        if(half_life_period > 20) return floorPrice;
        uint half_life_price = startPrice / (2 ** half_life_period);

        uint linear_period = elapsed % halfLifeIncrement / secsBetweenLinearDecay;
        uint linear_discount = (half_life_price / 2) * secsBetweenLinearDecay * linear_period / halfLifeIncrement;
        uint current_price = half_life_price - linear_discount;

        return Math.max(floorPrice,current_price);
    }

    function price() public view returns(uint){
        if(block.timestamp < startsAt) return startPrice;
        return priceAt(block.timestamp);
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
        require(approvedToMint[msg.sender], "unauthorized");
        require(msg.value >= floorPrice, "Minimum price not met");
        require(remainingSupply() > 0, "Collection is sold out");
        safeMint(_to, 1);
    }

    function adminMint(address _to, uint quantity)
        external
        onlyOwner
    {
        require(remainingSupply() >= quantity, "Collection is sold out");
        safeMint(_to, quantity);
    }
    
    function getClaimIneligibilityReason() external view returns (string memory) {		
        if (remainingSupply() < 1) {		
            return "Not enough supply";		
        }
        return "";
    }

    function authorizeMinter(address _wallet) external onlyOwner {
        approvedToMint[_wallet]=true;
        emit ApprovedMinter(_wallet);
    }

    function revokeMinter(address _wallet) external onlyOwner {
       approvedToMint[_wallet]=false;
        emit RevokedMinter(_wallet);
    }

    function setSeeds(uint[] calldata tokenIds, string[] calldata seeds) external onlyOwner {
        require(tokenIds.length == seeds.length, "tokenIds and seeds must be the same length");
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenSeedMap[tokenIds[i]] = seeds[i];
        }
    }

    function getSeed(uint tokenId) external view returns (string memory) {
        require(_exists(tokenId),"query for nonexistent token");
        return tokenSeedMap[tokenId];
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

    function setHalfLifeIncrement(uint256 _halfLifeIncrement) public onlyOwner {
        halfLifeIncrement = _halfLifeIncrement;
    }

    function setSecsBetweenLinearDecay(uint256 _secsBetweenLinearDecay) public onlyOwner {
        secsBetweenLinearDecay = _secsBetweenLinearDecay;
    }


    function setStartsAt(uint256 _startsAt) public onlyOwner {
        startsAt = _startsAt;
    }

    function setStartPrice(uint _startPrice) public onlyOwner {
        startPrice = _startPrice;
    }

    function setFloorPrice(uint _floorPrice) public onlyOwner {
        floorPrice = _floorPrice;
    }

    function setProjectCode(string calldata _projectCode) public onlyOwner {		
         projectCode = _projectCode;
     }

    function setMaxSupply(uint _maxSupply) public onlyOwner {		
         maxSupply = _maxSupply;
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