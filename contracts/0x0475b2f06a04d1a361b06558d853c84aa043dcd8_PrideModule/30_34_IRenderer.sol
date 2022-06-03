pragma solidity ^0.8.0;

interface IRenderer {
    function description() external view returns (string memory);

    function render(bytes32 seed)
        external
        view
        returns (string memory, string memory);
}