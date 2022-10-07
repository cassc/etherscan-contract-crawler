// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title SingleToken
 * @notice Manages all the ERC721 capabilities of the MetaPlayerOne token.
 */
contract SingleToken is ERC721, Pausable {
    struct Token { uint256 token_id; address creator; string token_uri; uint256 royalty; }

    Token[] public _tokens;

    event tokenCreated(uint256 token_id, address creator, uint256 royalty);

    /**
     * @dev setup contract owner.
     */
    constructor(address owner_of_) ERC721("MetaPlayerOneSuperRare", "MetaPlayerOneSuperRare") Pausable(owner_of_) {}

    /**
     * @dev allows you to mint ERC721 MetaPlayerOne tokens.
     * @param token_uri link to metadata.
     * @param royalty The percentage that will be returned to the owner every time it is sold on the MetaPlayerOne platform.
     */
    function mint(string memory token_uri, uint256 royalty) public notPaused {
        require(royalty <= 100, "Royalty can not be greater than 100");
        uint256 newTokenId = _tokens.length;
        _safeMint(msg.sender, newTokenId);
        _tokens.push(Token(newTokenId, msg.sender, token_uri, royalty));
        emit tokenCreated(newTokenId, msg.sender, royalty);
    }

    /**
     * @dev allows you to burn ERC721 MetaPlayerOne tokens.
     * @param token_id id of the token to be burned.
     */
    function burn(uint256 token_id) public notPaused {
        require(_exists(token_id), "Token does not exists");
        require(ownerOf(token_id) == msg.sender, "You are not an owner of this nft");
        _burn(token_id);
    }

    /**
     * @dev allows you to mint ERC721 MetaPlayerOne tokens.
     * @param token_id id of the token whose metadata is to be retrieved.
     * @return token_uri link ot metadata.
     */
    function tokenURI(uint256 token_id) public view override returns (string memory) {
        require(_exists(token_id), "Token does not exists");
        return _tokens[token_id].token_uri;
    }

    /**
     * @dev allows you to mint ERC721 MetaPlayerOne tokens.
     * @param token_id id of the token whose royalty is to be retrieved.
     * @return royalty royalty percentage.
     */
    function getRoyalty(uint256 token_id) public view returns (uint256) {
        require(_exists(token_id), "Token does not exists");
        return _tokens[token_id].royalty;
    }

    /**
     * @dev allows to get the address of the user who created the token.
     * @param token_id id of the token whose creator is to be retrieved.
     * @return creator address of token's creator.
     */
    function getCreator(uint256 token_id) public view returns (address) {
        require(_exists(token_id), "Token does not exists");
        return _tokens[token_id].creator;
    }
}