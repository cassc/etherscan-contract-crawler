// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DexBattle is ERC1155, Ownable, Pausable, ERC1155Supply {

    uint256 public maxLeaderSupply =3;
    uint256 public maxLegendarySupply = 100;
    uint256 public maxEpicSupply = 200;
    uint256 public maxRareSupply = 300;
    uint256 public maxUncommonSupply = 400;
    uint256 public maxCommonSupply = 500;

    uint256 public Leader_items_cost = 3000;
    uint256 public Legendary_items_cost = 200;
    uint256 public Epic_items_cost = 150;
    uint256 public Rare_items_cost = 100;
    uint256 public Uncommon_items_cost = 75;
    uint256 public Common_items_cost = 50;

    uint256 maxSupply ;
    uint256 cost;


    IERC20 public tokenAddress;
    

    constructor( address _tokenAddress )
        ERC1155("ipfs://QmenYNKckBCnky8916QL3Lvat4oE6Fd8aVZNsZ5nD5AvaP/")
        {
            tokenAddress = IERC20(_tokenAddress);
        }


    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function mint(uint256 id)
        public        
    {   

        
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
            
        require(totalSupply(id) < maxSupply, "We soldout");      
        tokenAddress.transferFrom(msg.sender, address(this), cost*10**18);
        _mint(msg.sender, id, 1, "");

        
        
        }

    function uri(uint256 _id) public view virtual override returns (string memory){
        require(exists(_id), "URI: token doesn't exist");
        return string(abi.encodePacked(super.uri(_id),Strings.toString(_id), ".json"));
    }
    

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
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




    function withdrawToken() public onlyOwner {
        tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
    }
}