// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./vault_v2.sol";

contract VaultFactoryV2 is Ownable {
    address public immutable aggregatorAddr;
    address public immutable ubxnToken;
    address public immutable ubxnPairToken;
    address public immutable uniswapRouter;

    event VaultGenerated(address);

    constructor(
        address _aggregatorAddr,
        address _ubxnToken,
        address _ubxnPairToken,
        address _uniswapRouter
    ) {
        require(_aggregatorAddr != address(0));
        require(_ubxnToken != address(0));
        require(_ubxnPairToken != address(0));
        require(_uniswapRouter != address(0));
        aggregatorAddr = _aggregatorAddr;
        ubxnToken = _ubxnToken;
        ubxnPairToken = _ubxnPairToken;
        uniswapRouter = _uniswapRouter;
    }

    function generateVault(
        string memory _name,
        address _quoteToken,
        address _baseToken,
        address _quotePriceFeed,
        address _basePriceFeed,
        address _strategist,
        uint256 _maxCap,
        address[] calldata _uniswapPath,
        FeeParams calldata _feeParams
    ) external onlyOwner returns (address) {
        // deploy a new vault
        VaultV2 newVault = new VaultV2(_name, address(this));
        newVault.initialize(
            VaultParams(
                _quoteToken,
                _baseToken,
                aggregatorAddr,
                uniswapRouter,
                _uniswapPath,
                ubxnToken,
                ubxnPairToken,
                _quotePriceFeed,
                _basePriceFeed,
                _maxCap
            ),
            _feeParams
        );
        newVault.setStrategist(_strategist);

        // emit event
        emit VaultGenerated(address(newVault));
        return address(newVault);
    }
}