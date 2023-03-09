// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import { ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import "ERC721A/ERC721A.sol";
import { IERC2981, ERC2981 } from "openzeppelin-contracts/token/common/ERC2981.sol";
import "./IERC4906.sol";
import { OperatorFilterer } from "closedsea/OperatorFilterer.sol";
import "openzeppelin-contracts/access/AccessControl.sol";

enum TicketID {
    Wave1,
    Wave2
}

enum BuyerRole {
    Prime,
    Composite,
    AllowList
}

error PreMaxExceed(uint256 _presaleMax);
error MintAmountIsZero();
error MaxSupplyOver();
error NotEnoughFunds(uint256 balance);
error NotMintable();
error InvalidMerkleProof();
error AlreadyClaimedMax();
error MintAmountOver();

contract Nayuta is ERC721A, IERC4906, ERC721AQueryable, OperatorFilterer, AccessControl, ERC2981, Ownable, Pausable {
    uint256 private constant PUBLIC_MAX_PER_TX = 10;
    uint256 private constant PRE_MAX_CAP = 20;
    uint256 public constant MAX_SUPPLY = 6000;
    uint256 private constant MIN_COST = 0.01 ether;
    string private constant BASE_EXTENSION = ".json";
    address private constant FUND_ADDRESS = 0xAAE8d38ED7C80C12743574310c5f1e6c410671CD;
    address private constant DEV_ADDRESS = 0x1B78Cb447EE17357306aEC69122C1937F8Cecb65;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public publicSale = false;
    bool public callerIsUserFlg = false;
    bool public mintable = false;
    bool public operatorFilteringEnabled = true;
    bool public renounceOwnerMintFlag = false;

    uint256 public publicCost = 0.04 ether;
    string private baseURI = "ar://K21aT1SGZthLMFzZoZG8oAx11fJNckQPdAy1nxqyM48/";

    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(TicketID => mapping(address => uint256)) public whiteListClaimed;

    mapping(BuyerRole => uint256) public presaleCost;
    mapping(uint256 => string) private metadataURI;

    constructor(bool _callerIsUserFlg) ERC721A("NAYUTA TOKYO DENNOU R", "NAYUTA") {
        _registerForOperatorFiltering();
        _setDefaultRoyalty(FUND_ADDRESS, 750);
        callerIsUserFlg = _callerIsUserFlg;
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        _grantRole(MINTER_ROLE, owner());
        presaleCost[BuyerRole.Prime] = 0.01 ether;
        presaleCost[BuyerRole.Composite] = 0.03 ether;
        presaleCost[BuyerRole.AllowList] = 0.04 ether;
    }

    modifier whenMintable() {
        if (mintable == false) revert NotMintable();
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

    function setCallerIsUserFlg(bool flg) external onlyRole(DEFAULT_ADMIN_ROLE) {
        callerIsUserFlg = flg;
    }

    function publicMint(address _to, uint256 _mintAmount) external payable whenNotPaused callerIsUser whenMintable {
        if (_mintAmount == 0) revert MintAmountIsZero();
        if (_totalMinted() + _mintAmount > MAX_SUPPLY) revert MaxSupplyOver();
        if (msg.value < publicCost * _mintAmount) revert NotEnoughFunds(msg.value);
        if (!publicSale) revert NotMintable();
        if (_mintAmount > PUBLIC_MAX_PER_TX) revert MintAmountOver();

        _mint(_to, _mintAmount);
    }

    function preMint(
        uint64 _mintAmount,
        uint256 _presaleMax,
        BuyerRole _role,
        bytes32[] calldata _merkleProof,
        TicketID ticket
    ) external payable whenMintable whenNotPaused {
        if (_presaleMax > PRE_MAX_CAP) revert PreMaxExceed(_presaleMax);
        if (_mintAmount == 0) revert MintAmountIsZero();
        if (_totalMinted() + _mintAmount > MAX_SUPPLY) revert MaxSupplyOver();
        if (msg.value < presaleCost[_role] * _mintAmount) revert NotEnoughFunds(msg.value);
        if (msg.value < MIN_COST) revert NotEnoughFunds(msg.value);
        if (!presalePhase[ticket]) revert NotMintable();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax, uint256(_role)));
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf)) revert InvalidMerkleProof();
        if (whiteListClaimed[ticket][msg.sender] + _mintAmount > _presaleMax) revert AlreadyClaimedMax();

        _mint(msg.sender, _mintAmount);
        whiteListClaimed[ticket][msg.sender] += _mintAmount;
    }

    function ownerMint(address _address, uint256 count) external onlyRole(MINTER_ROLE) {
        if (count == 0) revert MintAmountIsZero();
        require(!renounceOwnerMintFlag, "owner mint renounced");
        _safeMint(_address, count);
    }

    function setPresalePhase(bool _state, TicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[ticket] = _state;
    }

    function setPresaleCost(uint256 _preCost, BuyerRole _role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleCost[_role] = _preCost;
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

    function withdraw() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool dev, ) = payable(DEV_ADDRESS).call{ value: (address(this).balance * 75) / 1000 }("");
        require(dev, "no payment");

        (bool fund, ) = payable(FUND_ADDRESS).call{ value: address(this).balance }("");
        require(fund, "no payment");
    }

    function renounceOwnerMint() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        renounceOwnerMintFlag = true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
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

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
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