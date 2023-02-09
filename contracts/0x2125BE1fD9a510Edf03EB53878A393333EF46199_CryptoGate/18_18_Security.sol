pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import {IterableMapping} from "./IterableMapping.sol";

/* 
 * @title Security
 *
 * SPDX-License-Identifier: MIT
 * 
 * CRYPTOGATE
 * 
 * https://cryptogate.ch
 * 
 **/


contract CryptoGate is ERC20, ERC20Permit, ERC20Burnable, Pausable {
    using IterableMapping for IterableMapping.holder;

    mapping(string => Document) internal _documents;
    mapping(string => uint32) internal _docIndexes;

    struct Document {
        uint32 docIndex;
        uint64 lastModified;
        string uri;
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");

    string[] _docNames;

    IAccessControl public accessControl;
    IterableMapping.holder private holder;

    event DocumentRemoved(string indexed _name, string _uri);
    event DocumentUpdated(string indexed _name, string _uri);

    modifier onlyRole(bytes32 _role) {
        require(
            accessControl.hasRole(_role, msg.sender),
            "Caller is missing role."
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _roleAddress
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        accessControl = IAccessControl(_roleAddress);
    }

    function mint(address to, uint256 amount) external onlyRole(MANAGER_ROLE) {
        _mint(to, amount);
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function redeemOne(address _account, uint256 _amount)
        external
        onlyRole(MANAGER_ROLE)
    {
        _transfer(_account, msg.sender, _amount);
    }


    function redeemAll(
        uint256 _startIndex,
        uint256 _endIndex,
        address _dest
    ) external onlyRole(MANAGER_ROLE) {
        uint256 max = getTotalInvestors();

        if (_endIndex > max - 1) _endIndex = max - 1;

        require(_startIndex <= _endIndex, "Start index greater than end.");

        for (uint256 i = _startIndex; i <= _endIndex; i++) {
            address key = holder.getKeyAddressAtIndex(i);
            uint256 balance = getBalanceOf(key);
            _transfer(key, _dest, balance);
        }
    }


    function setNewRoleAddress(address _address)
        external
        onlyRole(MANAGER_ROLE)
    {
        accessControl = IAccessControl(_address);
    }

    function setDocument(string calldata _name, string calldata _uri)
        external
        onlyRole(MANAGER_ROLE)
    {
        _setDocument(_name, _uri);
    }

    function removeDocument(string calldata _name)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(
            _documents[_name].lastModified != uint64(0),
            "Document should exist"
        );
        uint32 index = _documents[_name].docIndex - 1;
        if (index != _docNames.length - 1) {
            _docNames[index] = _docNames[_docNames.length - 1];
            _documents[_docNames[index]].docIndex = index + 1;
        }
        _docNames.pop();
        emit DocumentRemoved(_name, _documents[_name].uri);
        delete _documents[_name];
    }

    function getDocument(string calldata _name)
        external
        view
        returns (string memory, uint256)
    {
        return (_documents[_name].uri, uint256(_documents[_name].lastModified));
    }

    function getAllDocuments() external view returns (string[] memory) {
        return _docNames;
    }

    function getDocumentCount() external view returns (uint256) {
        return _docNames.length;
    }

    function getDocumentName(uint256 _index)
        external
        view
        returns (string memory)
    {
        require(_index < _docNames.length, "Index out of bounds");
        return _docNames[_index];
    }


    function getBalanceOf(address _account) public view returns (uint256) {
        return holder.getBalanceOf(_account);
    }

    function getTotalInvestors() public view returns (uint256) {
        return holder.holderSize();
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        bool fromIsBlocklisted = accessControl.hasRole(BLOCKLISTED_ROLE, from);
        bool toIsAdmin = accessControl.hasRole(MANAGER_ROLE, to);
        bool toIsWhitelisted = accessControl.hasRole(WHITELISTED_ROLE, to);
        
        require(toIsWhitelisted, "Not whitelisted");
        require(!fromIsBlocklisted || (fromIsBlocklisted && toIsAdmin), "Blocklisted");
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._afterTokenTransfer(from, to, amount);
        uint256 balanceSender = this.balanceOf(from);
        uint256 balanceReceiver = this.balanceOf(to);
        holder.updateBalance(from, balanceSender);
        holder.updateBalance(to, balanceReceiver);
    }

    function _setDocument(string memory _name, string memory _uri) internal {
        require(bytes(_name).length > 0, "Zero name is not allowed");
        require(bytes(_uri).length > 0, "Should not be a empty uri");
        if (_documents[_name].lastModified == uint64(0)) {
            _docNames.push(_name);
            _documents[_name].docIndex = uint32(_docNames.length);
        }
        _documents[_name] = Document(
            _documents[_name].docIndex,
            uint64(block.timestamp),
            _uri
        );
        emit DocumentUpdated(_name, _uri);
    }
}