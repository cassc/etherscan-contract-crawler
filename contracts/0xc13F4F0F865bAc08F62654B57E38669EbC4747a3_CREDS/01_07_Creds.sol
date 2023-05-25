// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface DystoPunks {
    function tokensOfOwner(address ownwer) external view returns (uint256[] memory);

}

contract CREDS is ERC20, ERC20Burnable, Ownable {

    address constant public DystoAddress = 0xbEA8123277142dE42571f1fAc045225a1D347977;
    mapping(uint => uint256) public lastUpdate;
    uint256 constant public BASE_RATE = 7 ether;
	uint256 constant public INITIAL_ISSUANCE = 300 ether;
	uint256 constant public START = 1634349600;
	uint256 constant public END = 1855274400;
	uint256 constant public MAX_CLAIM = 777000 ether;
	uint256 private claimed = 0;
	bool public saleIsActive = false;


    constructor() ERC20("Creds", "CREDS") {}

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

     function totalAvailable(address ownwer) public view returns (uint256) {
        uint[] memory punks = DystoPunks(DystoAddress).tokensOfOwner(ownwer);
        uint arrayLength = punks.length;
        uint256 rewards = 0;
        uint256 time = block.timestamp;
        for (uint i=0; i<arrayLength; i++) {
              uint256 punkid = punks[i];
              uint256 lastTime = lastUpdate[punkid];
              if (lastTime > 0){
                  rewards = rewards+(BASE_RATE*((time-lastTime)/86400));
              } else {
                  rewards = rewards+(BASE_RATE*((time-START)/86400))+INITIAL_ISSUANCE;
              }

        }
        return rewards;

    }

    function updateTime(address ownwer) private {
        uint[] memory punks = DystoPunks(DystoAddress).tokensOfOwner(ownwer);
        uint arrayLength = punks.length;
        uint256 time = block.timestamp;
        for (uint i=0; i<arrayLength; i++) {
              uint256 punkid = punks[i];
              lastUpdate[punkid]=time;

        }

    }

    function claim() public payable  {
        require(saleIsActive, "Sale must be active to mint Tokens");
        uint256 time = block.timestamp;
        require(time <= END, "Date exceeds the max limit");
        uint[] memory punks = DystoPunks(DystoAddress).tokensOfOwner(msg.sender);
        uint arrayLength = punks.length;
        require(arrayLength > 0, "Not owner");
        uint256 amount = totalAvailable(msg.sender);
        require(amount > 0, "Nothing to claim");
        updateTime(msg.sender);
        _mint(msg.sender, amount);
    }

    function reservedCreds(address to, uint256 amount) public onlyOwner {
         require(claimed + amount <= MAX_CLAIM, "Value exceeds the max limit");
         _mint(to, amount);
         claimed += amount;
    }

    function unclaimedCreds() public view onlyOwner returns(uint256) {
         uint256 unclaimed = MAX_CLAIM - claimed;
         return unclaimed;
    }

    function punkCreds(uint punkid) public view returns(uint256) {
         uint256 rewards = 0;
         uint256 time = block.timestamp;
         uint256 lastTime = lastUpdate[punkid];
         if (lastTime > 0){
             rewards = rewards+(BASE_RATE*((time-lastTime)/86400));
         } else {
             rewards = rewards+(BASE_RATE*((time-START)/86400))+INITIAL_ISSUANCE;
         }
         return rewards;
    }

}