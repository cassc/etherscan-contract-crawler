// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

/*
    Expands swapping functionality over base strategy
    - ETH in and ETH out Variants
    - Sushiswap support in addition to Uniswap
*/
contract TokenSwapPathRegistry {
    struct SwapPathStruct {
        bytes pathData;
        address[] pathAddress;
        uint routerIndex;  // 0 == uniswapv2, 1 == sushiswap, 2 == uniswapv3
        bool isSwapV2; // true == v2 - false == v3
    }

    mapping(address => mapping(address => SwapPathStruct)) public swapPaths;
    event PathUpdated(address indexed tokenIn, address indexed tokenOut, bytes newPath);
    event TokenRevoked(address indexed tokenIn, address indexed tokenOut);

    /// @notice Adds a token to support with this contract
    /// @param _tokenIn Token in to add to this contract
    /// @param _tokenOut Token out to add to this contract
    /// @param _pathAddress Addresses used (in order) for the swap
    /// @param _pathFees Fees used (in order) to get the path for the pool to use for the swap

    /// @param _routerIndex indicate router when the swap will be executed - 0 == uniswapv2 / 1 == sushiswap / 2 == uniswapv3
    /// @param _isSwapV2 indicate type version of swap - true == v2 / false == v3
    /// @dev This function can be called to change the path for a token or to add a new supported
    /// token
    function _addToken(address _tokenIn, address _tokenOut, address[] memory _pathAddress, uint24[] memory _pathFees, uint _routerIndex, bool _isSwapV2) internal {
        require(_tokenIn != address(0) && _tokenOut != address(0), "token address cannot be address(0)");
        require(_pathAddress.length >= 2, "error address length");
        require((_pathAddress.length == _pathFees.length + 1) || _isSwapV2, "error path length");
        require(_pathAddress[0] == _tokenIn && _pathAddress[_pathAddress.length - 1] == _tokenOut, "error path address position");
        require(_routerIndex >= 0 && _routerIndex <= 2, "error router index");

        bytes memory path;
        if(!_isSwapV2) {
            for (uint256 i = 0; i < _pathFees.length; i++) {
                require(_pathAddress[i] != address(0) && _pathAddress[i + 1] != address(0), "error path address position with address(0)");
                path = abi.encodePacked(path, _pathAddress[i], _pathFees[i]);
            }
            path = abi.encodePacked(path, _pathAddress[_pathFees.length]);
        }

        SwapPathStruct memory swapPathStruct;
        swapPathStruct.pathData = path;
        swapPathStruct.pathAddress = _pathAddress;
        swapPathStruct.routerIndex = _routerIndex;
        swapPathStruct.isSwapV2 = _isSwapV2;

        swapPaths[_tokenIn][_tokenOut] = swapPathStruct;
        emit PathUpdated(_tokenIn, _tokenOut, swapPathStruct.pathData);
    }

    /// @notice Revokes a token supported by this contract
    /// @param _tokenIn Token in to add to this contract
    /// @param _tokenOut Token out to add to this contract
    function _revokeToken(address _tokenIn, address _tokenOut) internal {
        delete swapPaths[_tokenIn][_tokenOut];
        emit TokenRevoked(_tokenIn, _tokenOut);
    }
}