// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVeToken {
    function create_lock(uint256 _value, uint256 _lockDuration) external returns (uint256 _tokenId);
    function increase_amount(uint256 tokenId, uint256 value) external;
    function increase_unlock_time(uint256 tokenId, uint256 duration) external;
    function withdraw(uint256 tokenId) external;
    function balanceOfNFT(uint256 tokenId) external view returns (uint256 balance);
    function locked(uint256 tokenId) external view returns (uint256 amount, uint256 endTime);
    function token() external view returns (address);
    function merge(uint _from, uint _to) external;
    function transferFrom(address _from, address _to, uint _tokenId) external;
    function balanceOf(address _owner) external view returns (uint);
    function split(uint[] memory amounts, uint _tokenId) external;
    function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint);
    function approve(address _approved, uint _tokenId) external;
    function voted(uint _tokenId) external view returns (bool);
    function ownerOf(uint256 _tokenId) external view returns (address);
}