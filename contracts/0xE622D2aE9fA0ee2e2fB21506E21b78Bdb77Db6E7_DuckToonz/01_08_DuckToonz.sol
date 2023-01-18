// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract DuckToonz is ERC721A, Ownable,DefaultOperatorFilterer {
    enum EPublicMintStatus {
        NOTACTIVE,
        ALLOWLIST_MINT,
        PUBLIC_MINT,
        CLOSED
    }

    EPublicMintStatus public publicMintStatus;

    string public baseTokenURI = "ipfs://bafybeidl5m2dnjusyj7ubets32lse5x7zh427bqv7ssnzgkgrqkvzr5kfi/";
    string public defaultTokenURI;
    uint256 public maxSupply = 5000;
    uint256 public publicSalePrice = 0.0028 ether;
    address payable public payMent;

    mapping(address => uint256) public usermint;

    constructor() ERC721A("Duck Toonz", "Duck Toonz") {
        payMent = payable(msg.sender);
        _safeMint(msg.sender, 1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(
            publicMintStatus == EPublicMintStatus.PUBLIC_MINT,
            "Public sale closed"
        );
        require(_quantity <= 5, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");

        uint256 _remainFreeQuantity = 0;

        if (totalSupply() + _quantity <= 3000) {
            if (1 > usermint[msg.sender]) {
                _remainFreeQuantity = 1 - usermint[msg.sender];
            }
        }

        uint256 _needPayPrice = 0;
        if (_quantity > _remainFreeQuantity) {
            _needPayPrice = (_quantity - _remainFreeQuantity) * publicSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        usermint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function airdrop(
        address[] memory marketmintaddress,
        uint256[] memory mintquantity
    ) public payable onlyOwner {
        for (uint256 i = 0; i < marketmintaddress.length; i++) {
            require(
                totalSupply() + mintquantity[i] <= maxSupply,
                "Exceed supply"
            );
            _safeMint(marketmintaddress[i], mintquantity[i]);
        }
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function getHoldTokenIdsByOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 index = 0;
        uint256 hasMinted = _totalMinted();
        uint256 tokenIdsLen = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLen);
        for (
            uint256 tokenId = 1;
            index < tokenIdsLen && tokenId <= hasMinted;
            tokenId++
        ) {
            if (_owner == ownerOf(tokenId)) {
                tokenIds[index] = tokenId;
                index++;
            }
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
        : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setPublicPrice(uint256 mintprice) external onlyOwner {
        publicSalePrice = mintprice;
    }

    function setPublicMintStatus(uint256 status) external onlyOwner {
        publicMintStatus = EPublicMintStatus(status);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}