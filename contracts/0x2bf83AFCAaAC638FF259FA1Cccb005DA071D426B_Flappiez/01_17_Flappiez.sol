// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Flappiez is
    ERC721AQueryable,
    ERC721ABurnable,
    EIP712,
    Ownable,
    DefaultOperatorFilterer
{
    uint256 public maxSupply = 3333;
    uint256 public maxWhitelistSupply = 1333;
    uint256 public publicSalesTimestamp = 1676069880;
    uint256 public whitelistSalesTimestamp = 1676069880;
    uint256 public normalMintPrice = 0.01 ether;
    uint256 public whitelistMintPrice = 0.01 ether;
    uint256 public maxMintPerAccount = 10;
    uint256 public maxWhitelistMintPerAccount = 1;
    uint256 public totalNormalMint;
    uint256 public totalWhitelistMint;

    mapping(address => bool) public freeMinted;
    mapping(address => uint256) private _totalMintPerAccount;
    mapping(address => uint256) private _totalWhitelistMintPerAccount;

    address private _signerPublicKey =
        0xCF51b6eD0f603A2dF78b66ccDD192d5D0638b0aF;

    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("Flappiez", "FLAPPIEZ") EIP712("Flappiez", "1.0.0") {}

    function mint(uint256 amount) external payable {
        require(isPublicSalesActive(), "Public sales is not active");
        require(totalSupply() < maxSupply, "Sold out");
        require(
            totalSupply() + amount <= maxSupply,
            "Amount exceeds max supply"
        );
        require(amount > 0, "Invalid amount");
        require(msg.value >= amount * normalMintPrice, "Insufficient funds!");
        require(
            amount + _totalMintPerAccount[msg.sender] <= maxMintPerAccount,
            "Max NFTs per account reached"
        );

        totalNormalMint += amount;
        _totalMintPerAccount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
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
        require(
            amount + _totalMintPerAccount[msg.sender] <= maxMintPerAccount,
            "Max NFTs per account reached"
        );

        if (freeMinted[_msgSender()] || totalWhitelistMint >= maxWhitelistSupply) {
            require(
                amount + totalNormalMint <= maxSupply,
                "Amount exceeds max supply"
            );

            require(
                msg.value >= amount * normalMintPrice,
                "Insufficient funds!"
            );
        } else {
            require(
                totalWhitelistMint < maxWhitelistSupply,
                "Whitelist reached max supply!"
            );

            require(
                _totalWhitelistMintPerAccount[msg.sender] <=
                    maxWhitelistMintPerAccount,
                "Max free tokens per account reached"
            );

            require(
                msg.value >= normalMintPrice * amount - normalMintPrice,
                "Insufficient funds!"
            );

            freeMinted[_msgSender()] = true;
            totalWhitelistMint += 1;
            _totalWhitelistMintPerAccount[msg.sender] += 1;
        }

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
            _totalMintPerAccount[account] >=
            maxMintPerAccount; 
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
                    abi.encode(keccak256("Flappiez(address account)"), account)
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