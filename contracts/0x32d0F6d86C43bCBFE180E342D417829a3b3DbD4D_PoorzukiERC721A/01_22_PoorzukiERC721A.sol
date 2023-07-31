// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import "erc721a/contracts/ERC721A.sol";

contract PoorzukiERC721A is
    Ownable,
    PaymentSplitter,
    ERC2981,
    DefaultOperatorFilterer,
    ERC721A
{
    using Strings for uint256;

    enum Step {
        Before,
        SaleRunning,
        SoldOut,
        Reveal
    }

    struct PoorConfig {
        uint price;
        uint128 maxSupply;
        uint8 maxPerWallet;
        bytes32 merkleRoot;
    }

    struct FudConfig {
        uint price;
        uint8 maxPerWallet;
        bytes32 merkleRoot;
    }

    struct PublicConfig {
        uint price;
        uint8 maxPerWallet;
    }

    struct SaleConfig {
        uint128 maxSupply;
        Step sellingStep;
        string baseURI;
        uint startTime;
        PoorConfig poorConfig;
        FudConfig fudConfig;
        PublicConfig publicConfig;
    }

    SaleConfig public saleConfig;

    mapping(address => uint8) amountNFTperWalletPoor;
    mapping(address => uint8) amountNFTperWalletFud;
    mapping(address => uint8) amountNFTperWalletPublic;

    constructor(
        SaleConfig memory config,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721A("Poorzuki", "PZK") PaymentSplitter(payees, shares) {
        saleConfig = config;
        _setDefaultRoyalty(0x0a8d974601e4697b4441E5bEb8c57D1577072B45, 300);
    }

    function poorMint(
        uint8 quantity,
        bytes32[] calldata proof
    ) external payable {
        require(
            saleConfig.sellingStep == Step.SaleRunning,
            "Sale is not running"
        );
        require(
            block.timestamp >= saleConfig.startTime &&
                block.timestamp < saleConfig.startTime + 1 hours,
            "Sale is not running"
        );
        require(
            amountNFTperWalletPoor[msg.sender] + quantity <=
                saleConfig.poorConfig.maxPerWallet,
            "Max mint exceeded"
        );
        require(
            totalSupply() + uint(quantity) <=
                uint(saleConfig.poorConfig.maxSupply)
        );
        require(isPoorlisted(msg.sender, proof), "Not poorlisted");
        require(
            msg.value >= quantity * saleConfig.poorConfig.price,
            "You poor"
        );

        amountNFTperWalletPoor[msg.sender] += quantity;

        _mint(msg.sender, uint(quantity));
    }

    function fudMint(
        uint8 quantity,
        bytes32[] calldata proof
    ) external payable {
        require(
            saleConfig.sellingStep == Step.SaleRunning,
            "Sale is not running"
        );
        require(
            block.timestamp >= saleConfig.startTime + 1 hours &&
                block.timestamp < saleConfig.startTime + 1 hours + 10 minutes,
            "Sale is not running"
        );
        require(
            amountNFTperWalletFud[msg.sender] + quantity <=
                saleConfig.fudConfig.maxPerWallet,
            "Max mint exceeded"
        );
        require(totalSupply() + uint(quantity) <= uint(saleConfig.maxSupply));
        require(isFudlisted(msg.sender, proof), "Not fudlisted");
        require(msg.value >= quantity * saleConfig.fudConfig.price, "You poor");

        amountNFTperWalletFud[msg.sender] += quantity;

        _mint(msg.sender, uint(quantity));
    }

    function mint(uint8 quantity) external payable {
        require(
            saleConfig.sellingStep == Step.SaleRunning,
            "Sale is not running"
        );
        require(
            block.timestamp >= saleConfig.startTime + 1 hours + 10 minutes,
            "Sale is not running"
        );
        require(
            amountNFTperWalletPublic[msg.sender] + quantity <=
                saleConfig.publicConfig.maxPerWallet,
            "Max mint exceeded"
        );
        require(totalSupply() + uint(quantity) <= uint(saleConfig.maxSupply));
        require(
            msg.value >= quantity * saleConfig.publicConfig.price,
            "You poor"
        );

        amountNFTperWalletPublic[msg.sender] += quantity;

        _mint(msg.sender, uint(quantity));
    }

    function setStep(Step step) external onlyOwner {
        saleConfig.sellingStep = step;
    }

    function setConfig(SaleConfig calldata config) external onlyOwner {
        saleConfig = config;
    }

    function setRoyalties(uint96 bp) external onlyOwner {
        _setDefaultRoyalty(0x0a8d974601e4697b4441E5bEb8c57D1577072B45, bp);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(
        bytes32 _leaf,
        bytes32[] memory _proof,
        bytes32 _merkleRoot
    ) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _merkleRoot, _leaf);
    }

    function isPoorlisted(
        address _account,
        bytes32[] calldata _proof
    ) internal view returns (bool) {
        return
            _verify(leaf(_account), _proof, saleConfig.poorConfig.merkleRoot);
    }

    function isFudlisted(
        address _account,
        bytes32[] calldata _proof
    ) internal view returns (bool) {
        return _verify(leaf(_account), _proof, saleConfig.fudConfig.merkleRoot);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return
            string(
                abi.encodePacked(
                    saleConfig.baseURI,
                    saleConfig.sellingStep == Step.Reveal
                        ? _tokenId.toString()
                        : "prereveal",
                    ".json"
                )
            );
    }

    function releaseAll() external onlyOwner {
        for (uint256 i = 0; i < 4; i++) {
            release(payable(payee(i)));
        }
    }

    function airdrop(address[] calldata receivers) external onlyOwner {
        for (uint32 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], 1);
        }
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

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC2981, ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}