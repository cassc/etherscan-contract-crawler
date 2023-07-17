// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Base64.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Pausable.sol";
import { ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { ERC721ABurnable } from "ERC721A/extensions/ERC721ABurnable.sol";
import "ERC721A/ERC721A.sol";
import "./IERC4906.sol";
import "ERC721A/extensions/ERC4907A.sol";
import "openzeppelin-contracts/access/AccessControl.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import { IERC2981, ERC2981 } from "openzeppelin-contracts/token/common/ERC2981.sol";
import { OperatorFilterer } from "closedsea/OperatorFilterer.sol";

enum Ticket {
    Yellow,
    LightBlue,
    Green,
    Purple,
    Red,
    DarkBlue,
    White,
    Black
}

contract DAAAMO is ERC721A, ERC4907A, OperatorFilterer, ERC721AQueryable, IERC4906, ERC721ABurnable, ERC2981, Ownable, Pausable, AccessControl {
    string private baseURI = "https://arweave.net/1rINT2KayKeY1tM9bIXTMheBULXtBiGbIxz7o0aeXcI/";
    string private baseAnimationURI = "ar://BOop4RnqhN5Mm6mPGsvmXL00q3CsFq-IYJ3o7thaHPA/";

    bool public publicSale = false;
    uint256 public publicCost = 0.03 ether;
    bool public mintable = false;
    Ticket public publicTicket = Ticket.LightBlue;
    bool public operatorFilteringEnabled;

    string private description;
    string private imageSuffix = ".png";
    string private animationSuffix = ".mp4";

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 private constant PUBLIC_MAX_PER_TX = 10;
    uint256 private constant PRE_MAX_CAP = 20;

    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(Ticket => uint256) public presaleCost;
    mapping(Ticket => bool) public presalePhase;
    mapping(Ticket => uint256) public presaleMaxMint;
    mapping(Ticket => uint256) public presaleMinted;
    mapping(Ticket => bytes32) public merkleRoot;
    /* DAAAMO KEY の色 */
    mapping(uint256 => Ticket) public tokenTicket;
    mapping(Ticket => mapping(address => uint256)) public whiteListClaimed;

    mapping(uint256 => string) public metadataURI;

    /* ticketの情報 */
    string[8] public _ticketName;

    constructor() ERC721A("DAAAMO", "DAAAMO") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        _grantRole(MINTER_ROLE, owner());
        _setDefaultRoyalty(owner(), 1000);

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _mintERC2309(0x461e2D287640D1417E77a1baa7Efef6b9d9D3219, 200);

        _ticketName = ["Yellow", "LightBlue", "Green", "Purple", "Red", "DarkBlue", "White", "Black"];
    }

    modifier whenMintable() {
        require(mintable == true, "Mintable: paused");
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "nonexsitent token");
        if (bytes(metadataURI[tokenId]).length == 0) {
            return _createJson(tokenId);
        } else {
            return metadataURI[tokenId];
        }
    }

    /* solhint-disable quotes */
    function _createJson(uint256 tokenId) internal view virtual returns (string memory) {
        bytes memory bytesName = abi.encodePacked('"name":"DAAAMO-KEY #', Strings.toString(tokenId), '"');

        bytes memory bytesDesc = abi.encodePacked('"description":"', description, '"');

        bytes memory bytesImage = abi.encodePacked('"image":"', _baseURI(), _ticketName[uint256(tokenTicket[tokenId])], imageSuffix, '"');

        bytes memory bytesAnimationURL = abi.encodePacked('"animation_url":"', baseAnimationURI, _ticketName[uint256(tokenTicket[tokenId])], animationSuffix, '"');

        bytes memory bytesObject = abi.encodePacked("{", bytesName, ",", bytesDesc, ",", bytesImage, ",", bytesAnimationURL, "}");

        bytes memory bytesMetadata = abi.encodePacked("data:application/json;base64,", Base64.encode(bytesObject));

        return (string(bytesMetadata));
    }

    /* solhint-enable quotes */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot, Ticket ticket) external onlyRole(MINTER_ROLE) {
        merkleRoot[ticket] = _merkleRoot;
    }

    function setTokenMetadataURI(uint256 tokenId, string memory metadata) external onlyRole(MINTER_ROLE) {
        metadataURI[tokenId] = metadata;
        emit MetadataUpdate(tokenId);
    }

    function setPublicTicket(Ticket ticket) external onlyRole(MINTER_ROLE) {
        publicTicket = ticket;
    }

    function setDescription(string memory _description) external onlyRole(MINTER_ROLE) {
        description = _description;
    }

    function setImageSuffix(string memory _suffix) external onlyRole(MINTER_ROLE) {
        imageSuffix = _suffix;
    }

    function publicMint(uint256 _mintAmount) external payable whenNotPaused whenMintable {
        uint256 cost = publicCost * _mintAmount;
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(_totalMinted() + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
        require(publicSale, "Public Sale is not Active.");
        require(_mintAmount <= PUBLIC_MAX_PER_TX, "Mint amount over");
        _mintWithCategory(msg.sender, _mintAmount, publicTicket);
    }

    function _mintWithCategory(address sender, uint256 amount, Ticket ticket) private {
        uint256 currentIndex = _nextTokenId();
        _safeMint(sender, amount);
        unchecked {
            for (uint256 i = currentIndex; i < currentIndex + amount; ++i) {
                tokenTicket[i] = ticket;
            }
        }
    }

    function preMint(uint256 _mintAmount, uint256 _presaleMax, bytes32[] calldata _merkleProof, Ticket ticket) external payable whenMintable whenNotPaused {
        uint256 cost = presaleCost[ticket] * _mintAmount;
        require(_presaleMax <= PRE_MAX_CAP, "presale max can not exceed");
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(_totalMinted() + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
        require(presalePhase[ticket], "Presale is not active.");
        require(presaleMinted[ticket] + _mintAmount <= presaleMaxMint[ticket], "PresaleMaxMint over");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf), "Invalid Merkle Proof");
        require(whiteListClaimed[ticket][msg.sender] + _mintAmount <= _presaleMax, "Already claimed max");

        _mintWithCategory(msg.sender, _mintAmount, ticket);
        unchecked {
            whiteListClaimed[ticket][msg.sender] += _mintAmount;
            presaleMinted[ticket] += _mintAmount;
        }
    }

    function ownerMint(address _address, uint256 count, Ticket ticket) external onlyRole(MINTER_ROLE) {
        require(count > 0, "Mint amount is zero");
        require(_totalMinted() + count <= MAX_SUPPLY, "MAXSUPPLY over");
        _mintWithCategory(_address, count, ticket);
    }

    function setPresalePhase(bool _state, Ticket ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[ticket] = _state;
    }

    function setPresaleMaxMint(uint256 _preMaxMint, Ticket ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleMaxMint[ticket] = _preMaxMint;
    }

    function setPresaleCost(uint256 _preCost, Ticket ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
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
        emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function withdraw(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(_address), address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC4907A, AccessControl, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || ERC4907A.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}