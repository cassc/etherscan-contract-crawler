// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";

import "../IERC4906.sol";
import "../IMetadataRenderer.sol";

contract FunTeams is ERC721A, IERC4906, Ownable {
    address public constant rewardsDistributor = 0x00000000005F30F04d21d7b859C900CE4513b565;
    address public metadataRenderer;
    address public metadataUpdater;
    address public signer;

    uint256 public mintEnd;
    uint256 public mintPrice = 0.0025 ether;

    mapping(uint256 => bool) public tokenIsUnlocked;
    bool private _initialized;
    bool private _tokensUnlocked;

    event TokenUnlocked(uint256 tokenId, bool locked);

    error InvalidTokenId();
    error InvalidProof();
    error InvalidSignature();
    error MintClosed();
    error MintedAlready();
    error NeedsSigner();
    error NonTransferrable();
    error OnlyOwnerOrMetadataUpdater();
    error OnlyTokenOwner();
    error WrongPrice();

    receive() external payable {}

    constructor() ERC721A("mint.fun !teams", "!teams") {
        if (msg.sender != tx.origin) {
            transferOwnership(tx.origin);
        }
    }

    function mint(bytes calldata signature) public payable {
        if (msg.value != mintPrice) revert WrongPrice();
        if (block.timestamp > mintEnd) revert MintClosed();
        if (_getAux(msg.sender) != 0) revert MintedAlready();
        address recovered = ECDSA.tryRecoverCalldata(keccak256(abi.encodePacked(msg.sender)), signature);
        if (recovered != signer) revert InvalidSignature();

        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (ownerOf(id) == address(0)) revert InvalidTokenId();
        return IMetadataRenderer(metadataRenderer).tokenURI(id);
    }

    // Admin functions
    function refreshMetadata() public {
        if (msg.sender != metadataUpdater && msg.sender != owner()) {
            revert OnlyOwnerOrMetadataUpdater();
        }
        emit BatchMetadataUpdate(_startTokenId(), _nextTokenId() - 1);
    }

    function setMetadataRenderer(address _metadataRenderer) public onlyOwner {
        metadataRenderer = _metadataRenderer;
        refreshMetadata();
    }

    function setMetadataUpdater(address _metadataUpdater) public onlyOwner {
        metadataUpdater = _metadataUpdater;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setMintEnd(uint256 _mintEnd) public onlyOwner {
        if (address(signer) == address(0)) revert NeedsSigner();
        mintEnd = _mintEnd;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function sendToRewardsDistributor() public onlyOwner {
        (bool success,) = payable(rewardsDistributor).call{value: address(this).balance}("");
        if (!success) revert();
    }

    function setTokensUnlocked(bool tokensUnlocked_) public onlyOwner {
        _tokensUnlocked = tokensUnlocked_;
    }

    function setTokenLock(uint256 tokenID, bool unlocked) public onlyOwner {
        emit TokenUnlocked(tokenID, unlocked);
        tokenIsUnlocked[tokenID] = unlocked;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC4906).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
    }

    // transfer overrides for toggleable soulbound
    modifier requireUnlocked(uint256 tokenID) {
        if (!_tokensUnlocked) revert NonTransferrable();
        if (!tokenIsUnlocked[tokenID]) revert NonTransferrable();
        _;
    }

    function unlockToken(uint256 tokenID, bytes calldata signature) public {
        if (msg.sender != ownerOf(tokenID)) revert OnlyTokenOwner();
        address recovered = ECDSA.tryRecoverCalldata(keccak256(abi.encodePacked(tokenID, msg.sender)), signature);
        if (recovered != signer) revert InvalidSignature();
        emit TokenUnlocked(tokenID, true);
        tokenIsUnlocked[tokenID] = true;
    }

    function safeTransferFrom(address to, address from, uint256 tokenID)
        public
        payable
        virtual
        override
        requireUnlocked(tokenID)
    {
        super.safeTransferFrom(to, from, tokenID);
    }

    function safeTransferFrom(address to, address from, uint256 tokenID, bytes memory data)
        public
        payable
        virtual
        override
        requireUnlocked(tokenID)
    {
        super.safeTransferFrom(to, from, tokenID, data);
    }

    function transferFrom(address to, address from, uint256 tokenID)
        public
        payable
        virtual
        override
        requireUnlocked(tokenID)
    {
        super.transferFrom(to, from, tokenID);
    }

    function approve(address addr, uint256 tokenID) public payable virtual override requireUnlocked(tokenID) {
        super.approve(addr, tokenID);
    }

    function setApprovalForAll(address addr, bool approved) public virtual override {
        if (!_tokensUnlocked) revert NonTransferrable();
        super.setApprovalForAll(addr, approved);
    }

    function getApproved(uint256 tokenID) public view virtual override requireUnlocked(tokenID) returns (address) {
        return super.getApproved(tokenID);
    }
}