// 69bd48272bb24e102f2731d5744899879b44ae79
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "ACLBase.sol";

contract ConvexAcl is ACLBase {

    string public constant override NAME = "ConvexAcl";
    uint public constant override VERSION = 2;

    mapping(bytes32 => mapping (uint256 => bool)) public poolIdWhitelist;

    struct PoolId {
        bytes32 role;
        uint256 poolId; 
        bool poolStatus;
    }

    // ACL set methods
    function setPool(bytes32 _role,uint256 _poolId, bool _poolStatus) external onlySafe {
        poolIdWhitelist[_role][_poolId] = _poolStatus;
    }

    function setPools(PoolId[] calldata _poolIds) external onlySafe {    
        for (uint i=0; i < _poolIds.length; i++) { 
            poolIdWhitelist[_poolIds[i].role][_poolIds[i].poolId] = _poolIds[i].poolStatus;
        }
    }

    // ACL check methods
    function depositAll(uint256 _pid, bool _stake) public onlySelf {
        require(poolIdWhitelist[_checkedRole][_pid],"_pid not allowed!");
    }

    function deposit(uint256 _pid, uint256 _amount, bool _stake) public onlySelf {
        require(poolIdWhitelist[_checkedRole][_pid],"_pid not allowed!");
    }

    function getReward(address _account, bool _claimExtras) public onlySelf {
        checkRecipient(_account);
    }

    function withdrawAndUnwrap(uint256 amount, bool claim) public onlySelf {}
    function withdraw(uint256 amount, bool claim) public onlySelf {}
    function withdrawAllAndUnwrap(bool claim) external onlySelf {}

    fallback() external {
        revert("Unauthorized access");
    }
}