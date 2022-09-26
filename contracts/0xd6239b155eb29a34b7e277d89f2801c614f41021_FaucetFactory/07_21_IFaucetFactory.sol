// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IFaucetFactory {
    function faucetForTokenView(address _tokenAddress) external view returns (address _faucetAddress);

    function faucetForToken(address _tokenAddress) external returns (address _faucetAddress, bool deployed);
}