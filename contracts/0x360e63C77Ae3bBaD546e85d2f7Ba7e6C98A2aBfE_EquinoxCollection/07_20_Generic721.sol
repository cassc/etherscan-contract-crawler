//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract Generic721 is ERC721Enumerable {
    struct CardTypeStructure {
        string className;
        uint64 start; // class starting serial
        uint64 end; // class end serial
        uint64 minted; // minted
        uint64 initial;
        uint128 mintTime;
        uint128 mintEndTime;
    }

    mapping(uint64 => CardTypeStructure) public CardType;

    uint64 public CardTypeCount = 0;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    function getCardTypeFromID(uint64 _tokenID)
        public
        view
        returns (uint64, string memory)
    {
        for (uint64 i = 1; i < (CardTypeCount + 1); i++) {
            if (CardType[i].start <= _tokenID && _tokenID <= CardType[i].end) {
                return (i, CardType[i].className);
            }
        }
        return (0, "Unresolved");
    }

    function getAllData()
        public
        view
        returns (
            string[] memory,
            uint64[] memory,
            uint64[] memory,
            uint64[] memory,
            uint64[] memory,
            uint64[] memory,
            uint64,
            uint128[] memory
        )
    {
        string[] memory _className = new string[](CardTypeCount);
        uint64[] memory _start = new uint64[](CardTypeCount);
        uint64[] memory _end = new uint64[](CardTypeCount);
        uint64[] memory _minted = new uint64[](CardTypeCount);
        uint64[] memory _initial = new uint64[](CardTypeCount);
        uint64[] memory _available = new uint64[](CardTypeCount);
        uint128[] memory _mintEndTime = new uint128[](CardTypeCount);

        for (uint64 i = 0; i < CardTypeCount; i++) {
            CardTypeStructure memory p = CardType[i + 1];
            _className[i] = p.className;
            _start[i] = p.start;
            _end[i] = p.end;
            _minted[i] = p.minted;
            _initial[i] = p.initial;
            _available[i] = this.getCardTypeAvailable(i + 1);
            _mintEndTime[i] = p.mintEndTime;
        }
        // console.log("Count %s " , CardTypeCount);
        return (
            _className,
            _start,
            _end,
            _minted,
            _initial,
            _available,
            getCurrentSeries(),
            _mintEndTime
        );
    }

    function getMintTime(uint64 _cardID)
        public
        view
        returns (uint128, uint128)
    {
        return (CardType[_cardID].mintTime, CardType[_cardID].mintEndTime);
    }

    function getCurrentSeries() public view returns (uint64) {
        for (uint64 i = 1; i <= CardTypeCount; i++) {
            if (
                CardType[i].mintTime <= block.timestamp &&
                block.timestamp <= CardType[i].mintEndTime
            ) {
                return i;
            }
        }
        return 0;
    }

    function canMint(uint64 _cardID) public view returns (bool) {
        return (block.timestamp > CardType[_cardID].mintTime &&
            CardType[_cardID].mintEndTime > block.timestamp);
    }

    function getCardTypeMinted(uint64 _cardID) public view returns (uint64) {
        return CardType[_cardID].minted;
    }

    function getCardTypeInitial(uint64 _cardID) public view returns (uint64) {
        return CardType[_cardID].initial;
    }

    function getCardTypeNextID(uint64 _cardID) public view returns (uint64) {
        if (
            CardType[_cardID].start + CardType[_cardID].minted <=
            CardType[_cardID].end
        ) {
            return CardType[_cardID].start + CardType[_cardID].minted;
        } else {
            return 0;
        }
    }

    function getCardTypeAvailable(uint64 _cardID) public view returns (uint64) {
        return CardType[_cardID].initial - CardType[_cardID].minted;
    }

    function addCardClass(
        string memory _className,
        uint64 _start, // class starting serial
        uint64 _end, // class end serial
        uint128 _mintTime
    ) public virtual {
        require(
            _start < _end,
            "Starting index cannot be larger than ending index."
        );
        require(block.timestamp <= _mintTime, "Past");
        CardType[CardTypeCount + 1].className = _className;
        CardType[CardTypeCount + 1].start = _start;
        CardType[CardTypeCount + 1].end = _end;
        CardType[CardTypeCount + 1].initial = _end - _start + 1;
        CardType[CardTypeCount + 1].minted = 0;
        CardType[CardTypeCount + 1].mintTime = _mintTime;
        CardType[CardTypeCount + 1].mintEndTime = _mintTime + 30 days;
        CardTypeCount++;
    }

    function ManOverrideCard(
        uint64 _cardID,
        string memory _className,
        uint64 _start,
        uint64 _end,
        uint64 _initial,
        uint64 _minted
    ) public virtual {
        CardType[_cardID].className = _className;
        CardType[_cardID].start = _start;
        CardType[_cardID].end = _end;
        CardType[_cardID].initial = _initial;
        CardType[_cardID].minted = _minted;
    }

    function _safeMint(address _recipient, uint256 _tokenID)
        internal
        virtual
        override
    {
        for (uint64 i = 1; i <= CardTypeCount + 1; i++) {
            if (CardType[i].start <= _tokenID && _tokenID <= CardType[i].end) {
                require(
                    block.timestamp > CardType[i].mintTime,
                    "not ready yet."
                );
                ERC721._safeMint(_recipient, _tokenID);
                CardType[i].minted = CardType[i].minted + 1;
                return;
            }
        }
    }
}