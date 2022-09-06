// SPDX-License-Identifier: MIT
//@author DavidNazareno
//@title  Beings Academy

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BeingsAcademy is ERC20, ERC721Holder, Ownable {
    IERC721 public beingsNFT;

    uint256 public totalBeingsOnAcademy;
    struct Being {
        uint24 tokenId;
        uint48 timestamp;
        address owner;
    }

    mapping(uint256 => Being) public beingOnAcademy;

    enum BeingsAcademyState {
        CLOSED,
        OPEN
    }

    BeingsAcademyState public currentState;

    constructor(address _beingsNFT) ERC20("BeingsAcademy", "BEINGSACADEMY") {
        beingsNFT = IERC721(_beingsNFT);
    }

    function beingEnterAcademy(uint256[] calldata tokenIds) external {
        require(
            currentState == BeingsAcademyState.OPEN,
            "The Academy is closed"
        );

        uint256 tokenId;

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(beingsNFT.ownerOf(tokenId) == msg.sender, "not your being");
            require(
                beingOnAcademy[tokenId].tokenId == 0,
                "already being on academy"
            );

            beingsNFT.transferFrom(msg.sender, address(this), tokenId);

            beingOnAcademy[tokenId] = Being({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
        }
        emit BeingEnterAcademy(msg.sender, tokenIds);

        totalBeingsOnAcademy += tokenIds.length;
    }

    function beingOutAcademy(uint256[] calldata tokenIds) external {
        require(
            currentState == BeingsAcademyState.OPEN,
            "The Academy is closed"
        );
        uint256 tokenId;

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Being memory being = beingOnAcademy[tokenId];
            require(being.owner == msg.sender, "not an owner");

            delete beingOnAcademy[tokenId];

            beingsNFT.transferFrom(address(this), msg.sender, tokenId);
        }
        emit BeingOutAcademy(msg.sender, tokenIds);
        totalBeingsOnAcademy -= tokenIds.length;
    }

    function beingAcademyPeriod(uint256 tokenId)
        external
        view
        returns (
            bool studying,
            uint256 current,
            uint256 total
        )
    {
        Being memory being = beingOnAcademy[tokenId];

        require(being.tokenId != 0, "being not on academy");

        studying = true;
        current = block.timestamp - being.timestamp;

        total = current + being.timestamp;
    }

    function setBeingsNFT(address _beingsNFT) external onlyOwner {
        beingsNFT = IERC721(_beingsNFT);
    }

    function withdrawAll(address _wallet) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_wallet).transfer(balance);
    }

    function setBeingsAcademyState(BeingsAcademyState _state)
        external
        onlyOwner
    {
        currentState = _state;
    }

    event BeingEnterAcademy(address indexed from, uint256[] tokensId);
    event BeingOutAcademy(address indexed from, uint256[] tokensId);
}