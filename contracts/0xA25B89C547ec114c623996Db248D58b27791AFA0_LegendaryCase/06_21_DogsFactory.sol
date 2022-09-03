// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./DogsContract.sol";
import "./Initializable.sol";
import "./ItemsStructure.sol";
import "./Cases.sol";
import "./ApproveWallet.sol";
import "./ItemsToUpgrade.sol";

contract Poses is ItemsStructure {

    Item[] private _poses;

    constructor() {
        _poses.push(Item("Common", "Common", 100));
        _poses.push(Item("Uncommon", "Uncommon", 50));
        _poses.push(Item("Rare", "Rare", 20));
        _poses.push(Item("Epic", "Epic", 5));
        _poses.push(Item("Legendary", "Legendary", 1));
    }

    function getPose(uint256 id) internal view returns (Item memory) {
        return getItem(_poses, id);
    }
}

contract Hairstyles is ItemsStructure {

    Item[] private _hairstyles;

    constructor() {
        _hairstyles.push(Item("Uncommon", "Uncommon", 50));
        _hairstyles.push(Item("Rare", "Rare", 20));
        _hairstyles.push(Item("Epic", "Epic", 5));
    }

    function getHairstyle(uint256 id) internal view returns (Item memory) {
        return getItem(_hairstyles, id);
    }
}

contract DogsFactory is Dogs, Cases, ApproveWallet, Poses, Hairstyles, LegendaryPose, ItemsToUpgrade {

    using SafeMath for uint256;
    using Strings for uint256;

    string URI;

    event Birth(
        address owner,
        Dog dog,
        uint256 birth
    );

    event GrowingUp(
        address owner,
        Dog dog,
        uint256 birth
    );

    function updateDogName(uint256 _tokenId, string memory _dogName) public onlyDogOwner(_tokenId) {
        dogs[_tokenId].DogName = _dogName;
    }

    function dogsOf(address _owner) public view returns (uint256[] memory) {
        // get the number of dogs owned by _owner
        uint256 ownerCount = ownerDogCount[_owner];
        if (ownerCount == 0) {
            return new uint256[](0);
        }

        // iterate through each dogsId until we find all the dogs
        // owned by _owner
        uint256[] memory ids = new uint256[](ownerCount);
        uint256 i = 1;
        uint256 count = 0;
        while (count < ownerCount || i < dogs.length) {
            if (dogToOwner[i] == _owner) {
                ids[count] = i;
                count = count.add(1);
            }
            i = i.add(1);
        }

        return ids;
    }

    function getId() external view returns (uint256) {
        return dogs.length;
    }

    function createDog(
        address _owner, 
        string memory _dogName,
        string memory _age,
        Item memory _pose,
        Item memory _hairstyle,
        Item memory _face,
        Item memory _color,
        uint32 _balls,
        uint32 _bones,
        uint32 _dogFood,
        uint32 _medals
    ) external returns (uint256) {
        require(
            onlyCaseAdresses(_msgSenderContract()) || msg.sender == owner(),
            "DogsFactory: The address is not an approved case or owner"
        );

        Dog memory dog = Dog({
            DogName: _dogName,
            Age: _age,
            Pose: _pose,
            Hairstyle: _hairstyle,
            Face: _face,
            Color: _color,
            Balls: _balls,
            Bones: _bones,
            DogFood: _dogFood,
            Medals: _medals,
            BirthTime: block.timestamp,
            GrowUp: false
        });

        dogs.push(dog);

        uint256 newDogId = dogs.length - 1;

        emit Birth(_owner, dog, block.timestamp);

        _mint(_owner, newDogId);

        return newDogId;
    }

    function approveGrowUp(uint256 _tokenId) public onlyApproveWallet() {
        require( keccak256(abi.encodePacked(dogs[_tokenId].Age)) != keccak256(abi.encodePacked("Adult")), "DogsFactory: The dog is already an adult");
        require( dogs[_tokenId].GrowUp == false, "DogsFactory: Already approved");
        dogs[_tokenId].GrowUp = true;
    }

    function growUp(uint256 _tokenId) public onlyDogOwner(_tokenId) {
        require(dogs[_tokenId].GrowUp == true, "DogsFactory: The dog can't grow up");

        if ( keccak256(abi.encodePacked(dogs[_tokenId].Pose.Rarity)) == keccak256(abi.encodePacked("Legendary")) ) {
            bool check = updateLegendaryDog(_tokenId);
            if (check == true) {
                dogs[_tokenId].GrowUp = false;
            }
        } else {
            bool check = updateDog(_tokenId);
            if (check == true) {
                dogs[_tokenId].GrowUp = false;
            }
        }
    }

    function getGrowUp(uint256 _tokenId) public view returns (bool) {
        return dogs[_tokenId].GrowUp;
    } 

    function updateLegendaryDog(uint256 _tokenId) private returns (bool) {
        if ( keccak256(abi.encodePacked(dogs[_tokenId].Age)) == keccak256(abi.encodePacked("Teenager")) ) {
            dogs[_tokenId].Age = "Adult";
        }
        if ( keccak256(abi.encodePacked(dogs[_tokenId].Age)) == keccak256(abi.encodePacked("Child")) ) {
            dogs[_tokenId].Age = "Teenager";
        }

        string[] memory rarity = new string[](2);
        rarity[0] = dogs[_tokenId].Pose.Rarity;
        rarity[1] = dogs[_tokenId].Color.Rarity;

        (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, dogs[_tokenId].Age);

        dogs[_tokenId].Balls = balls;
        dogs[_tokenId].Bones = bones;
        dogs[_tokenId].DogFood = dogFood;
        dogs[_tokenId].Medals = medals;

        emit GrowingUp(msg.sender, dogs[_tokenId], block.timestamp);

        return true;
    }

    function updateDog(uint256 _tokenId) private returns (bool) {
        if ( keccak256(abi.encodePacked(dogs[_tokenId].Age)) == keccak256(abi.encodePacked("Teenager")) ) {
            dogs[_tokenId].Age = "Adult";
        }
        if ( keccak256(abi.encodePacked(dogs[_tokenId].Age)) == keccak256(abi.encodePacked("Child")) ) {
            dogs[_tokenId].Age = "Teenager";
        }

        Item memory pose = getPose(_tokenId);
        if ( keccak256(abi.encodePacked(pose.Rarity)) == keccak256(abi.encodePacked("Legendary")) ) {
            Item memory legendaryPose = getLegendaryPose(_tokenId);

            dogs[_tokenId].Pose = legendaryPose;
            dogs[_tokenId].Hairstyle = Item("","",0);
            dogs[_tokenId].Face = Item("","",0);

            string[] memory rarity = new string[](2);
            rarity[0] = dogs[_tokenId].Pose.Rarity;
            rarity[1] = dogs[_tokenId].Color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, dogs[_tokenId].Age);

            dogs[_tokenId].Balls = balls;
            dogs[_tokenId].Bones = bones;
            dogs[_tokenId].DogFood = dogFood;
            dogs[_tokenId].Medals = medals;

        } else {
            Item memory hairstyle = getHairstyle(_tokenId);
        
            dogs[_tokenId].Pose = pose;
            dogs[_tokenId].Hairstyle = hairstyle;

            string[] memory rarity = new string[](4);
            rarity[0] = dogs[_tokenId].Pose.Rarity;
            rarity[1] = dogs[_tokenId].Hairstyle.Rarity;
            rarity[2] = dogs[_tokenId].Face.Rarity;
            rarity[3] = dogs[_tokenId].Color.Rarity;

            (uint32 balls, uint32 bones, uint32 dogFood, uint32 medals) = getItemsToUpgrade(rarity, dogs[_tokenId].Age);

            dogs[_tokenId].Balls = balls;
            dogs[_tokenId].Bones = bones;
            dogs[_tokenId].DogFood = dogFood;
            dogs[_tokenId].Medals = medals;
        }

        emit GrowingUp(msg.sender, dogs[_tokenId], block.timestamp);

        return true;
    }

    function setTokenURI(string memory _URI) public onlyOwner () {
        URI = _URI;
    }

    function baseTokenURI() override public view returns (string memory) {
        return URI;
    }

}