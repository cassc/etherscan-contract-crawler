// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "ERC721.sol";
import "Strings.sol";
import "ECDSA.sol";

/**
 * @title TheSheep
 * TheSheep - ERC721 NFT contract.
 */
contract TheSheep is ERC721 {
    // Using.
    using Strings for uint256;
    using ECDSA for bytes32;

    // Enums.
    enum MintPermission {
        DENY,
        ALLOW_FOR_WHITELIST_BLACK_WOLVES,
        ALLOW_FOR_WHITELIST_WOLVES,
        ALLOW_FOR_WHITELIST_RAFFLE,
        ALLOW_FOR_ALL
    }

    // Vars.
    address _admin;
    address _signer;
    string _contractUri;
    bool _reveal = false;
    string _preRevealTokenUri;
    MintPermission _mintPermission = MintPermission.DENY;
    uint256 _minMintPrice;
    uint256 _minMintPriceFromSecond; // Only for public mint.
    uint256 _minMintPriceForWhitelist;
    string _baseTokenUri; // `https://thesheep.xyz/token-meta/`.
    uint256 _maxTokenId; // `2780`.
    uint256 _nextTokenIdToMint = 1;
    address _withdrawAddress;
    uint256 _maxWhitelistBlackWolvesMintBalance = 4;
    uint256 _maxWhitelistWolvesMintBalance = 2;
    uint256 _maxWhitelistRaffleMintBalance = 1;
    uint256 _maxFreeMintBalance = 10000;

    // Modifiers.
    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only owner can call this method.");
        _;
    }

    modifier mintDenied() {
        require(_mintPermission == MintPermission.DENY, "Mint not denied.");
        _;
    }

    modifier mintAllowedForWhitelistBlackWolves() {
        require(
            _mintPermission == MintPermission.ALLOW_FOR_WHITELIST_BLACK_WOLVES,
            "Mint not allowed for BlackWolves."
        );
        _;
    }

    modifier mintAllowedForWhitelistWolves() {
        require(
            _mintPermission == MintPermission.ALLOW_FOR_WHITELIST_WOLVES,
            "Mint not allowed for Wolves."
        );
        _;
    }

    modifier mintAllowedFoRaffle() {
        require(
            _mintPermission == MintPermission.ALLOW_FOR_WHITELIST_RAFFLE,
            "Mint not allowed for Raffle."
        );
        _;
    }

    modifier mintAllowedForAll() {
        require(
            _mintPermission == MintPermission.ALLOW_FOR_ALL,
            "Mint not allowed for all."
        );
        _;
    }

    modifier mintAllowedForWhitelist() {
        require(
            _mintPermission ==
                MintPermission.ALLOW_FOR_WHITELIST_BLACK_WOLVES ||
                _mintPermission == MintPermission.ALLOW_FOR_WHITELIST_WOLVES ||
                _mintPermission == MintPermission.ALLOW_FOR_WHITELIST_RAFFLE,
            "Mint not allowed for whitelist."
        );
        _;
    }

    /**
     * @dev Constructor.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory contractUri,
        string memory preRevealTokenUri,
        string memory baseTokenUri,
        uint256 maxTokenId,
        uint256 minMintPrice,
        uint256 minMintPriceFromSecond,
        uint256 minMintPriceForWhitelist,
        address withdrawAddress,
        address signer
    ) ERC721(name, symbol) {
        _admin = msg.sender;
        _signer = signer;
        _contractUri = contractUri;
        _preRevealTokenUri = preRevealTokenUri;
        _baseTokenUri = baseTokenUri;
        _maxTokenId = maxTokenId;
        _minMintPrice = minMintPrice;
        _minMintPriceFromSecond = minMintPriceFromSecond;
        _minMintPriceForWhitelist = minMintPriceForWhitelist;
        _withdrawAddress = withdrawAddress;
    }

    /**
     * @dev Contract URI view.
     */
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    /**
     * @dev Total supply view.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenIdToMint - 1;
        // return _maxTokenId;
    }

    /**
     * @dev Create collectible (whitelist).
     */
    function createCollectibleForWhitelist(bytes memory signature)
        public
        payable
        mintAllowedForWhitelist
        returns (uint256[] memory)
    {
        require(verifyAddressSigner(signature), "Signature valudation failed.");
        uint256 tokenId = _nextTokenIdToMint;
        require(tokenId <= _maxTokenId, "All tokens already minted.");

        uint256 mintCount;
        if (
            _mintPermission == MintPermission.ALLOW_FOR_WHITELIST_BLACK_WOLVES
        ) {
            mintCount =
                _maxWhitelistBlackWolvesMintBalance -
                balanceOf(msg.sender);
        } else if (
            _mintPermission == MintPermission.ALLOW_FOR_WHITELIST_WOLVES
        ) {
            mintCount = _maxWhitelistWolvesMintBalance - balanceOf(msg.sender);
        } else if (
            _mintPermission == MintPermission.ALLOW_FOR_WHITELIST_RAFFLE
        ) {
            mintCount = _maxWhitelistRaffleMintBalance - balanceOf(msg.sender);
        }

        require(mintCount > 0, "Max mint balance reached.");
        require(
            msg.value >= (_minMintPriceForWhitelist * mintCount),
            "Not enough funds."
        );

        uint256[] memory tokenIds = new uint256[](mintCount);
        for (uint256 i = 0; i < mintCount; i++) {
            _safeMint(msg.sender, tokenId);
            tokenIds[i] = tokenId;
            tokenId++;
        }
        payable(_withdrawAddress).transfer(msg.value);
        _nextTokenIdToMint += mintCount;

        return tokenIds;
    }

    /**
     * @dev Create collectible (public).
     */
    function createCollectible()
        public
        payable
        mintAllowedForAll
        returns (uint256)
    {
        uint256 tokenId = _nextTokenIdToMint;
        require(tokenId <= _maxTokenId, "All tokens already minted.");
        require(
            balanceOf(msg.sender) < _maxFreeMintBalance,
            "Max mint balance reached."
        );
        require(msg.value >= _minMintPrice, "Not enough funds.");
        if (balanceOf(msg.sender) > 0) {
            require(msg.value >= _minMintPriceFromSecond, "Not enough funds.");
        }
        _safeMint(msg.sender, tokenId);
        payable(_withdrawAddress).transfer(msg.value);
        _nextTokenIdToMint++;
        return tokenId;
    }

    /**
     * @dev Token URI view.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        if (!_reveal) {
            return _preRevealTokenUri;
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI internal view.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenUri;
    }

    /**
     * @dev Reveal.
     */
    function reveal() public onlyAdmin {
        _reveal = true;
    }

    /**
     * @dev Set mint permission. Deny mint.
     */
    function denyMint() public onlyAdmin {
        _mintPermission = MintPermission.DENY;
    }

    /**
     * @dev Set mint permission. Allow mint for whitelist (BlackWolves).
     */
    function allowMintForWhitelistBlackWolves() public onlyAdmin {
        _mintPermission = MintPermission.ALLOW_FOR_WHITELIST_BLACK_WOLVES;
    }

    /**
     * @dev Set mint permission. Allow mint for whitelist (Wolves).
     */
    function allowMintForWhitelistWolves() public onlyAdmin {
        _mintPermission = MintPermission.ALLOW_FOR_WHITELIST_WOLVES;
    }

    /**
     * @dev Set mint permission. Allow mint for whitelist (Raffle).
     */
    function allowMintForWhitelistRaffle() public onlyAdmin {
        _mintPermission = MintPermission.ALLOW_FOR_WHITELIST_RAFFLE;
    }

    /**
     * @dev Set mint permission. Allow mint for all.
     */
    function allowMintForAll() public onlyAdmin {
        _mintPermission = MintPermission.ALLOW_FOR_ALL;
    }

    /**
     * @dev Verify address signer.
     */
    function verifyAddressSigner(bytes memory signature)
        private
        view
        returns (bool)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        return
            _signer == messageHash.toEthSignedMessageHash().recover(signature);
    }

    /**
     * @dev Withdraw.
     */
    function withdraw() public onlyAdmin {
        payable(_withdrawAddress).transfer(address(this).balance);
    }

    /**
     * @dev Before token transfer override.
     */
    function _beforeTokenTransfer(
        address from,
        address, // address to,
        uint256 // uint256 tokenId
    ) internal view override {
        require(
            _mintPermission == MintPermission.DENY || from == address(0),
            "Mint not denied to allow user transfer."
        );
    }
}