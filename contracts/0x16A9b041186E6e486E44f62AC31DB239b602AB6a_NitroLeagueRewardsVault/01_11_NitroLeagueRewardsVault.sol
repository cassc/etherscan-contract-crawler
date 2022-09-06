//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NitroLeagueRewardsVault is ERC1155, Ownable{

    string public name = "Nitro League Rewards Vault";
    string public symbol = "NLRV";

    string private _baseURI; //the token metadata 
    string private _contractDefination; //the collection metadata 
    bool private _isMetaLocked;


    constructor() ERC1155("") {
    }

    function setBaseURI(string memory baseuri, string memory contracturi) public onlyOwner {
        require(bytes(baseuri).length > 0, "baseURI cannot be empty");
        require(_isMetaLocked == false, "contract is locked, cannot modify");

        _baseURI = baseuri;
        _contractDefination = contracturi;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI;
    }

    function uri(uint256 tokenid) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenid),".json")) ;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI, _contractDefination,".json")) ;

    }

    function getMetaLocked() public view returns(bool isMetaLocked){
        return _isMetaLocked;
    }

    function lockMetaData() public onlyOwner {
        _isMetaLocked = true;
    }

    function mint(address account, uint _id, uint256 amount) public onlyOwner returns (uint)
    {
        _mint(account, _id, amount, "");
        return _id;
    }

    function bulkMint(address[] memory accounts, uint[] memory _ids, uint256[] memory amounts) public onlyOwner
    {
        require(_ids.length == accounts.length,"data inconsistent");
        require(_ids.length == amounts.length,"data inconsistent");

         for(uint i =0; i < accounts.length; i++) {
            _mint(accounts[i], _ids[i], amounts[i], "");
         }
    }

   


}