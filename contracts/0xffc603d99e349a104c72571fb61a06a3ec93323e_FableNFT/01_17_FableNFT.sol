// SPDX-License-Identifier: MIT


//   ▄████████    ▄████████ ▀█████████▄   ▄█          ▄████████ 
//  ███    ███   ███    ███   ███    ███ ███         ███    ███ 
//  ███    █▀    ███    ███   ███    ███ ███         ███    █▀  
// ▄███▄▄▄       ███    ███  ▄███▄▄▄██▀  ███        ▄███▄▄▄     
//▀▀███▀▀▀     ▀███████████ ▀▀███▀▀▀██▄  ███       ▀▀███▀▀▀     
//  ███          ███    ███   ███    ██▄ ███         ███    █▄  
//  ███          ███    ███   ███    ███ ███▌    ▄   ███    ███ 
//  ███          ███    █▀  ▄█████████▀  █████▄▄██   ██████████ 
//                                       ▀                 


pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract FableNFT is
    ERC721AQueryable,
    ERC721ABurnable,
    EIP712,
    Ownable,
    DefaultOperatorFilterer
{
    uint256 public maxSupply = 999;
    uint256 public normalMintPrice = 0.022 ether;
    uint256 public whitelistMintPrice = 0.0189 ether;
    uint256 public maxMintPerAccount = 5;
    uint256 public maxWhitelistMintPerAccount = 1;
    uint256 public totalNormalMint;
    uint256 public totalWhitelistMint;
    uint256 public publicSalesTimestamp = 1675882800;
    uint256 public whitelistSalesTimestamp = 1675868400;

    mapping(address => uint256) private _totalMintPerAccount;
    mapping(address => uint256) private _totalWhitelistMintPerAccount;

    address private _signerPublicKey =
        0x1a5A66617a44fFe03F64CF7EbDBf2C5Be023e5E4;

    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("Fable NFT", "FABLE") EIP712("Fable NFT", "1.0.0") {}

    function mint(uint256 amount) external payable {
        require(isPublicSalesActive(), "Public sales is not active");
        require(totalSupply() < maxSupply, "Sold out");
        require(
            totalSupply() + amount <= maxSupply,
            "Amount exceeds max supply"
        );
        require(amount > 0, "Invalid amount");
        require(msg.value >= amount * normalMintPrice, "Invalid mint price");
        require(
            amount + _totalMintPerAccount[msg.sender] <= maxMintPerAccount,
            "Max tokens per account reached"
        );

        totalNormalMint += amount;
        _totalMintPerAccount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function batchMint(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(
            addresses.length == amounts.length,
            "addresses and amounts doesn't match"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function whitelistMint(uint256 amount, bytes calldata signature)
        external
        payable
    {
        require(isWhitelistSalesActive(), "Whitelist sales is not active");
        require(totalSupply() < maxSupply, "Sold out");
        require(totalSupply() + amount <= maxSupply, "Sold out");
        require(
            _recoverAddress(msg.sender, signature) == _signerPublicKey,
            "Not elegible for this claimphase"
        );
        require(amount > 0, "Invalid amount");
        require(msg.value >= amount * whitelistMintPrice, "Invalid mint price");
        require(
            amount + _totalMintPerAccount[msg.sender] <= maxWhitelistMintPerAccount,
            "Max tokens per account reached in this claim phase"
        );

        totalWhitelistMint += amount;
        _totalMintPerAccount[msg.sender] += amount;
        _totalWhitelistMintPerAccount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function isPublicSalesActive() public view returns (bool) {
        return publicSalesTimestamp <= block.timestamp;
    }

    function isWhitelistSalesActive() public view returns (bool) {
        return whitelistSalesTimestamp <= block.timestamp;
    }

    function hasMintedUsingWhitelist(address account)
        public
        view
        returns (bool)
    {
        return
            _totalWhitelistMintPerAccount[account] >=
            maxWhitelistMintPerAccount;
    }

    function totalMintPerAccount(address account)
        public
        view
        returns (uint256)
    {
        return _totalMintPerAccount[account];
    }

    function totalWhitelistMintPerAccount(address account)
        public
        view
        returns (uint256)
    {
        return _totalWhitelistMintPerAccount[account];
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractUri = contractURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function setSignerPublicKey(address signerPublicKey_) external onlyOwner {
        _signerPublicKey = signerPublicKey_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setNormalMintPrice(uint256 normalMintPrice_) external onlyOwner {
        normalMintPrice = normalMintPrice_;
    }

    function setWhitelistMintPrice(uint256 whitelistMintPrice_)
        external
        onlyOwner
    {
        whitelistMintPrice = whitelistMintPrice_;
    }

    function setMaxMintPerAccount(uint256 maxMintPerAccount_)
        external
        onlyOwner
    {
        maxMintPerAccount = maxMintPerAccount_;
    }

    function setMaxWhitelistMintPerAccount(uint256 maxWhitelistMintPerAccount_)
        external
        onlyOwner
    {
        maxWhitelistMintPerAccount = maxWhitelistMintPerAccount_;
    }

    function setPublicSalesTimestamp(uint256 timestamp) external onlyOwner {
        publicSalesTimestamp = timestamp;
    }

    function setWhitelistSalesTimestamp(uint256 timestamp) external onlyOwner {
        whitelistSalesTimestamp = timestamp;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _hash(address account) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(keccak256("FableNFT(address account)"), account)
                )
            );
    }

    function _recoverAddress(address account, bytes calldata signature)
        private
        view
        returns (address)
    {
        return ECDSA.recover(_hash(account), signature);
    }

    //OpenseaOperatorFilterer
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}