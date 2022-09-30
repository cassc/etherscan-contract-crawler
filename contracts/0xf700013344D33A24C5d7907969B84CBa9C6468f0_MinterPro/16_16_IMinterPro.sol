// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IMinterPro {
    function mintPro(
        address to,
        bytes calldata signature,
        bytes32 hashId,
        uint256 expiry
    ) external payable;

    function setMintingEthCost(uint256 cost) external;

    function withdrawEth(uint256 amount, address payable to) external;

    function upgradeBagContract(address) external;

    function upgradeCharacterContract(address) external;

    function setManager(address) external;

    function setMultisig(address) external;

    function setSigner(address) external;

    function supportsInterface(bytes4 interfaceId) external returns (bool);
}