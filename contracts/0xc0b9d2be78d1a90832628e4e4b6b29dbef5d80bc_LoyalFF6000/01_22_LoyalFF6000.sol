// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LoyalFF6000 is ERC721A, OperatorFilterer, Ownable, IERC2981 {
    uint256 public immutable maxSupply;

    uint256 private constant ROYALTY_DIVISOR = 1_000;

    string public baseURI;

    address loyalTokenAddress;

    // Sale state
    uint256 public maxMint;
    uint256 public price = 0.1 ether;
    bool public publicSaleLive;
    uint256 public teamClaimed;

    mapping(address => uint256) public saleCount;

    // Royalty state
    uint256 royaltyFee = 50;
    address royaltyReceiver;

    constructor(
        uint256 maxSupply_,
        uint256 maxMint_,
        address loyalTokenAddress_
    )
        ERC721A("Loyal FF6000", "LOYALFF6000")
        OperatorFilterer(
            address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6),
            false
        )
    {
        royaltyReceiver = msg.sender;
        maxSupply = maxSupply_;
        maxMint = maxMint_;
        loyalTokenAddress = loyalTokenAddress_;
    }

    modifier publicLive() {
        require(publicSaleLive, "Public sale is not yet live.");
        _;
    }

    modifier checkSale(uint256 quantity) {
        require(tx.origin == msg.sender, "Tx origin check failed.");
        require(quantity <= maxMint, "Exceeds transaction limit.");
        require(quantity > 0, "Quantity equal to zero.");
        require(price * quantity == msg.value, "Transaction value invalid.");
        // Any amount minted from the team allocation does not count towards public mintable total supply.
        require(totalSupply() + quantity <= maxSupply, "Exceeds total supply.");
        require(
            saleCount[msg.sender] + quantity <= maxMint,
            "Max mint exceeded."
        );
        _;
    }

    function getSaleCount(address _address) external view returns (uint256) {
        return saleCount[_address];
    }

    function mint(
        uint256 quantity
    ) external payable publicLive checkSale(quantity) {
        // check that msg.sender has at least 1 LOYAL token in their wallet
        require(
            IERC20(loyalTokenAddress).balanceOf(msg.sender) >= 1 * 10 ** 18,
            "You must hold at least 1 LOYAL token to mint."
        );

        saleCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function togglePublic() external onlyOwner {
        publicSaleLive = !publicSaleLive;
    }

    function setTransactionLimit(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function withdrawTransfer() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawCall() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
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

    // ERC-2981

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256) {
        return (royaltyReceiver, (_salePrice * royaltyFee) / ROYALTY_DIVISOR);
    }

    function setRoyaltyFee(uint256 _royaltyFee) external onlyOwner {
        require(_royaltyFee <= ROYALTY_DIVISOR, "Royalty fee too high.");
        royaltyFee = _royaltyFee;
    }

    function setRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        require(_royaltyReceiver != address(0), "Invalid receiver address.");
        royaltyReceiver = _royaltyReceiver;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC2981 interface ID.
            super.supportsInterface(interfaceId);
    }
}