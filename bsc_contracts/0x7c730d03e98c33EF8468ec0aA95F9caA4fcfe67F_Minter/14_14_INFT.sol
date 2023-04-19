// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface INFT {
    function mint(address receiver) external;
    function mintWithURI(address receiver, string memory _tokenURI) external returns (uint256);
    function mintWithURIRoyalty(address _token, string memory _tokenURI, uint96 _royaltyValue) external returns (uint256);
}