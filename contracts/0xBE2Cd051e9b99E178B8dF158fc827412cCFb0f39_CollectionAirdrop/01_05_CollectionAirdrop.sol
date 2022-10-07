// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title CollectionAirdrop
 */
contract CollectionAirdrop is Pausable {
    struct Metadata { string title; string description; string file_uri; }
    struct Airdrop { uint256 uid; address owner_of; uint256 claimed; uint256 amount; address token_address; uint256 start_time; uint256 limit_per_wallet; address access_token_address; uint256 access_fee; }
    struct Token { uint256 uid; uint256 airdrop_id; uint256 token_id; address token_address; bool claimed; }

    mapping(address => mapping(uint256 => uint256)) private _drop_received;

    Airdrop[] private _airdrops;
    Token[] private _tokens;

    constructor(address owner_of_) Pausable(_owner_of) {}

    event airdropCreated(uint256 uid, address owner_of, uint256 amount, address token_address, uint256 limit, Metadata metadata, uint256 start_time, address access_token_address, uint256 access_fee);
    event tokenSubmited(uint256 uid, uint256 token_id, address token_address);
    event tokenClaimed(uint256 uid, uint256 airdrop_uid, address claimer);
    event withdrawed(address owner_of, uint256 amount, uint256 airdrop_uid);

    function createDrop(Metadata memory metadata, address token_address, uint256 limit_per_wallet, uint256 start_time, uint256[] memory token_ids, address access_token_address, uint256 access_fee) public notPaused {
        IERC721 token = IERC721(token_address);
        uint256 newIdAirdrop = _airdrops.length;
        uint256 token_len = token_ids.length;
        _airdrops.push(Airdrop(newIdAirdrop, msg.sender, 0, token_len, token_address, start_time, limit_per_wallet, access_token_address, access_fee));
        emit airdropCreated(newIdAirdrop, msg.sender, token_len, token_address, limit_per_wallet, metadata, start_time, access_token_address, access_fee);
        for (uint256 i = 0; i < token_len; i++) {
            token.transferFrom(msg.sender, address(this), token_ids[i]);
            _tokens.push(Token(newIdAirdrop, newIdAirdrop, token_ids[i], token_address, false));
            emit tokenSubmited(newIdAirdrop, token_ids[i], token_address);
        }
    }

    function claim(uint256 uid, uint256 amount) public {
        Airdrop memory airdrop = _airdrops[uid];
        if (airdrop.access_token_address != address (0) && airdrop.access_fee != 0){
            require(IERC20(airdrop.access_token_address).balanceOf(msg.sender) >= airdrop.access_fee, "Balance of access token should be greater then access fee");
        }
        require(_drop_received[msg.sender][uid] + amount <= airdrop.limit_per_wallet, "Denied! Limit per wallet");
        require(airdrop.claimed + amount <= airdrop.amount, "Denied! Airdrop limit");
        require(_airdrops[uid].start_time < block.timestamp, "Denied! Airdrop hasn't start");
        uint256 matches = 0;
        _drop_received[msg.sender][uid] += amount;
        IERC721 erc721 = IERC721(airdrop.token_address);
        for (uint256 i = 0; i < _tokens.length; i++) {
            Token memory token = _tokens[i];
            if (token.airdrop_id == uid && !token.claimed) {
                if (matches >= amount) {
                    break;
                }
                erc721.transferFrom(address(this), msg.sender, token.token_id);
                _tokens[i].claimed = true;
                matches += 1;
                
            }
        }
    }

    function withdraw(uint256 uid) public {
        Airdrop memory airdrop = _airdrops[uid];
        require(msg.sender == airdrop.owner_of, "You are not an owner");
        require(airdrop.amount - airdrop.claimed > 0, "Nothing to withdraw");
        IERC721 erc721 = IERC721(airdrop.token_address);
        for (uint256 i = 0; i < _tokens.length; i++) {
            Token memory token = _tokens[i];
            if (token.airdrop_id == uid && !token.claimed) {
                erc721.transferFrom(address(this), msg.sender, token.token_id);
                emit tokenClaimed(uid, token.airdrop_id, msg.sender);
                _tokens[i].claimed = true;
            }
        }
        emit withdrawed(msg.sender, airdrop.amount - airdrop.claimed, uid);
    }
}