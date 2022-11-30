// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./utils/MultipleOwnable.sol";
import "./interfaces/IERC5192.sol";

contract PolarSubscription is ERC721, ERC721Enumerable, MultipleOwnable, ReentrancyGuard {
    using Counters for Counters.Counter;

    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @notice currently SBT Contract does not emit Unlocked event
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    Counters.Counter private _tokenIdCounter;

    string private uriBase;

    address public paymentAddress;
    address public usdc;

    bool public openSubscription = true;
    bool public onlyMintAndBurn = true;

    uint256 public subscriptionDuration = 32 days;
    uint256 public subscriptionCost = 19 ether;

    uint256 public totalSubscription;

    // Mapping from token ID to locked status
    mapping(uint256 => bool) _locked;

    mapping(address => uint256) public userSubscriptionCount;
    
    mapping(address => uint256) public userSubscriptionExpiration;

    mapping(address => bool) public ownNFT;

    mapping(address => bool) public isBlacklisted;

    modifier canSubscribe(address _user) {
        require(openSubscription, "PolarSubscription: not open");
        require(!isBlacklisted[_user], "PolarSubscription: blacklisted");
        require(block.timestamp > userSubscriptionExpiration[_user], "PolarSubscription: currently subscribed");
        _;
    }

    modifier IsTransferAllowed(uint256 tokenId) {
        require(!_locked[tokenId]);
        _;
    }

    constructor(
        address[] memory _owners,
        string memory uri,
        address _usdc,
        address _paymentAddress
    ) ERC721("Polar Subscription", "PolarSub") MultipleOwnable(_owners) {
        uriBase = uri;
        usdc = _usdc;
        paymentAddress = _paymentAddress;
    }

    function buySubscription() external nonReentrant canSubscribe(msg.sender) {
        IERC20(usdc).transferFrom(msg.sender, address(paymentAddress), subscriptionCost);
        _mintSubscription(msg.sender, subscriptionDuration);
    }

    function airDropSubscription(address _user, uint256 _duration) external canSubscribe(msg.sender) onlyOwner {
        _mintSubscription(_user, _duration);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public virtual override(IERC721, ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(
            from,
            to,
            tokenId
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public virtual override(IERC721, ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(
            from,
            to,
            tokenId,
            data
        );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public virtual override(IERC721, ERC721) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(
            from,
            to,
            tokenId
        );
    }

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool) {
        require(ownerOf(tokenId) != address(0));
        return _locked[tokenId];
    }

    function isSubscribed(address _user) external view returns (bool) {
        require(!isBlacklisted[_user]);
        return (block.timestamp <= userSubscriptionExpiration[_user]);
    }

    function _mintSubscription(address _user, uint256 _duration) internal {
        if (balanceOf(_user) == 0) {
            uint256 tokenId = _tokenIdCounter.current();
            safeMint(_user, tokenId);
            _tokenIdCounter.increment();
        }

        userSubscriptionExpiration[_user] = block.timestamp + _duration;
        userSubscriptionCount[_user] += 1;

        totalSubscription += 1;
    }


    function setOpenSubscription(bool _openSubscription) external onlySuperOwner {
        openSubscription = _openSubscription;
    }

    function setOnlyMintAndBurn(bool _new) external onlySuperOwner {
        onlyMintAndBurn = _new;
    }

    function setBaseURI(string memory _new) external onlySuperOwner {
        uriBase = _new;
    }

    function setIsBlacklisted(address _new, bool _value) external onlyOwner {
        isBlacklisted[_new] = _value;
    }

    function setSubscriptionCost(uint256 _cost) external onlyOwner {
        subscriptionCost = _cost;
    }

    function setSubscriptionDuration(uint256 _duration) external onlyOwner {
        subscriptionDuration = _duration;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view override returns (string memory) {
        return uriBase;
    }

    function safeMint(address to, uint256 tokenId) internal virtual {
        require(balanceOf(to) == 0, "MNT01");
        require(_locked[tokenId] != true, "MNT02");

        _locked[tokenId] = true;
        emit Locked(tokenId);

        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, 0, batchSize);
    }

    function supportsInterface(bytes4 _interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return _interfaceId == type(IERC5192).interfaceId || super.supportsInterface(_interfaceId);
    }

}