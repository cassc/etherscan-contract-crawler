// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";

interface IPixlrGenesis {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract CirclesInMotion is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    bool public mintIsActive = false;
    bool public onlyWhitelisted = false;
    uint256 public maxToken;
    uint256 public reservedForPixlrGenesis;
    uint256 public mintedByPixlrGenesis;
    uint256 public cimPrice;
    uint256 public maxTokensPerTransaction;
    string private _baseURIextended;
    mapping(address => bool) public whitelist;
    mapping(uint256 => bool) public pixlrGenesisClaimedFree;
    IPixlrGenesis pixlrGenesis;

    constructor(
        uint256 _maxToken,
        uint256 _reservedForPixlrGenesis,
        uint256 _cimPrice,
        uint256 _maxTokensPerTransaction,
        address _pixlrGenesis
    ) ERC721("CirclesInMotion", "CIM") {
        maxToken = _maxToken;
        reservedForPixlrGenesis = _reservedForPixlrGenesis;
        cimPrice = _cimPrice;
        maxTokensPerTransaction = _maxTokensPerTransaction;
        pixlrGenesis = IPixlrGenesis(_pixlrGenesis);
    }

    function addAddressesToWhitelist(address[] memory _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            whitelist[_addrs[i]] = true;
        }
    }

    function removeAddressesFromWhitelist(address[] memory _addrs)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            whitelist[_addrs[i]] = false;
        }
    }

    function flipWhitelistStatus() public onlyOwner {
        onlyWhitelisted = !onlyWhitelisted;
    }

    function flipMintStatus() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _baseURIextended = _baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setMaxToken(uint256 numberOfTokens) external onlyOwner {
        maxToken = numberOfTokens;
    }

    function setReservedForPixlrGenesis(uint256 numberOfTokens)
        external
        onlyOwner
    {
        reservedForPixlrGenesis = numberOfTokens;
    }

    function setPrice(uint256 _price) external onlyOwner {
        cimPrice = _price;
    }

    function setMaxTokensPerTransaction(uint256 numberOfTokens)
        external
        onlyOwner
    {
        maxTokensPerTransaction = numberOfTokens;
    }

    function mintForPixlrGenesis(uint16[] calldata pgTokenIds) public {
        // Can only mint when mintIsActive
        require(mintIsActive, "Minting is not available yet");
        // Check whitelist requirement
        if (onlyWhitelisted) {
            require(
                whitelist[msg.sender],
                "Minting is only available for whitelisted users"
            );
        }
        // Check number of tokens requested per transaction
        require(
            pgTokenIds.length <= maxTokensPerTransaction,
            "Number of tokens requested exceeded the value allowed per transaction"
        );
        // Check token availability
        require(
            (mintedByPixlrGenesis + pgTokenIds.length) <=
                reservedForPixlrGenesis,
            "Purchase would exceed reserved supply of CirclesInMotion tokens for PixlrGenesis holders"
        );
        for (uint256 i = 0; i < pgTokenIds.length; i++) {
            require(
                pixlrGenesis.ownerOf(pgTokenIds[i]) == msg.sender,
                "Only owner of this PixlrGenesis token can call this function"
            );
            require(
                !pixlrGenesisClaimedFree[pgTokenIds[i]],
                "Free token already claimed by this Pixlr Genesis token"
            );
            _safeMint(msg.sender, totalSupply());
            mintedByPixlrGenesis += 1;
            pixlrGenesisClaimedFree[pgTokenIds[i]] = true;
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        // Check mintIsActive
        require(mintIsActive, "Minting is not available yet");
        // Check whitelist requirement
        if (onlyWhitelisted) {
            require(
                whitelist[msg.sender],
                "Minting is only available for whitelisted users"
            );
        }
        // Check number of tokens requested per transaction
        require(
            numberOfTokens <= maxTokensPerTransaction,
            "Number of tokens requested exceeded the value allowed per transaction"
        );
        uint256 total = totalSupply();
        // Check token availability
        require(
            (total - mintedByPixlrGenesis + numberOfTokens) <=
                (maxToken - reservedForPixlrGenesis),
            "Purchase would exceed max supply of CirclesInMotion tokens"
        );
        // Check ether value == price;
        require(
            numberOfTokens * cimPrice == msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, total + i);
        }
    }

    function reserveTokens(uint256 amount) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        uint256 balance;
        if ((maxToken - supply) >= amount) {
            balance = amount;
        } else {
            balance = maxToken - supply;
        }

        for (i = 1; i <= balance; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}