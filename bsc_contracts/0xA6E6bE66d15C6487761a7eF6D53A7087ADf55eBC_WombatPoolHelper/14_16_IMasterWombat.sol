pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterWombat {

    function getAssetPid(address lp) external view returns(uint256);
    
    function depositFor(uint256 pid, uint256 amount, address account) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function multiClaim(uint256[] memory _pids) external returns (
        uint256 transfered,
        uint256[] memory amounts,
        uint256[] memory additionalRewards
    );

    function pendingTokens(uint256 _pid, address _user) external view
        returns (
            uint256 pendingRewards,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
    );

    function migrate(uint256[] calldata _pids) external;
}