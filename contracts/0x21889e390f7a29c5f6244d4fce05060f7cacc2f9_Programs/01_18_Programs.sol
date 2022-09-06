pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Lockable.sol";

contract Programs is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, ERC1155Pausable, Lockable {
    // Mapping from token ID to token sells
    mapping(uint256 => uint256) private _totalMints;
    mapping(uint256 => uint256) private _totalSells;
    mapping(uint256 => uint256) private _totalBuyers;

    uint256[] public projectIds;

    // Token name
    string private _name;
    // Token symbol
    string private _symbol;

    constructor(string memory name_, string memory symbol_, string memory uri_) ERC1155(uri_) {
        _name = name_;
        _symbol = symbol_;
        _setURI(uri_);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(uint256 id, uint256 amount, bytes memory data) public onlyOwner
    {
        _mint(owner(), id, amount, data);
        _totalMints[id] = _totalMints[id] + amount;
        _totalSells[id] = 0;

        bool _idExists = false;
        for (uint256 i = 0; i < projectIds.length; i ++) {
            if (projectIds[i] == id) {
                _idExists = true;
                break;
            }
        }

        if (!_idExists) {
            projectIds.push(id);
        }
    }

    function buy(uint256 id, uint256 amount) public payable
    {
        require(msg.sender != owner(), 'owner cannot buy');
        require(_totalSells[id] < _totalMints[id], 'funding was completed');

        payable(owner()).transfer(msg.value);
        _safeTransferFrom(owner(), msg.sender, id, amount, "");

        _totalSells[id] = _totalSells[id] + amount;
        _totalBuyers[id] = _totalBuyers[id] + 1;
    }

    function totalSells(uint256 id) public view returns (uint256)
    {
        return _totalSells[id];
    }

    function totalMints(uint256 id) public view returns (uint256)
    {
        return _totalMints[id];
    }

    function totalBuyers(uint256 id) public view returns (uint256)
    {
        return _totalBuyers[id];
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner
    {
        _mintBatch(to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSells[ids[i]] = 0;
            _totalMints[ids[i]] = amounts[i];
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply, ERC1155Pausable)
    {
        require(!isLocked(operator), "operator account is locked.");
        require(!isLocked(from), "from account is locked.");
        require(!isLocked(to), "to account is locked.");
        require(!paused(), "ERC1155Pausable: token transfer while paused");

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function getTotalProjectCount() public view returns (uint256)
    {
        return projectIds.length;
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }
}