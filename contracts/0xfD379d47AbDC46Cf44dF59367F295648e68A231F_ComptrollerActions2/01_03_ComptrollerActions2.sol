// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {IGnosisSafe} from "../../../../interfaces/IGnosisSafe.sol";

// ---*  Comptroller Actions  *--- //

/*

    ComptrollerV1 Functions (3,4,5,6,10,11,13,14,15):
    - changeAccountAdvisor
    - changeAdvisorAddress
    - changeAdvisorBranch
    - changeBranch
    - registerAdvisor
    - registerBranch
    - removeSafeFromAccount
    - removeUserAccount
 
*/

contract ComptrollerActions2 {

    function changeAccountAdvisor(
        address _onBehalf, 
        uint _placeholder,
        uint __placeholder,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller, address account, uint advisorId, uint fee) = abi.decode(_data,(address,address,uint,uint));
        txData = abi.encodePacked(uint8(0),comptroller,uint256(0),uint256(100),abi.encodeWithSignature(
                "changeAccountAdvisor(address,uint256,uint256)", account, advisorId, fee));
        return txData;
    }

    function changeAdvisorAddress(
        address _onBehalf, 
        uint _placeholder,
        uint __placeholder,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller, uint advisorId, address advisorAddress) = abi.decode(_data,(address,uint,address));
        txData = abi.encodePacked(uint8(0),comptroller,uint256(0),uint256(68),abi.encodeWithSignature(
                "changeAdvisorAddress(uint256,address)", advisorId, advisorAddress));
        return txData;
    }

    function changeAdvisorBranch(
        address _onBehalf, 
        uint _placeholder,
        uint __placeholder,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller, uint advisorId) = abi.decode(_data,(address,uint));
        txData = abi.encodePacked(uint8(0),comptroller,uint256(0),uint256(36),abi.encodeWithSignature(
                "changeAdvisorBranch(uint256)", advisorId));
        return txData;
    }

    function changeBranch(
        address _onBehalf, 
        uint _placeholder,
        uint __placeholder,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller, uint branchId, address branchAddress) = abi.decode(_data,(address,uint,address));
        txData = abi.encodePacked(uint8(0),comptroller,uint256(0),uint256(68),abi.encodeWithSignature(
                "changeBranch(uint256,address)", branchId, branchAddress));
        return txData;
    }

    function registerAdvisor(
        address _onBehalf, 
        uint _placeholder,
        uint __placeholder,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller, address advisorAddress, uint256 branchId) = abi.decode(_data,(address,address,uint));
        txData = abi.encodePacked(uint8(0),comptroller,uint256(0),uint256(68),abi.encodeWithSignature(
                "registerAdvisor(address,uint256)", advisorAddress, branchId));
        return txData;
    }

    function registerBranch(
        address _onBehalf, 
        uint _placeholder,
        uint __placeholder,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller, address branchAddress) = abi.decode(_data,(address,address));
        txData = abi.encodePacked(uint8(0),comptroller,uint256(0),uint256(36),abi.encodeWithSignature(
                "registerBranch(address)", branchAddress));
        return txData;
    }

    function removeBranch(
        address _onBehalf, 
        uint _placeholder,
        uint __placeholder,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller, uint branchId) = abi.decode(_data,(address,uint));
        txData = abi.encodePacked(uint8(0),comptroller,uint256(0),uint256(36),abi.encodeWithSignature(
                "removeBranch(uint256)", branchId));
        return txData;
    }

    function removeSafeFromAccount(
        address _onBehalf, 
        uint _placeholder,
        uint __placeholder,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller, address account, address[] memory subSafes) = abi.decode(_data,(address,address,address[]));
        uint ln = (4*32+subSafes.length*32);
        txData = abi.encodePacked(uint8(0),comptroller,uint256(0),uint256(ln),abi.encodeWithSignature(
                "removeSafeFromAccount(address,address[])", account, subSafes));
        return txData;
    }

    function removeUserAccount(
        address _onBehalf, 
        uint _placeholder,
        uint __placeholder,
        bytes calldata _data
    ) 
        public 
        returns (bytes memory txData) 
    {
        (address comptroller, uint userId, address toRemove) = abi.decode(_data,(address,uint,address));
        txData = abi.encodePacked(uint8(0),comptroller,uint256(0),uint256(68),abi.encodeWithSignature(
                "removeUserAccount(uint256,address)", userId, toRemove));
        return txData;
    }

}