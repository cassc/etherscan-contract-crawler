// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMintingoCollection.sol";
import "./Mintingocollection.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./MasterLibrary.sol";



// Mintingo Master Contract
contract Master is Context, Ownable {   
    using Strings for uint256;

    mapping(uint256 => address) public collections;
    mapping(address => uint256[]) public winners_by_collection;
    mapping(address => uint256) public players_wins;
    mapping(address => uint256) public players_attempts;
    address[] public collections_ids; // the last one (tail) is the current collection

  
    // create a new collection deploying a new Collection(ERC721) contract
    function  create_collection(
        string memory _name,
        string memory _symbol, uint256[] memory totalClaimable, uint[] memory tiers, address[] memory coins, uint256[] memory amounts, address[] memory coin_to_pay, address[] memory nfts, uint256[] memory price_to_pay) public onlyOwner() {
      address owner = address(this);
      address newAddress =  MasterLibrary.lib_create_collection(_name, _symbol, totalClaimable, tiers, coins, amounts, coin_to_pay, nfts, price_to_pay, owner);  
        collections_ids.push(newAddress);
        collections[collections_ids.length - 1] = newAddress;
    }

    function  reveal_by_id(
        address collection_id,
        uint256[] memory winners,
        uint256[] memory tiers,
        string memory revealed_uri
    ) public onlyOwner() {
        winners_by_collection[collection_id] = winners;
        IMintingoCollection(collection_id).reveal(winners, tiers, revealed_uri);
    }

    function set_variables(uint256 collection_id,uint256 _start_block, uint256 _expiration, uint256 _max_Supply, string memory _initNotRevealedUri) public onlyOwner(){
     require(collections[collection_id] != address(0), 'COLLECTION_DNE');
    address collection_address = collections[collection_id];
    IMintingoCollection(collection_address).setVariables(_start_block, _expiration, _max_Supply, _initNotRevealedUri);
       
    }

        function set_referral(uint256 collection_id, uint256 _decimals,uint256 _referralBonus,uint256 _secondsUntilInactive, bool _onlyRewardActiveReferrers,uint256[] memory _levelRate,uint256[] memory _refereeBonusRateMap) public onlyOwner(){
     require(collections[collection_id] != address(0), 'COLLECTION_DNE');
    address collection_address = collections[collection_id];
    IMintingoCollection(collection_address).set_referral(_decimals, _referralBonus, _secondsUntilInactive, _onlyRewardActiveReferrers, _levelRate, _refereeBonusRateMap);
       
    }

    function  buy_ticket(uint256 collection_id, address coin, uint256 _mintAmount, address payable _referrer) public {
        require(collections[collection_id] != address(0), 'COLLECTION_DNE');
        address collection_address = collections[collection_id];
        IMintingoCollection(collection_address).mint(_mintAmount, coin, msg.sender, _referrer);
    }


}