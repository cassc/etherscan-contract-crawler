//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./IGPC.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MutantMin is ReentrancyGuard  {
    IGPC GPC_CHEMISTRY_CONTRACT =
        IGPC(0x495f947276749Ce646f68AC8c248420045cb7b5e); //OS OpenStore Smart Contract Address

    address GPC2 = address(0x01FA3813618eE7453904B21678D16a76E8866566);
    mapping(uint256 => uint256) public currentMutantsMaxSupply;
    uint256 serum =
        25835164141757543259111126311128023380630954073833337382485104727321089146980;
    uint256 superSerum =
        25835164141757543259111126311128023380630954073833337382485104726221577519129;
    uint256 megaSerum =
        25835164141757543259111126311128023380630954073833337382485104728420600774666;

    address public owner = address(0x91153D6B02774f8Ae7faAd0ce0BDbA9Cfc14398B);

    constructor() {
        currentMutantsMaxSupply[serum] = 100;
        currentMutantsMaxSupply[superSerum] = 25;
        currentMutantsMaxSupply[megaSerum] = 10;
    }

    function mutantMint(uint256 _osTokenId, uint256[] memory tokenIds) external payable nonReentrant {
        require(
            currentMutantsMaxSupply[_osTokenId] != 0,
            "Incorrect serum passed in"
        );

        require(
            GPC_CHEMISTRY_CONTRACT.balanceOf(msg.sender, _osTokenId) > 0,
            "No Serums found in your wallet"
        );

        require(
            tokenIds.length <=
                GPC_CHEMISTRY_CONTRACT.balanceOf(msg.sender, _osTokenId),
            "Quantity is greater than serum count"
        );


        GPC_CHEMISTRY_CONTRACT.burn(msg.sender, _osTokenId, tokenIds.length);

        for(uint256 i = 0; i < tokenIds.length; i++){
             IERC721(GPC2).safeTransferFrom(owner,msg.sender,tokenIds[i]);
        }

    }
}