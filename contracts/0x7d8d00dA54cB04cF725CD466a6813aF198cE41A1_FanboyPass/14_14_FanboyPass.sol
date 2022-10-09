// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

contract FanboyPass is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public totalMint = 250;

    string IMGURL = "https://sekerfactory.mypinata.cloud/ipfs/QmXUt2ik3Ph59r8r7Tx4L745UB3T1EX7g9BFUYEqqSCPwH";


    constructor() ERC721("Skeleton Steph Fanboy Pass", "SSFP") {}

    function mint() public {
        require(
            Counters.current(_tokenIds) <= totalMint,
            "minting has reached its max"
        );
        uint256 newNFT = _tokenIds.current();
        _safeMint(msg.sender, newNFT);
        _tokenIds.increment();
    }

    function updateTotalMint(uint256 _newSupply) public onlyOwner {
        require(_newSupply > _tokenIds.current(), "new supply less than already minted");
        totalMint = _newSupply;
    }

    function updateTokenURI(string memory _newURI) public onlyOwner {
        IMGURL = _newURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "SS Fanboy Pass: URI query for nonexistent token"
        );
        return generateCardURI(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function generateCardURI(uint256 _id) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Skeleton Steph - Fanboy Pass",',
                                '"description":"Locks in your minting spot for the exclusive Skeleton Steph Genesis Mini-Series, which goes live Oct. 15th",',
                                '"attributes": ',
                                "[",
                                '{"trait_type":"Fanboy Number","value":"',
                                Strings.toString(_id),
                                "/",
                                Strings.toString(totalMint),
                                '"}',
                                "],",
                                '"image":"',
                                IMGURL,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}