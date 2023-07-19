// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./token/ERC721Preset.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NoahNFT is ERC721Preset {
    using Strings for uint256;
    using Counters for Counters.Counter;

    event Mint(
        uint256 activityId,
        uint256 tokenId,
        address owner
    );

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721Preset(name, symbol, baseTokenURI) {}

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "NoahNFT: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        "/metadata.json"
                    )
                )
                : "";
    }

    function getAlltokenIdByAddress(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balance = this.balanceOf(owner);
        require(balance != 0, "NoahNFT: Owner has no token");
        uint256[] memory res = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            res[i] = this.tokenOfOwnerByIndex(owner, i);
        }

        return res;
    }

    function mint(uint256 activityId, address to) public returns (uint256) {
        uint256 tokenId = _tokenIdTracker.current();
        super.mint(to);

        emit Mint(activityId, tokenId, to);
        return tokenId;
    }
}