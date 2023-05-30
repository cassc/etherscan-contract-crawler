// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./BatchNFT.sol";

/**
 * @dev Contract to random draw winners and mint NFTs from an array of addresses.
 */
abstract contract Lottery is BatchNFT {
    event LotteryWinners(address[] winners);

    /**
     * @dev Random draw lottery winners from an array of addresses, mint NFT,
     * and emit an event to record winners.
     *
     * Emits a {LotteryWinners} event.
     */
    function drawLottery(address[] calldata addresses_, uint256 amount_)
        public
        onlyOwner
    {
        // empty array to store winner addresses
        address[] memory winners = _randomDraw(addresses_, amount_);

        // batch mint NFT for winners
        batchMint(winners, 1);

        // record lottery winners
        emit LotteryWinners(winners);
    }

    /**
     * @dev Random draw from an array of addresses and return the result.
     */
    function _randomDraw(address[] memory addresses_, uint256 amount_)
        public
        view
        returns (address[] memory result)
    {
        require(
            amount_ <= addresses_.length,
            "amount_ must be less than or equal to addresses_.length"
        );

        // empty array to store result
        result = new address[](amount_);

        for (uint256 i = 0; i < amount_; i++) {
            uint256 random = uint256(
                keccak256(
                    abi.encodePacked(
                        i,
                        msg.sender,
                        block.coinbase,
                        block.difficulty,
                        block.gaslimit,
                        block.timestamp
                    )
                )
            ) % (addresses_.length - i);

            result[i] = addresses_[random];

            addresses_[random] = addresses_[addresses_.length - i - 1];
        }

        return result;
    }
}