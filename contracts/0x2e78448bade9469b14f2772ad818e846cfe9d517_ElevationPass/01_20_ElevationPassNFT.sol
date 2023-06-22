//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IElevationPass.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error ExceedingMaxPublicMintsPerWallet(uint16 maxPerWallet);
error ExceedingAllowlistAllowance(uint16 allowlistAllowance);
error InvalidAllowlistTime();
error TokenDoesNotExist(uint16 tokenId);
error MaxTotalSupplyCannotBeLessThanAlreadyMinted();
error NotAllowlisted();
error SaleNotActive();
error InsufficientSupplyAvailable(uint16 maxSupply);
error URIQueryForNonexistentToken();
error NoContracts();

contract ElevationPass is ERC721A, AccessControl, IElevationPass, ReentrancyGuard, OperatorFilterer, Ownable, ERC2981 {
    using Address for address;

    struct Allowlist {
        bytes32 root;
        uint256 startTime;
        uint256 endTime;
    }

    struct AllowlistProof {
        uint8 allowlistId;
        uint8 allowance;
        bytes32[] proof;
    }

    enum ElevationPassType { UNKNOWN, ASCENSION_PASS, LUMINARY_PASS, EMPYREAN_PASS, ZENITH_PASS, INFINITY_PASS}

    uint8 public maxElevationPassPublicMintsPerWallet = 3;

    uint16 public maxTotalSupply;

    uint256 public publicMintStartTime;

    string public baseURI = "";
    string public baseExtension = ".json";

    mapping(address => uint8) public mintedDuringPublicSale;
    mapping(uint8 => mapping(address => uint8)) public mintedDuringAllowlistSale;

    // Maps allowlistId to allowlist object.
    mapping(uint8 => Allowlist) public allowlists;

    // Maps token id to token type, will be filled after reveal.
    mapping(uint256 => ElevationPassType) private tokenTypeMapping;

    constructor(
        uint16 _maxTotalSupply,
        uint16 _reservedElevationTokens,
        address _internalMintAddress,
        uint256 _publicMintStartTime
    ) ERC721A("Elevation Pass", "ELVTION") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        maxTotalSupply = _maxTotalSupply;
        publicMintStartTime = _publicMintStartTime;

        uint16 batch = 30;
        uint16 remainder = _reservedElevationTokens % batch;
        uint16 batches = _reservedElevationTokens / batch;
        for(uint16 i = 0; i < batches; i++) {
            _mint(_internalMintAddress, batch);
        }

        if (remainder > 0) {
            _mint(_internalMintAddress, remainder);
        }
        // at 6.9% (default denominator is 10000).
        _setDefaultRoyalty(_internalMintAddress, 690);
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    modifier validateMint(uint16 _mintAmount, uint16 _maxSupply) {
        if (_totalMinted() + _mintAmount > _maxSupply) {
            revert InsufficientSupplyAvailable({
                maxSupply: _maxSupply
            });
        }
        _;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
  
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperator {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperator {
        super.approve(operator, tokenId);
    }

    function adminMint(
        address _to,
        uint16 _mintAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) validateMint(_mintAmount, maxTotalSupply) {
        _mint(_to, _mintAmount);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /** 
     * @dev Create allowlist with a specific allocation.
     * @dev The same id as another allowlist can be given to override the previous allowlist.
     * @param _root The merkle root of the allowlist.
     * @param _allowlistId The id of the allowlist.
     * @param _startTime The start time of the allowlist.
     * @param _endTime The end time of the allowlist.
    */
    function createAllowlist(
        bytes32 _root,
        uint8 _allowlistId,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_startTime >= _endTime) {
            revert InvalidAllowlistTime();
        }
        allowlists[_allowlistId] = Allowlist(_root, _startTime, _endTime);
    }

    function removeAllowlist(uint8 _id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete allowlists[_id];
    }

    /**
     * @notice Public mint function
     * @param _mintAmount The amount of tokens to mint.
     */
    function publicMint(
        uint8 _mintAmount
    ) external validateMint(_mintAmount, maxTotalSupply) nonReentrant callerIsUser {
        mintedDuringPublicSale[msg.sender] += _mintAmount;
        if (mintedDuringPublicSale[msg.sender] > maxElevationPassPublicMintsPerWallet) {
            revert ExceedingMaxPublicMintsPerWallet({
                maxPerWallet: maxElevationPassPublicMintsPerWallet
            });
        }
        if (block.timestamp < publicMintStartTime) {
            revert SaleNotActive();
        }
        _mint(msg.sender, _mintAmount);
    }

    function allowlistMint(
        uint8 _mintAmount,
        AllowlistProof calldata _proof
    ) external validateMint(_mintAmount, maxTotalSupply) nonReentrant callerIsUser {
        Allowlist memory allowlist = allowlists[_proof.allowlistId];
        if (block.timestamp >= allowlist.endTime || block.timestamp < allowlist.startTime ) {
            revert SaleNotActive();
        }

        mintedDuringAllowlistSale[_proof.allowlistId][msg.sender] += _mintAmount;

        if (mintedDuringAllowlistSale[_proof.allowlistId][msg.sender] > _proof.allowance) {
            revert ExceedingAllowlistAllowance({allowlistAllowance: _proof.allowance});
        }
        _allowlistCheckAndMint(_mintAmount, allowlist.root, _proof);
    }

    function _allowlistCheckAndMint(
        uint8 _mintAmount, bytes32 _root, AllowlistProof calldata _proof
    ) internal {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, _proof.allowance));
        if (!MerkleProof.verify(_proof.proof, _root, node)) {
            revert NotAllowlisted();
        }

        _mint(msg.sender, _mintAmount);
    }

    function exists(uint32 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl, ERC2981)
        returns (bool)
    {
        return (ERC721A.supportsInterface(_interfaceId) ||
        AccessControl.supportsInterface(_interfaceId)) ||
        ERC2981.supportsInterface(_interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        return
        bytes(_baseURI()).length != 0
        ? string(
            abi.encodePacked(baseURI, _toString(tokenId), baseExtension)
        )
        : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenType(uint16 _tokenId) public view returns(ElevationPassType) {
        if (!_exists(_tokenId)) {
            revert TokenDoesNotExist({tokenId: _tokenId});
        }
        return tokenTypeMapping[_tokenId];
    }

    function setBaseURI(string memory _newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _newBaseURI;
    }

    function setTokenTypeMappingForElevationPasses(ElevationPassType[] memory _tokenTypes, uint256 startId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokenTypes.length; ++i) {
            tokenTypeMapping[i + startId] = _tokenTypes[i];
        }
    }
    
    function setBaseExtension(string memory _baseExtension)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseExtension = _baseExtension;
    }

    function setMaxElevationPassMintsPerWallet(uint8 _maxMintsPerWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxElevationPassPublicMintsPerWallet = _maxMintsPerWallet;
    }

    function setMaxTotalSupply(uint16 _maxTotalSupply)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_maxTotalSupply <= _totalMinted()) {
            revert MaxTotalSupplyCannotBeLessThanAlreadyMinted();
        }
        maxTotalSupply = _maxTotalSupply;
    }

    function setPublicMintStartTime(uint256 _publicMintStartTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        publicMintStartTime = _publicMintStartTime;
    }

    function getNumberMinted(address _address) external view returns (uint256) {
        return _numberMinted(_address);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}