// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IPriceOracle.sol";

interface IRegistrarController {
    event NameRegistered(
        address indexed registrar,
        bytes32 indexed labelId,
        string name,
        address owner,
        uint256 tokenId,
        uint256 cost,
        uint256 expires
    );

    event NameRenewed(
        address indexed registrar,
        bytes32 indexed labelId,
        string name,
        uint256 tokenId,
        uint256 cost,
        uint256 expires
    );

    function rentPrice(
        address registrar,
        string memory name,
        uint256 duration
    ) external view returns (IPriceOracle.Price memory);

    function available(address registrar, string memory name)
        external
        view
        returns (bool);

    // Returns the expiration timestamp of the specified label.
    function nameExpires(address registrar, string memory name)
        external
        view
        returns (uint256);

    // extend name registration
    function renew(
        address registrar,
        string calldata name,
        uint256 duration
    ) external payable;
}