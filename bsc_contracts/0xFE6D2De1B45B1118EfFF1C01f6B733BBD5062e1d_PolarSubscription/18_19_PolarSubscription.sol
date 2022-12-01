// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./utils/MultipleOwnableUpgradeable.sol";
import "./interfaces/IERC5192.sol";


contract PolarSubscription is ERC721Upgradeable, ERC721EnumerableUpgradeable, MultipleOwnableUpgradeable, ReentrancyGuardUpgradeable {
    using Counters for Counters.Counter;

    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    Counters.Counter private _tokenIdCounter;

    string private uriBase;

    address public paymentAddress;
    address public usdc;

    bool public openSubscription;
    bool public onlyMintAndBurn;

    uint256 public subscriptionDuration;
    uint256 public subscriptionCost;

    uint256 public totalSubscription;
    
    mapping(uint256 => bool) _locked; // Mapping from token ID to locked status
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

    function initialize(
        address[] calldata _owners,
        string memory uri,
        address _usdc,
        address _paymentAddress
    ) initializer public {
        __Ownable_init(_owners);
        __ERC721_init("Polar Subscription", "PolarSub");
        __ReentrancyGuard_init();

        uriBase = uri;
        usdc = _usdc;
        paymentAddress = _paymentAddress;

        openSubscription = true;
        onlyMintAndBurn = true;

        subscriptionDuration = 32 days;
        subscriptionCost = 19 ether;
    }

    function buySubscription() external nonReentrant canSubscribe(msg.sender) {
        IERC20(usdc).transferFrom(msg.sender, address(paymentAddress), subscriptionCost);
        _mintSubscription(msg.sender, subscriptionDuration);
    }

    function airDropSubscription(address _user, uint256 _duration) external canSubscribe(_user) onlyOwner {
        _mintSubscription(_user, _duration);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721Upgradeable, ERC721Upgradeable) IsTransferAllowed(tokenId) {
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
    ) public virtual override(IERC721Upgradeable, ERC721Upgradeable) IsTransferAllowed(tokenId) {
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
    ) public virtual override(IERC721Upgradeable, ERC721Upgradeable) IsTransferAllowed(tokenId) {
        super.safeTransferFrom(
            from,
            to,
            tokenId
        );
    }

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
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, 0, batchSize);
    }

    function supportsInterface(bytes4 _interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return _interfaceId == type(IERC5192).interfaceId || super.supportsInterface(_interfaceId);
    }

}