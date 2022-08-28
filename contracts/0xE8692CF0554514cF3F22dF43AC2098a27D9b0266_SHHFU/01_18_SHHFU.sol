// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
/**
 * @title SHHFU
 * SHHFU - Collectibles
 */
contract SHHFU is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable
{
    using SafeMath for uint256;
    uint256 maxSupply = 10000;

    mapping(address => uint256[]) public userOwnedTokens;
    mapping(uint256 => uint256) public enabledDrops;
    mapping(uint256 => uint256) public dropsPrices;
    mapping(uint256 => uint256) public tokenIsAtIndex;

    mapping(address => uint8) private whitelistForDropOne;
    mapping(address => uint8) private whitelistForDropTwo;
    mapping(address => uint8) private whitelistForDropThree;
    mapping(address => uint8) private whitelistForDropFour;
    mapping(address => uint8) private whitelistForDropFive;

    mapping(uint256 => uint256) public enabledWhitelists;
    mapping(uint256 => uint256) public whitelistsEndTime;
    mapping(uint256 => uint256) public whitelistsPrices;

    event Mint(
        address indexed _minter,
        address indexed _to,
        uint16 _id,
        uint256 _value
    );
    event WhitelistMint(
        address indexed _minter,
        address indexed _to,
        uint16 _id,
        uint256 _value
    );
    event EnableWhitelistAddresses(
        address[] _addresses,
        uint256 _drop,
        uint8 _numAllowedToMint
    );

    event EnableWhitelist(uint256 _start, uint256 _end, uint256 _price,uint256 _drop);

    event EnableDrop(uint256 _drop, uint256 _start, uint256 _price);

    constructor() ERC721("SHHFU Ticket", "SHHFU") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.shhfu.com/v1/nfts/attribute/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address _to, uint16 _id) external payable  {
        uint16 drop = getDrop(_id);
        require(enabledDrops[drop] != 0, "Drop not enabled");
        require(block.timestamp >= enabledDrops[drop], "Drop has not started");
        require(msg.value == dropsPrices[drop], "Wrong price");
        __mint(_to, _id);
        emit Mint(msg.sender, _to, _id, msg.value);
    }

    function __mint(address _to, uint16 _id) internal whenNotPaused{
        _safeMint(_to, _id);
        userOwnedTokens[_to].push(_id);
        uint256 arrayLength = userOwnedTokens[_to].length;
        tokenIsAtIndex[_id] = arrayLength;
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused{
        if (_exists(tokenId)) {
            uint256 tokenIndex = tokenIsAtIndex[tokenId];
            userOwnedTokens[from][tokenIndex] = 0;
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getTokenIds(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokensOfOwner = new uint256[](
            ERC721.balanceOf(_owner)
        );
        uint256 i;

        for (i = 0; i < ERC721.balanceOf(_owner); i++) {
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }

    function withdraw() external onlyOwner {
        require(
            address(this).balance > 0,
            "You don't have enough withdrawable balance"
        );
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }

    function enableWhitelistAddresses (
        address[] calldata _addresses,
        uint256 _drop,
        uint8 _numAllowedToMint
    ) public onlyOwner  {
        require(_drop >= 1 && _drop <= 5, "Drop not recognized");
        require(block.timestamp <= whitelistsEndTime[_drop], "Whitelist has ended");
        mapping(address => uint8) storage _whitelist = whitelistForDropOne;

        if (_drop == 2) {
            _whitelist = whitelistForDropTwo;
        } else if (_drop == 3) {
            _whitelist = whitelistForDropThree;
        } else if (_drop == 4) {
            _whitelist = whitelistForDropFour;
        } else if (_drop == 5) {
            _whitelist = whitelistForDropFive;
        }
        for (uint256 i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = _numAllowedToMint;
        }
        emit EnableWhitelistAddresses(_addresses, _drop, _numAllowedToMint);
    }

    function enableWhitelist(
        uint256 _start,
        uint256 _end,
        uint256 _price,
        uint256 _drop
    ) public onlyOwner {
        require(_drop >= 1 && _drop <= 5, "Drop not recognized");
        require(_end > _start, "End Time needs to be after start time.");
        require(_start > block.timestamp, "Drop cannot start in the past");
        require(
            enabledDrops[_drop] == 0 || enabledDrops[_drop] > block.timestamp,
            "Drop already enabled"
        );
        require(enabledDrops[_drop] == 0 || _start < enabledDrops[_drop], "Whitelist cannot start after public sale");
        require(enabledDrops[_drop] == 0 || _end < enabledDrops[_drop], "Whitelist should end before public sale");

        enabledWhitelists[_drop] = _start;
        whitelistsEndTime[_drop] = _end;
        whitelistsPrices[_drop] = _price;
        emit EnableWhitelist(_start, _end, _price, _drop);
    }

    function getUserWhitelistMints(address _whitelistedAddress, uint16 drop)
        public
        view
        returns (uint8)
    {
        mapping(address => uint8) storage _whitelist = whitelistForDropOne;

        if (drop == 2) {
            _whitelist = whitelistForDropTwo;
        } else if (drop == 3) {
            _whitelist = whitelistForDropThree;
        } else if (drop == 4) {
            _whitelist = whitelistForDropFour;
        } else if (drop == 5) {
            _whitelist = whitelistForDropFive;
        }
        uint8 whitelistMintRemaining = _whitelist[_whitelistedAddress];
        return whitelistMintRemaining;
    }

    function whitelistMint(address _to, uint16 _id) external payable {
        uint16 drop = getDrop(_id);
        require(enabledWhitelists[drop] != 0, "Whitelist not enabled");
        require(
            block.timestamp >= enabledWhitelists[drop],
            "Whitelist mint has not started"
        );
        require(
            block.timestamp <= whitelistsEndTime[drop],
            "Whitelist mint has ended"
        );

        
        require(msg.value == whitelistsPrices[drop], "Wrong price");

        mapping(address => uint8) storage _whitelist = whitelistForDropOne;
        if (drop == 2) {
            _whitelist = whitelistForDropTwo;
        } else if (drop == 3) {
            _whitelist = whitelistForDropThree;
        } else if (drop == 4) {
            _whitelist = whitelistForDropFour;
        } else if (drop == 5) {
            _whitelist = whitelistForDropFive;
        }
        require(_whitelist[msg.sender] > 0, "Not allowed to mint whitelist");

        __mint(_to, _id);
        _whitelist[msg.sender] -= 1;
        emit WhitelistMint(msg.sender, _to, _id, msg.value);
    }

    function getDrop(uint16 _id) internal view returns (uint16) {
        require(_id > 0 && _id <= 10000, "Invalid token id");
        require(!_exists(_id), "Token already minted");
        return checkDrop(_id);
    }

    function enableDrop(
        uint256 _drop,
        uint256 _start,
        uint256 _price
    ) public onlyOwner {
        require(_drop >= 1 && _drop <= 5, "Drop not recognized");
        require(_start > enabledWhitelists[_drop], "Drop cannot start before whitelist");
        require(_start > whitelistsEndTime[_drop], "Drop cannot start during whitelist");
        require(_start > block.timestamp, "Drop cannot start in the past");

        require(
            enabledDrops[_drop] == 0 || enabledDrops[_drop] > block.timestamp,
            "Drop already enabled"
        );
        enabledDrops[_drop] = _start;
        dropsPrices[_drop] = _price;
        emit EnableDrop(_drop, _start, _price);
    }

    function checkDrop(uint16 _tokenId) public pure returns (uint16) {
        uint16[2][6] memory _tokens = [
            [1000, 1333],
            [7334, 7666],
            [3334, 3666],
            [1667, 1999],
            [1, 333],
            [2000, 2333]
        ];
        if (lookForToken(_tokens, _tokenId)) {
            return 1;
        }
        _tokens = [
            [7000, 7333],
            [334, 666],
            [9000, 9333],
            [2667, 2999],
            [5334, 5666],
            [4667, 4999]
        ];
        if (lookForToken(_tokens, _tokenId)) {
            return 2;
        }
        _tokens = [
            [9334, 9666],
            [1334, 1666],
            [4000, 4333],
            [667, 999],
            [6000, 6333],
            [6334, 6666]
        ];
        if (lookForToken(_tokens, _tokenId)) {
            return 3;
        }
        _tokens = [
            [4334, 4666],
            [5000, 5333],
            [8667, 8999],
            [3000, 3333],
            [8334, 8666],
            [3667, 3999]
        ];
        if (lookForToken(_tokens, _tokenId)) {
            return 4;
        }
        _tokens = [
            [2334, 2666],
            [6667, 6999],
            [5667, 5999],
            [8000, 8333],
            [7667, 7999],
            [9667, 10000]
        ];
        if (lookForToken(_tokens, _tokenId)) {
            return 5;
        }

        return 0;
    }

    function lookForToken(uint16[2][6] memory _tokens, uint16 _tokenId)
        private
        pure
        returns (bool)
    {
        for (uint16 i = 0; i < 6; i++) {
            uint256 start = _tokens[i][0];
            uint256 end = _tokens[i][1];
            if (_tokenId >= start && _tokenId <= end) {
                return true;
            }
        }
        return false;
    }
}