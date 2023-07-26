/**
 *Submitted for verification at Etherscan.io on 2023-07-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external;
}

contract Receiver {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function send( address token, address payable recipient, uint256 amount ) public {
        require(msg.sender == owner);
        IERC20(token).transfer(recipient, amount);
    }
}

contract Factory {
    address public owner;
    mapping ( uint256 => Receiver ) public receiversMap;
    
    constructor() {
        owner = msg.sender;
    }

    function create( uint256[] calldata salts ) external {
        require(msg.sender == owner);
        for(uint256 i = 0; i < salts.length; i++) {
            bytes32 salt = bytes32(salts[i]);
            receiversMap[salts[i]] = new Receiver{salt: salt}();
        }
    }

    function collect( address token, address payable recipient, uint256[] calldata receivers, uint[] calldata amounts ) public {
        require(msg.sender == owner);
        for(uint256 i = 0; i < receivers.length; i++) {
            receiversMap[receivers[i]].send( token, recipient, amounts[i] );
        }
    }
}