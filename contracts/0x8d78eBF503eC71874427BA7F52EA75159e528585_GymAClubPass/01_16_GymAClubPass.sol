// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract GymAClubPass is ERC1155, AccessControl, Pausable, ERC1155Burnable, ERC1155Supply, Ownable{
    
    using Strings for uint256;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public constant MAX_SUPPLY_LIMIT = type(uint256).max;
    mapping(uint256 => uint256) private _supplyLimit;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_, string memory uri_) ERC1155(uri_) {

        _name = name_;
        _symbol = symbol_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        string memory baseURI = super.uri(id);
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, id.toString()))
            : '';
    }

    function setURI(string memory newuri) public onlyRole(OPERATOR_ROLE) {
        _setURI(newuri);
    }

    function setSupplyLimit(uint256 id, uint256 limit) external onlyRole(OPERATOR_ROLE){
        require(limit > 0, "Cannot set limit to 0");
        require(_supplyLimit[id] == 0, "Cannot update supply limit");
        require(limit >= totalSupply(id) , "Limit is less than current supply");
        _supplyLimit[id] = limit;
    }

    function supplyLimitOf(uint256 id) external view returns( uint256 ){
        uint256 limit = _supplyLimit[id];
        if (limit == 0 && exists(id)){
            return MAX_SUPPLY_LIMIT;
        }else{
            return limit;
        }
    }

    function safeDeliver(
        address[] memory tos,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) 
    {
        _safeDeliver(tos, ids, amounts, data);
    }

    function _safeDeliver(
        address[] memory tos,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 length = tos.length;
        require(length == ids.length && length == amounts.length,  "tos, ids and amounts length mismatch");
        
        for (uint256 i = 0; i < length; ++i) {
            _mint(tos[i], ids[i], amounts[i], data);       
        }
    }

    function redeem(
        address account,
        uint256 id,
        uint256 value
    ) public virtual onlyRole(BURNER_ROLE){
        _burn(account, id, value);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                if(_supplyLimit[id] != 0 && totalSupply(id) > _supplyLimit[id]){
                    revert("Excess supply limit");
                }
            }
        }
        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                if(_supplyLimit[id] != 0){
                    _supplyLimit[id] -= amounts[i];
                }
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}