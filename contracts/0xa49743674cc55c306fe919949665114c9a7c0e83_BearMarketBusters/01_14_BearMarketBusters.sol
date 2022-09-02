//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BearMarketBusters is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool private _isSaleActive = true;
    string private _baseTokenURI = "";

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _bmbBaseTokenURI
    ) ERC721(_tokenName, _tokenSymbol) {
        _baseTokenURI = _bmbBaseTokenURI;
    }

    function mintBearMarketBuster(uint256 itemId) public payable nonReentrant {
        require(_isSaleActive, "Sale not yet active");
        require(itemId >= 1 && itemId <= 9, "Wrong itemId");
        if (itemId >= 1 && itemId <= 3) {
            require(msg.value >= 1 * 10**18, "Wrong price");
        }
        if (itemId >= 4 && itemId <= 6) {
            require(msg.value >= 2 * 10**18, "Wrong price");
        }
        if (itemId >= 7 && itemId <= 9) {
            require(msg.value >= 3 * 10**18, "Wrong price");
        }

        _safeMint(msg.sender, itemId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function isSaleActive() public view returns (bool) {
        return _isSaleActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* Owner Functions */

    function setIsSaleActive(bool value) public onlyOwner {
        _isSaleActive = value;
    }

    /* YUP FIRST IS MINE */
    function reserveFirstBear() public onlyOwner {
        _safeMint(msg.sender, 0);
    }

    function mintForAddress(address receiver, uint256 itemId) public onlyOwner {
        _safeMint(receiver, itemId);
    }

    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        // 10% to designer.
        // =============================================================================
        (bool gigiwincsSuccess, ) = payable(
            0x371aE80beAF2228ceCA33A62cE3BDd3f09e0f007
        ).call{value: (address(this).balance * 10) / 100}("");
        require(gigiwincsSuccess, "Failed to send 10% to gigiwincs");
        // =============================================================================
        // =============================================================================

        // Gimme that ETH
        // =============================================================================
        (bool ownerSuccess, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(ownerSuccess, "Failed to send ETH to owner");
    }
}