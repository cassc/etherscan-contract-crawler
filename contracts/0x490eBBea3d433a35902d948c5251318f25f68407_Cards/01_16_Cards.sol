// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Metadata.sol";



//     ██████  █████  ██████  ██████  ███████      ██ ███████  ██████  ██████       ██████   █████  ███    ███ ██████  ██      ███████ ██████  ███████ ██  
//    ██      ██   ██ ██   ██ ██   ██ ██          ██  ██      ██    ██ ██   ██     ██       ██   ██ ████  ████ ██   ██ ██      ██      ██   ██ ██       ██ 
//    ██      ███████ ██████  ██   ██ ███████     ██  █████   ██    ██ ██████      ██   ███ ███████ ██ ████ ██ ██████  ██      █████   ██████  ███████  ██ 
//    ██      ██   ██ ██   ██ ██   ██      ██     ██  ██      ██    ██ ██   ██     ██    ██ ██   ██ ██  ██  ██ ██   ██ ██      ██      ██   ██      ██  ██ 
//     ██████ ██   ██ ██   ██ ██████  ███████      ██ ██       ██████  ██   ██      ██████  ██   ██ ██      ██ ██████  ███████ ███████ ██   ██ ███████ ██  
//
//    The "Cards" NFT collection consists of the 1326
//    unique poker starting hand combinations that can
//    be obtained within a deck of 52 cards. Each starting
//    hand's metadata as well as each individual card's
//    image and name is generated fully on-chain and will
//    forever be accessible by external contracts and dApps.
//
//    By minting a poker hand, you are contributing to the
//    first ever fully on-chain composable Poker card deck.
//    Relying on cryptography, "Cards" uses a novel minting
//    method that puts emphasis on community by placing the
//    burden of on-chain data insertion on minter which makes
//    each mint a little more gas intensive than the ERC721
//    norm. Each token is orderly tied to a specific set of
//    cards via a permanent card deck merkle root that cannot
//    be altered.
//
//    Initial Launch --> https://wtf.cards



contract Cards is ERC721, ERC721Enumerable, Metadata, ReentrancyGuard {

    constructor() ERC721("Cards", "CARD") {}

    /**
    * @notice Verifiable immutable root of the 1326 2-card combinations in a 52 card deck.
    */
    bytes32 immutable public root = 0xb2f7e5087e23e0037c280a3eadd136a419be00de197b1c864632ca7adceb989f;

    /**
    * @notice Claim function can only be used via the launch website.
    *
    * @param _tokenId The token ID you are minting
    * @param _card1 The first card's index to be assigned to the token you are minting
    * @param _card2 The second card's index to be assigned to the token you are minting
    * @param _proof Proof that ties the token ID with the index of the cards in the hand.
    * @param _shuffleIndex The shuffling parameter of the mint.
    */
    function claim(uint256 _tokenId, uint256 _card1, uint256 _card2, bytes32[] calldata _proof, uint160 _shuffleIndex) public nonReentrant shuffle(_shuffleIndex) {
        require(!_exists(_tokenId), "This token was already minted.");
        require(MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(_tokenId, _card1, _card2))), "Must mint the proper token and cards.");
        tokenToCards[_tokenId] = [_card1, _card2];
        mintedHands.push(_tokenId);
        limiter[msg.sender] = true;
        _safeMint(msg.sender, _tokenId);
    }

    /**
    * @notice An external contract or dApp can call the plaintext names of a hand.
    *
    * @param _tokenId Token ID between 0 and 1325
    */
    function getNamesByToken(uint256 _tokenId) external view returns (string[2] memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return [cardNames[tokenToCards[_tokenId][0]], cardNames[tokenToCards[_tokenId][1]]];
    }

    /**
    * @notice An external contract or dApp can call the plaintext icons of a hand.
    *
    * @param _tokenId Token ID between 0 and 1325
    */
    function getIconsByToken(uint256 _tokenId) external view returns (string[2] memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return [cardIcons[tokenToCards[_tokenId][0]], cardIcons[tokenToCards[_tokenId][1]]];
    }

    /**
    * @notice An external contract or dApp can call the name of a specific card by its index.
    *
    * @param _index Card index between 0 and 51
    */
    function getCardNameByIndex(uint256 _index) external view returns (string memory) {
        return cardNames[_index];
    }

    /**
    * @notice An external contract or dApp can call the icon of a specific card by its index.
    *
    * @param _index Card index between 0 and 51
    */
    function getCardIconByIndex(uint256 _index) external view returns (string memory) {
        return cardIcons[_index];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked('data:application/json;base64,', getMetadataJSON(tokenId, getMetadataImage(tokenId))));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}