// SPDX-License-Identifier: MIT
// ndgtlft etm.

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract KurageFestivalMemento is ERC1155, Ownable, ReentrancyGuard, AccessControl {
    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // param config
    bytes32 public constant BOY = keccak256("BOY");
    string public name = "Kurage Festival Memento";
    string public symbol = "KFM"; 
    address public withdrawAddress;
    
    // token
    mapping(uint256 => itemStruct) public itemData;
    struct itemStruct {
        uint256 totalSupply;
        uint256 cost;
        string jsonUri;
        bool onSale;
    }

    // mint 
    function mint(uint256 _id, uint256 _mintAmount) public payable nonReentrant{
        require(itemData[_id].onSale, "this item is not on Sale now");
        require(_mintAmount > 0, "need to mint over 1 amount");
        require(itemData[_id].cost * _mintAmount <= msg.value, "cost is insufficient");
        require(tx.origin == msg.sender, "not externally owned account");
        itemData[_id].totalSupply += _mintAmount;
        _mint(msg.sender, _id, _mintAmount, "");
    }

    // onlyRole
    function airdropMint(address _address, uint256 _id, uint256 _mintAmount) public onlyRole(BOY){
        require(_mintAmount > 0, "need to mint over 1 amount");
        itemData[_id].totalSupply += _mintAmount;
        _mint(_address, _id, _mintAmount, "");
    }

    function setItemData(uint256 _id, uint256 _cost, string memory _jsonUri, bool _onSaleState) external onlyRole(BOY){
        itemData[_id].cost = _cost;
        itemData[_id].jsonUri = _jsonUri;
        itemData[_id].onSale = _onSaleState;
    }

    function setOnSaleState(uint256 _id, bool _state) public onlyRole(BOY){
        itemData[_id].onSale = _state;
    }

    // onlyOwner
    function withdraw() public onlyOwner{
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner{
        withdrawAddress = _withdrawAddress;
    }

    // view
    function totalSupply(uint256 _id) external view returns(uint256){
        return itemData[_id].totalSupply;
    }

    function cost(uint256 _id) external view returns(uint256){
        return itemData[_id].cost;
    }

    function onSale(uint256 _id) external view returns(bool){
        return itemData[_id].onSale;
    }
    
    //override
    function uri(uint256 _id) public view override returns (string memory) {
        return itemData[_id].jsonUri;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns(bool){
        return AccessControl.supportsInterface(interfaceId)|| ERC1155.supportsInterface(interfaceId);
    }
    
    // disabled for sbt
    modifier disabled { revert("Disabled"); _; }
    function setApprovalForAll(address operator, bool approved) public virtual override disabled {}
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override disabled{}
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override disabled{}
}