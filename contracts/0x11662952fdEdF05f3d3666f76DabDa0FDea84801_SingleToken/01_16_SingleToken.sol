// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

import {Pausable} from "../../../Pausable.sol";
import {IRandomizer} from "../../Randomizer/IRandomizer.sol";

/**
 * @author MetaPlayerOne DAO
 * @title SingleToken
 */
contract SingleToken is ERC721, Pausable, ERC2981 {
    mapping(uint256 => string) private _tokens;
    address private _randomizer_address;

    constructor(address owner_of_, address randomizer_address_)
        ERC721("MetaPlayerOneSuperRare", "MetaPlayerOneSuperRare")
        Pausable(owner_of_)
    {
        _randomizer_address = randomizer_address_;
    }

    function burn(uint256 tokenId) public notPaused {
        require(_exists(tokenId), "Token does not exists");
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not an owner of this nft"
        );
        _burn(tokenId);
    }

    function mint(string memory token_uri, uint96 fee) public notPaused {
        uint256 tokenId = IRandomizer(_randomizer_address).requestRandomWords();
        _setTokenRoyalty(tokenId, msg.sender, fee);
        _safeMint(msg.sender, tokenId);
        _tokens[tokenId] = token_uri;
    }

    function tokenURI(uint256 token_id)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(token_id), "Token does not exists");
        return _tokens[token_id];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}