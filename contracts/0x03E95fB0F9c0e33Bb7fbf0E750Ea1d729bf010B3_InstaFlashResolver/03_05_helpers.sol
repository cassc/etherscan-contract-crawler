//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Variables} from "./variables.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Helper is Variables {
    function getAaveAvailability(
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _route
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            (, , , , , , bool isBorrowingEnabled, , bool isActive, ) = aaveProtocolDataProvider
                .getReserveConfigurationData(_tokens[i]);
            (address aTokenAddr, , ) = aaveProtocolDataProvider
                .getReserveTokensAddresses(_tokens[i]);
            if (isActive == false) return false;
            if (token_.balanceOf(aTokenAddr) < _amounts[i]) return false;
            if ((_route == 4 || _route == 7) && !isBorrowingEnabled) return false;
        }
        return true;
    }

    function getMakerAvailability(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal pure returns (bool) {
        if (
            _tokens.length == 1 &&
            _tokens[0] == daiToken &&
            _amounts[0] <= daiBorrowAmount
        ) {
            return true;
        }
        return false;
    }

    function getCompoundAvailability(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == chainToken) {
                if (cEthToken.balance < _amounts[i]) return false;
            } else {
                address cTokenAddr_ = flashloanAggregator.tokenToCToken(
                    _tokens[i]
                );
                IERC20 token_ = IERC20(_tokens[i]);
                if (cTokenAddr_ == address(0)) return false;
                if (token_.balanceOf(cTokenAddr_) < _amounts[i]) return false;
            }
        }
        return true;
    }

    function getBalancerAvailability(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            if (token_.balanceOf(balancerLendingAddr) < _amounts[i]) {
                return false;
            }
            // console.log("hello");
            // if ((balancerWeightedPoolFactory.isPoolFromFactory(_tokens[i]) ||
            //     balancerWeightedPool2TokensFactory.isPoolFromFactory(_tokens[i]) ||
            //     balancerStablePoolFactory.isPoolFromFactory(_tokens[i]) ||
            //     balancerLiquidityBootstrappingPoolFactory.isPoolFromFactory(_tokens[i]) ||
            //     balancerMetaStablePoolFactory.isPoolFromFactory(_tokens[i]) ||
            //     balancerInvestmentPoolFactory.isPoolFromFactory(_tokens[i])
            //     ) == false) {
            //     return false;
            // }
        }
        return true;
    }

    function getRoutesWithAvailability(
        uint16[] memory _routes,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (uint16[] memory) {
        uint16[] memory routesWithAvailability_ = new uint16[](7);
        uint256 j = 0;
        for (uint256 i = 0; i < _routes.length; i++) {
            if (_routes[i] == 1 || _routes[i] == 4 || _routes[i] == 7) {
                if (getAaveAvailability(_tokens, _amounts, _routes[i])) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 2) {
                if (getMakerAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 3 || _routes[i] == 6) {
                if (getCompoundAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 5) {
                if (getBalancerAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else {
                require(false, "invalid-route");
            }
        }
        return routesWithAvailability_;
    }

    function bubbleSort(address[] memory _tokens, uint256[] memory _amounts)
        internal
        pure
        returns (address[] memory, uint256[] memory)
    {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            for (uint256 j = 0; j < _tokens.length - i - 1; j++) {
                if (_tokens[j] > _tokens[j + 1]) {
                    (
                        _tokens[j],
                        _tokens[j + 1],
                        _amounts[j],
                        _amounts[j + 1]
                    ) = (
                        _tokens[j + 1],
                        _tokens[j],
                        _amounts[j + 1],
                        _amounts[j]
                    );
                }
            }
        }
        return (_tokens, _amounts);
    }

    function validateTokens(address[] memory _tokens) internal pure {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            require(_tokens[i] != _tokens[i + 1], "non-unique-tokens");
        }
    }
}