// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";
import "@thirdweb-dev/contracts/extension/PlatformFee.sol";

contract DiJTDragons is ERC721Drop,PlatformFee{

    struct Dragon {
        uint256 matronId; // mom's ID
        uint256 sireId; // dad's ID
        uint birthTime;
        uint256 generation;
    }
    struct DragonCooldown{
        uint256 tokenID;
        uint256 cooldown;
    }
    
    event NewBreed(uint256 indexed tokenID, uint256 indexed matron, uint256 indexed sire,uint256 gen, uint256 timestamp);
    
    address public deployer;
    bool private breedAllowed;
    mapping (uint256 => Dragon) private _parentals;
    mapping (uint256 => uint) private isBreeding;

    constructor (string memory _name,string memory _symbol,address _royaltyRecipient,uint128 _royaltyBps,address _primarySaleRecipient) 
    ERC721Drop(_name,_symbol,_royaltyRecipient,_royaltyBps,_primarySaleRecipient) {
        breedAllowed =false;
        deployer = msg.sender;
    }

    function Breed(uint256 matron, uint256 sire)public {
        address p1 = ownerOf(matron);
        address p2 = ownerOf(sire);
        require(breedAllowed, "Breeding is not allowed");
        require(p1 == tx.origin, "You are not the owner of Dragon 1");
        require(p2 == tx.origin, "You are not the owner of Dragon 2");
        require(block.timestamp > isBreeding[matron], "Dragon 1 is still in Breeding cooldown");
        require(block.timestamp > isBreeding[sire], "Dragon 2 is still in Breeding cooldown");
        if(_isValidMatingPair(matron, sire)){
            uint256 generation =  generationCalculator(matron, sire);
            _parentals[_currentIndex] = Dragon(matron, sire, block.timestamp, generation);
            isBreeding[matron] = block.timestamp + cooldownPeriod(_parentals[matron].generation);
            isBreeding[sire] = block.timestamp + cooldownPeriod(_parentals[sire].generation);
            _mint(tx.origin, 1);
            emit NewBreed(_currentIndex, matron, sire, generation, block.timestamp);
        } 
    }
    function setBreed(bool breedable) public onlyOwner {
        breedAllowed = breedable;
    }
    function canBreed()public view returns(bool){
        return breedAllowed;
    }
    function getParentals(uint256 tokenID) public view returns(Dragon memory){
        return _parentals[tokenID];
    }
     function generationCalculator(uint256 matron, uint256 sire)private view returns(uint256){
        uint256 newGeneration = divide((_parentals[matron].generation + _parentals[sire].generation),2) + 1;
        return newGeneration;
    }
    function cooldownPeriod(uint256 _generation) private pure returns (uint256) {
        // No need to create a variable for the division, use the result directly
        uint256 generationTimer = _generation * ((_generation / 10 + 1)+1);
        if(generationTimer == 0){
            return 1800;
        }
        return generationTimer * 1800; // this is for 30min
    }
    function divide(uint256 a, uint256 b) private pure returns (uint256) {
        uint256 remainder = a % b;
        return (a - remainder) / b + remainder;
    }
    function getCooldown(uint256 dragonID) private view returns (uint){
        return isBreeding[dragonID];
    }
    function _canSetPlatformFeeInfo() internal view virtual override returns (bool) {
        return msg.sender == deployer;
    }
    function _isValidMatingPair(uint256 _matronId, uint256 _sireId) private view returns(bool)
    {
        Dragon storage _matron = _parentals[_matronId];
        Dragon storage _sire = _parentals[_sireId];
        require(_matronId != _sireId, "A Dragon can't breed with itself!");
        require(_matron.matronId != _sireId && _matron.sireId != _sireId, "Dragons can't breed with their parents.");
        require(_sire.matronId != _matronId && _sire.sireId != _matronId, "Dragons can't breed with their parents.");
        // We can short circuit the sibling check (below) if either Dragon is gen zero (has a matron ID of zero).
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }
        require(_sire.matronId != _matron.matronId && _sire.matronId != _matron.sireId, "Dragons can't breed with full or half siblings.");
        require(_sire.sireId != _matron.matronId && _sire.sireId != _matron.sireId, "Dragons can't breed with full or half siblings.");
        return true;
    }
    function getDragonsCooldowns(uint256[] memory dragons) public view returns (DragonCooldown[] memory) {
        DragonCooldown[] memory _OwnerCooldowns = new DragonCooldown[](dragons.length);
        uint256 count = 0;
        for (uint256 index = 0; index < dragons.length; index++) {
                _OwnerCooldowns[index].tokenID = dragons[index];
                _OwnerCooldowns[index].cooldown = isBreeding[dragons[index]];
                count++;
        }
        return _OwnerCooldowns;
    }
    function getOwnerCooldowns(address user) public view returns (DragonCooldown[] memory) {
        uint256 userBalance = balanceOf(user);
        require(userBalance > 0, "This user does not have any dragons");
        DragonCooldown[] memory _OwnerCooldowns = new DragonCooldown[](userBalance);
        uint256 count = 0;
        for (uint256 index = 0; index < _currentIndex; index++) {
            if (ownerOf(index) == user) {
                _OwnerCooldowns[count].tokenID = index;
                _OwnerCooldowns[count].cooldown = isBreeding[index];
                count++;
                if (count == userBalance) {
                    break;
                }
            }
        }
        return _OwnerCooldowns;
    }
}