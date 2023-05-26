// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import { BitMaps } from "openzeppelin-contracts/utils/structs/BitMaps.sol";
import { ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { ERC721ABurnable } from "ERC721A/extensions/ERC721ABurnable.sol";
import "ERC721A/ERC721A.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/DefaultOperatorFilterer.sol";
import { IERC2981, ERC2981 } from "openzeppelin-contracts/token/common/ERC2981.sol";
import "openzeppelin-contracts/access/AccessControl.sol";
import "./IERC4906.sol";

enum TicketID {
    AllowList
}

contract XEKFH_NTP is ERC721A, ERC721AQueryable, ERC721ABurnable, IERC4906, ERC2981, Ownable, Pausable, DefaultOperatorFilterer, AccessControl {
    using BitMaps for BitMaps.BitMap;
    string private baseURI = "ar://qRqCup1u2SF0XmS90D_jVQvrNBJCz0CorD-3HNdfLu0/";
    bytes32 public constant DELEGATOR_ROLE = keccak256("DELEGATOR_ROLE");

    bool public publicSale = false;
    uint256 public publicCost = 0.08 ether;

    bool public mintable = false;

    uint256 public constant MAX_SUPPLY = 222;
    address private constant FUND_ADDRESS = 0x868103596533b2E305A560785eF2d9242f475422;
    address private constant ROYALITY_ADDRESS = 0x24c6dcfD4A5cBc35b22F474803dB9C0305E8Eb41;
    string private constant BASE_EXTENSION = ".json";
    uint256 private constant PUBLIC_MAX_PER_TX = 5;
    uint256 private constant PRE_MAX_CAP = 20;

    mapping(uint256 => string) public metadataURI;
    BitMaps.BitMap private claimed;

    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(TicketID => mapping(address => uint256)) public whiteListClaimed;

    constructor(bool mintERC2309Flg) ERC721A("XEKFH_NTP", "XEKFHNTP") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        _grantRole(DEFAULT_ADMIN_ROLE, 0x73FcB275B2840387f10a619216887ae85Cbc84BE);
        _setDefaultRoyalty(ROYALITY_ADDRESS, 1000);
        if (mintERC2309Flg == true) {
            _mintERC2309(owner(), 2);
        }
    }

    modifier whenMintable() {
        require(mintable == true, "Mintable: paused");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(metadataURI[tokenId]).length == 0) {
            return string(abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION));
        } else {
            return metadataURI[tokenId];
        }
    }

    function setTokenMetadataURI(uint256 tokenId, string memory metadata) external onlyRole(DEFAULT_ADMIN_ROLE) {
        metadataURI[tokenId] = metadata;
        emit MetadataUpdate(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot, TicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot[ticket] = _merkleRoot;
    }

    function publicMint(address _to, uint256 _mintAmount) external payable whenNotPaused whenMintable {
        uint256 cost = publicCost * _mintAmount;
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
        require(publicSale, "Public Sale is not Active.");
        require(_mintAmount <= PUBLIC_MAX_PER_TX, "Mint amount over");

        _mint(_to, _mintAmount);
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        TicketID ticket
    ) external payable whenMintable whenNotPaused {
        uint256 cost = presaleCost[ticket] * _mintAmount;
        require(_presaleMax <= PRE_MAX_CAP, "presale max can not exceed");
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
        require(presalePhase[ticket], "Presale is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf), "Invalid Merkle Proof");
        require(whiteListClaimed[ticket][msg.sender] + _mintAmount <= _presaleMax, "Already claimed max");

        _mint(msg.sender, _mintAmount);
        whiteListClaimed[ticket][msg.sender] += _mintAmount;
    }

    function ownerMint(address _address, uint256 count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(count > 0, "Mint amount is zero");
        _safeMint(_address, count);
    }

    function setPresalePhase(bool _state, TicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[ticket] = _state;
    }

    function setPresaleCost(uint256 _preCost, TicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleCost[ticket] = _preCost;
    }

    function setPublicCost(uint256 _publicCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicCost = _publicCost;
    }

    function setPublicPhase(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSale = _state;
    }

    function setMintable(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintable = _state;
    }

    function setBaseURI(string memory _newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(_startTokenId(), totalSupply());
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(FUND_ADDRESS), address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
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

    function getClaimed(uint256 tokenId) external view returns (bool) {
        return BitMaps.get(claimed, tokenId);
    }

    function setClaimed(uint256 tokenId) external onlyRole(DELEGATOR_ROLE) {
        BitMaps.set(claimed, tokenId);
    }
}