// SPDX-License-Identifier: MIT

/**

 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AmadeusCreator2022.sol";
import "./Note.sol";

contract PassManager is Ownable, ReentrancyGuard {

    event Referral(address indexed from, address indexed to);

    constructor(address _note, address _pass, address _notePool) {
        note = _note;
        pass = _pass;
        notePool = payable(_notePool);
    }

    address private note;
    address payable private notePool;

    function setNoteAddress(address _note) external onlyOwner {
        note = _note;
    }

    function setNotePoolAddress(address _notePool) external onlyOwner {
        notePool = payable(_notePool);
    }

    address private pass;

    function setPass(address _pass) external onlyOwner {
        pass = _pass;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // Public Mint
    uint256 public annualFee = 0.1 ether;

    function setAnnualFee(uint256 _annualFee) external onlyOwner {
        annualFee = _annualFee;
    }

    function publicMint(address recommender) external payable {
        require(recommender != msg.sender, "You Cannot Recommend Yourself.");
        refundIfOver(annualFee);
        // send music note to recommender
        Note(note).mint(recommender, getNoteNum(recommender));
        // send eth to music note exchange pool
        notePool.transfer(msg.value * 9 / 10);
        AmadeusCreator2022(pass).publicMintWithRecommend(msg.sender);
        emit Referral(recommender, msg.sender);
    }

    mapping(address => bool) kol;

    function addKol(address[] calldata _kol) external onlyOwner {
        for (uint256 i = 0; i < _kol.length; i++) {
            kol[_kol[i]] = true;
        }
    }

    function isKol(address needToCheck) external view returns (bool) {
        return kol[needToCheck];
    }

    function getNoteNum(address recommender) internal view returns (uint256) {
        if (kol[recommender]) {
            return 4;
        }
        return 3;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
}