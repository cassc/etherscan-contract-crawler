// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0 <=0.8.19;

import "@openzeppelin/[email protected]/interfaces/IERC20.sol";
import "@openzeppelin/[email protected]/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/[email protected]/proxy/Proxy.sol";

contract Mauser is Proxy, ERC1967Upgrade {
    constructor(address admin) {
        _changeAdmin(admin);
    }

    function _implementation() internal view virtual override returns (address implementation) {
        return _getImplementation();
    }

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "Mauser: only admin can call this function");
        _;
    }

    function multiSend(bytes memory) public payable onlyAdmin {
        _fallback();
    }

    function changeAdmin(address newAdmin) public onlyAdmin {
        _changeAdmin(newAdmin);
    }

    function upgradeTo(address newImplementation) public onlyAdmin {
        _upgradeTo(newImplementation);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) public onlyAdmin {
        _upgradeToAndCall(newImplementation, data, forceCall);
    }

    function getAdmin() public view returns (address admin) {
        return _getAdmin();
    }

    function getImplementation() public view returns (address implementation) {
        return _getImplementation();
    }

    function _checkBalance(uint256 min, uint256 max, uint256 balance) private pure {
        require(min <= max, "Mauser: min must be less than or equal to max");
        require(balance >= min, "Mauser: balance too low");
        require(balance <= max, "Mauser: balance too high");
    }

    function checkBalance(uint256 min, uint256 max, address addr) public view {
        _checkBalance(min, max, addr.balance);
    }

    function checkBalance(uint256 min, uint256 max, address addr, address token) public view {
        _checkBalance(min, max, IERC20(token).balanceOf(addr));
    }
}