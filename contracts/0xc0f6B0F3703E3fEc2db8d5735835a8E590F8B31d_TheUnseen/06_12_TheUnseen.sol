// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract TheUnseen is ERC721A, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    uint256 constant MAX_SUPPLY = 345;
    uint256 constant LIMIT_PER_WALLET = 3;
    uint256 private PUBLIC_SALE_PRICE = 0.029 ether;
    bool private isPublicSaleActive = false;
    bool private unreveal = false;
    string private baseTokenURI;
    string private prerevealURI = "ipfs://bafkreie4zfjwl34t4xq6qw3zjdsjvwaz5j2mouxt43pysr4j6q55arkeke";
    mapping(address => uint256) private Userlimit;

    constructor(address controller_)
        ERC721A("The Unseen", "UNS")
    {
        baseTokenURI = "";
        // Transfer ownership to controller
        transferOwnership(controller_);
    }

    modifier validMint(uint256 _amount) {
        require(isPublicSaleActive, "Mint stopped");
        require(totalSupply() + _amount < MAX_SUPPLY, "max supply reached");
        _;
    }

    function mint(uint256 _amount) external payable validMint(_amount) {
        require(userLimit(msg.sender, _amount), "User limit exceeded");
        uint256 requiredAmount = SafeMath.mul(PUBLIC_SALE_PRICE, _amount);

        require(
            msg.value >= requiredAmount,
            "Not enough ETH sent, check price"
        );
        Userlimit[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);

    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /* ========== SET FUNCTION ========== */

    function setPublicMint(bool _active) external onlyOwner {
        isPublicSaleActive = _active;
    }

    function setPrice(uint256 _price) external onlyOwner {
            require(_price > 0, "Price must be greater than 0");
        PUBLIC_SALE_PRICE = _price;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseTokenURI = baseURI_;
    }

    function reveal() external onlyOwner {
        unreveal = !unreveal;
    }

    // Overriding with opensea's open registry
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /* ==========RETURN FUNCTION ========== */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function userLimit(address _user, uint256 _amount)
        public
        view
        returns (bool)
    {
        uint256 left = LIMIT_PER_WALLET - (Userlimit[_user] + _amount);
        if (left >= 0) {
            return true;
        }
        return false;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (unreveal == false) {
            return prerevealURI;
        } else {
            require(
                _exists(_tokenId),
                "ERC721Metadata: URI query for nonexistent token"
            );
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    
        }
    }
}