// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBaseV1Factory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function getInitializable() external view returns (address, address, bool);
    function setPause(bool _state) external;
    function acceptPauser() external;
    function setPauser(address _pauser) external;
    function isPaused() external view returns (bool);
    function getFee(bool _stable) external view returns(uint256);
}