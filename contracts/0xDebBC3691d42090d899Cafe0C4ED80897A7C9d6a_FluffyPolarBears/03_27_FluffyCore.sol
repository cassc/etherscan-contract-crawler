// SPDX-License-Identifier: MIT
//  ______ _        __  __         _____      _              ____
// |  ____| |      / _|/ _|       |  __ \    | |            |  _ \
// | |__  | |_   _| |_| |_ _   _  | |__) |__ | | __ _ _ __  | |_) | ___  __ _ _ __ ___
// |  __| | | | | |  _|  _| | | | |  ___/ _ \| |/ _` | '__| |  _ < / _ \/ _` | '__/ __|
// | |    | | |_| | | | | | |_| | | |  | (_) | | (_| | |    | |_) |  __/ (_| | |  \__ \
// |_|    |_|\__,_|_| |_|  \__, | |_|   \___/|_|\__,_|_|    |____/ \___|\__,_|_|  |___/
//                          __/ |
//                         |___/
//
// Fluffy Polar Bears ERC-1155 Contract
// “Ice to meet you, this contract is smart and fluffy.”
/// @creator:     FluffyPolarBears
/// @author:      kodbilen.eth - twitter.com/kodbilenadam
/// @contributor: peker.eth – twitter.com/MehmetAliCode

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FluffyCore is VRFConsumerBase, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIdCounter;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

    struct Token {
        uint256 tokenId;
        uint8 bg;
        uint8 costume;
        uint8 eyes;
        uint8 head;
        uint8 nose;
        uint8 legendaryId;
        bool isExists;
        bool isLegendary;
    }

    event TokenInfoChanged(
        Token token
    );

    mapping(uint256 => Token) tokens;
    uint256[] tokenIds;

    uint8 BGS = 9;
    uint8 COSTUMES = 83;
    uint8 EYES = 46;
    uint8 HEADS = 87;
    uint8 NOSES = 32;

    constructor()
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
        0x514910771AF9Ca656af840dff83E8264EcF986CA
    )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18;
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() onlyOwner public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }


    function getToken(uint256 _id) public view returns (Token memory token) {
        return tokens[_id];
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    function convert8 (uint256 _a) internal pure returns (uint8)  {
        return uint8(_a);
    }

    function setMetadata(uint256 tokenId) internal {
        uint256 random = uint256(keccak256(abi.encode(tokenId,
            randomResult,
            msg.sender,
            block.number,
            block.timestamp,
            blockhash(block.number - 1))));
        uint8 bg = convert8(random % BGS) + 1;
        uint8 costume = convert8(random % COSTUMES) + 1;
        uint8 eye = convert8(random % EYES) + 1;
        uint8 head = convert8(random % HEADS) + 1;
        uint8 nose = convert8(random % NOSES) + 1;


        Token memory _token = Token(tokenId, bg, costume, eye, head, nose, 0, true, false);
        tokens[tokenId] = _token;

        emit TokenInfoChanged(_token);
    }


}