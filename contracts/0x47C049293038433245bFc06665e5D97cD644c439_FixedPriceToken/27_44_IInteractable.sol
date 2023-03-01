// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IInteractable {
    function getInteractor() external view returns (address);

    function setInteractor(address _interactor) external;

    function interact(
        uint256 tokenId,
        bytes calldata interactionData,
        bytes calldata validationData
    ) external;
}