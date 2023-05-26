// SPDX-License-Identifier: MIT

/***
 __          __      _______          _____  _       _ _        _
 \ \        / /     |__   __|        |  __ \(_)     (_) |      | |
  \ \  /\  / /_ _ _   _| | ___   ___ | |  | |_  __ _ _| |_ __ _| |
   \ \/  \/ / _` | | | | |/ _ \ / _ \| |  | | |/ _` | | __/ _` | |
    \  /\  / (_| | |_| | | (_) | (_) | |__| | | (_| | | || (_| | |
     \/  \/ \__,_|\__, |_|\___/ \___/|_____/|_|\__, |_|\__\__,_|_|
                   __/ |                        __/ |
                  |___/                        |___/
***/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LocalWeather is ERC721A, Ownable {
    using Strings for uint256;

    bool public preReveal = true;

    string private baseURI;
    string private preRevealBaseURI;

    uint8 public constant MAX_BATCH_AMOUNT = 30;
    uint16 public constant TOTAL_NFTS = 2700;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {}

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setPreRevealBaseURI(string memory _preRevealBaseUri) public onlyOwner {
        preRevealBaseURI = _preRevealBaseUri;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    function batchAirdrop(address[] memory addresses, uint8[] memory quantities)
        public
        onlyOwner
    {
        require(
            addresses.length <= MAX_BATCH_AMOUNT,
            "Batch is greater then max amount"
        );
        require(
            addresses.length == quantities.length,
            "Address and quantities need to be equal length"
        );
        uint256 totalQuantity = 0;
        for (uint256 i; i < quantities.length; i++) {
            totalQuantity += quantities[i];
        }
        require(
            _totalMinted() + totalQuantity <= TOTAL_NFTS,
            "Not enough left to airdrop batch"
        );
        for (uint256 i; i < addresses.length; i++) {
            _mint(addresses[i], quantities[i]);
        }
    }

    function reveal() public onlyOwner {
        preReveal = false;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (preReveal == true) return string(abi.encodePacked(preRevealBaseURI, tokenId.toString()));
        else return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}