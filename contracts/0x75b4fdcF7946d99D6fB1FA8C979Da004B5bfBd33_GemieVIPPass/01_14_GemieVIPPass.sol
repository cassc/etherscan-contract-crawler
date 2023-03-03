// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract GemieVIPPass is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {
    error WhitelistQuotaReached();
    error MaxSupplyReached();
    error AlreadyMinted();
    error InvalidMintingSchedule();
    error WhitelistMintingNotAvailable();
    error PublicMintingNotAvailable();
    error AddressNotInWhitelist();

    uint256 public constant MAX_SUPPLY = 1000;
    string private baseTokenURI;
    mapping(address => bool) public hasMinted;
    uint32 private whitelistMintStartTime = 1678104000;
    uint32 private whitelistMintEndTime = 1678190400;
    uint32 private publicMintStartTime = 1678190401;
    uint32 private publicMintEndTime = 1678795200;
    bytes32 public whitelistMerkleRoot;
    uint256 public whitelistQuota = 450;
    uint256 public whitelistMinted;

    constructor() ERC721A("GemieVIPPass", "GVP") {
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    modifier onlySupplyAvailable(uint256 _quantity) {
        if (totalSupply() + _quantity > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        _;
    }

    modifier onlyHasNotMinted() {
        if (hasMinted[msg.sender]) {
            revert AlreadyMinted();
        }
        _;
    }

    function setMintingSchedule(
        uint32 _whitelistMintStartTime,
        uint32 _whitelistMintEndTime,
        uint32 _publicMintStartTime,
        uint32 _publicMintEndTime
    ) external onlyOwner {
        if (
            _whitelistMintStartTime >= _whitelistMintEndTime ||
            _publicMintStartTime >= _publicMintEndTime
        ) {
            revert InvalidMintingSchedule();
        }

        whitelistMintStartTime = _whitelistMintStartTime;
        whitelistMintEndTime = _whitelistMintEndTime;
        publicMintStartTime = _publicMintStartTime;
        publicMintEndTime = _publicMintEndTime;
    }

    function mintingSchedule()
        external
        view
        returns (uint32, uint32, uint32, uint32)
    {
        return (
            whitelistMintStartTime,
            whitelistMintEndTime,
            publicMintStartTime,
            publicMintEndTime
        );
    }

    function setWhitelistQuota(uint256 _whitelistQuota) external onlyOwner {
        if (_whitelistQuota > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        whitelistQuota = _whitelistQuota;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public {
        baseTokenURI = _baseTokenURI;
    }

    function devMint(
        address _recipient,
        uint256 _quantity
    ) external onlyOwner onlySupplyAvailable(_quantity + whitelistQuota) {
        _mint(_recipient, _quantity);
    }

    function airdrop(
        address[] calldata _recipients,
        uint256 _quantity
    )
        external
        onlyOwner
        onlySupplyAvailable(_quantity * _recipients.length + whitelistQuota)
    {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _quantity);
        }
    }

    function whitelistMint(
        bytes32[] calldata _merkleProof
    ) external onlyHasNotMinted {
        if (whitelistMinted + 1 > whitelistQuota) {
            revert WhitelistQuotaReached();
        }

        if (
            block.timestamp < whitelistMintStartTime ||
            block.timestamp > whitelistMintEndTime
        ) {
            revert WhitelistMintingNotAvailable();
        }

        if (
            !MerkleProof.verify(
                _merkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert AddressNotInWhitelist();
        }

        hasMinted[msg.sender] = true;
        whitelistMinted += 1;
        _mint(msg.sender, 1);
    }

    function publicMint() external onlyHasNotMinted onlySupplyAvailable(1) {
        if (
            block.timestamp < publicMintStartTime ||
            block.timestamp > publicMintEndTime
        ) {
            revert PublicMintingNotAvailable();
        }

        hasMinted[msg.sender] = true;
        _mint(msg.sender, 1);
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

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}