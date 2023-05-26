// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import { ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { ERC721ABurnable } from "ERC721A/extensions/ERC721ABurnable.sol";
import "ERC721A/ERC721A.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/DefaultOperatorFilterer.sol";
import { IERC2981, ERC2981 } from "openzeppelin-contracts/token/common/ERC2981.sol";

enum TicketID {
    AllowList1,
    AllowList2
}

contract Tougenkyou is ERC721A, ERC721AQueryable, ERC721ABurnable, ERC2981, Ownable, Pausable, DefaultOperatorFilterer {
    using Strings for uint256;

    string private baseURI = "ar://DO3K5VGKt20yIpJlDVe4T-ZENylKtdoh6R8WdiJKvmE/";

    bool public publicSale = false;
    bool public callerIsUserFlg = false;
    uint256 public publicCost = 0.08 ether;

    bool public mintable = false;

    uint256 public constant MAX_SUPPLY = 3000;
    string private constant BASE_EXTENSION = ".json";
    uint256 private constant PUBLIC_MAX_PER_TX = 3;
    uint256 private constant PRE_MAX_CAP = 20;

    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(TicketID => mapping(address => uint256)) public whiteListClaimed;

    constructor(bool mintERC2309Flg) ERC721A("Tougenkyou", "MOMO") {
        _setDefaultRoyalty(0x37df2D6523265a68975e2429e74E841d524b6BB9, 1000);
        if (mintERC2309Flg == true) {
            _mintERC2309(0x0495F6b0C4273E233DFd48D5AFE347ef7Ee595BA, 198);
            _initializeOwnershipAt(50);
            _initializeOwnershipAt(100);
            _initializeOwnershipAt(150);
        }
    }

    modifier whenMintable() {
        require(mintable == true, "Mintable: paused");
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        if (callerIsUserFlg == true) {
            require(tx.origin == msg.sender, "The caller is another contract");
        }
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION));
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

    function setCallerIsUserFlg(bool flg) external onlyOwner {
        callerIsUserFlg = flg;
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

    function ownerMint(address _address, uint256 count) external onlyOwner {
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

    function withdraw() external onlyOwner {
        Address.sendValue(payable(0x37df2D6523265a68975e2429e74E841d524b6BB9), address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
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
}