/**
 *Submitted for verification at BscScan.com on 2023-04-23
*/

// SPDX-License-Identifier: CC-BY-SA-4.0
pragma solidity ^0.8.0;

contract lynknStorage {
    constructor(address _owner, uint _levelPrice, uint _maxLevel, uint8 _linksRatio, uint8 _freeLinks) {
        owner = _owner;
        levelPrice = _levelPrice;
        maxLevel = _maxLevel;
        linksRatio = _linksRatio;
        freeLinks = _freeLinks;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    address private owner;

    uint private levelPrice;
    uint private maxLevel;
    uint8 private linksRatio;
    uint8 private freeLinks;
    
    struct userProfile {
        string name;
        string text;
        string image;
        string data;
    }

    struct userTheme {
        string primary;
        string secondary;
        string style;
        string special;
        string data;
    }

    struct userLink {
        uint i;
        uint x;
        uint y;
        uint w;
        uint h;
        string cover;
        string icon;
        string link;
        string text;
        string data;
    }

    mapping(address => userProfile) private profiles;
    mapping(address => userLink[]) private links;
    mapping(address => userTheme) private themes;
    mapping(address => uint) private levels;

    // USER FUNCTIONS \\
    function setProfile(userProfile memory profile) public {
        profiles[msg.sender] = profile;
    }

    function getProfile(address userAddress) public view returns (userProfile memory, uint) {
        return (profiles[userAddress], levels[userAddress]);
    }

    function setLinks(userLink[] memory newLinks) public {
        uint maxLinks = (levels[msg.sender] / linksRatio) + freeLinks;

        require(newLinks.length <= maxLinks, "Link array exceeds max links allowed for this user");

        delete links[msg.sender];

        for (uint j = 0; j < newLinks.length; j++) {
            links[msg.sender].push(newLinks[j]);
        }
    }

    function getLinks(address userAddress) public view returns (userLink[] memory) {        
        return links[userAddress];
    }

    function setTheme(userTheme memory theme) public payable {
        if (levels[msg.sender] < 10) {

            require(msg.value >= levelPrice, string(abi.encodePacked(
                "Insufficient payment for theme change. Required: ", 
                levelPrice,
                ". Actual: ",
                msg.value
            )));

            themes[msg.sender] = theme;

            levels[msg.sender] += 1;

            if (msg.value > levelPrice) {
                payable(msg.sender).transfer(msg.value - levelPrice);
            }
        } else if (levels[msg.sender] >= 10) {
            themes[msg.sender] = theme;
        }
    }

    function getTheme(address userAddress) public view returns (userTheme memory) {
        return themes[userAddress];
    }

    function buyLevels(uint numLevels) public payable {
        uint levelCost = numLevels;
        if (numLevels >= 20) {
            levelCost = numLevels - 3;
        } else if (numLevels >= 10) {
            levelCost = numLevels - 1;
        }

        require(msg.value >= (levelPrice * levelCost), string(abi.encodePacked(
                "Insufficient payment for levels requested. Required: ", 
                (levelPrice * levelCost),
                ". Actual: ",
                msg.value
            )));
        require(levels[msg.sender] + numLevels <= maxLevel, string(abi.encodePacked(
                "Requested levels exceeds maximum levels allowed. Requested: ", 
                numLevels,
                ". Current level: ",
                levels[msg.sender],
                ". Total requested: ",
                levels[msg.sender] + numLevels,
                ". Max level: ",
                maxLevel
            )));

        levels[msg.sender] += numLevels;

        if (msg.value > levelPrice * levelCost) {
            payable(msg.sender).transfer(msg.value - (levelPrice * numLevels));
        }
    }

    
    // OWNER FUNCTIONS \\
    function setValues(uint _maxLevel, uint _levelPrice, uint8 _linksRatio, uint8 _freeLinks) public onlyOwner {
        levelPrice = _levelPrice;
        maxLevel = _maxLevel;
        linksRatio = _linksRatio;
        freeLinks = _freeLinks;
    }

    function withdrawToOwner() public onlyOwner () {
        uint256 balance = address(this).balance;
        address payable sendTo = payable(owner);
        sendTo.transfer(balance);
    }

    function withdraw(address payable cashoutAddress, uint amount) public onlyOwner {
        uint balance = address(this).balance;
        if (amount == 0) {
            amount = balance;
        }
        require(balance > amount, "Requested more in withdraw call than contract has in balance");

        cashoutAddress.transfer(amount);
    }
}