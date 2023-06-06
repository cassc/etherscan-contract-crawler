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
        uint swapType;  // 0 == uniswapv2, 1 == sushiswap, 2 == uniswapv3
    }

    mapping(address => mapping(address => SwapPathStruct)) public swapPaths;
    event PathUpdated(address indexed tokenIn, address indexed tokenOut, bytes newPath);
    event TokenRevoked(address indexed tokenIn, address indexed tokenOut);

    /// @notice Adds a token to support with this contract
    /// @param _tokenIn Token in to add to this contract
    /// @param _tokenOut Token out to add to this contract
    /// @param _pathAddress Addresses used (in order) for the swap
    /// @param _pathFees Fees used (in order) to get the path for the pool to use for the swap / only for uniswap v3
    /// @param _swapParams params type for swap curve router
    /// @param _poolAddress pool address for swap curve router
    /// @param _swapType indicate which type of swap will be executed - 0 == uniswapv2 / 1 == sushiswap / 2 == uniswapv3 / 3 == curve
    /// @dev This function can be called to change the path for a token or to add a new supported
    /// token
    function _addToken(
        address _tokenIn, address _tokenOut,
        address[] memory _pathAddress, // v2 + v3
        uint24[] memory _pathFees, // v3
        uint[][] memory _swapParams, address[] memory _poolAddress, // curve
        uint _swapType
    ) internal {
        require(_tokenIn != address(0) && _tokenOut != address(0), "token address cannot be address(0)");
        require(_pathAddress.length >= 2, "error address length");
        require((_pathAddress.length == _pathFees.length + 1) || _swapType != 2, "error path length");
        require((_pathAddress.length == 9 && _swapParams.length == 4 && _poolAddress.length == 4) || _swapType != 3, "error params swap curve");
        require(_swapType >= 0 && _swapType <= 3, "error router index");

        bytes memory path;
        if(_swapType == 0 || _swapType == 1) {
            for (uint i = 0; i < _pathAddress.length; i++) {
                path = abi.encodePacked(path, _pathAddress[i]);
            }
        } else if(_swapType == 2) {
            for (uint i = 0; i < _pathFees.length; i++) {
                require(_pathAddress[i] != address(0) && _pathAddress[i + 1] != address(0), "error path address position with address(0)");
                path = abi.encodePacked(path, _pathAddress[i], _pathFees[i]);
            }
            path = abi.encodePacked(path, _pathAddress[_pathFees.length]);
        } else if(_swapType == 3) {
            for (uint i = 0; i < _pathAddress.length; i++) {
                path = abi.encodePacked(path, _pathAddress[i]);
            }
            for (uint i = 0; i < _swapParams.length; i++) {
                require(_swapParams[i].length == 3, "error params swap curve");
                for(uint j = 0; j < _swapParams[i].length; j++) {
                    path = abi.encodePacked(path, uint8(_swapParams[i][j]));
                }
            }
            for (uint i = 0; i < _poolAddress.length; i++) {
                path = abi.encodePacked(path, _poolAddress[i]);
            }
            _pathAddress = _formatPathAddressCurve(_pathAddress);
        }

        SwapPathStruct memory swapPathStruct;
        swapPathStruct.pathData = path;
        swapPathStruct.pathAddress = _pathAddress;
        swapPathStruct.swapType = _swapType;

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

    function _formatPathAddressCurve(address[] memory _pathAddress) internal pure returns(address[] memory){
        uint newLength = (_pathAddress.length/2) + 1;
        address[] memory newPathAddress = new address[](newLength);
        for(uint i = 0; i < _pathAddress.length; i++) {
            if(i%2 == 0) {
                newPathAddress[i/2] = _pathAddress[i];
            }
        }
        return newPathAddress;
    }
}