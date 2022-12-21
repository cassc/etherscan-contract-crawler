// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./interfaces/IFluentTokenAllowList.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract FluentTokenAllowList is
    IFluentTokenAllowList,
    Initializable,
    AccessControlUpgradeable
{
    int public constant Version = 3;
    event AddedToAllowList(address indexed user, string message);
    event RemovedFromAllowList(address indexed user, string message);
    event TokenTransfered(
        address indexed contractFrom,
        address indexed to,
        address indexed erc20Addr,
        uint256 amount
    );

    /**
     * FFC_INPUT_ROLE for the actor who is allowed to add and remove token addresses from the Allowlist.
     */
    bytes32 public constant FFC_INPUT_ROLE = keccak256("FFC_INPUT_ROLE");

    bytes32 public constant TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE =
        keccak256("TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE");

    mapping(address => bool) public erc20AllowList;

    function initialize() public initializer {
        AccessControlUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(FFC_INPUT_ROLE, msg.sender);
    }

    function addAllowList(address addr) external onlyRole(FFC_INPUT_ROLE) {
        require(
            !erc20AllowList[addr],
            "Token address already in the AllowList"
        );
        emit AddedToAllowList(addr, "Successfully added to AllowList");
        erc20AllowList[addr] = true;
    }

    function removeFromAllowList(address addr) public onlyRole(FFC_INPUT_ROLE) {
        require(erc20AllowList[addr], "Token address not in the AllowList");
        emit RemovedFromAllowList(addr, "Successfully removed from AllowList");
        erc20AllowList[addr] = false;
    }

    function checkAllowList(address _addr) external view returns (bool) {
        return erc20AllowList[_addr];
    }

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external onlyRole(TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE) {
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(erc20Addr),
            to,
            amount
        );
    }

    function transferErc20Token(
        address contractFrom,
        address to,
        address erc20Addr,
        uint256 amount
    ) external onlyRole(TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE) {
        require(contractFrom != address(0x0), "ZERO Addr is not allowed");
        require(to != address(0x0), "ZERO Addr is not allowed");
        require(erc20Addr != address(0x0), "ZERO Addr is not allowed");
        require(
            erc20AllowList[erc20Addr],
            "Address not in the ERC20 AllowList"
        );
        bytes memory data = abi.encodeWithSelector(
            IFluentTokenAllowList.transferErc20.selector,
            to,
            erc20Addr,
            amount
        );

        emit TokenTransfered(contractFrom, to, erc20Addr, amount);
        (bool success, ) = contractFrom.call(data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}