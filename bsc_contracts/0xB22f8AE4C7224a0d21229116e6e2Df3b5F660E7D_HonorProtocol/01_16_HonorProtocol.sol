// SPDX-License-Identifier: MIT
// Honor Protocol - Token Dao
// Duan 
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract HonorProtocol is ERC20, Ownable {

  struct ArmyRank {
    uint vote;
    address contracts;
    address voter;
    uint castAt;
    uint lastMintAt;
  }

  struct Governance {
    uint totalvotes;
    uint totalmint;
    uint countmint;
    uint lastmint;
    uint miningsc;
  }

  mapping(address => Governance) public Governances;
  mapping(uint => ArmyRank) public ArmyRanks;

  address public miningDao; // Mining Contract
  ERC721 public armyRankNFT; // NFT Contract
  address nftaddress;
  
  Ownable Duan; // using Ownable as identifier for Duan
  address public miningAddress; // Same Mining Contract address as MiningDao, declared pass Ownable Duan for calling owner() function and security for Mint/Mining Utility
 
  uint public maxSupply = 100000000 * 10 ** 18; // Reserved for Yield, Staking, Mining & ATE & Future Utility - Honor Ecosystem - 100M (Governance)
  uint public governanceMaxAmount = 1500000 * 10 ** 18; // 1.5m token max governance mint
  uint public miningAmount = 50 * 10 ** 18; // 50 token max per mining
  uint public cooldownTimeInSeconds = 7776000; // 90 days in seconds cooldown for next vote
  uint256 public MiningDay = 864000; // Default 10 days in seconds cooldown for next mining
  bool public voteStatus = false;
  
  constructor() ERC20('Honor Protocol', 'HONOR') {
    _mint(msg.sender, 2500000 * 10 ** 18); // Initial Total Supply 2.5% (2.5m)
    miningAddress = address(Duan);
  }

 // Voting ON/OFF
  function voteOn() external onlyOwner {
    voteStatus = true;
  }
  function voteOff() external onlyOwner {
    voteStatus = false;
  }

  // Check owner of Mining Smart Contract
  function MiningOwner() public view returns (address) {
    if (miningAddress == address(0)) {
      revert("Mining Smart Contract not yet set");
    }
    else {
    return Duan.owner();
    }
  }

  // Set Mining Contract
  function setMiningContract(address _miningDao) external onlyOwner {
    if (miningDao == address(0)) {
      miningDao = _miningDao;
    }
    else {
      require(Governances[address(this)].totalvotes >= 2500, "Not Enough 25% Votes"); // 2500 NFTs out of 10,000
      miningDao = _miningDao;
      Governance storage Gov = Governances[address(this)];
      Gov.totalvotes = 0;
      Gov.miningsc = Gov.miningsc + 1; // To keep count and track how many Mining Smart Contract change after vote.
    }
    Duan = Ownable(_miningDao);
    miningAddress = address(Duan);
  }

  // Set NFT Army Ranks Contract
  function setNFTContract(address _nftaddress) external onlyOwner {
    require(nftaddress == address(0), "One Time Only");
    armyRankNFT = ERC721(_nftaddress);
    nftaddress = address(armyRankNFT);
  }

  // Set Mining day, default is 10 days in seconds
  function setMiningDay(uint _seconds) external onlyOwner {
    require(_seconds >= 864000, "Min 86400 (10 days)");
    MiningDay = _seconds;
  }

  // Mint = Mining & Honor Protocol Ecosystem
  function mint(address _address, address _owner, uint _amount, uint _tokenId) public {
    require(msg.sender == miningDao, "Protected, Can only be used by Honor Protocol Mining Ecosystem - Token"); // Only MiningDao can access

    uint daysSinceLastMining = (block.timestamp - ArmyRanks[_tokenId].lastMintAt) / MiningDay;
    require(daysSinceLastMining >= 1, "Not past 10 days");

    require(_address != Duan.owner(), "Blocked, your are the Mining owner (using Ownable) - Token"); // Block Owner from Mining SC for safety reasons
    require(_address != owner() || _address != _owner, "Blocked, your are the owner - Token"); // Block Owner from Token SC & Mining SC for safety reasons

    uint supply = totalSupply();
    require(_amount + supply <= maxSupply, "Max Supply 100,000,000 - 100M");
    require(_amount <= miningAmount, "Max Minining 50 Token"); // Maximum Mining Token (Max Level NFT General)
    
     ArmyRanks[_tokenId].lastMintAt = block.timestamp;
    _mint(msg.sender, _amount);
  }

  // Auto Burn
  function burn(uint _amount) public {
    _burn(msg.sender, _amount);
  }

  // Goverance Mint (Community Driven) | 55% Votes (5500 NFTS)
  function governanceMint(uint _amount) external onlyOwner {
    Governance storage Gov = Governances[address(this)];
    uint daysSinceLastMint = (block.timestamp - Gov.lastmint) / cooldownTimeInSeconds; // Next 90 days can Governance Mint again
    require(daysSinceLastMint >= 1, "Not Past 90 Days");

    uint supply = totalSupply();
    require(_amount <= governanceMaxAmount, "Max Governance Mint Amount Exceeded - 1.5M");
    require(_amount + supply <= maxSupply, "Max Supply 100,000,000 - 100M");
    require(Governances[address(this)].totalvotes >= 5500, "Not Enough 55% Votes"); // 5500 NFTs out of 10,000
    _mint(msg.sender, _amount);
    
    uint govamount = Gov.totalmint;
    uint govcount = Gov.countmint;
    Gov.totalvotes = 0;
    Gov.totalmint = govamount + _amount;
    Gov.countmint = govcount + 1;
    Gov.lastmint = block.timestamp;
  }

  // Community Vote
  function castvote(uint _tokenId) public {
    require(voteStatus == true, "Honor Protocol Vote Offline");
    require(nftaddress != address(0), "NFT address is address 0");
    require(msg.sender != owner(), "Owner cannot Vote");
    require(msg.sender == armyRankNFT.ownerOf(_tokenId),"You are not the owner of this TokenId");
    uint votecheck = ArmyRanks[_tokenId].vote;

    if (votecheck == 0){
    ArmyRanks[_tokenId] = ArmyRank(
      1,
      msg.sender,
      nftaddress,
      block.timestamp,
      ArmyRanks[_tokenId].lastMintAt
      );
    }
    else if (votecheck >= 1) {
      uint daysSinceLastVote = (block.timestamp - ArmyRanks[_tokenId].castAt) / cooldownTimeInSeconds; // Next 90 days can vote again
      require(daysSinceLastVote >= 1, "Not Past 90 Days");

      uint holdervotes = ArmyRanks[_tokenId].vote;
      ArmyRanks[_tokenId] = ArmyRank(
        holdervotes + 1,
        msg.sender,
        nftaddress,
        block.timestamp,
         ArmyRanks[_tokenId].lastMintAt
      );
    }
    else{
      // no else cases
      revert("Error");
    }

    Governance storage Gov = Governances[address(this)];
    uint addvote = Gov.totalvotes;
    Gov.totalvotes = addvote + 1;
  }

}