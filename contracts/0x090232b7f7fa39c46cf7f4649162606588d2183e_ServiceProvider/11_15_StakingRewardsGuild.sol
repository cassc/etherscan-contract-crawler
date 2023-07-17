// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { CudosAccessControls } from "../CudosAccessControls.sol";

contract StakingRewardsGuild {
    using SafeERC20 for IERC20;

    IERC20 public token;
    CudosAccessControls public accessControls;

    constructor(IERC20 _token, CudosAccessControls _accessControls) {
        token = _token;
        accessControls = _accessControls;
    }

    function withdrawTo(address _recipient, uint256 _amount) external {
        require(
            accessControls.hasSmartContractRole(msg.sender),
            // StakingRewardsGuild.withdrawTo: Only authorised smart contract
            "OASM"
        );
        // StakingRewardsGuild.withdrawTo: recipient is zero address
        require(_recipient != address(0), "SRG1");

        token.transfer(_recipient, _amount);
    }

    // *****
    // Admin
    // *****

    function recoverERC20(address _erc20, address _recipient, uint256 _amount) external {
        // StakingRewardsGuild.recoverERC20: Only admin
        require(accessControls.hasAdminRole(msg.sender), "OA");
        IERC20(_erc20).safeTransfer(_recipient, _amount);
    }
}