// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IFaucet} from "../IFaucet.sol";

interface IFaucetMetadataRenderer {
    function getTokenURIForFaucet(
        address _faucetAddress,
        uint256 _tokenId,
        IFaucet.FaucetDetails memory _fd
    ) external view returns (string memory);
}