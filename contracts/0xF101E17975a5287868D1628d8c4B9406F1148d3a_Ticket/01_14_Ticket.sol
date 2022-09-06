// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Ticket is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public i_imageUri;

    constructor(string memory imageUri) ERC721("Saturna Ticket", "ST") {}

    struct Lottery {
        uint256 id;
        uint256 date;
    }

    mapping(uint256 => Lottery) public s_lottries;

    address public s_lotteryHub;

    modifier onlyLotteryHub() {
        require(
            msg.sender == s_lotteryHub,
            "OnlyLotteryHub: Caller is not lottery contract"
        );
        _;
    }

    function mint(uint256 _lotteryId, address _participant)
        external
        onlyLotteryHub
    {
        uint256 supply = totalSupply();
        Lottery memory newLottery = Lottery(_lotteryId, block.timestamp);
        s_lottries[supply + 1] = newLottery;
        _safeMint(_participant, supply + 1);
    }

    function buildMetadata(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        Lottery memory currentLottery = s_lottries[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                string(
                                    abi.encodePacked(
                                        "# ",
                                        _tokenId.toString(),
                                        " "
                                    )
                                ),
                                '", "description":"',
                                "Saturna Lottery Ticket",
                                '", "image": "',
                                i_imageUri,
                                '", "attributes":[{"trait_type":"Lottery Id","value":"',
                                currentLottery.id.toString(),
                                '"},{"trait_type":"Date":"',
                                currentLottery.date.toString(),
                                '"}]}'
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetadata(_tokenId);
    }

    function setLotteryHub(address _lotteryhub) public onlyOwner {
        s_lotteryHub = _lotteryhub;
    }
}