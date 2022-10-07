// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MultipleToken
 * @notice Manages all the ERC1155 capabilities of the MetaPlayerOne token.
 */
contract MultipleToken is ERC1155, Pausable {
    struct Token { uint256 token_id; address creator; string token_uri; uint256 royalty; }

    Token[] public _tokens;
    mapping(uint256 => bool) _exists;

    event tokenCreated(uint256 token_id, address creator, string token_uri, uint256 royalty, uint256 amount);

    /**
     * @dev setup contract owner.
     */
    constructor(address owner_of_) ERC1155("") Pausable(owner_of_) {}

    /**
     * @dev allows you to mint ERC1155 MetaPlayerOne tokens.
     * @param token_uri link to metadata.
     * @param amount amount of ERC1155 to mint
     * @param royalty The percentage that will be returned to the owner every time it is sold on the MetaPlayerOne platform.
     */
    function mint(string memory token_uri, uint256 amount, uint256 royalty) public notPaused {
        require(royalty <= 100, "Royalty can not be greater than 100");
        uint256 newTokenId = _tokens.length;
        _mint(msg.sender, newTokenId, amount, "");
        _tokens.push(Token(newTokenId, msg.sender, token_uri, royalty));
        emit tokenCreated(newTokenId, msg.sender, token_uri, royalty, amount);
        _exists[newTokenId] = true;
    }

     /**
     * @dev allows you to burn ERC1155 MetaPlayerOne tokens.
     * @param token_id id of the token to be burned.
     * @param amount amount of the tokens to be burned.
     */
    function burn(uint256 token_id, uint256 amount) public {
        require(_exists[token_id], "Token does not exists");
        require(balanceOf(msg.sender, token_id) >= amount, "You are not an owner of this nft");
        _burn(msg.sender, token_id, amount);
    }

    function uri(uint256 token_id) public view override returns (string memory) {
        require(_exists[token_id], "Token does not exists");
        return _tokens[token_id].token_uri;
    }

    function getRoyalty(uint256 token_id) public view returns (uint256) {
        require(_exists[token_id], "Token does not exists");
        return _tokens[token_id].royalty;
    }

    function getCreator(uint256 token_id) public view returns (address) {
        require(_exists[token_id], "Token does not exists");
        return _tokens[token_id].creator;
    }
}