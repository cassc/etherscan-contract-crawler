// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/profiles/IABIResolver.sol";
import "../interfaces/profiles/IAddrResolver.sol";
import "../interfaces/profiles/IContentHashResolver.sol";
import "../interfaces/profiles/IInterfaceResolver.sol";
import "../interfaces/profiles/INameResolver.sol";
import "../interfaces/profiles/IPubkeyResolver.sol";
import "../interfaces/profiles/ITextResolver.sol";
import "../interfaces/profiles/IExtendedResolver.sol";

/**
 * A generic resolver interface which includes all the functions including the ones deprecated
 */
interface IResolver is
    IERC165,
    IABIResolver,
    IAddrResolver,
    IContentHashResolver,
    IInterfaceResolver,
    INameResolver,
    IPubkeyResolver,
    ITextResolver,
    IExtendedResolver
{
    function setABI(
        bytes32 node,
        uint256 contentType,
        bytes calldata data
    ) external;

    function setAddr(bytes32 node, address addr) external;

    function setAddrWithCoinType(
        bytes32 node,
        uint256 coinType,
        bytes calldata a
    ) external;

    function setContenthash(bytes32 node, bytes calldata hash) external;

    function setName(bytes32 node, string calldata _name) external;

    function setPubkey(
        bytes32 node,
        bytes32 x,
        bytes32 y
    ) external;

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external;

    function setInterface(
        bytes32 node,
        bytes4 interfaceID,
        address implementer
    ) external;

    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results);
}