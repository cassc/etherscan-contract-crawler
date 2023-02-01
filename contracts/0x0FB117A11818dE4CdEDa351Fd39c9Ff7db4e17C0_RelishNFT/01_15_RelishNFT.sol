// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract RelishNFT is ERC721, Pausable, Ownable {
    event Minted(address indexed recipient, uint16 tokenType, uint256 tokenId);

    uint256 public mintStartDate;

    // Counters
    using Counters for Counters.Counter;
    Counters.Counter private _level1Counter;
    Counters.Counter private _level2Counter;
    Counters.Counter private _level3Counter;

    uint16 public constant LEVEL1_TOKEN = 0;
    uint16 public constant LEVEL2_TOKEN = 1;
    uint16 public constant LEVEL3_TOKEN = 2;

    // uint256 public constant LEVEL1_TOKEN_TOTAL_SUPPLY = 200; // SUPPLIES[LEVEL1_TOKEN]
    // uint256 public constant LEVEL2_TOKEN_TOTAL_SUPPLY = 10; // SUPPLIES[LEVEL2_TOKEN]
    // uint256 public constant LEVEL3_TOKEN_TOTAL_SUPPLY = 1; // SUPPLIES[LEVEL3_TOKEN]

    mapping(uint16 => uint256) public SUPPLIES;
    mapping(uint16 => uint256) public PRICES;

    uint256 public LEVEL2_TOKEN_OFFSET = SUPPLIES[LEVEL1_TOKEN];
    uint256 public LEVEL3_TOKEN_OFFSET =
        SUPPLIES[LEVEL1_TOKEN] + SUPPLIES[LEVEL2_TOKEN];

    string private BASE_URI;

    constructor(
        address owner,
        string memory baseURI,
        uint256[3] memory supplies,
        uint256[3] memory prices,
        uint256 _mintStartDate
    ) ERC721("Corner Booth Club x Kimski", "CBCxKimski") {
        transferOwnership(owner);
        BASE_URI = baseURI;

        SUPPLIES[LEVEL1_TOKEN] = supplies[LEVEL1_TOKEN];
        SUPPLIES[LEVEL2_TOKEN] = supplies[LEVEL2_TOKEN];
        SUPPLIES[LEVEL3_TOKEN] = supplies[LEVEL3_TOKEN];

        PRICES[LEVEL1_TOKEN] = prices[LEVEL1_TOKEN];
        PRICES[LEVEL2_TOKEN] = prices[LEVEL2_TOKEN];
        PRICES[LEVEL3_TOKEN] = prices[LEVEL3_TOKEN];

        mintStartDate = _mintStartDate;
    }

    function setURI(string memory newuri) public onlyOwner {
        BASE_URI = newuri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function mint(address recipient, uint16 tokenType) public payable {
        require(block.timestamp >= mintStartDate, "MIN_NOT_STARTED_YET");
        require(tokenType < 3, "UNKOWN_TOKEN_TYPE");
        require(msg.value >= PRICES[tokenType], "NOT_ENOUGH_ETH");

        assertTotalSupply(tokenType);

        // increment & mint
        uint256 tokenId = getNextNftId(tokenType);

        _mint(recipient, tokenId);
        emit Minted(recipient, tokenType, tokenId);
    }

    function mintAdmin(address recipient, uint16 tokenType)
        public
        payable
        onlyOwner
    {
        require(tokenType < 3, "UNKOWN_TOKEN_TYPE");

        assertTotalSupply(tokenType);

        // increment & mint
        uint256 tokenId = getNextNftId(tokenType);

        _mint(recipient, tokenId);
        emit Minted(recipient, tokenType, tokenId);
    }

    function getNextNftId(uint16 tokenType) private returns (uint256) {
        console.log("getNextNftId", tokenType);
        if (tokenType == LEVEL1_TOKEN) {
            _level1Counter.increment();
            console.log("getNextNftId levet1", _level1Counter.current());
            return _level1Counter.current();
        } else if (tokenType == LEVEL2_TOKEN) {
            _level2Counter.increment();
            console.log(
                "getNextNftId levet2",
                _level2Counter.current() + LEVEL2_TOKEN_OFFSET
            );
            return _level2Counter.current() + LEVEL2_TOKEN_OFFSET;
        } else if (tokenType == LEVEL3_TOKEN) {
            _level3Counter.increment();
            console.log(
                "getNextNftId levet3",
                _level3Counter.current() + LEVEL3_TOKEN_OFFSET
            );
            return _level3Counter.current() + LEVEL3_TOKEN_OFFSET;
        }
        revert("UNKOWN_TOKEN_TYPE");
    }

    function assertTotalSupply(uint16 tokenType) private view {
        if (tokenType == LEVEL1_TOKEN) {
            require(
                _level1Counter.current() < SUPPLIES[LEVEL1_TOKEN],
                "LEVEL1_NFT_OUT_OF_STOCK"
            );
        } else if (tokenType == LEVEL2_TOKEN) {
            require(
                _level2Counter.current() < SUPPLIES[LEVEL2_TOKEN],
                "LEVEL2_NFT_OUT_OF_STOCK"
            );
        } else if (tokenType == LEVEL3_TOKEN) {
            require(
                _level3Counter.current() < SUPPLIES[LEVEL3_TOKEN],
                "LEVEL3_NFT_OUT_OF_STOCK"
            );
        } else revert("UNKOWN_TOKEN");
    }

    function supply(uint16 tokenType) public view returns (uint256) {
        if (tokenType == LEVEL1_TOKEN) {
            return _level1Counter.current();
        } else if (tokenType == LEVEL2_TOKEN) {
            return _level2Counter.current();
        } else if (tokenType == LEVEL3_TOKEN) {
            return _level3Counter.current();
        }
        return 0;
    }

    function totalSupply() public view returns (uint256) {
        return
            SUPPLIES[LEVEL1_TOKEN] +
            SUPPLIES[LEVEL2_TOKEN] +
            SUPPLIES[LEVEL3_TOKEN];
    }

    function totalMinted() public view returns (uint256) {
        return
            _level1Counter.current() +
            _level2Counter.current() +
            _level3Counter.current();
    }

    function totalTokensLeft() public view returns (uint256) {
        return totalSupply() - totalMinted();
    }

    // used by frontend
    // tokens left & price of each token
    // [level1LeftTokens, level1Price]
    function mintInfo() public view returns (uint256[6] memory) {
        return [
            _level1Counter.current(),
            PRICES[LEVEL1_TOKEN],
            _level2Counter.current(),
            PRICES[LEVEL2_TOKEN],
            _level3Counter.current(),
            PRICES[LEVEL3_TOKEN]
        ];
    }

    function currentOwnersForType(uint16 tokenType)
        public
        view
        returns (address[] memory)
    {
        uint256 total = supply(tokenType);
        address[] memory ownersList = new address[](total);
        uint256 j = 0;
        for (uint256 i = 1; i <= total; i++) {
            if (_exists(i)) {
                ownersList[j] = ownerOf(i);
                j++;
            }
        }
        return ownersList;
    }

    function withdraw(address payable recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        recipient.transfer(balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}