// SPDX-License-Identifier: MIT
// @author dniminenn

pragma solidity ^0.8.0;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.3.2/contracts/utils/Strings.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.3.2/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract Eyetopia is ERC721A, Ownable {
    string _baseUrl = "https://dnim.xyz/assets/";
    string _contractUrl = "https://eyetopia.xyz/eyetopia.json";
    uint private _amountClaim = 100000000000000000000;
    uint public constant MAX_SUPPLY = 333;

    constructor() ERC721A("Eyetopia", "EYETOPIA") {}

    function _startTokenId() override internal view virtual returns (uint) {
        return 1;
    }

    function setClaim(uint _amount) public onlyOwner {
        _amountClaim = _amount;
    }

    function getClaimAmount() public view returns (uint) {
        return _amountClaim;
    }

    function mintTo(address _to) public onlyOwner {
       require(totalSupply() < MAX_SUPPLY, "Over supply");
       _safeMint(_to, 1);
    }

    function mintTo(address _to, uint quantity) public onlyOwner {
        require((totalSupply() + quantity) < (MAX_SUPPLY + 1), "Over supply");
        _safeMint(_to, quantity);
    }

    function withdraw(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }

    function claim(address _to) public payable {
        require(totalSupply() < MAX_SUPPLY, "Minting is over");
        require(msg.value == _amountClaim, "Incorrect price");
        _safeMint(_to, 1);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseUrl;
    }

    function updateBase(string memory newBase) public onlyOwner {
        _baseUrl = newBase;
    }

    function tokenURI(uint _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return _contractUrl;
    }
    
    function setcontractURI(string memory newURI) public onlyOwner {
        _contractUrl = newURI;
    }

}