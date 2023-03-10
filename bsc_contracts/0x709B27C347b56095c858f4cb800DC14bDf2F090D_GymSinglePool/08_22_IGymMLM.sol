// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGymMLM {
    function addGymMLM(address, uint256) external;

    function addGymMLMNFT(address, uint256) external;

    function distributeRewards(
        uint256,
        address,
        address,
        uint32
    ) external;

    function distributeCommissions(
        uint256,
        uint256,
        uint256,
        bool,
        address
    ) external;

    function updateInvestment(address _user, bool _isInvesting) external;

    function getPendingRewards(address, uint32) external view returns (uint256);

    function hasInvestment(address) external view returns (bool);

    function addressToId(address) external view returns (uint256);

    function setUpdateSig(address _newAddr,address _oldAddr,address[] memory _partners) external;
}