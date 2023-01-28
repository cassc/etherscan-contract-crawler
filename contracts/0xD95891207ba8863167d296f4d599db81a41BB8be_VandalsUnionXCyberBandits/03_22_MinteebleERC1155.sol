// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MinteebleERC1155 is
    ERC1155Supply,
    AccessControlEnumerable,
    ReentrancyGuard
{
    uint256[] public ids;
    bool public dynamicIdsEnabled;
    string public name;
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        dynamicIdsEnabled = true;
        name = _name;
        symbol = _symbol;
    }

    modifier requireAdmin(address _account) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _account), "Unauthorized");
        _;
    }

    modifier idExists(uint256 _id) {
        bool idFound = false;
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == _id) idFound = true;
        }
        require(idFound, "Id not found");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _addId(uint256 _id) internal {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] != _id, "Id already exists");
        }

        ids.push(_id);
    }

    function _removeId(uint256 _id) internal {
        bool idFound = false;

        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == _id) {
                require(totalSupply(_id) == 0, "Cannot delete id with supply");

                ids[i] = ids[ids.length - 1];
                delete ids[ids.length - 1];
                ids.pop();

                idFound = true;
            }
        }

        require(idFound, "Id not found");
    }

    function addId(uint256 _id) public requireAdmin(msg.sender) {
        _addId(_id);
    }

    function removeId(uint256 _id) public requireAdmin(msg.sender) {
        _removeId(_id);
    }

    function getIds() public view returns (uint256[] memory) {
        return ids;
    }

    function setURI(string memory _newUri) public requireAdmin(msg.sender) {
        _setURI(_newUri);
    }

    function mintForAddress(
        address _recipientAccount,
        uint256 _id,
        uint256 _amount
    ) public requireAdmin(msg.sender) idExists(_id) nonReentrant {
        _mint(_recipientAccount, _id, _amount, "");
    }

    function airdrop(uint256 _id, address[] memory _accounts)
        public
        requireAdmin(msg.sender)
        idExists(_id)
        nonReentrant
    {
        for (uint256 i; i < _accounts.length; i++) {
            _mint(_accounts[i], _id, 1, "");
        }
    }
}