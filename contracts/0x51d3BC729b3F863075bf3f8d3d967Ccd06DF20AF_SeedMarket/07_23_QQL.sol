// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./ERC721TokenUriDelegate.sol";
import "./ERC721OperatorFilter.sol";
import "./MintPass.sol";

contract QQL is
    Ownable,
    ERC721OperatorFilter,
    ERC721TokenUriDelegate,
    ERC721Enumerable
{
    MintPass immutable pass_;
    uint256 nextTokenId_ = 1;
    mapping(uint256 => bytes32) tokenSeed_;
    mapping(bytes32 => uint256) seedToTokenId_;
    mapping(uint256 => string) scriptPieces_;

    /// By default, an artist has the right to mint all of their seeds. However,
    /// they may irrevocably transfer that right, at which point the current owner
    /// of the right has exclusive opportunity to mint it.
    mapping(bytes32 => address) seedOwners_;
    /// If seed approval is given, then the approved party may claim rights for any
    /// seed.
    mapping(address => mapping(address => bool)) approvalForAllSeeds_;

    mapping(uint256 => address payable) tokenRoyaltyRecipient_;
    address payable projectRoyaltyRecipient_;
    uint256 constant PROJECT_ROYALTY_BPS = 500; // 5%
    uint256 constant TOKEN_ROYALTY_BPS = 200; // 2%
    uint256 immutable unlockTimestamp_;
    uint256 immutable maxPremintPassId_;

    event SeedTransfer(
        address indexed from,
        address indexed to,
        bytes32 indexed seed
    );
    event ApprovalForAllSeeds(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event TokenRoyaltyRecipientChange(
        uint256 indexed tokenId,
        address indexed newRecipient
    );

    event ProjectRoyaltyRecipientChange(address indexed newRecipient);

    constructor(
        MintPass pass,
        uint256 _maxPremintPassId,
        uint256 _unlockTimestamp
    ) ERC721("", "") {
        pass_ = pass;
        maxPremintPassId_ = _maxPremintPassId;
        unlockTimestamp_ = _unlockTimestamp;
    }

    function name() public pure override returns (string memory) {
        return "QQL";
    }

    function symbol() public pure override returns (string memory) {
        return "QQL";
    }

    function setScriptPiece(uint256 id, string memory data) external onlyOwner {
        if (bytes(scriptPieces_[id]).length != 0)
            revert("QQL: script pieces are immutable");

        scriptPieces_[id] = data;
    }

    function scriptPiece(uint256 id) external view returns (string memory) {
        return scriptPieces_[id];
    }

    function transferSeed(
        address from,
        address to,
        bytes32 seed
    ) external {
        if (!isApprovedOrOwnerForSeed(msg.sender, seed))
            revert("QQL: unauthorized for seed");
        if (ownerOfSeed(seed) != from) revert("QQL: wrong owner for seed");
        if (to == address(0)) revert("QQL: can't send seed to zero address");
        emit SeedTransfer(from, to, seed);
        seedOwners_[seed] = to;
    }

    function ownerOfSeed(bytes32 seed) public view returns (address) {
        address explicitOwner = seedOwners_[seed];
        if (explicitOwner == address(0)) {
            return address(bytes20(seed));
        }
        return explicitOwner;
    }

    function approveForAllSeeds(address operator, bool approved) external {
        address artist = msg.sender;
        approvalForAllSeeds_[artist][operator] = approved;
        emit ApprovalForAllSeeds(msg.sender, operator, approved);
    }

    function isApprovedForAllSeeds(address owner, address operator)
        external
        view
        returns (bool)
    {
        return approvalForAllSeeds_[owner][operator];
    }

    function isApprovedOrOwnerForSeed(address operator, bytes32 seed)
        public
        view
        returns (bool)
    {
        address seedOwner = ownerOfSeed(seed);
        if (seedOwner == operator) {
            return true;
        }
        return approvalForAllSeeds_[seedOwner][operator];
    }

    function mint(uint256 mintPassId, bytes32 seed) external returns (uint256) {
        return mintTo(mintPassId, seed, msg.sender);
    }

    /// Consumes the specified mint pass to mint a QQL with the specified seed,
    /// which will be owned by the specified recipient. The royalty stream will
    /// be owned by the original parametric artist (the address embedded in the
    /// seed).
    ///
    /// The caller must be authorized by the owner of the mint pass to operate
    /// the mint pass, and the recipient must be authorized by the owner of the
    /// seed to operate the seed.
    ///
    /// Returns the ID of the newly minted QQL token.
    function mintTo(
        uint256 mintPassId,
        bytes32 seed,
        address recipient
    ) public returns (uint256) {
        if (!isApprovedOrOwnerForSeed(recipient, seed))
            revert("QQL: unauthorized for seed");
        if (!pass_.isApprovedOrOwner(msg.sender, mintPassId))
            revert("QQL: unauthorized for pass");
        if (seedToTokenId_[seed] != 0) revert("QQL: seed already used");
        if (
            block.timestamp < unlockTimestamp_ && mintPassId > maxPremintPassId_
        ) revert("QQL: mint pass not yet unlocked");

        uint256 tokenId = nextTokenId_++;
        tokenSeed_[tokenId] = seed;
        seedToTokenId_[seed] = tokenId;
        // Royalty recipient is always the original artist, which may be
        // distinct from the minter (`msg.sender`).
        tokenRoyaltyRecipient_[tokenId] = payable(address(bytes20(seed)));
        pass_.burn(mintPassId);
        _safeMint(recipient, tokenId);
        return tokenId;
    }

    function parametricArtist(uint256 tokenId) external view returns (address) {
        bytes32 seed = tokenSeed_[tokenId];
        if (seed == bytes32(0)) revert("QQL: token does not exist");
        return address(bytes20(seed));
    }

    function setProjectRoyaltyRecipient(address payable recipient)
        public
        onlyOwner
    {
        projectRoyaltyRecipient_ = recipient;
        emit ProjectRoyaltyRecipientChange(recipient);
    }

    function projectRoyaltyRecipient() external view returns (address payable) {
        return projectRoyaltyRecipient_;
    }

    function tokenRoyaltyRecipient(uint256 tokenId)
        external
        view
        returns (address)
    {
        return tokenRoyaltyRecipient_[tokenId];
    }

    function changeTokenRoyaltyRecipient(
        uint256 tokenId,
        address payable newRecipient
    ) external {
        if (tokenRoyaltyRecipient_[tokenId] != msg.sender) {
            revert("QQL: unauthorized");
        }
        if (newRecipient == address(0)) {
            revert("QQL: can't set zero address as token royalty recipient");
        }
        emit TokenRoyaltyRecipientChange(tokenId, newRecipient);
        tokenRoyaltyRecipient_[tokenId] = newRecipient;
    }

    function getRoyalties(uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory bps)
    {
        recipients = new address payable[](2);
        bps = new uint256[](2);
        recipients[0] = projectRoyaltyRecipient_;
        recipients[1] = tokenRoyaltyRecipient_[tokenId];
        if (recipients[1] == address(0)) {
            revert("QQL: royalty for nonexistent token");
        }
        bps[0] = PROJECT_ROYALTY_BPS;
        bps[1] = TOKEN_ROYALTY_BPS;
    }

    /// Returns the seed associated with the given QQL token. Returns
    /// `bytes32(0)` if and only if the token does not exist.
    function tokenSeed(uint256 tokenId) external view returns (bytes32) {
        return tokenSeed_[tokenId];
    }

    /// Returns the token ID associated with the given seed. Returns 0 if
    /// and only if no token was ever minted with that seed.
    function seedToTokenId(bytes32 seed) external view returns (uint256) {
        return seedToTokenId_[seed];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721, ERC721Enumerable, ERC721OperatorFilter)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721TokenUriDelegate, ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function unlockTimestamp() public view returns (uint256) {
        return unlockTimestamp_;
    }

    function maxPremintPassId() public view returns (uint256) {
        return maxPremintPassId_;
    }
}