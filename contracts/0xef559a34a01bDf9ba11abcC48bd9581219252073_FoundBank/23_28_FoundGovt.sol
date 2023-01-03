// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

  /*$$$$$   /$$$$$$  /$$    /$$ /$$$$$$$$ /$$$$$$$  /$$   /$$  /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$$
 /$$__  $$ /$$__  $$| $$   | $$| $$_____/| $$__  $$| $$$ | $$ /$$__  $$| $$$ | $$ /$$__  $$| $$_____/
| $$  \__/| $$  \ $$| $$   | $$| $$      | $$  \ $$| $$$$| $$| $$  \ $$| $$$$| $$| $$  \__/| $$
| $$ /$$$$| $$  | $$|  $$ / $$/| $$$$$   | $$$$$$$/| $$ $$ $$| $$$$$$$$| $$ $$ $$| $$      | $$$$$
| $$|_  $$| $$  | $$ \  $$ $$/ | $$__/   | $$__  $$| $$  $$$$| $$__  $$| $$  $$$$| $$      | $$__/
| $$  \ $$| $$  | $$  \  $$$/  | $$      | $$  \ $$| $$\  $$$| $$  | $$| $$\  $$$| $$    $$| $$
|  $$$$$$/|  $$$$$$/   \  $/   | $$$$$$$$| $$  | $$| $$ \  $$| $$  | $$| $$ \  $$|  $$$$$$/| $$$$$$$$
 \______/  \______/     \_/    |________/|__/  |__/|__/  \__/|__/  |__/|__/  \__/ \______/ |_______*/

interface FoundGovt {
    function tax() external view returns (uint);
    function payee() external view returns (address);
}

contract Governed is Pausable, Ownable {
    uint private _govtCount;

    mapping(uint => FoundGovt) private _govts;

    event AddGovernment(uint indexed id, FoundGovt indexed govt);
    event RemoveGovernment(uint indexed id, FoundGovt indexed govt);

    function governmentCount() public view returns (uint) {
        return _govtCount;
    }

    function governmentAddress(uint id) public view returns (FoundGovt) {
        return _govts[id];
    }

    function governmentTax(uint id) public view returns (uint) {
        FoundGovt govt = _govts[id];

        if (address(govt) == address(0)) {
            return 0;
        }

        return govt.tax();
    }

    function governmentPayee(uint id) public view returns (address) {
        FoundGovt govt = _govts[id];

        if (address(govt) == address(0)) {
            return address(0);
        }

        return govt.payee();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addGovernment(FoundGovt govt) external onlyOwner {
        _govts[++_govtCount] = govt;
        emit AddGovernment(_govtCount, govt);
    }

    function removeGovernment(uint id) external onlyOwner {
        emit RemoveGovernment(id, _govts[id]);
        _govts[id] = FoundGovt(address(0));
    }
}