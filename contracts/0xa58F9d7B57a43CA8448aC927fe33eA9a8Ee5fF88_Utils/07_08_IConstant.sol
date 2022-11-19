// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

/* solhint-disable */
interface IConstant {
    function ETH_ADDR() external view returns (address);

    function INT_UNIT() external view returns (uint256);

    function ACCURACY() external view returns (uint256);

    function BLOCKS_PER_YEAR() external view returns (uint256);
}
/* solhint-enable */