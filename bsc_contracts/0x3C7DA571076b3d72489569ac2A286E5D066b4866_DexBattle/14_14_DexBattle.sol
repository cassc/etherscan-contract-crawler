// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DexBattle is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {

    uint256 public maxLeaderSupply =25;
    uint256 public maxLegendarySupply = 150;
    uint256 public maxEpicSupply = 250;
    uint256 public maxRareSupply = 350;
    uint256 public maxUncommonSupply = 400;
    uint256 public maxCommonSupply = 500;

    uint256 public Leader_items_cost = 3 ether;
    uint256 public Legendary_items_cost = 1 ether;
    uint256 public Epic_items_cost = 0.5 ether;
    uint256 public Rare_items_cost = 0.1 ether;
    uint256 public Uncommon_items_cost = 0.05 ether;
    uint256 public Common_items_cost = 0.01 ether;

    uint256 maxSupply ;
    uint256 cost;

    bool public paused = false ;

    

    constructor()
        ERC1155("ipfs://QmS9hYAAAbSniyfUJMxUZvPcm1iRkbm8rjJoDNDVxum1eN/")
{}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

	
function Pause (bool _state) public onlyOwner {

paused = _state;

}

    function mint(uint256 id)
        public  payable     
    { 

     require(!paused, "contarct is paused");  

        
    if (id >= 128)
            {
                maxSupply = maxLegendarySupply;
                cost = Legendary_items_cost;
                }
            
        else if (id >= 99)
            
            {maxSupply = maxEpicSupply;
            cost = Epic_items_cost;
            }
           
        else if (id >= 64)
            {
                maxSupply = maxRareSupply;
                cost = Rare_items_cost;
                }
            
        else if (id >= 37)
            {
                maxSupply = maxUncommonSupply;
                cost = Uncommon_items_cost;
                }
        
        else if (id >= 10)
            {
                maxSupply = maxCommonSupply;
                cost = Common_items_cost;
                }
        
        else 
            {
                maxSupply = maxLeaderSupply;
                cost = Leader_items_cost;
                }
        
        require(totalSupply(id) <= maxSupply, "We soldout");
        require(msg.value >= cost, "Not enough bnb sent");
        _mint(msg.sender, id, 1, "");

        
        
        }

    function ownerMint(uint256 id , uint256 amounts) public onlyOwner nonReentrant {
            _mint(msg.sender , id , amounts , "");
    }

    function uri(uint256 _id) public view virtual override returns (string memory){
        require(exists(_id), "URI: token doesn't exist");
        return string(abi.encodePacked(super.uri(_id),Strings.toString(_id), ".json"));
    }
    

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
	  require (!paused , "contract is paused");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //only owner

        //set max supplies

        function setMaxLegendarySupply(uint256 _newsupply) public onlyOwner {
    maxLegendarySupply = _newsupply;
  }

          function setMaxEpicSupply(uint256 _newsupply) public onlyOwner {
    maxEpicSupply = _newsupply;
  }

          function setMaxRareSupply(uint256 _newsupply) public onlyOwner {
    maxRareSupply = _newsupply;
  }

          function setMaxUncommonSupply(uint256 _newsupply) public onlyOwner {
    maxUncommonSupply = _newsupply;
  }

          function setMaxCommonSupply(uint256 _newsupply) public onlyOwner {
    maxCommonSupply = _newsupply;
  }

          function setMaxleaderSupply(uint256 _newsupply) public onlyOwner {
    maxLeaderSupply = _newsupply;
  }

          // set costs

         function set_Legendary_items_cost(uint256 _newcost) public onlyOwner {
    Legendary_items_cost = _newcost;
  }

        function set_Epic_items_cost(uint256 _newcost) public onlyOwner {
    Epic_items_cost = _newcost;
  }

        function set_Rare_items_cost(uint256 _newcost) public onlyOwner {
    Rare_items_cost = _newcost;
  }

        function set_Uncommon_items_cost(uint256 _newcost) public onlyOwner {
    Uncommon_items_cost = _newcost;
  }

        function set_Common_items_cost(uint256 _newcost) public onlyOwner {
    Common_items_cost = _newcost;
  }

        function set_Leader_items_cost(uint256 _newcost) public onlyOwner {
    Leader_items_cost = _newcost;
  }




    function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}