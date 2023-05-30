// SPDX-License-Identifier: MIT
// Creator: WagmiLabs
// Developer: Nftfede.eth
// Contract: Wagmilabs Trading Hub NFTs

/*
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─██████──────────██████─██████████████─██████████████─██████──────────██████─██████████────██████─────────██████████████─██████████████───██████████████─
─██░░██──────────██░░██─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██████████████░░██─██░░░░░░██────██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░██───██░░░░░░░░░░██─
─██░░██──────────██░░██─██░░██████░░██─██░░██████████─██░░░░░░░░░░░░░░░░░░██─████░░████────██░░██─────────██░░██████░░██─██░░██████░░██───██░░██████████─
─██░░██──────────██░░██─██░░██──██░░██─██░░██─────────██░░██████░░██████░░██───██░░██──────██░░██─────────██░░██──██░░██─██░░██──██░░██───██░░██─────────
─██░░██──██████──██░░██─██░░██████░░██─██░░██─────────██░░██──██░░██──██░░██───██░░██──────██░░██─────────██░░██████░░██─██░░██████░░████─██░░██████████─
─██░░██──██░░██──██░░██─██░░░░░░░░░░██─██░░██──██████─██░░██──██░░██──██░░██───██░░██──────██░░██─────────██░░░░░░░░░░██─██░░░░░░░░░░░░██─██░░░░░░░░░░██─
─██░░██──██░░██──██░░██─██░░██████░░██─██░░██──██░░██─██░░██──██████──██░░██───██░░██──────██░░██─────────██░░██████░░██─██░░████████░░██─██████████░░██─
─██░░██████░░██████░░██─██░░██──██░░██─██░░██──██░░██─██░░██──────────██░░██───██░░██──────██░░██─────────██░░██──██░░██─██░░██────██░░██─────────██░░██─
─██░░░░░░░░░░░░░░░░░░██─██░░██──██░░██─██░░██████░░██─██░░██──────────██░░██─████░░████────██░░██████████─██░░██──██░░██─██░░████████░░██─██████████░░██─
─██░░██████░░██████░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░██──────────██░░██─██░░░░░░██────██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░░░██─██░░░░░░░░░░██─
─██████──██████──██████─██████──██████─██████████████─██████──────────██████─██████████────██████████████─██████──██████─████████████████─██████████████─
─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
*/

pragma solidity >0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ISubscription {
    function checkSubscriptionAdvanced(
        address ownerAddress
    ) external view returns (bool, uint256, uint256);
}

contract WagmilabsTradingHub is ReentrancyGuard, ERC721AQueryable {
    constructor() ERC721A(_tokenName, _tokenSymbol) {
        owner = msg.sender;
    }

    // global variables
    address subscriptionAddress;

    address owner;

    bytes32 public root;

    bool public allowlistPaused = true;
    bool public publicPaused = true;
    bool public renewalPaused = true;

    string public constant _tokenName = "Wagmi Labs Pass";
    string public constant _tokenSymbol = "WLP";
    string public baseURI;

    uint16 public constant maxSupply = 1200;

    uint256 priceForRenewal = 0.0075 ether; // for 1 month
    uint256 minRenewalMonths = 12; // 1 year in months
    uint256 maxRenewalMonths = 12; // 1 year in months
    uint256 monthInMilliSeconds = 2629800000; // 1 month in milliseconds

    uint256 public allowlistPrice = 0.15 ether;
    uint256 public publicPrice = 0.15 ether;
    uint8 maxMint = 3;

    // mappings
    mapping(address => uint256) public allowlistClaimed;
    mapping(uint256 => uint256) public expiration;

    // events
    event IncrementExpiration(
        uint256 indexed tokenId,
        uint256 indexed expirationTimestamp
    );

    // modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // setter functions

    function changeOwner(address newOnwer) public onlyOwner {
        owner = newOnwer;
    }

    /**
     * @dev type 1 represents minRenewal, type 0 represents maxReneweal
     */
    function updateRenewalMonths(
        uint256 minMonths,
        uint256 maxMonths
    ) public onlyOwner {
        minRenewalMonths = minMonths;
        maxRenewalMonths = maxMonths;
    }

    /**
     * @dev 0 = allowlist, 1 = public, 2 renewal (price for 1 month)
     */
    function updatePriceWei(uint256 _price, uint8 _type) public onlyOwner {
        if (_type == 0) allowlistPrice = _price;
        else if (_type == 1) publicPrice = _price;
        else if (_type == 2) priceForRenewal = _price;
        else revert("Invalid type");
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    /**
     * @dev 0 = allowlist, 1 = public, 2 = renewal
     */
    function setPaused(bool _paused, uint8 _type) public onlyOwner {
        if (_type == 0) allowlistPaused = _paused;
        else if (_type == 1) publicPaused = _paused;
        else if (_type == 2) renewalPaused = _paused;
        else revert("Invalid type");
    }

    function setBaseUri(string memory _newBaseUri) public onlyOwner {
        baseURI = _newBaseUri;
    }

    function setSubscriptionAddress(
        address _subscriptionAddress
    ) public onlyOwner {
        subscriptionAddress = _subscriptionAddress;
    }

    // Mint functions

    /**
     * @dev price 0.15 eth, max mint 3
     */
    function MintAllowlist(
        uint8 _mintAmount,
        bytes32[] memory proof
    ) public payable {
        require(!allowlistPaused, "Contract is paused");
        require(_mintAmount + totalSupply() <= maxSupply, "Mint out.");
        require(
            isWhitelisted(proof, keccak256(abi.encodePacked(msg.sender))),
            "Not a part of Allowlist"
        );
        require(_mintAmount <= maxMint, "Invalid mint amount");
        require(
            _mintAmount + allowlistClaimed[msg.sender] <= maxMint,
            "Invalid mint amount"
        );

        uint256 price = allowlistPrice * _mintAmount;

        require(msg.value >= price, "Insufficient value");
        allowlistClaimed[msg.sender] += _mintAmount;

        uint256 unixTimestampDuration = block.timestamp *
            1000 +
            12 *
            monthInMilliSeconds;

        for (uint256 i = 0; i < _mintAmount; i++) {
            expiration[_currentIndex + i] = unixTimestampDuration;
        }

        _safeMint(msg.sender, _mintAmount);
    }

    /**
     * @dev price 0.15 eth
     */
    function MintPublic(uint8 _mintAmount) public payable {
        // make requires
        require(!publicPaused, "Contract is paused");
        require(_mintAmount + totalSupply() <= maxSupply, "Mint out.");
        uint256 price = publicPrice * _mintAmount;
        require(msg.value >= price, "Insufficient value");

        uint256 unixTimestampDuration = block.timestamp *
            1000 +
            12 *
            monthInMilliSeconds;

        for (uint256 i = 0; i < _mintAmount; i++) {
            expiration[_currentIndex + i] = unixTimestampDuration;
        }

        _safeMint(msg.sender, _mintAmount);
    }

    function team(uint8 _amount) public onlyOwner {
        require(_amount + totalSupply() <= maxSupply, "Mint out.");

        uint256 unixTimestampDuration = block.timestamp *
            1000 +
            12 *
            monthInMilliSeconds;

        for (uint256 i = 0; i < _amount; i++) {
            expiration[_currentIndex + i] = unixTimestampDuration;
        }

        _safeMint(msg.sender, _amount);
    }

    /**
     * @dev price for 1 month 0.0075 eth
     */
    function incrementExpirationTime(
        uint256 tokenId,
        uint256 months
    ) public payable {
        require(!renewalPaused, "Renewal pused");
        require(
            months >= minRenewalMonths && months <= maxRenewalMonths,
            "Invalid renewal period"
        );

        uint256 currentExpiration = checkExpiration(tokenId);
        require(
            (currentExpiration + months * monthInMilliSeconds) <
                (block.timestamp *
                    1000 +
                    (maxRenewalMonths * monthInMilliSeconds * 2)),
            "Not available yet"
        );

        uint256 incrementPrice = (months * priceForRenewal);

        require(msg.value >= incrementPrice, "Insufficient amount");

        bool passValid = checkTokenidValid(tokenId);

        uint256 unixTimestampTime = (months * monthInMilliSeconds);
        if (passValid) expiration[tokenId] += unixTimestampTime;
        else expiration[tokenId] = (block.timestamp * 1000 + unixTimestampTime);

        uint256 newDuration = expiration[tokenId];

        emit IncrementExpiration(tokenId, newDuration);
    }

    // view functions

    /**
     * @dev check if address has at least 1 valid pass
     */
    function hasValidPass(
        address walletAddress
    ) public view returns (bool, uint256, uint256) {
        bool hasValidP = false;

        // 0 = pass, 1 = basic subscription, 2 = pro subscription
        uint256 planType = 0;
        uint256 planExpiration = 0;

        uint256[] memory tokens = tokensOfOwner(walletAddress);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (checkTokenidValid(tokens[i])) {
                hasValidP = true;
                planType = 0;
                planExpiration = checkExpiration(tokens[i]);
                break;
            }
        }

        if (!hasValidP) {
            (
                bool hasSubscription,
                uint256 subscriptionType,
                uint256 subscriptionExpiration
            ) = ISubscription(subscriptionAddress).checkSubscriptionAdvanced(
                    walletAddress
                );

            planType = subscriptionType;

            if (hasSubscription) {
                planExpiration = subscriptionExpiration;
                hasValidP = true;
            }
        }
        return (hasValidP, planType, planExpiration);
    }

    /**
     * @dev checkl if a token id is still valid
     */
    function checkTokenidValid(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "The token you are querying is inexistent");
        uint256 currentTime = block.timestamp * 1000;
        if (checkExpiration(tokenId) > currentTime) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev check ifr wallet is whitelisted
     */
    function isWhitelisted(
        bytes32[] memory proof,
        bytes32 leaf
    ) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @dev check expiration timestamp of token id (in milliseconds)
     */
    function checkExpiration(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "The token you are querying is inexistent");
        return expiration[tokenId];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "The token you are querying is inexistent");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    // whithdraw function
    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
    }
}