// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./InitializableOwnable.sol";
import "./Strings.sol";
import "./Address.sol";

contract TPSkin2022 is ERC721, InitializableOwnable {
    using Strings for uint256;

    //tokenId => style
    mapping(uint256 => uint256) private _token_style;
    mapping(uint256 => uint256) public styleSupply;
    mapping(address => bool) private _minted;
    uint256 private _totalSupply = 2022;
    uint256 private _circulationSupply;
    uint256 private _startTime;
    uint256 private _endTime;

    event Mint(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed style
    );

    constructor(string memory name_, string memory symbol_) public {
        initOwner(msg.sender);
        initNameSymbol(name_, symbol_);
    }

    function updateOpenTime(uint256 start_, uint256 end_) public onlyOwner {
        _startTime = start_;
        _endTime = end_;
    }

    function updateBaseURI(string memory _uri) public onlyOwner {
        initBaseUri(_uri);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function circulationSupply() public view returns (uint256) {
        return _circulationSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "TP Skin 2022: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        uint256 style = _token_style[tokenId];
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, style.toString(), ".json"))
                : "";
    }

    function mint() public returns (uint256 tokenId) {
        require(
            _circulationSupply < _totalSupply,
            "TP Skin 2022: Better luck next time!"
        );
        require(block.timestamp >= _startTime, "TP Skin 2022: Coming soon!");
        require(block.timestamp < _endTime, "TP Skin 2022: finished");
        require(!_minted[msg.sender], "TP Skin 2022: already minted");
        tokenId = _circulationSupply + 1;
        uint256 style = randomStyle(tokenId);
        _safeMint(msg.sender, tokenId);
        _circulationSupply += 1;
        _token_style[tokenId] = style;
        styleSupply[style] += 1;
        _minted[msg.sender] = true;
        emit Mint(msg.sender, tokenId, style);
    }

    function randomStyle(uint256 tokenId) internal returns (uint256 style) {
        uint256 random = (uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    msg.sender,
                    block.coinbase.balance,
                    tokenId,
                    block.difficulty,
                    block.gaslimit
                )
            )
        ) % 100) + 1;
        if (random <= 7) {
            style = 1;
        } else if (random <= 17) {
            style = 2;
        } else if (random <= 29) {
            style = 3;
        } else if (random <= 41) {
            style = 4;
        } else if (random <= 55) {
            style = 5;
        } else if (random <= 75) {
            style = 6;
        } else {
            style = 7;
        }
    }
}
