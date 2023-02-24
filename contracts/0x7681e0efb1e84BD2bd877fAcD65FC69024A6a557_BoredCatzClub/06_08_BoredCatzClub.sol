// SPDX-License-Identifier: MIT
// Developer: https://twitter.com/0xArtCro
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BoredCatzClub is Ownable, ERC721A, ReentrancyGuard {
    string private baseTokenURI;

    // Minting
    bool public paused;

    uint256 public phase1Timestamp = 1677326400;
    uint256 public phase2Timestamp = 1677931200;
    uint256 public phase3Timestamp = 1678536000;
    uint256 public phase4Timestamp = 1679140800;

    mapping(address => uint256) private oglist;
    mapping(address => bool) private whitelist;

    uint256 public maxMint = 99;
    uint256 public price2 = 0.007 ether;
    uint256 public price3 = 0.0095 ether;
    uint256 public price4 = 0.015 ether;

    // Payout
    address public immutable crodooWallet;
    address public projectWallet;
    address public nickWallet;

    // Errors
    error MintNotOpen();
    error PausedMint();
    error InsufficientPayment();
    error OverMint();
    error MintLimit();
    error FreeMintLimit();

    // Constants
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant LAUNCHPAD_ROYALTIES = 5;

    // Structs
    struct TokenInfo {
        uint256 id;
        uint256 royalties;
    }

    struct MintInfo {
        bool paused;
        uint256 supply;
        uint256 maxSupply;
        uint256 maxMint;
        uint256 phase1Timestamp;
        uint256 phase2Timestamp;
        uint256 phase3Timestamp;
        uint256 phase4Timestamp;
    }

    constructor(
        string memory uri_,
        address projectWallet_,
        address nickWallet_,
        address crodooWallet_
    ) ERC721A("Bored Catz Club", "BCC") {
        baseTokenURI = uri_;
        projectWallet = projectWallet_;
        nickWallet = nickWallet_;
        crodooWallet = crodooWallet_;
    }

    // Owner
    // - Setup
    function setProjectWallet(address projectWallet_) public onlyOwner {
        projectWallet = projectWallet_;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        baseTokenURI = uri;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function addWhitelist(address[] memory addresses_) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; ) {
            whitelist[addresses_[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function addOglist(
        address[] memory addresses_,
        uint256[] memory amount_
    ) external onlyOwner {
        require(addresses_.length == amount_.length);
        for (uint256 i = 0; i < addresses_.length; ) {
            oglist[addresses_[i]] = amount_[i];
            unchecked {
                ++i;
            }
        }
    }

    function setTimestamps(
        uint256 phase1Timestamp_,
        uint256 phase2Timestamp_,
        uint256 phase3Timestamp_,
        uint256 phase4Timestamp_
    ) external onlyOwner {
        phase1Timestamp = phase1Timestamp_;
        phase2Timestamp = phase2Timestamp_;
        phase3Timestamp = phase3Timestamp_;
        phase4Timestamp = phase4Timestamp_;
    }

    function setMaxMint(uint256 maxMint_) external onlyOwner {
        maxMint = maxMint_;
    }

    function setPrice(
        uint256 price2_,
        uint256 price3_,
        uint256 price4_
    ) external onlyOwner {
        price2 = price2_;
        price3 = price3_;
        price4 = price4_;
    }

    // - Team minting
    function teamMint(uint256 amount, address to) external onlyOwner {
        uint currentSupply = totalSupply();

        if (currentSupply + amount > MAX_SUPPLY) revert OverMint();
        _mint(to, amount);
    }

    // - Team Funds
    function _payoutCroDoo(uint256 _amount) private {
        (bool success, ) = payable(crodooWallet).call{
            value: _amount,
            gas: 50000
        }("");
        require(success, "Cannot payout CroDoo");
    }

    function _payoutNick(uint256 _amount) private {
        (bool success, ) = payable(nickWallet).call{value: _amount, gas: 50000}(
            ""
        );
        require(success, "Cannot payout CroDoo");
    }

    function _payout(uint256 _amount) private {
        (bool success, ) = payable(projectWallet).call{
            value: _amount,
            gas: 50000
        }("");
        require(success, "Cannot payout");
    }

    // External
    function freeMint(uint256 amount) external nonReentrant {
        if (paused) revert PausedMint();
        if (block.timestamp < phase1Timestamp) revert MintNotOpen();
        if (amount > freeMintCount(_msgSender())) revert FreeMintLimit();

        uint currentSupply = totalSupply();
        if (currentSupply + amount > MAX_SUPPLY) revert OverMint();

        _mint(_msgSender(), amount);
        oglist[_msgSender()] -= amount;
    }

    function mint(uint256 amount) external payable nonReentrant {
        if (paused) revert PausedMint();
        if (!isWhitelisted(_msgSender()) && block.timestamp < phase3Timestamp)
            revert MintNotOpen();
        if (block.timestamp < phase2Timestamp) revert MintNotOpen();
        if (amount > maxMint) revert MintLimit();

        uint256 totalPrice = mintPrice() * amount;
        uint currentSupply = totalSupply();

        if (currentSupply + amount > MAX_SUPPLY) revert OverMint();
        if (msg.value != totalPrice) revert InsufficientPayment();

        _mint(_msgSender(), amount);

        uint256 royalties = (totalPrice * LAUNCHPAD_ROYALTIES) / 100;
        uint256 payout = totalPrice - royalties - royalties;

        _payout(payout);
        _payoutCroDoo(royalties);
        _payoutNick(royalties);
    }

    // Internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(
        uint _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory _tokenURI = string(
            abi.encodePacked(baseTokenURI, Strings.toString(_tokenId), ".json")
        );

        return _tokenURI;
    }

    // Getters
    function getMintInfo() external view returns (MintInfo memory) {
        return
            MintInfo(
                paused,
                totalSupply(),
                MAX_SUPPLY,
                maxMint,
                phase1Timestamp,
                phase2Timestamp,
                phase3Timestamp,
                phase4Timestamp
            );
    }

    function freeMintCount(address _address) public view returns (uint256) {
        return oglist[_address];
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function mintPrice() public view returns (uint256) {
        if (block.timestamp >= phase4Timestamp) return price4;
        if (block.timestamp >= phase3Timestamp) return price3;

        return price2;
    }

    // Override
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}