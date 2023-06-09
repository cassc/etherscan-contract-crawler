// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Ticket is ERC721, Ownable {
    using Counters for Counters.Counter;

    mapping(uint256 => uint256) public sums;
    mapping(uint256 => uint256) private tokenIds;

    mapping(address => uint256) private amountOfTickets;
    address[20] private topPlayers;

    string private baseUri = "https://veritty-backend-app.herokuapp.com/metadata/";

    constructor(uint256[] memory _tokenIds, uint256[] memory _sums) ERC721("VERITTY Ticket", "VRT") {
        require(_tokenIds.length == _sums.length, "Ticket: invalid arguments");

        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            tokenIds[_sums[i]] = _tokenIds[i];
        }
    }

    function mint(address _to, uint256 _sum) public onlyOwner returns (uint256) {
        uint256 tokenId = tokenIds[_sum]++;
        _mint(_to, tokenId);

        sums[tokenId] = _sum;

        return tokenId;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function getTopPlayer(uint256 index) external view returns (address) {
        return topPlayers[index];
    }

    function getTopPlayers() external view returns (address[20] memory) {
        return topPlayers;
    }

    function win(uint256 _tokenId) external view returns (bool) {
        return sums[_tokenId] != 0;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(baseUri, Strings.toString(tokenId)));
    }

    function _updateStatistics(address from, address winner) internal {
        amountOfTickets[winner]++;
        if (from != address(0)) {
            amountOfTickets[from]--;
        }

        _updateTop20(winner);
    }

    function _updateTop20(address player) internal {
        uint256 balance = amountOfTickets[player];
        uint256 lastPlayerBalance = amountOfTickets[topPlayers[19]];

        bool inArray;
        for (uint256 i = 0; i < 20; i++) {
            if (topPlayers[i] == player) {
                inArray = true;
                break;
            }
        }
        if (!inArray) {
            if (balance == lastPlayerBalance + 1) {
                topPlayers[19] = player;
            }
        }
        _sortTopPlayers();
    }

    function _sortTopPlayers() internal {
        address[20] memory tp = topPlayers;

        for (uint i = 1; i < 20; i++) {
            uint j = i;
            while (j > 0 && (amountOfTickets[tp[j - 1]] < amountOfTickets[tp[j]])) {
                address tmp = tp[j];
                tp[j] = tp[j - 1];
                tp[j - 1] = tmp;
                j--;
            }
        }
        topPlayers = tp;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721) {
        _updateStatistics(from, to);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}