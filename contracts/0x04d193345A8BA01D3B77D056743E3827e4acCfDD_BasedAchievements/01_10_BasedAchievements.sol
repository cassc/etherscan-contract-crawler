// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BasedAchievements is ERC1155 {
    /**
      ___________   
     '._==_==_=_.'  
     .-\:      /-.  
    | (|:.     |) | 
     '-|:.     |-'  
       \::.    /    
        '::. .'     
          ) (       
        _.' '._  Congratulations on your Achievement, Summoner.

    This contract introduces collector achievements for the Based-Ghouls community.
    Hold certain NFTs or combinations of NFTs to earn new NFTs.
    You may not interact with this contract directly, please ask the community (if it exists) for the relevant front end.

    Designed & Implemented by 0xHanValen & Sergeant Slaughtermelon.
    */

    using Strings for uint256;

    mapping(address => bool) public minters;
    mapping(address => bool) public owners;
    address public owner;

    string private _uri;
    mapping(uint256 => mapping(address => uint256)) private balances;

    constructor() ERC1155("") {
        owner = msg.sender;
        owners[msg.sender] = true;
        _uri = "https://based-achievements.s3.amazonaws.com/data/";
    }

    modifier onlyOwners() {
        require(owners[msg.sender], "Not Owner");
        _;
    }

    function editMinters(address targetMinter, bool status) public onlyOwners {
        minters[targetMinter] = status;
    }

    function editOwners(address targetOwner, bool status) public onlyOwners {
        owners[targetOwner] = status;
    }

    function changeURI(string memory newURI) public onlyOwners {
        _uri = newURI;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override virtual {
        require(minters[operator], "Soul Bound Token");
    }

    function mint(address to, uint256 index) public {
        require(minters[msg.sender], "Not Minter");
        require(balances[index][to] <= 1, "Too many");
        balances[index][to]++;
        _mint(to, index, 1, "");
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        return string(abi.encodePacked(_uri, id.toString(), ".json"));
    }
}