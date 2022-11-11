// SPDX-License-Identifier: MIT
// Taipe Experience Contracts
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "../nft/TaipeNFT.sol";
import "./IMinter.sol";

import {TaipeLib} from "../lib/TaipeLib.sol";

contract RandomMinter is IMinter, Context {
    // shuffle algorithm
    mapping(uint => uint) private _availableTokens;
    uint private _availableCount;
    uint private _startingId;

    // nft instance
    TaipeNFT internal _nft;

    constructor(TaipeLib.Tier tier, address nft) {
        _nft = TaipeNFT(nft);
        _availableCount = TaipeLib.getAvailableCount(tier);
        _startingId = TaipeLib.getStartingId(tier);
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Only self can do this");
        _;
    }

    modifier hasAvailableToken() {
        require(tokensLeft() > 0, "No available token");
        _;
    }

    function mint(address to)
        public
        virtual
        override
        hasAvailableToken
        returns (uint id)
    {
        uint r = _random();
        id = this._mintRandomNft(to, r);
    }

    function _mintRandomNft(address to, uint random_number)
        external
        onlySelf
        returns (uint randomTokenId)
    {
        randomTokenId = _takeRandomNftId(random_number);
        _nft.mintTo(to, randomTokenId);
    }

    function _takeRandomNftId(uint random_number)
        internal
        returns (uint randomTokenId)
    {
        uint randomIndex = random_number % _availableCount;
        randomTokenId = _fisherYatesShuffle(randomIndex);
    }

    function _fisherYatesShuffle(uint indexToUse) internal returns (uint) {
        // implements fisher-yates shuffle algorithm
        uint valAtIndex = _availableTokens[indexToUse];
        uint result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = indexToUse;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint lastIndex = _availableCount - 1;
        if (indexToUse != lastIndex) {
            // Replace the value at indexToUse, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            uint lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                _availableTokens[indexToUse] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                _availableTokens[indexToUse] = lastValInArray;
                // Gas refund courtsey of @dievardump
                delete _availableTokens[lastIndex];
            }
        }
        _availableCount--;

        return 1 + _startingId + result;
    }

    // replace with VRF
    function _random() private view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        tx.gasprice,
                        block.number,
                        block.timestamp,
                        block.difficulty,
                        blockhash(block.number - 1),
                        address(this)
                    )
                )
            );
    }

    function tokensLeft() public view returns (uint) {
        return _availableCount - inflightTokens();
    }

    function inflightTokens() public view virtual returns (uint) {
        return 0;
    }
}