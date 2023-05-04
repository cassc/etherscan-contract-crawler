// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract Storage is Ownable{

    IERC20 public tokenAddress; //THIS IS THE TOKEN THAT CAN BE USED TO MINT THE NFT
    uint public rate;
    address public treasurer;
    string public baseURI;
    uint public lastTimestamp;

    mapping(address => uint) public addressToId; //Check in safemint if user is already owner
    mapping(uint => uint) public idToTime;
    mapping(uint => bool) public isSubscribed;
    mapping(address => bool) public isHolder;

    string[] IpfsUri = [
        "https://api.npoint.io/d77b7224349124758fb2",
        "https://api.npoint.io/1c50dcf81e6c2350f361"
    ];

   
    function setRate(uint newRate)external onlyOwner{
        rate = newRate*10**18;
    }

    function setTreasurer(address newTreasurer)external onlyOwner {
        treasurer = newTreasurer;
    }

    function setbaseURI(string memory _newURI, uint _index)external onlyOwner{
        IpfsUri[_index] = _newURI;
    }

    function setTokenAddress(address _USDC)external onlyOwner {
        tokenAddress = IERC20(_USDC);
    }    //sets tokenaddress which is used to pay with later
}