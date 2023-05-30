// SPDX-License-Identifier: MIT

////////////////////////////////////////////////////////////////////
//                       ,╓▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄,                     //
//                 ,▄▓██████████████████████████▄▄                //
//             ,▄███████████████████████████████████▄,            //
//          .▄█████████████████████████████████████████▄          //
//        ,▓█████████████████████████████████████████████▄        //
//       ▄█████████████████████████████████████████████████       //
//      ▓███████████████████████████████████████████████████      //
//     ╟█████████████████████████████████████████████████████     //
//    ]██████████████████████████████████████████████████████▌    //
//    ▐███████████████████████████████████████████████████████    //
//    ║███████████████████████████████████████████████████████    //
//    ▐███████████████████████████████████████████████████████    //
//     ████████▀▀█████████████████████████████████████▀▀██████    //
//     ╙██████        └╙▀▀██████████████████▀▀╙╙└       ║█████    //
//      ╚█████▌              └╟█████████╙               █████`    //
//       ╚█████              ,▓█████████▄              ╟████      //
//        ╙█████            ▄█████████████ç           ▐███▌       //
//         ╙██████▄,     ▄▓███████▀╙████████▄,    ,▄▓█████        //
//          ╟████████████████████└   ╙███████████████████▌        //
//          ▐███████████████████      ╙██████████████████▌        //
//          ▓██████████████████▌  ▐█⌐  ███████████████████⌐       //
//          ╚█████████████████████████████████████████████        //
//            └╙└   ╙████████████████████████████▀▀▀▀▀▀▀└         //
//                 ██▄▓████████████████████████╙,▓█               //
//                 ╚██╜▀╙███████████████████▀█▀]██▌               //
//                  ██▌,▄╙╙╙╙██▀╟██████▒╙██▌ ,╓███                //
//                  ███▓█▌▓█▌ ▄▄ ▀▀▒╙▀▀▒ .▄▄j█████                //
//                 ║█████████████▓███▄███▄████████▒               //
//                  ╙█████████████████████████████▌               //
//                    ╙▀████████████████████████▀└                //
//                       ╙▀█████████████████▀▀└                   //
//                          └╙▀█████████▀╙`                       //
//                                '''                             //
////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Boneheads is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;
    uint constant MAX_TOKENS = 10000;
    uint constant NUM_RESERVED_TOKENS = 250;
    address constant SHAREHOLDERS_ADDRESS = 0xb1FA950B59eE7e228e5f666Bf33d64E8158aC1A3;

    constructor() ERC721("BONEHEADS", "BONE") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve() public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < NUM_RESERVED_TOKENS; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    function mint(uint numberOfBoneheads) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfBoneheads <= 50, "Exceeded max purchase amount");
        require(totalSupply() + numberOfBoneheads <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(0.1 ether * numberOfBoneheads <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfBoneheads; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(SHAREHOLDERS_ADDRESS).transfer(balance);
    }
}