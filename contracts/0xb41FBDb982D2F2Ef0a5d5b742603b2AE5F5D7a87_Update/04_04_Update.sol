// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IBYTEGANS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Update is Ownable {
    IBYTEGANS constant TOKEN =
        IBYTEGANS(0x45C67B2b81067911dE611e11FC5c7a4605cA4162);

    struct TokenData {
        uint16 tokenId;
        string name;
        string file;
        string trait;
    }

    function updateTokens(TokenData[] memory data) external onlyOwner {
        for (uint i; i < data.length; i++) {
            TokenData memory current = data[i];

            TOKEN.setTokenInfo(
                current.tokenId,
                current.name,
                current.file,
                current.trait
            );
        }
    }

    function delegate(
        address at,
        bytes calldata data
    ) external onlyOwner returns (bool success, bytes memory ret) {
        (success, ret) = at.delegatecall(data);
    }
}