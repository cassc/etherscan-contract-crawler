// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface iOctoHedz {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);

}

contract INKZ is ERC20, ERC20Burnable, Ownable {

    iOctoHedz public OctoHedz;
    address constant public OctoHedzAddress = 0x6E5a65B5f9Dd7b1b08Ff212E210DCd642DE0db8B; 
    mapping(uint => uint256) public lastUpdate;
    mapping(address => bool) public allowedAddresses;
    uint256 constant public INKZ_RATE = 8 ether;
	uint256 constant public START = 1639965380;
	uint256 constant public END = 1892771849;

	bool public saleIsActive = true;


    constructor() ERC20("INKz", "INKZ") {
        OctoHedz = iOctoHedz(OctoHedzAddress);
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }


     function getTotalClaimable(address owner) public view returns (uint256) {
        uint[] memory octos = iOctoHedz(OctoHedzAddress).tokensOfOwner(owner);
        uint arrayLength = octos.length;
        uint256 rewards = 0;
        uint256 time = block.timestamp;
        for (uint i=0; i<arrayLength; i++) {
              uint256 octoid = octos[i];
              uint256 lastTime = lastUpdate[octoid];
              if (lastTime > 0){
                  rewards = rewards+(INKZ_RATE*((time-lastTime)/86400));
              } else {
                  rewards = rewards+(INKZ_RATE*((time-START)/86400));
              }

        }
        return rewards;

    }


    function updateTime(address owner) private {
        uint[] memory octos = iOctoHedz(OctoHedzAddress).tokensOfOwner(owner);
        uint arrayLength = octos.length;
        uint256 time = block.timestamp;
        for (uint i=0; i<arrayLength; i++) {
              uint256 octoid = octos[i];
              lastUpdate[octoid]=time;

        }

    }


    function claimReward() public payable  {
        require(saleIsActive, "Sale must be active to claim INKz");
        uint256 time = block.timestamp;
        require(time <= END, "Date exceeds the max limit");
        uint[] memory octos = iOctoHedz(OctoHedzAddress).tokensOfOwner(msg.sender);
        uint arrayLength = octos.length;
        require(arrayLength > 0, "Not owner");
        uint256 amount = getTotalClaimable(msg.sender);
        require(amount > 0, "Nothing to claim");
        updateTime(msg.sender);
        _mint(msg.sender, amount);
    }

    function octoINKz(uint octoid) public view returns(uint256) {
         uint256 rewards = 0;
         uint256 time = block.timestamp;
         uint256 lastTime = lastUpdate[octoid];
         if (lastTime > 0){
             rewards = rewards+(INKZ_RATE*((time-lastTime)/86400));
         } else {
             rewards = rewards+(INKZ_RATE*((time-START)/86400));
         }
         return rewards;
    }

    
    function claimINKzRewards(address _address, uint256 _amount) external {
        require(saleIsActive, "Sale must be active to claim INKz");
        require(allowedAddresses[msg.sender], "Address does not have permission to distrubute tokens");
        _mint(_address, _amount);
    }

        function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(OctoHedz), "Address does not have permission to burn");
        _burn(user, amount);
    }

}