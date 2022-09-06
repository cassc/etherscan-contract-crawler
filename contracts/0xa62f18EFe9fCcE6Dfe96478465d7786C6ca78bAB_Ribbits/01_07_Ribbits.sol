//SPDX-License-Identifier: MIT  
pragma solidity ^0.8.4;  
  
import "erc721a/contracts/ERC721A.sol";  
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StarLoop.sol";

contract Ribbits is StarLoop, Ownable, ERC721A {  
    using SafeMath for uint256;

    constructor() ERC721A("Ribbits", "RIBBITS") {}  
  
    uint public constant MAX_PLAYS = 6969;
    uint256 gameCost = .0420 ether;
    string public _contractBaseURI;

    event replay(address, uint256);

    function devMint(uint amt) external onlyOwner {
        uint totalMinted = totalSupply();
        require(totalMinted == 0, "One Time Function");
        _safeMint(msg.sender, amt);   
    }

    function spinWheel(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint bytemap,
        uint nstamp,
        uint q,
        uint a
        ) external payable {
        uint vrf = processVrfSigned(v, r, s, bytemap, nstamp, q);
        uint totalMinted = totalSupply();
        require(q < 21, "Quantity too many"); 
        require(q > 0, "Quantity cannot be zero");
        require(totalMinted.add(q) < MAX_PLAYS, "Max Game Plays Reached");
        require(gameCost.mul(a - vrf) <= msg.value, "Insufficient funds sent");
        _safeMint(msg.sender, a);   
        emit replay(msg.sender, gameCost.mul(vrf));
        if (a > vrf) payable(msg.sender).transfer(gameCost.mul(vrf));
    }  

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        uint gameEngine = (balance * 10) / 100;
        uint creatorShare = (balance * 35) / 100; 
        uint communityShare = (balance * 20) / 100; 
        payable(0xF9C2Ba78aE44ba98888B0e9EB27EB63d576F261B).transfer(gameEngine);
        payable(0x94849de5AFC8eaB40859b1a1dcF6Bc2eae2385Db).transfer(creatorShare);
        payable(0x78e3FA63addC269982f0078c6f0F204AeC1AC8BE).transfer(creatorShare);
        payable(0xea32A9C1D0ffae2b168c6f64843daBD72df8EAC5).transfer(communityShare);
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }

    function setBaseURI(string calldata _baseURIx) external onlyOwner {
        _contractBaseURI = _baseURIx;
    }
}