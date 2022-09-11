// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IOpenseaFactory {
    
    function initialize(
        address _owner,
        address _splitter,
        uint256 royaltyInBasisPoints, 
        address _underlyingNFT, 
        uint256 premintStart,
        uint256 premintEnd,
        string calldata contractURI
    ) external;

    function emitEvents(uint256 start, uint256 end) external;
}