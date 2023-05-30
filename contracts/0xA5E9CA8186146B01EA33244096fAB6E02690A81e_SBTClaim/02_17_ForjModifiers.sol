// SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.8.0 <=0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ForjModifiers is Ownable {

    address multisig;
    bool paused;

    mapping(address => bool) public isAdmin;

    function modifiersInitialize(
        address _admin,
        address _multisig,
        bool _paused
    ) public onlyAdminOrOwner(msg.sender) {
        isAdmin[_admin] = true;
        multisig = _multisig;
        paused = _paused;
    }

    function _onlyAdminOrOwner(address _address) private view {
        require(
            isAdmin[_address] || _address == owner(),
            "This address is not allowed"
        );
    }

    modifier onlyAdminOrOwner(address _address) {
        _onlyAdminOrOwner(_address);
        _;
    }
    
    function _onlyMultiSig(address _address) private view {
        require(_address == multisig, "Not Multisig wallet");
    }

    modifier onlyMultiSig(address _address) {
        _onlyMultiSig(_address);
        _;
    }

    function _onlyUnpaused() private view {
        require(!paused, "Sale Stopped Currently");
    }

    modifier onlyUnpaused() {
        _onlyUnpaused();
        _;
    }

    function emergencyPause(bool _paused) public onlyAdminOrOwner(msg.sender){
        paused = _paused;
    }
}