// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CNPJ is ERC721A, Ownable {
    address public constant withdrawAddress = 0x1456e26f7F79d1AD86DC55d7f96D998D2a1c264E;
    uint256 public maxSupply = 11111;
    uint256 public maxBurnMint = 2222;
    uint256 public mintCost = 0.001 ether;
    uint256 public burnMintCost = 0.001 ether;
    uint256 public maxMintAmount = 1;
    uint256 public maxMintAmountForWhitelist = 30;

    bool public onlyWhitelisted = true;
    bool public paused = true;
    bool public burnMintPaused = true;
    mapping(address => uint256) public whitelistCounts;

    string public baseURI = "";
    string public baseExtension = ".json";

    constructor() ERC721A("CNP Jobs", "CNPJ") {
        _safeMint(withdrawAddress, 2800);
    }

    function getMaxMintAmount() public view returns (uint256) {
        if (onlyWhitelisted == true) {
            return maxMintAmountForWhitelist;
        } else {
            return maxMintAmount;
        }
    }

    function getActualMaxMintAmount(address value) public view returns (uint256) {
        if (onlyWhitelisted == true) {
            uint256 whitelistCount = getWhitelistCount(value);
            if (whitelistCount > maxMintAmountForWhitelist) {
                return maxMintAmountForWhitelist;
            } else {
                return whitelistCount;
            }
        } else {
            return maxMintAmount;
        }
    }

    function getTotalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function getWhitelistCount(address value) public view returns (uint256) {
        return whitelistCounts[value];
    }

    function addWhitelists(address[] memory addresses, uint256[] memory counts) public onlyOwner {
        require(addresses.length == counts.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistCounts[addresses[i]] = counts[i];
        }
    }

    modifier mintPausable() {
        require(!paused, "mint is paused");
        _;
    }

    modifier burnMintPausable() {
        require(!burnMintPaused, "burn mint is paused");
        _;
    }

    modifier verifyMaxSupply(uint256 quantity) {
        require(quantity + totalSupply() <= maxSupply, "claim is over the max supply");
        _;
    }

    modifier verifyMaxAmountAtOnce(uint256 quantity) {
        require(quantity <= getMaxMintAmount(), "claim is over max quantity at once");
        _;
    }

    modifier enoughEth(uint256 quantity) {
        require(msg.value >= mintCost * quantity, "not enough eth");
        _;
    }

    modifier whitelist(uint256 quantity) {
        if (onlyWhitelisted) {
            require(whitelistCounts[msg.sender] != 0, "sender is not whitelisted");
            require(whitelistCounts[msg.sender] >= quantity, "over whitelisted count");
        }
        _;
    }

    modifier verifyTotalBurn(uint256 quantity) {
        require(quantity + _totalBurned() <= maxBurnMint, "over total burn count");
        _;
    }

    function claimWhiteList(uint256 quantity) private {
        if (onlyWhitelisted) {
            whitelistCounts[msg.sender] = whitelistCounts[msg.sender] - quantity;
        }
    }

    function mint(uint256 quantity) external payable
        mintPausable
        verifyMaxSupply(quantity)
        verifyMaxAmountAtOnce(quantity)
        enoughEth(quantity)
        whitelist(quantity) {

        claimWhiteList(quantity);
        _safeMint(msg.sender, quantity);
    }

    function burnMint(uint256[] memory burnTokenIds) external payable
        burnMintPausable
        verifyMaxAmountAtOnce(burnTokenIds.length)
        enoughEth(burnTokenIds.length)
        verifyTotalBurn(burnTokenIds.length)
        whitelist(burnTokenIds.length)  {

        claimWhiteList(burnTokenIds.length);
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            uint256 tokenId = burnTokenIds[i];
            require (_msgSender() == ownerOf(tokenId));
            _burn(tokenId);
        }
        _safeMint(_msgSender(), burnTokenIds.length);
    }

    function setMaxSupply(uint256 _value) public onlyOwner {
        maxSupply = _value;
    }

    function setMaxBurnMint(uint256 _value) public onlyOwner {
        maxBurnMint = _value;
    }

    function setMintCost(uint256 _value) public onlyOwner {
        mintCost = _value;
    }

    function setBurnMintCost(uint256 _value) public onlyOwner {
        burnMintCost = _value;
    }

    function setMaxMintAmount(uint256 _value) public onlyOwner {
        maxMintAmount = _value;
    }

    function setMaxMintAmountForWhiteList(uint256 _value) public onlyOwner {
        maxMintAmountForWhitelist = _value;
    }

    function setOnlyWhitelisted(bool _value) public onlyOwner {
        onlyWhitelisted = _value;
    }

    function pause(bool _value) public onlyOwner {
        paused = _value;
    }

    function burnMintPause(bool _value) public onlyOwner {
        burnMintPaused = _value;
    }

    function setBaseURI(string memory _value) public onlyOwner {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value) public onlyOwner {
        baseExtension = _value;
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}