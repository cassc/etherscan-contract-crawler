// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract DininhoPets is ERC721AQueryable, ERC721ABurnable, EIP712, Ownable {
    uint public maxSupply = 3333;
    uint public normalMintPrice = 0.001 ether;
    uint public maxNormalMintPerAccount = 3;
    uint public publicSalesTimestamp = 1670496400;

    mapping(address => uint) private _totalNormalMintPerAccount;
    mapping(address => bool) private _whitelistMintNonces;
    address private _signerPublicKey = 0x06890C0A9CEEC665435cffe3D27cAdb907d33603;
    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("Dininho Pets", "DNP") EIP712("DininhoPets", "1.0.0") {
    }

    function mint(uint amount) external payable {
        require(totalSupply() < maxSupply, "sold out");
        require(isPublicSalesActive(), "sales is not active");
        require(amount > 0, "invalid amount");
        require(msg.value >= amount * normalMintPrice, "invalid mint price");
        require(amount + totalSupply() <= maxSupply, "amount exceeds max supply");
        require(amount + _totalNormalMintPerAccount[msg.sender] <= maxNormalMintPerAccount, "max tokens per account reached");

        _totalNormalMintPerAccount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function whitelistMint(uint amount, bytes calldata signature) external {
        require(_recoverAddress(msg.sender, amount, signature) == _signerPublicKey, "account is not whitelisted");
        require(amount + totalSupply() <= maxSupply, "amount exceeds max supply");
        require(!hasMintedUsingWhitelist(msg.sender), "already minted using whitelist");

        _whitelistMintNonces[msg.sender] = true;
        _safeMint(msg.sender, amount);
    }

    function isPublicSalesActive() public view returns (bool) {
        return publicSalesTimestamp <= block.timestamp;
    }

    function hasMintedUsingWhitelist(address account) public view returns (bool) {
        return _whitelistMintNonces[account];
    }

    function totalNormalMintPerAccount(address account) public view returns (uint) {
        return _totalNormalMintPerAccount[account];
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

    function setMaxSupply(uint maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setNormalMintPrice(uint normalMintPrice_) external onlyOwner {
        normalMintPrice = normalMintPrice_;
    }

    function setMaxNormalMintPerAccount(uint maxNormalMintPerAccount_) external onlyOwner {
        maxNormalMintPerAccount = maxNormalMintPerAccount_;
    }

    function setPublicSalesTimestamp(uint timestamp) external onlyOwner {
        publicSalesTimestamp = timestamp;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _hash(address account, uint amount) private view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("DininhoPets(address account,uint256 amount)"),
                    account,
                    amount
                )
            )
        );
    }

    function _recoverAddress(address account, uint amount, bytes calldata signature) private view returns (address) {
        return ECDSA.recover(_hash(account, amount), signature);
    }
}