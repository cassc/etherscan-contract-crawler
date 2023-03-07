// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IBreedingInfoV2.sol";
import "./interfaces/IERC721xHelper.sol";
import "./interfaces/IStaminaInfo.sol";
import "./interfaces/ITOLTransfer.sol";
// import "hardhat/console.sol";

contract OrdKubz is
    ERC721x,
    DefaultOperatorFiltererUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721xHelper
{

    uint256 public MAX_SUPPLY;

    string public baseTokenURI;
    string public tokenURISuffix;
    string public tokenURIOverride;

    address public signer;
    mapping(string => bool) public withdrawNonce; // nonce => used
    mapping(address => bool) public isWithdrawing; // address => is withdrawing

    mapping(uint256 => string) public lastBridgeTargets; // tokenId => btcAddress

    mapping(address => bool) public whitelistedMarketplaces;
    mapping(address => bool) public blacklistedMarketplaces;
    uint8 public marketplaceRestriction;

    bool public canBridge; 

    event UserDeposited(address indexed user, uint256 indexed tokenId, string btcAddress);
    event UserWithdraw(address indexed user, uint256 indexed tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory baseURI,
        address signerAddress
    ) public initializer {
        ERC721x.__ERC721x_init("Ordinal Kubz", "Ordinal Kubz");
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        baseTokenURI = baseURI;
        MAX_SUPPLY = 10000;
        signer = signerAddress;
    }

    function setCanBridge(bool b) external onlyOwner {
        canBridge = b;
    }
    // =============== AIR DROP ===============

    function airdrop(address receiver, uint256 tokenAmount) external onlyOwner {
        safeMint(receiver, tokenAmount);
    }

    function airdropList(address[] calldata receivers) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i = 0; i < receivers.length; i++) {
            safeMint(receivers[i], 1);
        }
    }

    function airdropListWithAmounts(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i = 0; i < receivers.length; i++) {
            safeMint(receivers[i], amounts[i]);
        }
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    // =============== BASE URI ===============

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (bytes(tokenURIOverride).length > 0) {
            return tokenURIOverride;
        }
        return string.concat(super.tokenURI(_tokenId), tokenURISuffix);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setTokenURISuffix(string calldata _tokenURISuffix)
        external
        onlyOwner
    {
        if (compareStrings(_tokenURISuffix, "!empty!")) {
            tokenURISuffix = "";
        } else {
            tokenURISuffix = _tokenURISuffix;
        }
    }

    function setTokenURIOverride(string calldata _tokenURIOverride)
        external
        onlyOwner
    {
        if (compareStrings(_tokenURIOverride, "!empty!")) {
            tokenURIOverride = "";
        } else {
            tokenURIOverride = _tokenURIOverride;
        }
    }

    // =============== MARKETPLACE CONTROL ===============
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        require(_to != address(this), "Disallowed direct transfer");
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        require(_to != address(this), "Disallowed direct transfer");
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }


    // =============== MARKETPLACE CONTROL ===============
    function checkGuardianOrMarketplace(address operator) internal view {
        // Always allow guardian contract
        if (approvedContract[operator]) return;
        require(
            !(marketplaceRestriction == 1 && blacklistedMarketplaces[operator]),
            "Please contact Keungz for approval."
        );
        return;
    }

    function approve(address to, uint256 tokenId)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
    {
        checkGuardianOrMarketplace(to);
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
    {
        checkGuardianOrMarketplace(operator);
        super.setApprovalForAll(operator, approved);
    }

    function blacklistMarketplaces(address[] calldata markets, bool blacklisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            blacklistedMarketplaces[market] = blacklisted;
            // emit MarketplaceBlacklisted(market, blacklisted);
        }
    }

    // 0 = no restriction, 1 = blacklist
    function setMarketplaceRestriction(uint8 rule) external onlyOwner {
        marketplaceRestriction = rule;
    }

    function _mayTransfer(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        if (operator == ownerOf(tokenId)) return true;
        checkGuardianOrMarketplace(operator);
        return true;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721AUpgradeable) {
        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + quantity;
            tokenId += 1
        ) {
            if (
                from != address(0) &&
                to != address(0) &&
                !_mayTransfer(msg.sender, tokenId)
            ) {
                revert("Kubz: illegal operator");
            }
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    // =============== Bridging ===============
    function checkValidity(bytes calldata signature, string memory action)
        public
        view
        returns (bool)
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signer,
            "invalid signature"
        );
        return true;
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (bool) {
        if (operator == address(this)) return true;
        if (isWithdrawing[operator]) return true;
        return super.isApprovedForAll(owner, operator);
    }

    function deposit(uint256 tokenId, string calldata btcAddress) external {
        require(canBridge, "Bridging not open");
        require(msg.sender == ownerOf(tokenId), "Not NFT owner");
        super.transferFrom(msg.sender, address(this), tokenId);
        lastBridgeTargets[tokenId] = btcAddress;
        emit UserDeposited(msg.sender, tokenId, btcAddress);
    }

    function withdraw(uint256 tokenId, string calldata nonce, bytes calldata signature) external nonReentrant {
        string memory action = string.concat("ord-kubz-withdraw_", Strings.toString(tokenId), "_", nonce);
        checkValidity(signature, action);
        require(!withdrawNonce[nonce], "Nonce already used");
        withdrawNonce[nonce] = true;
        isWithdrawing[msg.sender] = true;
        super.transferFrom(address(this), msg.sender, tokenId);
        isWithdrawing[msg.sender] = false;
        emit UserWithdraw(msg.sender, tokenId);
    }

    // =============== IERC721xHelper ===============
    function isUnlockedMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = isUnlocked(tokenIds[i]);
        }
        return part;
    }

    function ownerOfMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (address[] memory)
    {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = ownerOf(tokenIds[i]);
        }
        return part;
    }

    function tokenNameByIndexMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (string[] memory)
    {
        string[] memory part = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokenNameByIndex(tokenIds[i]);
        }
        return part;
    }
}