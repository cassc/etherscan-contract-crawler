// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";

contract Reforesta is ERC721A, DefaultOperatorFilterer, Ownable, Pausable {
    string public baseURI;

    uint256 public MAX_SUPPLY = 5000;

    // mint allowance per address
    uint256 public MAX_PER_WHITELIST_ADDRESS = 3;
    uint256 public MAX_PER_AIRDROP_ADDRESS = 3;

    // public sale mint max per tx
    uint256 public MAX_PER_TX = 6;
    uint256 public mintPriceInWei = 0.5 ether;

    // withdrawal variables
    address[] public wallets;
    uint256[] public walletsShares;
    uint256 public totalShares;

    bytes32 public whitelistMerkleRoot;
    bytes32 public airdropMerkleRoot;

    bool public isWhitelistMintOpen;
    bool public isAirdropMintOpen;
    bool public isPublicMintOpen;

    // track number of token minted
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public airdropMinted;

    constructor() ERC721A("Reforesta", "RFS") {}

    //==================================
    //   MINT FUNC
    //==================================

    /**
     * @notice Mint for whitelist addresses
     * @dev Allow whitelist address to mint token not greater than on MAX_PER_WHITELIST_ADDRESS limit
     * @param _numberOfTokenToMint The number of token to mint
     * @param _proof The address proof
     */
    function whitelistMint(
        uint256 _numberOfTokenToMint,
        bytes32[] calldata _proof
    ) external payable {
        require(isWhitelistMintOpen, "Not yet open.");

        require(
            _verifySenderProof(_msgSender(), whitelistMerkleRoot, _proof),
            "invalid proof"
        );

        require(
            whitelistMinted[_msgSender()] + _numberOfTokenToMint <=
                MAX_PER_WHITELIST_ADDRESS,
            "Exceed max whitelist allowance"
        );
        require(
            _numberOfTokenToMint * mintPriceInWei == msg.value,
            "Invalid funds provided."
        );
        whitelistMinted[_msgSender()] += _numberOfTokenToMint;

        _safeMint(_msgSender(), _numberOfTokenToMint);
    }

    /**
     * @notice Mint the number of token not greater than MAX_PER_TX
     * @param count The number of token to mint
     */
    function publicMint(uint256 count) public payable {
        require(isPublicMintOpen, "Not yet open.");

        uint256 totalSupply = _totalMinted();
        require(totalSupply + count <= MAX_SUPPLY, "Exceeds max supply.");
        require(count <= MAX_PER_TX, "Exceeds max per transaction.");
        require(count * mintPriceInWei == msg.value, "Invalid funds provided.");

        _safeMint(_msgSender(), count);
    }

    /**
     * @notice Mint for airdop addresses
     * @dev Allow whitelist address to mint token not greater than on MAX_PER_WHITELIST_ADDRESS limit
     * @param _numberOfTokenToMint The number of token to mint
     * @param _proof The address proof
     */
    function airdropMint(
        uint256 _numberOfTokenToMint,
        bytes32[] calldata _proof
    ) external {
        require(isAirdropMintOpen, "Not yet open");

        uint256 totalSupply = _totalMinted();
        require(
            totalSupply + _numberOfTokenToMint <= MAX_SUPPLY,
            "Exceeds max supply."
        );

        require(
            _verifySenderProof(_msgSender(), airdropMerkleRoot, _proof),
            "invalid proof"
        );

        require(
            airdropMinted[_msgSender()] + _numberOfTokenToMint <=
                MAX_PER_AIRDROP_ADDRESS,
            "Exceed max whitelist allowance"
        );

        airdropMinted[_msgSender()] += _numberOfTokenToMint;

        _safeMint(_msgSender(), _numberOfTokenToMint);
    }

    //==================================
    //   Only Owner Access
    //==================================

    /**
     * @dev Set new mint price
     * @param _mintPriceInWei The new mint price
     */
    function setMintPrice(uint256 _mintPriceInWei) external onlyOwner {
        mintPriceInWei = _mintPriceInWei;
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        MAX_SUPPLY = maxSupply;
    }

    /**
     * @dev Set limit that whitelist address can mint
     * @param _whitelistMintLimit The mint limit per whitelist address
     */
    function setMaxMintPerWhitelist(
        uint256 _whitelistMintLimit
    ) external onlyOwner {
        MAX_PER_WHITELIST_ADDRESS = _whitelistMintLimit;
    }

    /**
     * @dev Set limit that airdop address can mint
     * @param _airdopMintLimit The mint limit per airdrop address
     */
    function setMaxMintPerAirdrop(uint256 _airdopMintLimit) external onlyOwner {
        MAX_PER_AIRDROP_ADDRESS = _airdopMintLimit;
    }

    /**
     * @dev Set limit mint per tx on public sale
     * @param _mintMaxPerTx The number of mint per tx
     */
    function setMaxPerTxMint(uint256 _mintMaxPerTx) external onlyOwner {
        MAX_PER_TX = _mintMaxPerTx;
    }

    function toggleWhitelistMintState() external onlyOwner {
        isWhitelistMintOpen = !isWhitelistMintOpen;
    }

    function toggleAirdopMintState() external onlyOwner {
        isAirdropMintOpen = !isAirdropMintOpen;
    }

    function togglePublicMintState() external onlyOwner {
        isPublicMintOpen = !isPublicMintOpen;
    }

    /**
     * @notice Allow owner to pause token transfer
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Allow owner to unpause token transfer
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Set whitelist address
     * @param _whitelistMerkleRoot The merkle root of whitelist addresses
     */
    function setWhitelistMerkleRoot(
        bytes32 _whitelistMerkleRoot
    ) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    /**
     * @dev Set whitelist address
     * @param _airdropMerkleRoot The merkle root of airdrop addresses
     */
    function setAirdropMerkleRoot(
        bytes32 _airdropMerkleRoot
    ) external onlyOwner {
        airdropMerkleRoot = _airdropMerkleRoot;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    // === Withdrawal ===

    /// @dev Set wallets shares
    /// @param _wallets The wallets
    /// @param _walletsShares The wallets shares
    function setWithdrawalInfo(
        address[] memory _wallets,
        uint256[] memory _walletsShares
    ) public onlyOwner {
        require(_wallets.length == _walletsShares.length, "not equal");
        wallets = _wallets;
        walletsShares = _walletsShares;

        totalShares = 0;
        for (uint256 i = 0; i < _walletsShares.length; i++) {
            totalShares += _walletsShares[i];
        }
    }

    /// @dev Withdraw contract native token balance
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "no eth to withdraw");
        uint256 totalReceived = address(this).balance;
        for (uint256 i = 0; i < walletsShares.length; i++) {
            uint256 payment = (totalReceived * walletsShares[i]) / totalShares;
            Address.sendValue(payable(wallets[i]), payment);
        }
    }

    //==================================
    //   Internal Function
    //==================================

    function _verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function _verifySenderProof(
        address sender,
        bytes32 merkleRoot,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender));
        return _verify(proof, merkleRoot, leaf);
    }

    //==================================
    //   Override Function
    //==================================

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "paused token transfer");
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

    receive() external payable {}
}