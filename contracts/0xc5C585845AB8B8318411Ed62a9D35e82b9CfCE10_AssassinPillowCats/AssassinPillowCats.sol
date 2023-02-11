/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// KAMIMART PRODUCTIONS
// with inspiration from Olive47
// special thanks to NateAlex and Secret Project Team

contract AssassinPillowCats {

    mapping(uint256 => address) public token;
    mapping(uint256 => Cat) public cats;
    uint256 counter = 0;

    struct Cat {
        string name;
        bool isAssassin;
        bool isPillow;
        bool isAlive;
        bool isSleeping;
        uint256 dreams;
        uint256 dreamCounter;
    }

   modifier onlyOwner(uint256 _id) {
        require(msg.sender == token[_id], "Not the owner");
        _;
    }


    function getOwnerOfCat(uint256 _id) public view returns (address) {
        return token[_id];
    }

    function mintCat() public {
        
        if(counter >= 444) {
            /// @notice stop the execution if revert is executed
            revert("We've hit the limit of cats!");
        }
        token[counter] = address(msg.sender);

        if(block.timestamp%2 == 0) {
            Cat memory newCat = Cat("Assassin Cat", true, false, true, false, 0, 0);
            cats[counter] = newCat;
        } else {
            Cat memory newCat = Cat("Pillow Cat", false, true, true, false, 0, 0);
            cats[counter] = newCat;
        }

        counter++;
    }

    function sleep(uint256 _id) public returns (string memory) {

        require(msg.sender == token[_id], "Not the owner");
        require(cats[_id].isPillow == true, "This is not a Pillow Cat");
        require(cats[_id].isAlive == true, "This Pillow Cat is already dead!");
        require(cats[_id].isSleeping == false, "This Pillow Cat is already sleeping!");
        cats[_id].isSleeping = true;
        cats[_id].dreamCounter = block.timestamp;

        return "Your Pillow Cat is now dreaming!";

    }

    function wake(uint256 _id) public returns (string memory) {

        require(msg.sender == token[_id], "Not the owner");
        require(cats[_id].isPillow == true, "This is not a Pillow Cat");
        require(cats[_id].isAlive == true, "This Pillow Cat is already dead!");
        require(cats[_id].isSleeping == true, "This Pillow Cat is already awake!");

        cats[_id].isSleeping = false;
        cats[_id].dreams = (block.timestamp - cats[_id].dreamCounter) + cats[_id].dreams;

        return "Your Pillow Cat is now awake!";

    }

    function kill(uint256 _id, uint256 _victimID) public returns (string memory) {
        require(msg.sender == token[_id], "Not the owner");
        require(cats[_id].isAssassin == true, "This is not an Assasin Cat");
        require(cats[_id].isAlive == true, "This Assassin Cat is already dead!");
        require(cats[_victimID].isPillow == true, "The target is not a Pillow Cat");
        require(cats[_victimID].isAlive == true, "The target is already dead!");
        if(cats[_victimID].isSleeping == true) {
            cats[_victimID].isSleeping = false;
            cats[_id].dreams = (block.timestamp - cats[_victimID].dreamCounter) + cats[_id].dreams + cats[_victimID].dreams ;
            cats[_victimID].dreams = 0;
            return "You have killed a Pillow Cat";
        } else {
        cats[_id].isAlive = false;
        cats[_victimID].dreams = cats[_victimID].dreams + cats[_id].dreams;
        cats[_id].dreams = 0;
        return "Wow you missed and died";
        }
    }
        // KAMISAMA AKA PUFFA-J AKA DON_KEYEDJOTE AKA B4k4Kozmo AKA KATSUBOY
}