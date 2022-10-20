pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @dev Interface of the VeWom
 */
interface IVeWom {
    struct Breeding {
        uint48 unlockTime;
        uint104 womAmount;
        uint104 veWomAmount;
    }

    struct UserInfo {
        // reserve usage for future upgrades
        uint256[10] reserved;
        Breeding[] breedings;
    }

    function totalSupply() external view returns (uint256);

    function balanceOf(address _addr) external view returns (uint256);

    function isUser(address _addr) external view returns (bool);

    function getUserInfo(address addr) external view returns (Breeding[] memory);

    function mint(uint256 amount, uint256 lockDays) external returns (uint256 veWomAmount);

    function burn(uint256 slot) external;
}