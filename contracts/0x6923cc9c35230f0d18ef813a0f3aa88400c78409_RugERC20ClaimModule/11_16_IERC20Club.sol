// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC1644} from "./IERC1644.sol";
import {ITokenEnforceable} from "../TokenEnforceable/ITokenEnforceable.sol";

// IERC1644 Adds controller mechanisms for the owner to burn and transfer without allowances
interface IERC20Club is IERC1644 {
    event ControlDisabled(address indexed controller);
    event MemberJoined(address indexed member);
    event MemberExited(address indexed member);
    event TokenRecovered(
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    // solhint-disable-next-line func-name-mixedcase
    function __ERC20Club_init(
        string memory name_,
        string memory symbol_,
        address mintPolicy_,
        address burnPolicy_,
        address transferPolicy_
    ) external;

    function memberCount() external view returns (uint256);

    function disableControl() external;

    function mintTo(address account, uint256 amount) external returns (bool);

    function redeem(uint256 amount) external returns (bool);

    function redeemFrom(address account, uint256 amount)
        external
        returns (bool);

    function recoverERC20(
        address recipient,
        address token,
        uint256 amount
    ) external;
}

interface IERC20ClubFull is
    IERC20,
    IERC20Metadata,
    ITokenEnforceable,
    IERC20Club
{
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}