// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IDonate {
    function queryDonatedList() external view returns (address[] memory);
}

contract DonateProcessor {
    using SafeERC20 for IERC20;
    address public constant DONATE = 0x8DDeaD5dA29A08E35110eE0c216A85cBE2C65884;

    constructor() {}

    function processDonate(address token) external {
        uint256 donateAmount = IERC20(token).balanceOf(address(this));
        require(donateAmount > 0, "zero donate amount error");
        address[] memory donates = IDonate(DONATE).queryDonatedList();
        uint256 perDonate = donateAmount / donates.length;
        for (uint256 i = 0; i < donates.length; i++) {
            IERC20(token).safeTransfer(donates[i], perDonate);
        }
    }
}