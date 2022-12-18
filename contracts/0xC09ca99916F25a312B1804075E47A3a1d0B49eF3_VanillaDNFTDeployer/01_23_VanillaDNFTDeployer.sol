// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/IVanillaDNFTDeployer.sol";

import "./VanillaDerivativeNFT.sol";

contract VanillaDNFTDeployer is IVanillaDNFTDeployer {
    struct Parameters {
        address factory;
        address originalNFT;
        uint256 tokenId;
    }

    Parameters public override parameters;

    address public vanillaFactory;

    constructor(address factory) {
        vanillaFactory = factory;
    }

    modifier onlyFactoryCall() {
        require(msg.sender == vanillaFactory, "The caller must be the factory");
        _;
    }

    function deploy(
        address factory,
        address originalNFT,
        uint256 tokenId,
        address spanningDelegate_
    ) external onlyFactoryCall returns (address licenseAddress) {
        require(
            factory == msg.sender,
            "The factory parameter is not same as the caller."
        );
        parameters = Parameters({
            factory: factory,
            originalNFT: originalNFT,
            tokenId: tokenId
        });
        licenseAddress = address(
            new VanillaDerivativeNFT{
                salt: keccak256(abi.encode(factory, originalNFT, tokenId))
            }(spanningDelegate_)
        );
        delete parameters;
    }
}