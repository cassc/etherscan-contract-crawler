// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Base.sol";
import "./SlotData.sol";
import "./EnhancedMap.sol";
import "./EnhancedUniqueIndexMap.sol";


contract Proxy is Base {

    using SlotData for bytes32;
    using EnhancedMap for bytes32;
    using EnhancedUniqueIndexMap for bytes32;

    constructor (address admin) {
        require(admin != address(0),"admin may never be empty address");
        adminSlot.sysSaveSlotData(bytes32(uint256(uint160(admin))));
        outOfServiceSlot.sysSaveSlotData(bytes32(uint256(0)));
        revertMessageSlot.sysSaveSlotData(bytes32(uint256(1)));
        transparentSlot.sysSaveSlotData(bytes32(uint256(1)));

    }

    bytes32 constant adminSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("adminSlot"))))));

    bytes32 constant revertMessageSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("revertMessageSlot"))))));

    bytes32 constant outOfServiceSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("outOfServiceSlot"))))));

    //address <===>  index EnhancedUniqueIndexMap
    //0x2f80e9a12a11b80d2130b8e7dfc3bb1a6c04d0d87cc5c7ea711d9a261a1e0764
    bytes32 constant delegatesSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("delegatesSlot"))))));

    bytes32 constant transparentSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("transparentSlot"))))));


    event DelegateSet(address delegate, bool activated);
    //===================================================================================

    //
    function sysCountDelegate() view public returns (uint256){
        return delegatesSlot.sysUniqueIndexMapSize();
    }

    function sysGetDelegateAddress(uint256 index) view public returns (address){
        return address(uint160(uint256(delegatesSlot.sysUniqueIndexMapGetValue(index))));
    }

    function sysGetDelegateIndex(address addr) view public returns (uint256) {
        return uint256(delegatesSlot.sysUniqueIndexMapGetIndex(bytes32(uint256(uint160(addr)))));
    }

    function sysGetDelegateAddresses() view public returns (address[] memory){
        uint256 count = sysCountDelegate();
        address[] memory delegates = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            delegates[i] = sysGetDelegateAddress(i + 1);
        }
        return delegates;
    }

    //add delegates on current version
    function sysAddDelegates(address[] memory _inputs) external onlyAdmin {
        for (uint256 i = 0; i < _inputs.length; i ++) {
            delegatesSlot.sysUniqueIndexMapAdd(bytes32(uint256(uint160(_inputs[i]))));
            emit DelegateSet(_inputs[i], true);
        }
    }

    //delete delegates
    //be careful, if you delete a delegate, the index will change
    function sysDelDelegates(address[] memory _inputs) external onlyAdmin {
        for (uint256 i = 0; i < _inputs.length; i ++) {

            delegatesSlot.sysUniqueIndexMapDelArrange(bytes32(uint256(uint160(_inputs[i]))));
            emit DelegateSet(_inputs[i], false);
        }
    }

    //add and delete delegates
    function sysReplaceDelegates(address[] memory _delegatesToDel, address[] memory _delegatesToAdd) external onlyAdmin {
        require(_delegatesToDel.length == _delegatesToAdd.length, "sysReplaceDelegates, length does not match");
        for (uint256 i = 0; i < _delegatesToDel.length; i ++) {
            delegatesSlot.sysUniqueIndexMapReplace(bytes32(uint256(uint160(_delegatesToDel[i]))), bytes32(uint256(uint160(_delegatesToAdd[i]))));
            emit DelegateSet(_delegatesToDel[i], false);
            emit DelegateSet(_delegatesToAdd[i], true);
        }
    }

    //=============================================

    function sysGetAdmin() view public returns (address){
        return address(uint160(uint256(adminSlot.sysLoadSlotData())));
    }

    function sysSetAdmin(address _input) external onlyAdmin {
        adminSlot.sysSaveSlotData(bytes32(uint256(uint160(_input))));
    }

    function sysGetRevertMessage() view public returns (uint256){
        return uint256(revertMessageSlot.sysLoadSlotData());
    }

    function sysSetRevertMessage(uint256 _input) external onlyAdmin {
        revertMessageSlot.sysSaveSlotData(bytes32(_input));
    }

    function sysGetOutOfService() view public returns (uint256){
        return uint256(outOfServiceSlot.sysLoadSlotData());
    }

    function sysSetOutOfService(uint256 _input) external onlyAdmin {
        outOfServiceSlot.sysSaveSlotData(bytes32(_input));
    }

    function sysGetTransparent() view public returns (uint256){
        return uint256(transparentSlot.sysLoadSlotData());
    }

    function sysSetTransparent(uint256 _input) external onlyAdmin {
        transparentSlot.sysSaveSlotData(bytes32(_input));
    }

    //=====================internal functions=====================

    receive() payable external {
        process();
    }

    fallback() payable external {
        process();
    }


    //since low-level address.delegateCall is available in solidity,
    //we don't need to write assembly
    function process() internal outOfService {

        if (msg.sender == sysGetAdmin() && sysGetTransparent() == 1) {
            revert("admin cann't call normal function in Transparent mode");
        }

        /*
        the default transfer will set data to empty,
        so that the msg.data.length = 0 and msg.sig = bytes4(0x00000000),
        */

        //the sig might be 0x00
        discover();

        //hit here means not found selector
        if (sysGetRevertMessage() == 1) {
            revert(string(abi.encodePacked(sysPrintAddressToHex(address(this)), ", function selector not found : ", sysPrintBytes4ToHex(msg.sig))));
        } else {
            revert();
        }

    }

    function discover() internal {
        bool found = false;
        bool error;
        bytes memory returnData;
        address targetDelegate;
        uint256 len = sysCountDelegate();
        for (uint256 i = 0; i < len; i++) {
            targetDelegate = sysGetDelegateAddress(i + 1);
            (found, error, returnData) = redirect(targetDelegate, msg.data);

            if (found) {

                returnAsm(error, returnData);
            }
        }
    }

    //since low-level ```<address>.delegatecall(bytes memory) returns (bool, bytes memory)``` can return returndata,
    //we use high-level solidity for better reading
    function redirect(address delegateTo, bytes memory callData) internal returns (bool found, bool error, bytes memory returnData){
        require(delegateTo != address(0), "delegateTo must not be 0x00");
        bool success;
        (success, returnData) = delegateTo.delegatecall(callData);
        if (success && keccak256(returnData) == keccak256(notFoundMark)) {
            //the delegate returns ```notFoundMark``` notFoundMark, which means invoke goes to wrong contract or function doesn't exist
            return (false, true, returnData);
        } else {
            return (true, !success, returnData);
        }

    }

    function sysPrintBytesToHex(bytes memory input) internal pure returns (string memory){
        bytes memory ret = new bytes(input.length * 2);
        bytes memory alphabet = "0123456789abcdef";
        for (uint256 i = 0; i < input.length; i++) {
            bytes32 t = bytes32(input[i]);
            bytes32 tt = t >> 31 * 8;
            uint256 b = uint256(tt);
            uint256 high = b / 0x10;
            uint256 low = b % 0x10;
            bytes1 highAscii = alphabet[high];
            bytes1 lowAscii = alphabet[low];
            ret[2 * i] = highAscii;
            ret[2 * i + 1] = lowAscii;
        }
        return string(ret);
    }

    function sysPrintAddressToHex(address input) internal pure returns (string memory){
        return sysPrintBytesToHex(
            abi.encodePacked(input)
        );
    }

    function sysPrintBytes4ToHex(bytes4 input) internal pure returns (string memory){
        return sysPrintBytesToHex(
            abi.encodePacked(input)
        );
    }

    function sysPrintUint256ToHex(uint256 input) internal pure returns (string memory){
        return sysPrintBytesToHex(
            abi.encodePacked(input)
        );
    }

    modifier onlyAdmin(){
        require(msg.sender == sysGetAdmin(), "only admin");
        _;
    }

    modifier outOfService(){
        if (sysGetOutOfService() == uint256(1)) {
            if (sysGetRevertMessage() == 1) {
                revert("Proxy is out-of-service right now");
            } else {
                revert();
            }
        }
        _;
    }

}