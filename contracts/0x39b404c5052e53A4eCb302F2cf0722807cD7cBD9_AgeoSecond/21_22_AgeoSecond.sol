// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import { ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { ERC721ABurnable } from "ERC721A/extensions/ERC721ABurnable.sol";
import "ERC721A/ERC721A.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/DefaultOperatorFilterer.sol";
import { IERC2981, ERC2981 } from "openzeppelin-contracts/token/common/ERC2981.sol";
import "./IERC4906.sol";
import "openzeppelin-contracts/access/AccessControl.sol";

enum TicketID {
    FreeMint,
    AllowList,
    SBTSale,
    WaitList
}

error PreMaxExceed(uint256 _presaleMax);
error MaxSupplyOver();
error NotEnoughFunds();
error NotMintable();
error InvalidMerkleProof();
error AlreadyClaimedMax();
error MintAmountOver();

contract AgeoSecond is ERC721A, IERC4906, ERC721AQueryable, AccessControl, ERC721ABurnable, ERC2981, Ownable, DefaultOperatorFilterer {
    string private baseURI = "https://arweave.net/_DgGmYIE9Akg7fhTU3PW_4Uj4KmuZ3QdBaufqmJbdLg/";
    address private constant FUND_ADDRESS = 0x01A28a38738A616B5D90e4a029F0e65FF20cC3c6;
    bool private constant OWNER_MINT_PROTECT_SUPPLY = true;

    bool public publicSale = false;
    bool public callerIsUserFlg = false;
    uint256 public publicCost = 0.04 ether;
    mapping(uint256 => string) private metadataURI;

    bool public mintable = false;

    uint256 public constant MAX_SUPPLY = 650;
    string private constant BASE_EXTENSION = ".json";
    uint256 private constant PUBLIC_MAX_PER_TX = 1;
    uint256 private constant PRE_MAX_CAP = 5;

    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(TicketID => mapping(address => uint256)) public whiteListClaimed;

    constructor(bool _callerIsUserFlg) ERC721A("AgeoSecond", "AGEOSECOND") {
        _setDefaultRoyalty(FUND_ADDRESS, 1000);
        callerIsUserFlg = _callerIsUserFlg;
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        if (_callerIsUserFlg) {
            _mintERC2309(FUND_ADDRESS, 49);
        }
        presaleCost[TicketID.AllowList] = 0.04 ether;
        presaleCost[TicketID.SBTSale] = 0.035 ether;
        presaleCost[TicketID.WaitList] = 0.04 ether;

        presalePhase[TicketID.FreeMint] = true;
        presalePhase[TicketID.AllowList] = true;
        presalePhase[TicketID.SBTSale] = true;
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

    function setCallerIsUserFlg(bool flg) public onlyRole(DEFAULT_ADMIN_ROLE) {
        callerIsUserFlg = flg;
    }

    function publicMint(address _to, uint256 _mintAmount) external payable callerIsUser whenMintable {
        if (_totalMinted() + _mintAmount > MAX_SUPPLY) revert MaxSupplyOver();
        if (msg.value < publicCost * _mintAmount) revert NotEnoughFunds();
        if (!publicSale) revert NotMintable();
        if (_mintAmount > PUBLIC_MAX_PER_TX) revert MintAmountOver();

        _mint(_to, _mintAmount);
    }

    function preMint(uint256 _mintAmount, uint256 _presaleMax, bytes32[] calldata _merkleProof, TicketID ticket) external payable whenMintable callerIsUser {
        if (_presaleMax > PRE_MAX_CAP) revert PreMaxExceed(_presaleMax);
        if (_totalMinted() + _mintAmount > MAX_SUPPLY) revert MaxSupplyOver();
        if (msg.value < presaleCost[ticket] * _mintAmount) revert NotEnoughFunds();
        if (!presalePhase[ticket]) revert NotMintable();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf)) revert InvalidMerkleProof();
        if (whiteListClaimed[ticket][msg.sender] + _mintAmount > _presaleMax) revert AlreadyClaimedMax();

        _mint(msg.sender, _mintAmount);
        whiteListClaimed[ticket][msg.sender] += _mintAmount;
    }

    function mintCheck(uint256 _mintAmount, uint256 cost) private view {
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
    }

    function ownerMint(address _address, uint256 count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(count > 0, "Mint amount is zero");
        require(!OWNER_MINT_PROTECT_SUPPLY || totalSupply() + count <= MAX_SUPPLY, "MAXSUPPLY over");
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

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(FUND_ADDRESS).transfer(balance);
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

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}