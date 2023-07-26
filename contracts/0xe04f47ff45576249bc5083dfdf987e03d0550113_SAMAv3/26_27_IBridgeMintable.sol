//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IBridgeMintable {
    function proxyMintBatch(
        address _minter,
        address _account,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes memory _data
    ) external;
}