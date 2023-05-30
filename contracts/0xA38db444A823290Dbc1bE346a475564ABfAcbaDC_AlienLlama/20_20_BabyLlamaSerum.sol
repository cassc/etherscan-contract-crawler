// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract BabyLlamaSerum is ERC1155Supply, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 constant public A1_TYPE = 1;
    uint256 constant public A2_TYPE = 2;
    uint256 constant public A3_TYPE = 3;

    uint256 constant public A1_MAX = 7777;
    uint256 constant public A2_MAX = 7777;
    uint256 constant public A3_MAX = 10;

    address private _laboratoryAddress;
    string private _baseURI;
    uint256 private _price = 0.07 ether;
    bool private _saleOn = false;
    address private labManager = 0xd5C98c4e77c5e79D81349cD3C5A5695811F5FD70;

    constructor(string memory baseURI_) ERC1155(baseURI_) {
        setBaseUri( baseURI_ );
        // transferOwnership(labManager);
    }

    function mintA1() public onlyOwner {
        require( totalSupply(A1_TYPE) < A1_MAX, "A1 Serum can not exceed over 7777" );
        _mint( owner(), A1_TYPE, A1_MAX, "");
    }

    function mintA2( uint256 count ) public payable nonReentrant{
        uint256 minted = totalSupply(A2_TYPE);

        require( saleOn(), "Sale On is off" );
        require( msg.value == price() * count, "Invalid value" );
        require( minted + count <= A2_MAX, "A2 Serum can not exceed over 7777");
        
        _mint( msg.sender, A2_TYPE, count, "");
        withdraw();
    }

    function mintA3() public onlyOwner {
        require( totalSupply(A3_TYPE) < A3_MAX,  "A3 Serum can not exceed over 10" );
        _mint( owner(), A3_TYPE, A3_MAX, "");
    }

    function setLaboratoryAddress(address laboratoryAddress) public onlyOwner {
        require( Address.isContract(laboratoryAddress), "laboratoryAddress is not Contract" );
        _laboratoryAddress = laboratoryAddress;
    }

    function burnSerumForAddress(uint256 typeId, address experimenter) public {
        require(msg.sender == _laboratoryAddress, "Burn Only Labs");
        _burn(experimenter, typeId, 1);
    }

    function setBaseUri(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    function uri(uint256 typeId) public view override returns (string memory){
        require( typeId == A1_TYPE || typeId == A2_TYPE || typeId == A3_TYPE, "Invalid Serum Type" );
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, typeId.toString())) : _baseURI;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function saleOn() public view returns (bool){
        return _saleOn;
    }

    function startSale() public onlyOwner{
        _saleOn = true;
    }

    function closeSale() public onlyOwner{
        _saleOn = false;
    }

    function withdraw() public payable {
        require(payable(owner()).send(address(this).balance));
    }
    
}