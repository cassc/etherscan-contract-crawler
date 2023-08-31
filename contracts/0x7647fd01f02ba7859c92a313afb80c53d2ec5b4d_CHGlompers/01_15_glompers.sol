// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface WarmInterface {
    function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}

contract CHGlompers is DefaultOperatorFilterer, ERC721A, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    address constant WarmAddress = 0xC3AA9bc72Bd623168860a1e5c6a4530d3D80456c;
    address constant CandyHuntersAddress = 0x89c9c2e4eBEfF6903223B062458e11E56636f838;
    WarmInterface warmInstance = WarmInterface(WarmAddress);

    mapping(uint256 => bool) public tokenClaimed;
    bool public mintActive = true;
    string private baseURI = "https://candyhunters-nft.web.app/api/token/";

    constructor() ERC721A("Glompers of Sweetopia", "GLOMPERS") {
        _setDefaultRoyalty(0x08c239fCE14d628b891B8882ED60733F6aDF5B3A, 700);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner{
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function flipMintActive() public onlyOwner {
        mintActive = !mintActive;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(mintActive, "Mint is not active");
        require(warmInstance.ownerOf(CandyHuntersAddress,tokenId) == msg.sender, "You do not own this Candy Hunter");
        require(tokenClaimed[tokenId] == false, "You have already claimed this Glomper");
        tokenClaimed[tokenId] = true;
        _mint(msg.sender, 1);
    }

    function multiClaim(uint256[] calldata tokenIds) public nonReentrant {
        require(mintActive, "Mint is not active");
        uint256 quantity = tokenIds.length;
        for (uint256 i; i < quantity; i++){
            require(warmInstance.ownerOf(CandyHuntersAddress,tokenIds[i]) == msg.sender, "You do not own this Candy Hunter");
            require(tokenClaimed[tokenIds[i]] == false, "You have already claimed this Glomper");
            tokenClaimed[tokenIds[i]] = true;
        }
        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);

    }

}