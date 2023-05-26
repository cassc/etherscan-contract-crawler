// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title: SlumStars
/// @author: HayattiQ (NFTBoil)

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Pausable.sol";
import { ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { ERC721ABurnable } from "ERC721A/extensions/ERC721ABurnable.sol";
import "ERC721A/ERC721A.sol";
import "ERC721A/extensions/ERC4907A.sol";
import "openzeppelin-contracts/access/AccessControl.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/RevokableDefaultOperatorFilterer.sol";
import { UpdatableOperatorFilterer } from "operator-filter-registry/UpdatableOperatorFilterer.sol";
import { IERC2981, ERC2981 } from "openzeppelin-contracts/token/common/ERC2981.sol";

enum TicketID {
    AllowList,
    FamilySale
}

contract KunoichiGakuenOrigin is ERC721A, ERC4907A, ERC721AQueryable, ERC721ABurnable, ERC2981, Ownable, Pausable, AccessControl, RevokableDefaultOperatorFilterer {
    using Strings for uint256;

    string private baseURI = "ar://wOdAb4QIL5lRiQgbh5EsCJbCHn2I_Kzu3Zw5IJcf_Ss/";

    bool public publicSale = false;
    uint256 public publicCost = 0.03 ether;

    bool public mintable = false;

    uint256 public constant MAX_SUPPLY = 5000;
    string private constant BASE_EXTENSION = ".json";
    uint256 private constant PUBLIC_MAX_PER_TX = 10;
    uint256 private constant PRE_MAX_CAP = 20;

    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DELEGATOR_ROLE = keccak256("DELEGATOR_ROLE");

    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(TicketID => mapping(address => uint256)) public whiteListClaimed;

    mapping(uint256 => string) metadataURI;

    constructor() ERC721A("KunoichiGakuenOrigin", "KUNOICHI") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _setDefaultRoyalty(0xA20d63131210dAEA56BF99A660d9599ec78dF54D, 1000);
        _mintERC2309(0xA20d63131210dAEA56BF99A660d9599ec78dF54D, 100);
    }

    modifier whenMintable() {
        require(mintable == true, "Mintable: paused");
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // internal
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

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot, TicketID ticket) external onlyOwner {
        merkleRoot[ticket] = _merkleRoot;
    }

    function setTokenMetadataURI(uint256 tokenId, string memory metadata) external onlyRole(DELEGATOR_ROLE) {
        metadataURI[tokenId] = metadata;
    }

    function publicMint(uint256 _mintAmount) external payable whenNotPaused callerIsUser whenMintable {
        uint256 cost = publicCost * _mintAmount;
        mintCheck(_mintAmount, cost);
        require(publicSale, "Public Sale is not Active.");
        require(_mintAmount <= PUBLIC_MAX_PER_TX, "Mint amount over");

        _mint(msg.sender, _mintAmount);
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        TicketID ticket
    ) external payable whenMintable callerIsUser whenNotPaused {
        uint256 cost = presaleCost[ticket] * _mintAmount;
        require(_presaleMax <= PRE_MAX_CAP, "presale max can not exceed");
        mintCheck(_mintAmount, cost);
        require(presalePhase[ticket], "Presale is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf), "Invalid Merkle Proof");
        require(whiteListClaimed[ticket][msg.sender] + _mintAmount <= _presaleMax, "Already claimed max");

        _mint(msg.sender, _mintAmount);
        whiteListClaimed[ticket][msg.sender] += _mintAmount;
    }

    function mintCheck(uint256 _mintAmount, uint256 cost) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
    }

    function ownerMint(address _address, uint256 count) external onlyRole(MINTER_ROLE) {
        require(count > 0, "Mint amount is zero");
        require(totalSupply() + count <= MAX_SUPPLY, "MAXSUPPLY over");
        _safeMint(_address, count);
    }

    function setPresalePhase(bool _state, TicketID ticket) external onlyOwner {
        presalePhase[ticket] = _state;
    }

    function setPresaleCost(uint256 _preCost, TicketID ticket) external onlyOwner {
        presaleCost[ticket] = _preCost;
    }

    function setPublicCost(uint256 _publicCost) external onlyOwner {
        publicCost = _publicCost;
    }

    function setPublicPhase(bool _state) external onlyOwner {
        publicSale = _state;
    }

    function setMintable(bool _state) external onlyOwner {
        mintable = _state;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external {
        Address.sendValue(payable(0xA20d63131210dAEA56BF99A660d9599ec78dF54D), address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC4907A, AccessControl, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId) || ERC4907A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
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

    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
}