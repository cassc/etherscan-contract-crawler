// 61f5a666f1e2638ad41e1350907deced9dabdb64
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "ACLBase.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract ApexAcl is ACLBase {

    string public constant NAME = "ApexAcl";
    uint public constant VERSION = 1;
    

    mapping(uint256 => mapping (uint256 => bool)) public starkKeyPositionIdPairs;  // role => token => bool

    struct StarkKeyPositionIdPair {
        uint256 starkKey;
        uint256 positionId; 
        bool status;
    }

    // ACL set methods

    function setstarkKeyPositionIdPair(uint256 _starkKey, uint256 _positionId, bool _status) external onlySafe{    
        starkKeyPositionIdPairs[_starkKey][_positionId] = _status;
    }

    function setstarkKeyPositionIdPairs(StarkKeyPositionIdPair[] calldata _starkKeyPositionIdPair) external onlySafe{    
        for (uint i=0; i < _starkKeyPositionIdPair.length; i++) { 
            starkKeyPositionIdPairs[_starkKeyPositionIdPair[i].starkKey][_starkKeyPositionIdPair[i].positionId] = _starkKeyPositionIdPair[i].status;
        }
    }

    // ACL check methods

    function deposit(
        IERC20 token,
        uint256 amount,
        uint256 starkKey,
        uint256 positionId,
        bytes calldata exchangeData
    ) public payable onlySelf {
        require(starkKeyPositionIdPairs[starkKey][positionId],'starkKey or positionId not allowed!');
    }

    function withdraw(uint256 ownerKey, uint256 assetType) public onlySelf {}

    fallback() external {
        revert("Unauthorized access");
    }
}