// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ForjCustomErrors} from "contracts/utils/ForjCustomErrors.sol";

contract ForjModifiers is Ownable, ForjCustomErrors {

    bool public modifiersInitialized;

    address public multisig;
    bool public paused;

    mapping(address => bool) public isAdmin;

    function _modifiersInitialize(
        address _admin,
        address _multisig
    ) internal onlyAdminOrOwner(msg.sender) {
        if(modifiersInitialized) revert AlreadyInitialized();
        isAdmin[_admin] = true;
        multisig = _multisig;
        modifiersInitialized = true;
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

    function setMultiSig(address _multisig) public onlyAdminOrOwner(msg.sender){
        multisig = _multisig;
    }

    function setAdmin(address _admin, bool _isAdmin) public onlyAdminOrOwner(msg.sender){
        isAdmin[_admin] = _isAdmin;
    }
}