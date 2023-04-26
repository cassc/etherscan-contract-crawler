//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGorjsArtistCollection {
    function tokenURI(uint256 tokenId) external view;

    function setBaseURI(string calldata baseURIString_) external;

    function setDaoToken(address daoToken_) external;

    function setControllerContract(address _controllerContract) external;

    function mint(address to, uint256 id) external;

    function claimRewards() external;

    function lock(uint256[] memory _ids) external;

    function unlock(uint256[] memory _ids) external;

    function stakeBalanceOf(address _owner) external view returns (uint256);

    function stakedTokens(address _owner) external;

    function setApprovalForAll(address operator, bool approved) external;

    function approve(address operator, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;
}