// SPDX-License-Identifier: MIT
// Capsule Machine NFT
// Because we have the freedom to say and make what we want we must.

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CapsuleMachineNFT is ERC721A {
    using SafeMath for uint256;

    address private constant artist_1 = 0x28a3182325A294b2f9eb021e70a5F11E9437c4c5;
    address private constant artist_2 = 0x9438d54Dc1eeAB1B2E1bdad6F1A46A80aBAD82DD;
    address private constant artist_3 = 0xf15b41e2CEECFF60fD3DdEed994475f17579a413;
    address private constant artist_4 = 0x43eE0FA4c93Cd778C09A108973731BA148d46b11;
    address private constant artist_5 = 0x7b33E65A682CC5c106b8B859bD6703E1548d65d8;
    address private constant artist_6 = 0x15109f7f8Ac81710daec2bc9296C4bAB677b6820;
    address private constant artist_7 = 0xffAB16457766C76d264cacdA07911CeAAB021D88;
    address private constant artist_8 = 0xb185cF7fD38D46387E760BDB66357D8B050839eA;
    address private constant artist_9 = 0x4dCEA2Fb6Eed9b45223CC214232B8a7DB55394d8;
    address private constant artist_10 = 0xBf3343C0cd08752de20fC846756EBC26A3F2d1f1;
    address private constant artist_11 = 0x5B183897c25E738dAFF8dCd7E1AA1E0501613640;
    address private constant artist_12 = 0xc0A2c04F88C51fF086D1162b9C579d7bD6e86255;
    address private constant artist_13 = 0x3F52b97EA2105307005b51532356f02A1C6095C8;
    address private constant artist_14 = 0xaA86bb428DaA756Ef618373c0415735F5621D628;
    address private constant artist_15 = 0x3c8FbAd346D66B0d58dddfb16AD94e515EA09BCC;
    address private constant artist_16 = 0x52F11485954ffCf3504846AD7b8E03CE8941b92e;
    address private constant artist_17 = 0xCd9a76966C158739A3c4407dfdB2F7B93B156c34;
    address private constant artist_18 = 0x60D261917a07746cADf5aD57367F394F8DD4Bd07;
    address private constant artist_19 = 0xB3f746d20406314130917E4bE87069667840A69b;
    address private constant artist_20 = 0xf68C43DadB156AC9C9a2C4052A5B3c3cb2e628A8;

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 cut = balance.div(20);
        payable(artist_1).transfer(cut);
        payable(artist_2).transfer(cut);
        payable(artist_3).transfer(cut);
        payable(artist_4).transfer(cut);
        payable(artist_5).transfer(cut);
        payable(artist_6).transfer(cut);
        payable(artist_7).transfer(cut);
        payable(artist_8).transfer(cut);
        payable(artist_9).transfer(cut);
        payable(artist_10).transfer(cut);
        payable(artist_11).transfer(cut);
        payable(artist_12).transfer(cut);
        payable(artist_13).transfer(cut);
        payable(artist_14).transfer(cut);
        payable(artist_15).transfer(cut);
        payable(artist_16).transfer(cut);
        payable(artist_17).transfer(cut);
        payable(artist_18).transfer(cut);
        payable(artist_19).transfer(cut);
        payable(artist_20).transfer(cut);
    }

    constructor()
        ERC721A("Capsule Machine NFT", "CMNFT", 20, "ipfs://QmNsrxoVdgkBbHH7qemsoHYvoxgW8wQ2KTwE5G1LdLXEJW/")
    {}

    function mint(uint256 quantity) external payable {
        _safeMint(msg.sender, quantity);
    }
}