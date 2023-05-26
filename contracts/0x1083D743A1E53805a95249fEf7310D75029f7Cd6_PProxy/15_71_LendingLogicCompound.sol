// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ILendingLogic.sol";
import "./LendingRegistry.sol";
import "../../interfaces/ICToken.sol";

contract LendingLogicCompound is Ownable, ILendingLogic {
    using SafeMath for uint256;

    LendingRegistry public lendingRegistry;
    bytes32 public immutable protocolKey;
    uint256 public blocksPerYear;

    constructor(address _lendingRegistry, bytes32 _protocolKey) {
        require(_lendingRegistry != address(0), "INVALID_LENDING_REGISTRY");
        lendingRegistry = LendingRegistry(_lendingRegistry);
        protocolKey = _protocolKey;
    }

    function setBlocksPerYear(uint256 _blocks) external onlyOwner {
        // calculated by taking APY onn compound.finance  / dividing by supplyrate per block
        // this is apparently the amount of blocks compound expects to be minted this year
        // 2145683;
        blocksPerYear = _blocks;
    }

    function getAPRFromWrapped(address _token) public view override returns(uint256) {
        return ICToken(_token).supplyRatePerBlock().mul(blocksPerYear);
    }

    function getAPRFromUnderlying(address _token) external view override returns(uint256) {
        address cToken = lendingRegistry.underlyingToProtocolWrapped(_token, protocolKey);
        return getAPRFromWrapped(cToken);
    }

    function lend(address _underlying, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        IERC20 underlying = IERC20(_underlying);

        targets = new address[](3);
        data = new bytes[](3);


        address cToken = lendingRegistry.underlyingToProtocolWrapped(_underlying, protocolKey);

        // zero out approval to be sure
        targets[0] = _underlying;
        data[0] = abi.encodeWithSelector(underlying.approve.selector, cToken, 0);

        // Set approval
        targets[1] = _underlying;
        data[1] = abi.encodeWithSelector(underlying.approve.selector, cToken, _amount);

        // Deposit into Compound
        targets[2] = cToken;

        data[2] =  abi.encodeWithSelector(ICToken.mint.selector, _amount);

        return(targets, data);
    }

    function unlend(address _wrapped, uint256 _amount) external view override returns(address[] memory targets, bytes[] memory data) {
        targets = new address[](1);
        data = new bytes[](1);

        targets[0] = _wrapped;
        data[0] = abi.encodeWithSelector(ICToken.redeem.selector, _amount);

        return(targets, data);
    }

    function exchangeRate(address _wrapped) external override returns(uint256) {
        return ICToken(_wrapped).exchangeRateCurrent();
    }

    function exchangeRateView(address _wrapped) external view override returns(uint256) {
        return ICToken(_wrapped).exchangeRateStored();
    }

}