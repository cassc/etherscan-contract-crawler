// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./rarible/royalties/contracts/RoyaltiesV2.sol";

contract Nyanda is ERC721A, Ownable, RoyaltiesV2, DefaultOperatorFilterer {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant TOTAL_SUPPLY = 10000;
    uint256 public constant MINT_PER_TRANSACTION = 10;
    uint256 public constant PRICE = 0.001 ether;
    uint256 private constant HUNDRED_PERCENT_IN_BASIS_POINTS = 10000;

    mapping(uint256 => uint256) private mintBlockList;
    mapping(uint256 => address) private mintOwner;

    string private baseTokenURI = "https://frolicking-kashata-cc8b6e.netlify.app/api/json/";

    // Address of the royalty recipient 
    address payable private defaultRoyaltiesReceipientAddress;

    // Percentage basis points of the royalty
    uint96 private defaultPercentageBasisPoints = 1000;  // 10%

    constructor() ERC721A("NYANDA", "NYAN") {
        defaultRoyaltiesReceipientAddress = payable(address(this));
    }

    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), "/"));
    }    

    function mint(uint256 quantity) external payable {
        require(_totalMinted() + quantity <= TOTAL_SUPPLY, "Not enough remaining supply");
        require(quantity <= MINT_PER_TRANSACTION, "quantity too large");
        require(msg.value == PRICE * quantity, "Invalid eth amount");
        for (uint256 i = _totalMinted(); i < _totalMinted() + quantity; i++) {
            mintBlockList[i] = block.number;
            mintOwner[i] = msg.sender;
        }
        _mint(msg.sender, quantity);
    }

    function teamMint(uint256 quantity, address recipient) external onlyOwner {
        require(_totalMinted() + quantity <= TOTAL_SUPPLY, "Not enough remaining supply");
        for (uint256 i = _totalMinted(); i < _totalMinted() + quantity; i++) {
            mintBlockList[i] = block.number;
            mintOwner[i] = msg.sender;
        }
        _mint(recipient, quantity);
    }

    function getMintBlock(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return mintBlockList[tokenId];
    }

    function getMintOwner(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return mintOwner[tokenId];
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

    function setDefaultRoyaltiesReceipientAddress(address payable newDefaultRoyaltiesReceipientAddress) external onlyOwner {
        require(newDefaultRoyaltiesReceipientAddress != address(0), "invalid address");
        defaultRoyaltiesReceipientAddress = newDefaultRoyaltiesReceipientAddress;
    }

    function setDefaultPercentageBasisPoints(uint96 newDefaultPercentageBasisPoints) external onlyOwner {
        defaultPercentageBasisPoints = newDefaultPercentageBasisPoints;
    }

    function getRaribleV2Royalties(uint256) external view override returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = defaultPercentageBasisPoints;
        _royalties[0].account = defaultRoyaltiesReceipientAddress;
        return _royalties;
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (defaultRoyaltiesReceipientAddress, (_salePrice * defaultPercentageBasisPoints) / HUNDRED_PERCENT_IN_BASIS_POINTS);
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721A) 
        returns (bool) 
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }    

    function withdraw(address recipient) external onlyOwner {
        require(recipient != address(0), "recipient shouldn't be 0");

        (bool sent, ) = recipient.call{value: address(this).balance}("");
        require(sent, "failed to withdraw");
    }

    receive() external payable {}
}