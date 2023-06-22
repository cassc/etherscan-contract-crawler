// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./Parameters.sol";
import "../Kohi/Graphics2D.sol";

interface IUniverseMachineRenderer is IERC165 {
    function image(Parameters memory parameters)
        external
        view
        returns (string memory);

    function render(
        uint256 tokenId,
        int32 seed,
        address parameters
    ) external view returns (uint8[] memory);
}

contract UniverseMachineRendererStub is IUniverseMachineRenderer {
    function image(Parameters memory parameters)
        external
        pure
        override
        returns (string memory)
    {}

    function render(
        uint256 tokenId,
        int32 seed,
        address parameters
    ) external view override returns (uint8[] memory) {}

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IUniverseMachineRenderer).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}