// SPDX-License-Identifier: MIT

import "contracts/DODOV3MM/D3Pool/D3MM.sol";
import "contracts/DODOV3MM/intf/ID3Maker.sol";

pragma solidity 0.8.16;

contract MockD3MM is D3MM {
    function updateReserve(address token) external {
        _updateReserve(token);
    }

    function setAllFlagByAnyone(uint256 newFlag) external {
        allFlag = newFlag;
    }

    function getTokenFlag(address token) external view returns (uint256){
        (, uint256 tokenIndex) = ID3Maker(state._MAKER_).getTokenMMInfoForPool(token);
        return (allFlag >> (tokenIndex) & 1);
    }
}