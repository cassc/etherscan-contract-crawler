// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKurayamiMintPass {
    function redeem(
        address _account,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}