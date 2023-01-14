// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IEventListener {
    event AddedContract(address contractAddress);
    event PackTransfer(address contractAddress, address from, address to, uint256 tokenId);

    function addContract(address _contractAddress) external;

    function callEvent(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}