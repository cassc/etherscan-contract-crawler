// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

import "./Ownable.sol";

abstract contract AdminControl is Ownable {
    address[] private administrators;

    constructor() {
        _addAdmin(_msgSender());
    }

    modifier isAdmin() {
        _checkAdmin();
        _;
    }

    function _checkAdmin() internal view virtual {
        require(adminExists(msg.sender), "caller is not the administrator");
    }

    function adminExists(address account) public view virtual returns (bool){
        for (uint i = 0;i < administrators.length;i++){
            if (administrators[i] == account){
                return true;
            }
        }
        return false;
    }

    function addAdmin(address account) public onlyOwner {
        if (!adminExists(account)){
            _addAdmin(account);
        } else {
            revert("administrator already exists");
        }
    }

    function _addAdmin(address account) internal virtual {
        administrators.push(account);
    }

    function removeAdmin(address account) public onlyOwner{
        if (adminExists(account)){
            _removeAdmin(account);
        } else {
            revert("administrator is not exists");
        }
    }

    function _removeAdmin(address account) internal virtual{
        for (uint i = 1;i < administrators.length;i++){
            if (administrators[i] == account){
                delete administrators[i];
            }
        }
    }
}
