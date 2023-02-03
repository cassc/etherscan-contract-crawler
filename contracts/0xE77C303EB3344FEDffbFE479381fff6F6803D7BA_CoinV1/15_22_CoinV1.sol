// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "../foundation/FoundNote.sol";
import "../foundation/DailyMint.sol";
import "./DescriptorV1.sol";

contract CoinV1 is DescriptorV1 {
    using Strings for uint;

    FoundNote private _note;
    DailyMint private _mint;

    function tokenCount() external view returns (uint) {
        uint coinId = _note.currentDay();
        uint artId = _note.coinToArt(coinId);
        return artId == 0 ? coinId - 1 : coinId;
    }

    function ownerOf(uint tokenId) external view returns (address) {
        uint artId = _note.coinToArt(tokenId);
        return _note.data().ownerOf(artId);
    }

    function _encodeArtId(uint tokenId) override internal view returns (uint) {
        return _note.coinToArt(tokenId);
    }

    function _encodeData(uint tokenId) override internal view returns (bytes memory) {
        uint artId = _note.coinToArt(tokenId);
        return abi.encodePacked(
            '{"id":', tokenId.toString(),
            artId > 0 ? _encodeInfo(artId) : new bytes(0),
            '}'
        );
    }

    function coinStats() external view returns (string memory) {
        bytes memory stats;
        uint total = _note.currentDay();

        for (uint coinId = 1; coinId <= total; coinId += 1) {
            if (coinId == total) {
                stats = abi.encodePacked(stats, tokenStats(coinId));
            } else {
                stats = abi.encodePacked(stats, tokenStats(coinId), ',');
            }
        }

        ArtData data = _note.data();

        return string(
            abi.encodePacked(
                '{"currentDay":', _note.currentDay().toString(),
                ',"timestamp":', block.timestamp.toString(),
                ',"totalSupply":', EncoderV1.encodeDecimals(_mint.totalSupply()),
                ',"totalArt":', data.tokenCount().toString(),
                ',"stats":[', stats ,']}'
            )
        );
    }

    function coinBalances(address addr) external view returns (string memory) {
        bytes memory balances;
        uint total = _note.currentDay();

        for (uint coinId = 1; coinId <= total; coinId += 1) {
            uint balance = _mint.balanceOf(addr, coinId);
            if (coinId == total) {
                balances = abi.encodePacked(balances, EncoderV1.encodeDecimals(balance));
            } else {
                balances = abi.encodePacked(balances, EncoderV1.encodeDecimals(balance), ',');
            }
        }

        return string(abi.encodePacked('[', balances ,']'));
    }

    function artStats(uint coinId, uint start, uint end) external view returns (string memory) {
        uint startId = start == 0 ? 1 : start;
        uint coin = coinId == 0 ? _note.currentDay() : coinId;
        uint total = end == 0 ? _note.data().tokenCount() : end;

        bytes memory stats;

        for (uint artId = startId; artId <= total; artId += 1) {
            if (artId == total) {
                stats = abi.encodePacked(stats, _artStats(artId, coin));
            } else {
                stats = abi.encodePacked(stats, _artStats(artId, coin), ',');
            }
        }

        return string(
            abi.encodePacked(
                '{"currentDay":', coin.toString(),
                ',"timestamp":', block.timestamp.toString(),
                ',"stats":[', stats ,']}'
            )
        );
    }

    function tokenStats(uint coinId) public view returns (string memory) {
        uint artId = _note.coinToArt(coinId);
        return string(
            abi.encodePacked(
                '{"coinId":', coinId.toString(),
                ',"artId":', artId.toString(),
                ',"dailyBonus":', EncoderV1.encodeDecimals(_note.dailyBonus()),
                ',"address":', EncoderV1.encodeAddress(address(_mint.addressOf(coinId))),
                _tokenStats(artId, coinId),
                '}'
            )
        );
    }

    function _tokenStats(uint artId, uint coinId) internal view returns (bytes memory) {
        return abi.encodePacked(
            ',"votes":', EncoderV1.encodeDecimals(_note.votesOnArt(coinId, artId)),
            ',"claim":', EncoderV1.encodeDecimals(_note.getClaim(coinId)),
            ',"lock":', EncoderV1.encodeDecimals(_note.getLock(artId)),
            ',"supply":', EncoderV1.encodeDecimals(_mint.totalSupplyOf(coinId)),
            ',"rate":', EncoderV1.encodeDecimals(_mint.convertCoin(coinId, 1 ether))
        );
    }

    function _artStats(uint artId, uint coinId) internal view returns (string memory) {
        return string(abi.encodePacked(
            '{"artId":', artId.toString(),
            ',"coinId":', _note.artToCoin(artId).toString(),
            ',"votes":', EncoderV1.encodeDecimals(_note.votesOnArt(coinId, artId)),
            '}'
        ));
    }

    constructor(ArtData data_, FoundNote note_, DailyMint mint_) DescriptorV1(data_) {
        _note = note_;
        _mint = mint_;
    }
}