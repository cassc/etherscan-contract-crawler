// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetLiquidityEvents.sol";
import "../../interfaces/multivault/IMultiVaultFacetLiquidity.sol";
import "../../interfaces/IMultiVaultToken.sol";
import "../storage/MultiVaultStorage.sol";

import "../../MultiVaultToken.sol";


abstract contract MultiVaultHelperLiquidity is IMultiVaultFacetLiquidityEvents {
    modifier onlyActivatedLP(address token) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(s.liquidity[token].activation != 0);

        _;
    }

    function _getLPToken(
        address token
    ) internal view returns (address lp) {
        lp = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            address(this),
            keccak256(abi.encodePacked('LP', token)),
            hex'192c19818bebb5c6c95f5dcb3c3257379fc46fb654780cb06f3211ee77e1a360' // MultiVaultToken init code hash
        )))));
    }

    function _exchangeRateCurrent(
        address token
    ) internal view returns(uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IMultiVaultFacetLiquidity.Liquidity memory liquidity = s.liquidity[token];

        if (liquidity.supply == 0 || liquidity.activation == 0) return MultiVaultStorage.LP_EXCHANGE_RATE_BPS;

        return MultiVaultStorage.LP_EXCHANGE_RATE_BPS * liquidity.cash / liquidity.supply;
    }

    function _getCash(
        address token
    ) internal view returns(uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IMultiVaultFacetLiquidity.Liquidity memory liquidity = s.liquidity[token];

        return liquidity.cash;
    }

    function _getSupply(
        address token
    ) internal view returns(uint) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        IMultiVaultFacetLiquidity.Liquidity memory liquidity = s.liquidity[token];

        return liquidity.supply;
    }

    function _convertLPToUnderlying(
        address token,
        uint amount
    ) internal view returns (uint) {
        return _exchangeRateCurrent(token) * amount / MultiVaultStorage.LP_EXCHANGE_RATE_BPS;
    }

    function _convertUnderlyingToLP(
        address token,
        uint amount
    ) internal view returns (uint) {
        return MultiVaultStorage.LP_EXCHANGE_RATE_BPS * amount / _exchangeRateCurrent(token);
    }

    function _deployLPToken(
        address token
    ) internal returns (address lp) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(s.liquidity[token].activation == 0);

        s.liquidity[token].activation = block.number;
        s.liquidity[token].interest = s.defaultInterest;

        bytes memory bytecode = type(MultiVaultToken).creationCode;

        bytes32 salt = keccak256(abi.encodePacked('LP', token));

        assembly {
            lp := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        string memory name = IERC20Metadata(token).name();
        string memory symbol = IERC20Metadata(token).symbol();
        uint8 decimals = IERC20Metadata(token).decimals();

        IMultiVaultToken(lp).initialize(
            string(abi.encodePacked(MultiVaultStorage.DEFAULT_NAME_LP_PREFIX, name)),
            string(abi.encodePacked(MultiVaultStorage.DEFAULT_SYMBOL_LP_PREFIX, symbol)),
            decimals
        );
    }

    function _increaseTokenCash(
        address token,
        uint amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        if (amount == 0) return;

        s.liquidity[token].cash += amount;

        emit EarnTokenCash(token, amount);
    }
}