// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

abstract contract RoyalSociety {
    function walletOfOwner(address owner)
        external
        view
        virtual
        returns (uint256[] memory tokenIds);

    function balanceOf(address owner)
        external
        view
        virtual
        returns (uint256 balance);
}

contract RoyalSocietyChips is ERC721Enumerable, Ownable {
    RoyalSociety public royalSociety;

    uint256 private _dropTime = 1630713600; // Date and time (GMT): Friday, September 3, 2021 8:00:00 PM EST (https://www.epochconverter.com/)
    uint256 private _dropDuration = 604800; // 604800 is one week.
    uint256 private _maxSupply = 10000; // Used for a few checks
    uint256 private _maxPerTx = 31; // Prevents gas limit errors. One higher than necessary for gt/lt checks.
    uint256 private _lastOwnerSweep;

    string private _baseTokenURI;
    mapping(uint256 => bool) internal cardRedeemed;

    constructor(string memory baseURI, address royalSocietyAddress)
        ERC721("Royal Society Chips", "RoyalSocietyChips")
    {
        setBaseURI(baseURI);
        royalSociety = RoyalSociety(royalSocietyAddress);
    }

    modifier dropIsOpen() {
        require(block.timestamp >= _dropTime, "Drop is not yet open.");
        require(block.timestamp < _dropTime + _dropDuration, "Drop has ended.");
        _;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setDropTime(uint256 time) public onlyOwner {
        _dropTime = time;
    }

    function getDropTime() public view returns (uint256) {
        return _dropTime;
    }

    function setDropDuration(uint256 time) public onlyOwner {
        _dropDuration = time;
    }

    function getDropDuration() public view returns (uint256) {
        return _dropDuration;
    }

    function isDropOpen() public view returns (bool) {
        return (block.timestamp >= _dropTime &&
            block.timestamp < _dropTime + _dropDuration);
    }

    // Returns true if a card ID has been used to redeem a chip.
    function isCardRedeemed(uint256 _cardId) public view returns (bool) {
        return cardRedeemed[_cardId];
    }

    // Gets total chips that remain unredeemed for front end use.
    function getTotalLeftUnredeemed() public view returns (uint256) {
        return _maxSupply - totalSupply();
    }

    // Returns an integer with the total amount of unredeemed card IDs at an address.
    function getUnredeemedAmount(address player) public view returns (uint256) {
        uint256[] memory cardIds = royalSociety.walletOfOwner(player);
        uint256 totalUnredeemed;
        for (uint256 i; i < cardIds.length; i++) {
            if (cardRedeemed[cardIds[i]] == false) {
                totalUnredeemed += 1;
            }
        }
        return totalUnredeemed;
    }

    // Returns list with the unredeemed card IDs at an address.
    function getUnredeemedCards(address player)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory cardIds = royalSociety.walletOfOwner(player);
        uint256 unredeemedAmount = getUnredeemedAmount(player);
        uint256[] memory cardIdsUnredeemed = new uint256[](unredeemedAmount);

        uint256 cardsAdded;
        uint256 cardId;
        for (uint256 i; i < cardIds.length; i++) {
            cardId = cardIds[i];
            if (cardRedeemed[cardId] == false) {
                cardIdsUnredeemed[cardsAdded] = cardId;
                cardsAdded += 1;
            }
        }
        return cardIdsUnredeemed;
    }

    // Allows players to claim the chip IDs that match unredeemed cards in their wallet.
    function claim(uint256 _count) public payable dropIsOpen {
        require(
            _maxPerTx > _count,
            "This amount is over the max per transaction limit in place to prevent gas limit issues."
        );
        uint256[] memory cardIdsUnredeemed = getUnredeemedCards(msg.sender);
        require(
            cardIdsUnredeemed.length >= _count,
            "Not enough unredeemed cards in this wallet for this amount."
        );

        uint256 cardId;
        for (uint256 i; i < _count; i++) {
            cardId = cardIdsUnredeemed[i];
            _safeMint(msg.sender, cardId);
            cardRedeemed[cardId] = true;
        }
    }

    // Gets the next unredeemed token that was left unredeemed during the drop.
    function getNextUnredeemed() internal view returns (uint256 tokenId) {
        uint256 i = _lastOwnerSweep;
        for (i; i < _maxSupply; i++) {
            if (cardRedeemed[i] == false) {
                return i;
            }
        }
        revert("All tokens already redeemed");
    }

    // Allows owner to claim unredeemed chips after the drop period
    function claimUnredeemed(uint256 _count) public payable onlyOwner {
        uint256 totalLeft = _maxSupply - totalSupply();
        require(
            block.timestamp > _dropTime + _dropDuration,
            "The drop has not yet ended."
        );
        require(
            totalLeft >= _count,
            "This amount is more than remain unclaimed."
        );

        uint256 sweepID;
        for (uint256 i; i < _count; i++) {
            sweepID = getNextUnredeemed();

            _safeMint(msg.sender, sweepID);
            cardRedeemed[sweepID] = true;
            _lastOwnerSweep = sweepID;
        }
    }

    // Returns list of all token IDs at an address.
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}