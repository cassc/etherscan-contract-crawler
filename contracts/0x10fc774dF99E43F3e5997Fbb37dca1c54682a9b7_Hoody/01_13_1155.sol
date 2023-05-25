// SPDX-License-Identifier: MIT
//
//██╗░░██╗░█████╗░░█████╗░██████╗░██╗░░░██╗
//██║░░██║██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝
//███████║██║░░██║██║░░██║██║░░██║░╚████╔╝░
//██╔══██║██║░░██║██║░░██║██║░░██║░░╚██╔╝░░
//██║░░██║╚█████╔╝╚█████╔╝██████╔╝░░░██║░░░
//╚═╝░░╚═╝░╚════╝░░╚════╝░╚═════╝░░░░╚═╝░░░
//
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Hoody is ERC1155Supply, Ownable {
    string public constant name = "Building Blocks";
    string public constant symbol = "Blocks";
    bool public saleIsActive = false;
    bool public wlSaleIsActive = false;

    struct Test {
        uint id;
        string name;
        uint max_mint;
        uint max_supply;
        uint team_reserved;
        uint team_minted;
        uint price; 
    }
    
    Test[] public collections;

    mapping(uint => mapping(address => bool)) public allowlists;
    mapping(uint => mapping(address => bool)) public teamAllowlists;

    uint public ACTIVE_ID = 1;
    string public baseUri = "https://ipfs.io/ipfs/QmV1FpL122fAd9peTZi8qDaEVA8cG3q8b2ZedaSWATYnUi/";

    constructor() ERC1155(baseUri) {
    }

    function activeId() public view returns (uint) {
        return ACTIVE_ID;
    }

    function mint(uint256 _quantity) external payable {
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(wlSaleIsActive || saleIsActive, "Sale must be active to mint");
        if (wlSaleIsActive){
            require(!saleIsActive, "Allowlist sale is now over");
            require(allowlists[ACTIVE_ID][msg.sender], "Only allowlisted addresses can mint");
        }
        require(balanceOf(msg.sender, ACTIVE_ID) + _quantity <= collections[ACTIVE_ID - 1].max_mint, "Purchase exceeds the maximum allowed per wallet");
        require(totalSupply(ACTIVE_ID) + _quantity <= collections[ACTIVE_ID - 1].max_supply - collections[ACTIVE_ID - 1].team_reserved - collections[ACTIVE_ID - 1].team_minted, "Purchase would exceed max supply");
        require(msg.value >= collections[ACTIVE_ID - 1].price * _quantity, "Ether value sent is not correct");

        _mint(msg.sender, ACTIVE_ID, _quantity, "");
    }
    
    function teamMint(uint256 _quantity) external {
        require(teamAllowlists[ACTIVE_ID][msg.sender], "Only allowlisted team addresses can mint");
        require(collections[ACTIVE_ID - 1].team_minted + _quantity <= collections[ACTIVE_ID - 1].team_reserved, "This amount is more than max allowed");

        _mint(msg.sender, ACTIVE_ID, _quantity, "");

        collections[ACTIVE_ID - 1].team_minted += _quantity;
    }

    function contractURI() public view returns (string memory) {
        return baseUri;
    }

    function toggleActiveSale() external onlyOwner {
        saleIsActive = !saleIsActive;
        wlSaleIsActive = !saleIsActive;
    }
    
    function toggleActiveWlSale() external onlyOwner {
        wlSaleIsActive = !wlSaleIsActive;
    }

    function addDrops(uint _activeTokenId, string memory _name, uint _maxMint, uint _maxSupply, uint _teamReservedSupply, uint _price) external onlyOwner {
        require(_activeTokenId >0 && _activeTokenId <= 4, "Only 4 collections available");
        bool found = false;
        for (uint i = 0; i < collections.length; i++) {
            if (collections[i].id == _activeTokenId) {
                found = true;
                break;
            }
        }
        require(!found, "Collection already exists");

        ACTIVE_ID = _activeTokenId;
        saleIsActive = false;

        collections.push(Test({
            id: _activeTokenId,
            name: _name,
            max_mint: _maxMint,
            max_supply: _maxSupply,
            team_reserved: _teamReservedSupply,
            team_minted: 0,
            price: _price
        }));

        mapping(address => bool) storage almap = allowlists[_activeTokenId];
        almap[msg.sender] = true;

        mapping(address => bool) storage tlmap = teamAllowlists[_activeTokenId];
        tlmap[msg.sender] = true;
    }

    function setURI(string memory _newUri) external onlyOwner {
        baseUri = _newUri;
        _setURI(_newUri);
    }

    function uri(uint256 _tokenId) public override view returns (string memory) {
        return string(abi.encodePacked(baseUri, Strings.toString(_tokenId)));
    } 

    function maxSupply() public view returns (uint) {
        return collections[ACTIVE_ID - 1].max_supply;
    }

    function price() public view returns (uint) {
        return collections[ACTIVE_ID - 1].price;
    }

    function addWL(address[] memory _addresses) external onlyOwner {
        require(allowlists[ACTIVE_ID][msg.sender], "Drop does not exist");
        for (uint i = 0; i < _addresses.length; i++) {
            allowlists[ACTIVE_ID][_addresses[i]] = true;
        }
    }

    function addTeamWL(address[] memory _addresses) external onlyOwner {
        require(teamAllowlists[ACTIVE_ID][msg.sender], "Drop does not exist");
        for (uint i = 0; i < _addresses.length; i++) {
            teamAllowlists[ACTIVE_ID][_addresses[i]] = true;
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}