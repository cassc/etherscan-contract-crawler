// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ITreasury.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import {
    IERC20Permit
} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface ICommandGate {
    function whitelistAddress(address addr_) external;

    function depositNativeTokenWithCommand(
        address contract_,
        bytes4 fnSig_,
        bytes calldata params_
    ) external payable;

    function depositERC20PermitWithCommand(
        IERC20Permit token_,
        uint256 value_,
        uint256 deadline_,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes4 fnSig_,
        address contract_,
        bytes calldata data_
    ) external;

    function depositERC20WithCommand(
        IERC20 token_,
        uint256 value_,
        bytes4 fnSig_,
        address contract_,
        bytes memory data_
    ) external;

    function depositERC721MultiWithCommand(
        uint256[] calldata tokenIds_,
        address[] calldata contracts_,
        bytes[] calldata data_
    ) external;
}