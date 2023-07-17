// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ISwaprWallet {
    function isNFTLocked(address lock, uint nftId) external view returns (bool);

    function getNFT(address lock, uint nftId) external view returns (bytes memory sig);

    function lockNFT(bytes calldata sig, address lock, uint nftId, address owner) external;

    function updateLockedNFT(bytes calldata sig, address lock, uint nftId) external;

    function depositNativeSwapr(address depositor) external payable;

    function swapNative(address from, address to, uint amount) external;

    function releaseNative(address receiver, address owner, uint amount) external;

    function depositERC(address token) external;

    function depositERCSwapr(address token, address depositor, uint amount) external;

    function swapERC(address token, address from, address to, uint amount) external;

    function disposeNFT(address lock, uint nftId) external;

    function releaseNFT(address lock, uint nftId, address receiver) external;

    function splitReleaseNFT(
        address lock,
        uint nftId,
        uint[] calldata splitParts,
        address[] calldata addresses
    ) external returns (uint256[] memory newIDs);

    function releaseERC(address token, address receiver, address owner, uint amount) external;

    function getBalance(address owner, address token) external view returns (uint balance);
}