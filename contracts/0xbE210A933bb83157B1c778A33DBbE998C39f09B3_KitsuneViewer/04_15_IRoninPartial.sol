// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IRoninPartial{
    function tokenCount() external view returns(uint16);
    function balanceOf(address _owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);

    function reservation(address _reservist) external view returns(uint24 blockNumber, uint16[] memory tokens);

    function mint(uint _count) external payable;

    function transferFrom(address _from, address _to, uint _tokenId) external;
}