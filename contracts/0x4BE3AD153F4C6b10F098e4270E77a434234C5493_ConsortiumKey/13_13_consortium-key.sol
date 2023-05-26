// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ConsortiumKey is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // contract dynamics
    string public baseURI;
    uint256 public immutable totalSupply;
    uint256 public allowListSupply;
    uint256 public publicInitialSupply;

    // mint dynamics
    uint256 public maxSaleMint = 1;
    uint256 public mintPricePublicInitial = 690000000000000000; // 0.69 ETH
    uint256 public mintPriceAllowLInitial = 440000000000000000; // 0.44 ETH
    uint256 public mintPriceBurnOff = 1130000000000000000; // 1.13 ETH

    // we setup two maps to track the minting by wallets
    mapping(address => bool) private _allowList;
    mapping(address => bool) private _hasMinted;

    // state of mint dynamics
    bool public initialSaleIsActive = false; // yeah, yeah, i know
    bool public burnoffSaleIsActive = false; // yeah, yeah, i know

    // counters for faster use by frontend
    Counters.Counter private totalMintedCounter;
    Counters.Counter private allowListMintedCounter;
    Counters.Counter private publicINitialMintedCounter;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        uint256 _totalSupply
    ) ERC721(_name, _symbol) {
        baseURI = _baseTokenURI;
        totalSupply = _totalSupply;
        publicInitialSupply = _totalSupply;
        doMint();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = true;
            allowListSupply += 1;
            publicInitialSupply -= 1;
        }
    }

    // start initial sale
    function toggleInitialSaleState() external onlyOwner {
        require(!burnoffSaleIsActive, "Too late in cycle.");
        initialSaleIsActive = true;
    }

    // end initial sale, move to burnoff sale
    function toggleBurnoffSaleState() external onlyOwner {
        require(
            initialSaleIsActive || burnoffSaleIsActive,
            "Too early in cycle."
        );
        initialSaleIsActive = false;
        burnoffSaleIsActive = true;
    }

    function mint() public payable nonReentrant {
        require(totalMintedCounter.current() < totalSupply, "Minted out.");
        require((initialSaleIsActive || burnoffSaleIsActive), "Mint not open.");
        require(!hasMinted(_msgSender()), "You've minted, ser.");
        if (burnoffSaleIsActive) {
            require(
                msg.value >= mintPriceBurnOff,
                "Send more ether for burnoff."
            );
            doMint();
            return;
        }
        if (hasAllowList(_msgSender())) {
            require( // we'll never not satisfy this if hasMinted guard works
                allowListMintedCounter.current() < allowListSupply,
                "AllowList minted out."
            );
            require(
                msg.value >= mintPriceAllowLInitial,
                "Send more ether for allowlist."
            );
            doMint();
            allowListMintedCounter._value += 1;
            return;
        }
        require(
            publicINitialMintedCounter.current() < publicInitialSupply,
            "Public minted out."
        );
        require(
            msg.value >= mintPricePublicInitial,
            "Send more ether for public."
        );
        doMint();
        publicINitialMintedCounter._value += 1;
    }

    // Returns the current amount of NFTs minted in total.
    function totalMinted() public view returns (uint256) {
        return totalMintedCounter.current();
    }

    // Returns the current amount of NFTs minted from the allow list tranche.
    function allowListMinted() public view returns (uint256) {
        return allowListMintedCounter.current();
    }

    // Returns the current amount of NFTs minted from the public tranche.
    function publicINitialMinted() public view returns (uint256) {
        return publicINitialMintedCounter.current();
    }

    // Returns whether the address is on the allow list
    function hasAllowList(address _addy) public view returns (bool) {
        return _allowList[_addy];
    }

    // Returns whether the address has minted
    function hasMinted(address _addy) public view returns (bool) {
        return _hasMinted[_addy];
    }

    // helper function to do the mint
    function doMint() internal {
        _safeMint(_msgSender(), (totalMintedCounter.current() + 1));
        totalMintedCounter._value += 1;
        _hasMinted[_msgSender()] = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}