// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico
pragma solidity ^0.8.0;

import "tinlake-auth/auth.sol";

interface IAssetNFT {
    function mintTo(address usr) external returns (uint256);
}

contract AssetMinter is Auth {
    IAssetNFT assets;

    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function depend(bytes32 contractName, address addr) external auth {
        if (contractName == "assetNFT") assets = IAssetNFT(addr);
        else revert();
    }

    function mintTo(address _to) public auth returns (uint256) {
        require(address(assets) != address(0), "asset-nft-not-set");
        return assets.mintTo(_to);
    }
}