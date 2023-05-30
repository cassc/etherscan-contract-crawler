interface DoodleRooms {
    function ownerOf(uint256) external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address, uint256) external view returns (uint256);
}