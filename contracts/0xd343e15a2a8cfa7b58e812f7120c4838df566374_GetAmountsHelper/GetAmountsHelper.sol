/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
}

interface V2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract GetAmountsHelper {
    struct outItem {
        address _routerAddress;
        uint256 amountIn;
        address[] path;
        uint256[] amounts;
        uint256 decimalsIn;
        uint256 decimalsOut;
    }

    struct InItem {
        address _routerAddress;
        uint256 amountOut;
        address[] path;
        uint256[] amounts;
        uint256 decimalsIn;
        uint256 decimalsOut;
    }

    function getMax(uint256[] memory numbers) public pure returns (uint256, uint256) {
        uint256 maxNumber = numbers[0];
        uint256 maxIndex = 0;
        for (uint256 i = 1; i < numbers.length; i++) {
            if (numbers[i] > maxNumber) {
                maxNumber = numbers[i];
                maxIndex = i;
            }
        }
        return (maxNumber, maxIndex);
    }

    function getMin(uint256[] memory numbers) public pure returns (uint256, uint256) {
        uint256 minNumber = numbers[0];
        uint256 minIndex = 0;
        for (uint256 i = 1; i < numbers.length; i++) {
            if (numbers[i] < minNumber) {
                minNumber = numbers[i];
                minIndex = i;
            }
        }
        return (minNumber, minIndex);
    }

    function getAmountsOut(
        address routerAddress,
        uint256 amountIn,
        address[] memory path
    ) private returns (uint256[] memory amounts) {
        (bool success,bytes memory returnData) = routerAddress.call(abi.encodeWithSelector(V2Router.getAmountsOut.selector, amountIn, path));
        if (success) {
            amounts = abi.decode(returnData, (uint256[]));
        } else {
            amounts = new uint256[](0);
        }
    }

    function massGetAmountsOut(
        address[] memory routerAddressList,
        uint256 amountIn,
        address[] memory path
    ) private returns (outItem memory _listItem) {
        uint256 _num = routerAddressList.length;
        outItem[] memory _list = new outItem[](_num);
        uint256[] memory _amountOutList = new uint256[](_num);
        for (uint256 i = 0; i < _num; i++) {
            address routerAddress = routerAddressList[i];
            uint256[] memory _amounts = getAmountsOut(routerAddress, amountIn, path);
            _list[i] = outItem({
                _routerAddress: routerAddress,
                amountIn: amountIn,
                path: path,
                amounts: _amounts,
                decimalsIn: IERC20(path[0]).decimals(),
                decimalsOut: IERC20(path[path.length - 1]).decimals()
            });
            _amountOutList[i] = _amounts.length > 0 ? _amounts[_amounts.length - 1] : 0;
        }
        (,uint256 _maxIndex) = getMax(_amountOutList);
        _listItem = _list[_maxIndex];
    }

    function multiGetAmountsOut(
        address[] memory routerAddressList,
        uint256 amountIn,
        address[][] memory pathList
    ) external returns (outItem[] memory _list) {
        uint256 _num = pathList.length;
        _list = new outItem[](_num);
        for (uint256 i = 0; i < _num; i++) {
            _list[i] = massGetAmountsOut(routerAddressList, amountIn, pathList[i]);
        }
    }

    function getAmountsIn(
        address routerAddress,
        uint256 amountOut,
        address[] memory path
    ) private returns (uint256[] memory amounts) {
        (bool success,bytes memory returnData) = routerAddress.call(abi.encodeWithSelector(V2Router.getAmountsIn.selector, amountOut, path));
        if (success) {
            amounts = abi.decode(returnData, (uint256[]));
        } else {
            amounts = new uint256[](0);
        }
    }

    function massGetAmountsIn(
        address[] memory routerAddressList,
        uint256 amountOut,
        address[] memory path
    ) private returns (InItem memory _listItem) {
        uint256 _num = routerAddressList.length;
        InItem[] memory _list = new InItem[](_num);
        uint256[] memory _amountInList = new uint256[](_num);
        for (uint256 i = 0; i < _num; i++) {
            uint256[] memory _amounts = getAmountsIn(routerAddressList[i], amountOut, path);
            _list[i] = InItem({
                _routerAddress: routerAddressList[i],
                amountOut: amountOut,
                path: path,
                amounts: _amounts,
                decimalsIn: IERC20(path[0]).decimals(),
                decimalsOut: IERC20(path[path.length - 1]).decimals()
            });
            _amountInList[i] = _amounts.length > 0 ? _amounts[0] : type(uint256).max;
        }
        (,uint256 minIndex) = getMin(_amountInList);
        _listItem = _list[minIndex];
    }

    function multiGetAmountsIn(
        address[] memory routerAddressList,
        uint256 amountOut,
        address[][] memory pathList
    ) external returns (InItem[] memory _list) {
        uint256 _num = pathList.length;
        _list = new InItem[](_num);
        for (uint256 i = 0; i < _num; i++) {
            _list[i] = massGetAmountsIn(routerAddressList, amountOut, pathList[i]);
        }
    }

}