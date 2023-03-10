// c077ffa5099a4bfaa04669bbc798b1408ec6fa3e
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "DEXBase.sol";

contract CurveAcl is DEXBase {

    string public constant override NAME = "CurveAcl";
    uint256 public constant override VERSION = 2;

    address public constant ZERO_ADDRESS = address(0);

    function _commonCheck(address[9] memory _route) internal view {
        (address _inToken, address _outToken, address[4] memory _routePools) = getRoutePools(_route);
        swapInOutTokenCheck(_inToken, _outToken);
    }

    function getRoutePools(address[9] memory _route) internal pure returns (address,address,address[4] memory) {
        address _inToken = address(_route[0]);
        address[4] memory _routePools;
        address _outToken;
        uint j = 0;
        for (uint i=0; i < _route.length - 1;) {
            if (_route[i] != ZERO_ADDRESS) {
                if (_route[i + 1] != ZERO_ADDRESS) {
                    _routePools[j] = address(_route[i + 1]);
                    j++;
                } else {
                    _outToken = address(_route[i]);
                }
            }
            i = i + 2;
        }
        return (_inToken, _outToken, _routePools);
    }

    function exchange_multiple(address[9] memory _route, uint256[3][4] memory _swap_params, uint256 _amount, uint256 _expected)
        external
        payable
        onlySelf {
        _commonCheck(_route);
    }

    function exchange_multiple(address[9] memory _route, uint256[3][4] memory _swap_params, uint256 _amount, uint256 _expected, address[4] memory _pools)    //default
        external
        payable
        onlySelf {
        _commonCheck(_route);
    }

    function exchange_multiple(address[9] memory _route, uint256[3][4] memory _swap_params, uint256 _amount, uint256 _expected, address[4] memory _pools, address _receiver)
        external
        payable
        onlySelf {
        checkRecipient(_receiver);
        _commonCheck(_route);
    }

}