// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IStrange {
    // Public
    function purchase(uint256 _quantity) external payable;

    function presalePurchase(
        uint256 _quantity,
        bytes32 _hash,
        bytes memory _signature
    ) external payable;

    // only owner

    function gift(address[] calldata _recipients) external;

    function setSigner(address _address) external;

    function setPaused(bool _state) external;

    function setPresale(bool _state) external;

    function setWalletLimit(bool _state) external;

    function setTokenOffset() external;

    function setProvenance(string memory _provenance) external;

    function setReveal(bool _state) external;

    function setBaseURI(string memory _URI) external;

    function withdrawAll() external;
}