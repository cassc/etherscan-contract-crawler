// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {XOGame} from "./XOGame.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract XOBribes is IERC721Metadata {
    XOGame private immutable game;

    mapping(address => uint256) public bribes;
    mapping(address => uint256) public contributions;

    event BribeOffer(address indexed from, address indexed to, uint256 amount);

    constructor(XOGame _game) payable {
        game = _game;
    }

    function offer(address to) external payable {
        require(game.winner() == XOGame.Cell.Empty, "Game ended");
        require(msg.value > 0, "Invalid amount");

        if (bribes[to] == 0) {
            // Simulate mint
            emit Transfer(address(0), to, uint256(uint160(to)));
        }

        bribes[to] += msg.value;
        contributions[msg.sender] += msg.value;

        emit BribeOffer(msg.sender, to, msg.value);
    }

    function accept() external {
        require(game.winner() == XOGame.Cell.O, "O needs to win");

        uint256 amount = bribes[msg.sender];
        require(amount > 0, "No bribe");

        bribes[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        // Simulate burn
        emit Transfer(msg.sender, address(0), uint256(uint160(msg.sender)));
    }

    function retract() external {
        require(game.winner() == XOGame.Cell.X, "X needs to win");

        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No contribution");

        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // ERC721

    function balanceOf(address owner) external view returns (uint256 balance) {
        return bribes[owner] > 0 ? 1 : 0;
    }

    function ownerOf(uint256 tokenId) external pure returns (address owner) {
        return address(uint160(tokenId));
    }

    function name() external pure returns (string memory) {
        return "Bribes (O)";
    }

    function symbol() external pure returns (string memory) {
        return "BRBO";
    }

    function tokenURI(uint256 tokenId) external pure returns (string memory) {
        return string.concat("https://xo.w1nt3r.xyz/api/bribe/o/", Strings.toHexString(address(uint160(tokenId))));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId;
    }

    // Non-transferrable NFT implementation

    function safeTransferFrom(address, address, uint256) external pure {
        revert();
    }

    function transferFrom(address, address, uint256) external pure {
        revert();
    }

    function approve(address, uint256) external pure {
        revert();
    }

    function getApproved(uint256) external pure returns (address operator) {
        return address(0);
    }

    function setApprovalForAll(address, bool) external pure {
        revert();
    }

    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external pure {
        revert();
    }
}