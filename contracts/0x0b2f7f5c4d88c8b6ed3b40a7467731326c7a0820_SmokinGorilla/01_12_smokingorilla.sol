// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IERC20 {
    function transfer(address to, uint256 amt) external;
}

contract SmokinGorilla is ERC721, Ownable {
    using Counters for Counters.Counter;

    string private gorillaURI;
    uint256 public startTime;
    uint256 public constant GORILLA_PRICE = 0.035 ether;
    uint256 public constant MAX_GORILLAS = 8000;
    mapping(address => uint256) public whitelistMints;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Smokin Gorilla", "SG") {
        startTime = block.timestamp;
        for (uint256 i = 0; i < 400; i++) {
            safeMintByOwner(msg.sender);
        }
    }

    function setURI(string calldata _newURI) public onlyOwner {
        gorillaURI = _newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return gorillaURI;
    }

    function safeMintByOwner(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function addWhitelist(address[] calldata _users, uint256[] calldata _amts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelistMints[_users[i]] = _amts[i];
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(address token, uint256 _amt) public onlyOwner {
        IERC20(token).transfer(msg.sender, _amt);
    }

    function whitelistMint(uint256 _amt) public {
        require(block.timestamp > startTime, "too early");
        require(block.timestamp < 1 days + startTime, "too late");
        require(
            whitelistMints[msg.sender] >= _amt,
            "Either not whitelisted or trying to mint too many"
        );
        whitelistMints[msg.sender] = whitelistMints[msg.sender] - _amt;
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId + _amt <= 1100, "Whitelist is complete");
        for (uint256 i = 0; i < _amt; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId + i);
        }
    }

    function mint(uint256 _amt) public payable {
        require(block.timestamp > startTime + 1 days, "public mint not available yet");
        require(
            totalGorillas() + _amt <= MAX_GORILLAS,
            "Purchase would exceed max supply of Apes"
        );
        uint256 userBalance = balanceOf(msg.sender);
        require(userBalance + _amt <= 12, "mint max");
        require(GORILLA_PRICE * _amt == msg.value, "Invalid Price");
        for (uint256 i = 0; i < _amt; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            if (tokenId < MAX_GORILLAS) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, tokenId++);
            }
        }
    }

    function totalGorillas() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function nftsOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_GORILLAS
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }

        return ownedTokenIds;
    }
}