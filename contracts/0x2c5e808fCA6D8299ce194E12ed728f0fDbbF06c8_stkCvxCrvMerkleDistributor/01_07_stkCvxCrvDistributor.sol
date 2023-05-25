// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "GenericDistributor.sol";

contract stkCvxCrvMerkleDistributor is GenericDistributor {
    using SafeERC20 for IERC20;

    constructor(
        address _vault,
        address _depositor,
        address _token
    ) GenericDistributor(_vault, _depositor, _token) {}
}