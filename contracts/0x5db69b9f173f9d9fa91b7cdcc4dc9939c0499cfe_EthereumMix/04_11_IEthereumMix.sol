// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IFungibleToken.sol";

interface IEthereumMix is IFungibleToken {

    event SetSigner(address indexed signer);
    event SendOverHorizon(address indexed sender, uint256 indexed toChain, address indexed receiver, uint256 sendId, uint256 amount);
    event ReceiveOverHorizon(address indexed receiver, uint256 indexed fromChain, address indexed sender, uint256 sendId, uint256 amount);

    function signer() external view returns (address);
    function sendOverHorizon(uint256 toChain, address receiver, uint256 amount) external returns (uint256 sendId);
    function sended(address sender, uint256 toChain, address receiver, uint256 sendId) external view returns (uint256 amount);
    function sendCount(address sender, uint256 toChain, address receiver) external view returns (uint256);
    function receiveOverHorizon(uint256 fromChain, uint256 toChain, address sender, uint256 sendId, uint256 amount, bytes calldata signature) external;
    function received(address receiver, uint256 fromChain, address sender, uint256 sendId) external view returns (bool);
}