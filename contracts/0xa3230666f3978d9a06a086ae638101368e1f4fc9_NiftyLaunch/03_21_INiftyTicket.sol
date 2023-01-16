// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface INiftyTicket {
    // =============================================================
    //                           CUSTOM
    // =============================================================

    function initialize(
        string memory name_,
        string memory symbol_,
        address sudoPool,
        uint256 qty,
        string memory _baseURI
    ) external;

    function transferOwnership(address newOwner) external;

    function finalize() external;

    function owner() external view returns (address);

    function launchToSudoPool(address launch) external view returns (address);

    function name() external view returns (string calldata _name);

    function symbol() external view returns (string calldata _symbol);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);
}