pragma solidity 0.8.12;

interface IANS {
    function isAuthEnabled(address account) external view returns (bool);
    function isProofValid(address account) external view returns (bool);

    function isTokenTransferRequestApproved(
        address account,
        address token,
        uint256 tokenId
    ) external view returns (bool, uint256);

    function clearRequest(address account, uint256 index)
        external
        returns (bool);
}