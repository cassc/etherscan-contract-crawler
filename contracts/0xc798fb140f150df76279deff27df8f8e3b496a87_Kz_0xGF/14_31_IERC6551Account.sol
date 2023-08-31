interface IERC6551Account {
    function token()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId);

    function owner() external view returns (address);

    function nonce() external view returns (uint256);
}