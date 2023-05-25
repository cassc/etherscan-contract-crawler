pragma solidity ^0.7.0;

// SPDX-License-Identifier: GPL-3.0



interface IZkSync {
    event WithdrawalPending(uint16 indexed tokenId, address indexed recepient, uint128 amount);
    event WithdrawalNFTPending(uint32 indexed tokenId);

    function withdrawPendingBalance(
        address payable _owner,
        address _token,
        uint128 _amount
    ) external;

    function withdrawPendingNFTBalance(uint32 _tokenId) external;

    function getPendingBalance(address _address, address _token)
        external
        view
        returns (uint128);
}