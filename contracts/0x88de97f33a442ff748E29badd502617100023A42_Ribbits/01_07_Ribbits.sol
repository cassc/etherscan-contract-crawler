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
        payable(0x7CD96081cD428232540757809Ce32fE3AD8a4320).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }

    function setBaseURI(string calldata _baseURIx) external onlyOwner {
        _contractBaseURI = _baseURIx;
    }
}