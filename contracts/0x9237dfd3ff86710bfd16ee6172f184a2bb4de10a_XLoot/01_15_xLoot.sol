// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract XLoot is ERC721, Ownable {
    bool private enabledBurn;
    mapping(uint => uint) private config;
    string private baseURI;

    address private loot;

    address private constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    event MintToken(address indexed from, uint amountLoot, uint amountXLoot);

    constructor(address _loot) ERC721("xLOOT", "xLOOT") {
        enabledBurn = false;
        loot = _loot;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function setEnableBurn(bool value) public onlyOwner {
        enabledBurn = value;
    }

    function getEnableBurn() public view returns (bool) {
        return enabledBurn;
    }

    function setConfig(uint xLootAmount, uint lootAmount) public onlyOwner {
        config[xLootAmount] = lootAmount;
    }

    function getConfig(uint xLootAmount) public view returns (uint) {
        return config[xLootAmount];
    }

    modifier activeBurn() {
        require(enabledBurn, "ERROR: Disabled burn");
        _;
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function mint(uint amount) public activeBurn {
        IERC20 lootToken = IERC20(loot);
        uint amountLoot = config[amount];

        require(config[amount] > 0, "ERROR: Invalid burn amount");
        require(
            amountLoot <= lootToken.balanceOf(_msgSender()),
            "ERROR: Amount exceeds balance"
        );

        lootToken.transferFrom(_msgSender(), DEAD_ADDRESS, amountLoot);

        for (uint i = 0; i < amount; i++) {
            safeMint(_msgSender());
        }

        emit MintToken(_msgSender(), amountLoot, amount);
    }
}