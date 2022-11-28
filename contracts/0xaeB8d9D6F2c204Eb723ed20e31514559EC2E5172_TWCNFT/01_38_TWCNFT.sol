// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/interfaces/IERC721AUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC2981Upgradeable } from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import { ERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import { DefaultOperatorFiltererUpgradeable } from "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import { Multicall } from "../base/Multicall.sol";
import { Kind } from "../libs/Kind.sol";

interface IMakeCountry {
    function getCountry(Kind.KINDS _kind, uint256 _tokenId) external returns (Kind.COUNTRY);
}

contract TWCNFT is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC2981Upgradeable,
    ERC721AQueryableUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    Multicall
{
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    using ECDSAUpgradeable for bytes32;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint256 private constant PRECISION = 1e18;

    string private _baseTokenURI;

    uint256 public MINT_PRICE;
    uint256 public MINT_WHITE_LIST_PRICE;
    uint256 public MAX_SUPPLY;
    uint256 public WHITE_LIST_TOKENS;
    uint256 public MAX_PER_WALLET;
    uint256 public MAX_PER_TX;

    address public signer;
    address public point;
    address public makeCountry;
    uint256 public lanuchTime;

    struct KindInfo {
        uint256 totalSupply;
        uint256 point;
        uint256 minted;
    }

    struct TokenInfo {
        Kind.KINDS kind;
        Kind.COUNTRY country;
    }

    mapping(Kind.KINDS => KindInfo) public kindInfo;
    mapping(uint256 => TokenInfo) public mintedTokens; // token id => Token
    mapping(address => mapping(Kind.KINDS => uint256)) public mintedKinds;
    mapping(address => uint256) public whiteList;

    event Mint(address _sender, Kind.KINDS _kind, uint256 _tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _point) external initializerERC721A initializer {
        __ERC721A_init("TheWorldCupFi NFT", "TWC");
        __ERC2981_init();
        __Ownable_init();
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        point = _point;

        MAX_PER_TX = 5;
        MAX_PER_WALLET = 5;
        MAX_SUPPLY = 24000;
        MINT_PRICE = 0.05 ether;
        MINT_WHITE_LIST_PRICE = 0.03 ether;

        kindInfo[Kind.KINDS.G0] = KindInfo({ totalSupply: 4800, point: 0, minted: 0 });
        kindInfo[Kind.KINDS.G1] = KindInfo({ totalSupply: 9600, point: 600, minted: 0 });
        kindInfo[Kind.KINDS.G2] = KindInfo({ totalSupply: 4800, point: 1350, minted: 0 });
        kindInfo[Kind.KINDS.G3] = KindInfo({ totalSupply: 4800, point: 3200, minted: 0 });
    }

    function mintWhiteList(uint256 _quantity) external payable nonReentrant whenNotPaused {
        _requireEOA();
        _requireWhiteListTime();
        _requireValidKind(Kind.KINDS.G0, _quantity);
        _requireInWhiteList(msg.sender);
        _requireValidWhiteListQuantity(msg.sender, _quantity);
        _requireValidMaxSupply(_quantity);
        _requireValidMinted(Kind.KINDS.G0, msg.sender, _quantity);
        _requrieValidEnoughEtherForWhiteList(_quantity);

        whiteList[msg.sender] = whiteList[msg.sender] - _quantity;

        uint256 startTokenId = _nextTokenId();

        _mint(msg.sender, _quantity);

        for (uint256 i = 0; i < _quantity; i++) {
            mintedTokens[startTokenId].kind = Kind.KINDS.G0;
            mintedKinds[msg.sender][Kind.KINDS.G0]++;

            kindInfo[Kind.KINDS.G0].minted++;

            if (makeCountry != address(0)) {
                mintedTokens[startTokenId].country = IMakeCountry(makeCountry).getCountry(Kind.KINDS.G0, startTokenId);
            }

            emit Mint(msg.sender, Kind.KINDS.G0, startTokenId);

            startTokenId++;
        }
    }

    function mint(Kind.KINDS _kind, uint256 _quantity) external payable nonReentrant whenNotPaused {
        _requireEOA();
        _requireLanuchTime();
        _requireNonZero(_quantity);
        _requireValidTX(_quantity);
        _requireValidKind(_kind, _quantity);
        _requireValidMaxSupply(_quantity);
        _requireValidMinted(_kind, msg.sender, _quantity);

        if (_kind == Kind.KINDS.G0) {
            _requrieValidEnoughEther(_quantity);
        } else {
            uint256 totalCost = kindInfo[_kind].point * _quantity * PRECISION;

            _requrieValidEnoughPoints(_kind, totalCost);

            IERC20Upgradeable(point).transferFrom(msg.sender, address(this), totalCost);
        }

        uint256 startTokenId = _nextTokenId();

        _mint(msg.sender, _quantity);

        for (uint256 i = 0; i < _quantity; i++) {
            mintedTokens[startTokenId].kind = _kind;
            mintedKinds[msg.sender][_kind]++;

            kindInfo[_kind].minted++;

            if (makeCountry != address(0)) {
                mintedTokens[startTokenId].country = IMakeCountry(makeCountry).getCountry(_kind, startTokenId);
            }

            emit Mint(msg.sender, _kind, startTokenId);

            startTokenId++;
        }
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMakeCountry(address _makeCountry) external onlyOwner {
        makeCountry = _makeCountry;
    }

    function setBaseURI(string calldata _uri) external onlyRole(MANAGER_ROLE) {
        _baseTokenURI = _uri;
    }

    function setLanuchTime(uint256 _time) external onlyRole(MANAGER_ROLE) {
        lanuchTime = _time;
    }

    function setCountry(uint256[] calldata _tokenIds, uint256[] calldata _countries) external onlyRole(MANAGER_ROLE) {
        _setCountrySpec(_tokenIds.length, _countries.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (mintedTokens[_tokenIds[i]].country == Kind.COUNTRY.NONE) {
                mintedTokens[_tokenIds[i]].country = Kind.COUNTRY(_countries[i]);
            }
        }
    }

    function setWhiteList(address[] calldata _users) external onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < _users.length; i++) {
            whiteList[_users[i]] = 3;
        }
    }

    function removeWhiteList(address[] calldata _users) external onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < _users.length; i++) {
            delete whiteList[_users[i]];
        }
    }

    function getKind(uint256 _tokenId) external view returns (Kind.KINDS) {
        return mintedTokens[_tokenId].kind;
    }

    function getCountry(uint256 _tokenId) external view returns (Kind.COUNTRY) {
        return mintedTokens[_tokenId].country;
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function withdraw(address _reciver) external onlyOwner {
        payable(_reciver).transfer(address(this).balance);
    }

    function _authorizeUpgrade(address _newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable, IERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _setCountrySpec(uint256 _tokenIds, uint256 _countries) internal pure {
        require(_tokenIds == _countries, "Tokens mismatch");
    }

    function _requireEOA() internal view {
        require(tx.origin == msg.sender, "Only EOA");
    }

    function _requireNonZero(uint256 _quantity) internal pure {
        require(_quantity > 0, "Quantity must be non-zero");
    }

    function _requireValidTX(uint256 _quantity) internal view {
        require(_quantity <= MAX_PER_TX, "Exceeds max per tx");
    }

    function _requireValidMaxSupply(uint256 _quantity) internal view {
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "Exceeds max supply");
    }

    function _requireValidMinted(
        Kind.KINDS _kind,
        address _sender,
        uint256 _quantity
    ) internal view {
        require(mintedKinds[_sender][_kind] + _quantity <= MAX_PER_WALLET, "Invalid mint quantity");
    }

    function _requireValidWhiteListQuantity(address _sender, uint256 _quantity) internal view {
        require((_quantity > 0) && (_quantity <= 3), "Invalid argment quantity");
        require(_quantity <= whiteList[_sender], "Invalid sender whitelist quantity");
    }

    function _requireValidSignature(bytes calldata _signature) internal view {
        require(keccak256(abi.encode(msg.sender, signer)).toEthSignedMessageHash().recover(_signature) == signer, "Invalid signature");
    }

    function _requireValidKind(Kind.KINDS _kind, uint256 _quantity) internal view {
        require(uint256(_kind) < uint256(Kind.KINDS.NONE), "Invalid kind");
        require(kindInfo[_kind].minted + _quantity <= kindInfo[_kind].totalSupply, "Exceeds kind supply");
    }

    function _requrieValidEnoughEther(uint256 _quantity) internal view {
        require(msg.value >= _quantity * MINT_PRICE, "Not enough ETH to pay for mint");
    }

    function _requrieValidEnoughEtherForWhiteList(uint256 _quantity) internal view {
        require(msg.value >= _quantity * MINT_WHITE_LIST_PRICE, "Not enough ETH to pay for mint");
    }

    function _requrieValidEnoughPoints(Kind.KINDS _kind, uint256 _totalCost) internal view {
        require(uint256(_kind) < uint256(Kind.KINDS.NONE), "Invalid kind");

        require(IERC20Upgradeable(point).balanceOf(msg.sender) >= _totalCost, "Not enough point to pay for mint");
    }

    function _requireInWhiteList(address _sender) internal view {
        require(whiteList[_sender] > 0, "Invalid sender");
    }

    function _requireWhiteListTime() internal view {
        require(lanuchTime > 0 && (block.timestamp >= lanuchTime && block.timestamp <= lanuchTime + 30 minutes), "Invalid lanuch time");
    }

    function _requireLanuchTime() internal view {
        require(lanuchTime > 0 && (block.timestamp > lanuchTime + 30 minutes), "Invalid lanuch time");
    }
}