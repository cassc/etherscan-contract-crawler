pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Catctus is ERC721, AccessControl {
    using SafeMath for uint;
    
    uint public constant MAX_CATCTUS = 10000;

    uint public price;
    bool public hasSaleStarted = false;

    address firstAccountAddress;
    address secondAccountAddress;
    
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins.");
        _;
    }
    
    constructor(string memory baseURI, address _secondAccountAddress) ERC721("Catctus", "CATCTUS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setBaseURI(baseURI);
        price = 0.02 ether;
        firstAccountAddress = msg.sender;
        secondAccountAddress = _secondAccountAddress;
    }
    
    function mint(uint quantity) public payable {
        mint(quantity, msg.sender);
    }

    function burn(uint id) external {
        require(ownerOf(id) == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _burn(id);
    }
    
    function mint(uint quantity, address receiver) public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= MAX_CATCTUS, "sold out");
        require(msg.value >= price.mul(quantity) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ether value sent is below the price");
        
        if(msg.value > 0) {
            payable(firstAccountAddress).transfer(msg.value.mul(49).div(100));
            payable(secondAccountAddress).transfer(msg.value.mul(51).div(100));
        }
        
        for (uint i = 0; i < quantity; i++) {
            uint mintIndex = totalSupply();
            _safeMint(receiver, mintIndex);
        }
    }
    
    function tokensOfOwner(address _owner) public view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        _setBaseURI(baseURI);
    }
    
    function setPrice(uint _price) public onlyAdmin {
        price = _price;
    }
    
    function startSale() public onlyAdmin {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyAdmin {
        hasSaleStarted = false;
    }

    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeAdmin(address account) public virtual onlyAdmin {
        renounceRole(DEFAULT_ADMIN_ROLE, account);
    }
}