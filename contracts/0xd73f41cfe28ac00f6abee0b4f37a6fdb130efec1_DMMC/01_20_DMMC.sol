// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract DMMC is
    Initializable,
    DefaultOperatorFiltererUpgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using StringsUpgradeable for uint256;

    uint256 public constant PRIVATE_MINT_SUPPLY = 1000;
    uint256 public constant WHITELIST_MINT_MAX_SUPPLY = 4000;
    uint256 public constant PUBLIC_MINT_MAX_SUPPLY = 5995;

    string public baseURI;
    string public baseExtension;

    uint256 public whitelistMintCost;
    uint256 public publicMintCost;

    bool public isWhitelistMintActive;
    bool public isPublicMintActive;

    bytes32 public whitelistMerkleRoot;

    uint256 public maxMintPerTx;

    function initialize() public initializer {
        __ERC721_init("Drunken Monkey Members Club", "DMMC");
        __Ownable_init();

        baseURI = "https://api.dmmc.app/metadata/";
        baseExtension = ".json";

        whitelistMintCost = 1 ether;
        publicMintCost = 2 ether;

        isWhitelistMintActive = false;
        isPublicMintActive = false;

        whitelistMerkleRoot = "";

        maxMintPerTx = 5;
    }

    // Modifiers

    modifier whitelistPausedCompliance() {
        require(isWhitelistMintActive, "Whitelist minting is currently paused");
        _;
    }

    modifier publicPausedCompliance() {
        require(isPublicMintActive, "Public minting is currently paused");
        _;
    }

    modifier whitelistAmountCompliance(uint256 _value, uint256 _amount) {
        require(
            _value >= _amount * whitelistMintCost,
            "Insufficient funds sent"
        );
        _;
    }

    modifier publicAmountCompliance(uint256 _value, uint256 _amount) {
        require(_value >= _amount * publicMintCost, "Insufficient funds sent");
        _;
    }

    modifier maxAmountPerTxCompliance(uint256 _amount) {
        require(
            _amount <= maxMintPerTx,
            "Amount exceeds limit per transaction"
        );
        _;
    }

    modifier isValidMerkleProof(
        bytes32[] calldata _merkleProof,
        bytes32 _root,
        address _recipient
    ) {
        require(
            MerkleProof.verify(
                _merkleProof,
                _root,
                keccak256(abi.encodePacked(_recipient))
            ),
            "Whitelist merkle proof is invalid"
        );
        _;
    }

    // Mint

    function whitelistMint(
        uint256 _amount,
        address _recipient,
        bytes32[] calldata _merkleProof
    )
        public
        payable
        whitelistPausedCompliance
        whitelistAmountCompliance(msg.value, _amount)
        maxAmountPerTxCompliance(_amount)
        isValidMerkleProof(_merkleProof, whitelistMerkleRoot, _recipient)
    {
        uint256 supply = totalSupply();
        require(
            supply + _amount <= WHITELIST_MINT_MAX_SUPPLY,
            "Insufficient supply remaining"
        );

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_recipient, supply + i);
        }
    }

    function publicMint(
        uint256 _amount,
        address _recipient
    )
        public
        payable
        publicPausedCompliance
        publicAmountCompliance(msg.value, _amount)
        maxAmountPerTxCompliance(_amount)
    {
        uint256 supply = totalSupply();
        require(
            supply + _amount <= PUBLIC_MINT_MAX_SUPPLY,
            "Insufficient supply remaining"
        );

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_recipient, supply + i);
        }
    }

    // Airdrop

    function airdropByIds(
        uint256[] calldata _ids,
        address _recipient
    ) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            _safeMint(_recipient, _ids[i]);
        }
    }

    function airdropByAmount(
        uint256 _amount,
        address _recipient
    ) public onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + _amount <= PUBLIC_MINT_MAX_SUPPLY,
            "Insufficient supply remaining"
        );

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(_recipient, supply + i);
        }
    }

    // ERC721

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Setters

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setWhitelistMintCost(uint256 _whitelistMintCost) public onlyOwner {
        whitelistMintCost = _whitelistMintCost;
    }

    function setPublicMintCost(uint256 _publicMintCost) public onlyOwner {
        publicMintCost = _publicMintCost;
    }

    function setIsWhitelistMintActive(
        bool _isWhitelistMintActive
    ) public onlyOwner {
        isWhitelistMintActive = _isWhitelistMintActive;
    }

    function setIsPublicMintActive(bool _isPublicMintActive) public onlyOwner {
        isPublicMintActive = _isPublicMintActive;
    }

    function setWhitelistMerkleRoot(
        bytes32 _whitelistMerkleRoot
    ) public onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    // Withdraw

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }
}