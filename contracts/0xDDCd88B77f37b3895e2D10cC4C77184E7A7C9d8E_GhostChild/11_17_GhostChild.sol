// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract GhostChild is
    DefaultOperatorFilterer,
    ERC721A,
    ERC2981,
    Ownable,
    ReentrancyGuard
{
    event BaseURIUpdated(string baseURI);

    using Strings for uint256;
    bool public isRevealed = false;
    uint256 public maxPerTx = 2;
    uint256 public maxSupply = 3333;
    uint256 public maxPerWallet = 2;
    uint256 public price = 0.029 ether;
    bool public isPublicMintEnabled;
    bool public isWhitelistMintEnabled;
    string internal baseTokenURI;
    string public hiddenMetadataUri;
    bytes32 public merkleRoot;

    error MaxSupplyExceeded();

    mapping(address => uint256) public walletMints;

    constructor() ERC721A("Ghost Child", "BONES") {
    }

    function setPublicMintEnabled(bool _PublicMintEnabled) external onlyOwner {
        isPublicMintEnabled = _PublicMintEnabled;
    }

    function setWhitelistMintEnabled(bool _WhitelistMintEnabled) external onlyOwner {
        isWhitelistMintEnabled = _WhitelistMintEnabled;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
        emit BaseURIUpdated(_baseTokenURI);
    }

    function setRevealed(bool _state) public onlyOwner {
    isRevealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (isRevealed == false) {
        return hiddenMetadataUri;
        }

        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function airdrop(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) public onlyOwner nonReentrant {
        uint256 length = _accounts.length;

        for (uint256 i = 0; i < length; ) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];

            if (totalSupply() + amount > maxSupply)
                revert MaxSupplyExceeded();

            _mint(account, amount);

            unchecked {
                i += 1;
            }
        }
    }

    function ownerBatchMint(uint256 _quantity) public onlyOwner nonReentrant {
        uint256 totalMinted = totalSupply();
        require(totalMinted + _quantity <= maxSupply, "sold out");

        _mint(msg.sender, _quantity);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata proof) external payable {
        require(isWhitelistMintEnabled, "minting not enabled");
        uint256 totalMinted = totalSupply();
        require(totalMinted + quantity <= maxSupply, "sold out");
        require(quantity < maxPerTx + 1, "Max per TX reached.");
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Incorrect proof"
        );
        require(msg.value >= quantity * price, "Insuffficient Funds");
        require(
            walletMints[msg.sender] + quantity <= maxPerWallet,
            "exceed max per wallet"
        );

        walletMints[msg.sender] = walletMints[msg.sender] + quantity;
        _mint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable {
        require(isPublicMintEnabled, "minting not enabled");
        uint256 totalMinted = totalSupply();
        require(totalMinted + quantity <= maxSupply, "sold out");
        require(quantity < maxPerTx + 1, "Max per TX reached.");
        require(msg.value >= quantity * price, "Insuffficient Funds");
        require(
            walletMints[msg.sender] + quantity <= maxPerWallet,
            "exceed max per wallet"
        );

        walletMints[msg.sender] = walletMints[msg.sender] + quantity;
        _mint(msg.sender, quantity);
    }

    // ========= VIEW =========

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // ========= ROYALTY =========

    function setRoyaltyInfo(
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // ========= OPERATOR FILTERER OVERRIDES =========

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ========= BURN =========

    function burn(
        uint256 tokenId
    ) 
    
    external {
        _burn(tokenId, true);
    }

}