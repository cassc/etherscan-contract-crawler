// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ICollectionNFTCloneableV1 {
    function mint(uint256 _hashesTokenId) external payable;

    function burn(uint256 _tokenId) external;

    function completeSignatureBlock() external;

    function setBaseTokenURI(string memory _baseTokenURI) external;

    function setRoyaltyBps(uint16 _royaltyBps) external;

    function transferCreator(address _creatorAddress) external;

    function setSignatureBlockAddress(address _signatureBlockAddress) external;

    function withdraw() external;
}