// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                     *@@@@@                                     //
//           #@@@#                   @@@@@@@@@@.                   @@@@,          //
//            ,@@@@@@               [email protected]@@@@@@@@@@               [email protected]@@@@@            //
//               &@@@@@@             #@@@@@@@@@             ,@@@@@@,              //
//                  @@@@@@@.            #@@@*            (@@@@@@&                 //
//                    (@@@@@@@*                       &@@@@@@@                    //
//                       @@@@@@@@(                 @@@@@@@@(                      //
//                         [email protected]@@@@@@@%           @@@@@@@@@                         //
//                            &@@@@@@@@&    ,@@@@@@@@@*                           //
//                               @@@@@@@@@@@@@@@@@@%                              //
//                                 /@@@@@@@@@@@@@.                                //
//                                    @@@@@@@@/                                   //
//                   [email protected]@@@@&            ,@@@            ,@@@@@@                   //
//                  @@@@@@@@@@                        ,@@@@@@@@@@                 //
//                 &@@@@@@@@@@,                       &@@@@@@@@@@                 //
//                  @@@@@@@@@(                         @@@@@@@@@(                 //
//                     #@@*                               #@@*                    //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////

import "./ERC721AMint.sol";
import "./MultiMint.sol";
import "./Withdraw.sol";
import "./MerkleProof.sol";

// @author: miinded.com

contract MekaDrivers is ERC721AMint, MultiMint, MerkleProofVerify, Withdraw {

    constructor(string memory baseURI)
    ERC721A("MekaDrivers", "DRIVERS") {
        setBaseUri(baseURI);
        setReserve(100);
        setMaxSupply(8888);

        _setMint("HOLDERS", Mint(1674846000, 1674889200, 200, 200, 0.08 ether, false, true));
        _setMint("WHITELIST", Mint(1674889200, 1674932400, 2, 2, 0.12 ether, false, true));
        _setMint("PUBLIC", Mint(1674932400, 2654875480, 5, 5, 0.12 ether, false, true));

        withdrawAdd(Part(0xB575FDd949066B79Bb0ea6295C028694AA54CdB2, 100));
    }

    function HoldersMint(bytes32[] memory _proof, uint256 _count, uint256 _max)
    public payable notSoldOut(_count) canMint("HOLDERS", _count) merkleVerify(_proof, keccak256(abi.encodePacked(_msgSender(), "HOLDERS", _max))) nonReentrant {
        require(mintBalance("HOLDERS", _msgSender()) <= _max, "MekaDrivers: Max minted");

        _mintTokens(_msgSender(), _count);
    }

    function WhitelistMint(bytes32[] memory _proof, uint256 _count)
    public payable notSoldOut(_count) canMint("WHITELIST", _count) merkleVerify(_proof, keccak256(abi.encodePacked(_msgSender(), "WHITELIST", uint256(2)))) nonReentrant {
        _mintTokens(_msgSender(), _count);
    }

    function PublicMint(uint256 _count)
    public payable notSoldOut(_count) canMint("PUBLIC", _count) nonReentrant {
        _mintTokens(_msgSender(), _count);
    }

}