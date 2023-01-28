// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721A} from 'erc721a/ERC721A.sol';
import {Base64} from "openzeppelin-contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

contract Lottery is ERC721A {

    mapping(uint256 => bool) public winningTokens;
    mapping(uint256 => bool) public tokenClaimed;
    mapping(uint256 => uint256) public winningTokensIndex;
    uint256 public max = 5000;
    uint256 public price = 0.01 ether;
    uint256 public winners = 10;
    uint256 public winningAmount = 1 ether;
    bool public minting;
    bool public phraseSet;
    bool public tokensSet;
    address public owner;
    string public winningPhraseHash;
    
    constructor() ERC721A("A Few of Us", "AFOUAGMI") {
        owner = msg.sender;
    }

    /*
    * Modifiers
    */ 

    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    /*
    * Admin
    */

    function setWinningTokens(uint256[] calldata _tokenIds) external onlyOwner {
        require(phraseSet == true, "phrase not set");
        require(tokensSet == false, "tokens already set");
        require(_tokenIds.length == winners, "not enough winners");
        for (uint256 i; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(tokenId < totalSupply(), "not within supply");
            winningTokens[tokenId] = true;
            winningTokensIndex[i] = tokenId;
        }
        tokensSet = true;
    }

    function setWinningPhrase(string memory _phrase) external onlyOwner {
        require(phraseSet == false, "phrase already set");
        winningPhraseHash = _phrase;
        phraseSet = true;
    }

    function withdraw(uint256 _amount) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "failed to withdraw");
    }

    /*
    * Tokens
    */

    function mint(uint256 _amount) external payable {
        require(phraseSet == true, "phrase not set");
        require(totalSupply() + _amount <= max, "not enough supply");
        require(msg.value >= _amount * price, "not enough ether");
        _safeMint(msg.sender, _amount);
    }

    function getWinningTokens() external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](winners);
        for (uint256 i; i < winners; i++) {
            tokenIds[i] = winningTokensIndex[i];
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory isWinner = "false";
        if (winningTokens[tokenId]) {
            isWinner = "true";
        }
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "AFOUAGMI #', Strings.toString(tokenId), '"',
                        ', "description": "A Few Of Us Are Gonna Make It."',
                        ', "attributes": [{"trait_type": "winner", "value": "',
                        isWinner,
                        '"}]',
                        ', "image_data": "data:image/svg+xml;base64,',
                        Base64.encode(
                            bytes(
                                string(
                                    abi.encodePacked(
                                        '<svg height="160" width="160" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" style="enable-background:new 0 0 160 160" xml:space="preserve">',
                                        '<rect width="160" height="160" fill="black" />',
                                        '</svg>'
                                    )
                                )
                            )
                        ),
                        '"}'
                    )
                )
            )
        );
        return string(
            abi.encodePacked(
                'data:application/json;base64,', 
                json
            )
        );
    }

    /*
    * Winners
    */

    function claimToken(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), "not owner of token");
        require(winningTokens[_tokenId] == true, "not a winning token");
        require(tokenClaimed[_tokenId] == false, "token already claimed");
        tokenClaimed[_tokenId] = true;
        (bool success, ) = payable(msg.sender).call{value: winningAmount}("");
        require(success, "failed to withdraw");
    }
    
}