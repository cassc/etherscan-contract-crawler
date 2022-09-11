pragma solidity 0.8.6;


import "Ownable.sol";
import "IForwarder.sol";


// TODO: use revertFailedCall in Shared
contract Forwarder is IForwarder, Ownable {

    mapping(address => bool) private _canCall;


    constructor() Ownable() {}


    function forward(
        address target,
        bytes calldata callData
    ) external override payable returns (bool success, bytes memory returnData) {
        require(_canCall[msg.sender], "Forw: caller not the Registry");
        (success, returnData) = target.call{value: msg.value}(callData);
    }

    function canCall(address caller) external view returns (bool) {
        return _canCall[caller];
    }

    function setCaller(address caller, bool b) external onlyOwner {
        _canCall[caller] = b;
    }
}