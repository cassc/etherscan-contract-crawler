// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


error OnlyGateKeeper();
error MaxBatchExceeded();

contract chaosrealm is ERC721A, ReentrancyGuard { 

  event newkeeperset(address _newowner);

  address public owner;
    
  enum Rank {
      Bronze,
      Silver,
      Gold, 
      Platinum,
      Diamond, 
      Master, 
      GrandMaster,
      S_Rank 
  }

  constructor(address _owner) ERC721A("chaosrealm", "ChaosRealm") {
       owner = _owner;
  }

  
  function change_owner(address _newowner) external nonReentrant {
       if (msg.sender != owner) 
       revert OnlyGateKeeper();
       owner = _newowner;  
       emit newkeeperset(_newowner);  
      
    }

  function getOwnershipData(uint256 tokenId) public view returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
  }

    // helper function that returns a string of the rank. 
    // NOTE: transferring to a new address will reset the ranking.
    // NOTE: this calculation assumes a year length of 365.24 days, accounting for leap years.
    function getRank(uint256 _tokenId) public view returns (string memory) { 
        uint256 current_unix = block.timestamp; 
        TokenOwnership memory ownership = getOwnershipData(_tokenId);
        uint256 Time_held_for = current_unix - ownership.startTimestamp;
        string memory rank = '';
            if (Time_held_for <= 15768096) { //  < 6months
                rank = "Bronze"; 
            } 
            if (Time_held_for > 15768096 && Time_held_for <= 31536192) { // 6m-1yr
                rank = "Silver"; 
            } 
            if (Time_held_for > 31536192 && Time_held_for <= 47304288) { //  1yr-1.5yrs
                rank = "Gold"; 
            }
            if (Time_held_for > 47304288 && Time_held_for <= 63072384) { // 1.5yr-2yrs
                rank = "Platinum"; 
            }
            if (Time_held_for > 63072384 && Time_held_for <= 78840480) { // 2ys-2.5yrs
                rank = "Diamond";  
            }
            if (Time_held_for > 78840480 && Time_held_for <= 94608576) { // 2.5yr-3yrs 
                 rank = "Master";  
            }
            if (Time_held_for > 94608576 && Time_held_for <= 126144768) { // 3yr-4yrs
                 rank = "GrandMaster";   
            }
            if (Time_held_for > 126144768) { // > 4yrs
                rank ="S-Rank";  
            }
            return rank;
    }

    

  // Note: Minting only allowed by owner, no whitelist or auction. Acquiring a chaos denizen is done on the secondary market. 
  // Note: Inital supply is 100 however max supply is not capped, owner can mint additional denizens. 
  function Mint(uint256 quantity) external nonReentrant {
      if (msg.sender != owner) 
      revert OnlyGateKeeper();
      if (quantity > 25) 
      revert MaxBatchExceeded(); // To prevent excessive first-time token transfer costs (https://chiru-labs.github.io/ERC721A/#/erc721a?id=_mint)
    _safeMint(msg.sender, quantity);
  }


  // metadata URI
  // NOTE: created to be equally rare so metadata will be sparse. 
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external nonReentrant {
    if (msg.sender != owner) 
    revert OnlyGateKeeper();
    _baseTokenURI = baseURI;
  }


  function withdrawMoney() external nonReentrant {
    if (msg.sender != owner) 
    revert OnlyGateKeeper();
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  // Lego for other applications to check if a address is a chaos denizen (returns bool and highest rank) 
  function is_chaos_denizen(address _address) public view returns (bool, string memory) {
      bool holder = false;
      Rank highest_rank_position = Rank.Bronze;
      string memory highest_rank = ''; 
      uint256 length = totalSupply(); 
          for (uint256 i = 0; i < length; ){  
              TokenOwnership memory ownership = getOwnershipData(i);
              if (ownership.addr == _address) {  
                  holder = true;
                   if (ownership.addr == _address) {  
                  holder = true;
                  Rank current_rank = return_enum_rank(ownership);  
                  if (current_rank >= highest_rank_position) {
                    highest_rank_position = current_rank;
                    highest_rank = getRank(i);
                  }
              }
          unchecked { ++i; }  
          }
  }
   return (holder, highest_rank);
  }

  
  // internal helper function that returns enum position of rank
  function return_enum_rank(TokenOwnership memory _ownership) internal view returns (Rank) { 
        uint256 current_unix = block.timestamp;
        uint256 Time_held_for = current_unix - _ownership.startTimestamp;
        Rank rank = Rank.Bronze;
            if (Time_held_for <= 15768096) { //  < 6months
                rank = Rank.Bronze; 
            } 
            if (Time_held_for > 15768096 && Time_held_for <= 31536192) { // 6m-1yr
                rank = Rank.Silver; 
            } 
            if (Time_held_for > 31536192 && Time_held_for <= 47304288) { //  1yr-1.5yrs
                rank = Rank.Gold;  
            }
            if (Time_held_for > 47304288 && Time_held_for <= 63072384) { // 1.5yr-2yrs
                rank = Rank.Platinum; 
            }
            if (Time_held_for > 63072384 && Time_held_for <= 78840480) { // 2ys-2.5yrs
                rank = Rank.Diamond;  
            }
            if (Time_held_for > 78840480 && Time_held_for <= 94608576) { // 2.5yr-3yrs 
                 rank = Rank.Master;  
            }
            if (Time_held_for > 94608576 && Time_held_for <= 126144768) { // 3yr-4yrs
                 rank = Rank.GrandMaster;   
            }
            if (Time_held_for > 126144768) { // > 4yrs
                rank = Rank.S_Rank;  
            }
            return rank;
    }

}