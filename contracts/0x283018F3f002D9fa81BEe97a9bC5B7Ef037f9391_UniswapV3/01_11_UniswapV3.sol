// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IUniswapV3Router.sol";
import "./interfaces/IWeth.sol";
import "../utils/TransferHelper.sol";
import "../interfaces/IRouter.sol";

contract UniswapV3 is IRouter, Ownable {
    using SafeMath for uint256;

    string public constant version = "UniswapV3 1";

    address public weth;

    address private zeroAddress = 0x0000000000000000000000000000000000000002;

    address public exchange;

    address public router;

    // Array for path indices
    bytes32[] public pathBytes;

    struct PathInfo {
        address tokenIn;
        address tokenOut;
        uint24 fee;
    }

    // Path to index mapping
    mapping(bytes32 => PathInfo) public paths;

    event AddUniV3Path(bytes32 hash, PathInfo path);

    event RemoveUniV3Path(bytes32 hash, PathInfo path);

    constructor(
        address _router,
        address _exchange,
        address _weth
    ) {
        router = _router;
        exchange = _exchange;
        weth = _weth;
    }

    receive() external payable {}

    /**
        Only exchange can call
     */
    modifier onlyExchange() {
        require(exchange == _msgSender(), "ONLY_EXCHANGE");
        _;
    }

    function setExchange(address _exchange) public onlyOwner {
        require(exchange != address(0), "ZERO_ADDRESS");
        exchange = _exchange;
    }

    /**
        Add univ3 path to list
     */
    function addPath(PathInfo memory _path) public onlyOwner returns (bytes32) {
        // Generate hash index for path
        bytes32 hash = keccak256(abi.encodePacked(_path.tokenIn, _path.tokenOut, _path.fee));

        // Duplication check
        require(paths[hash].tokenIn == address(0) && paths[hash].tokenOut == address(0), "ALREADY_EXIST_PATH");

        // Register path
        pathBytes.push(hash);
        paths[hash] = _path;

        emit AddUniV3Path(hash, _path);

        return hash;
    }

    function getPathIndex(PathInfo memory _path) public view returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(_path.tokenIn, _path.tokenOut, _path.fee));

        if (paths[hash].tokenIn == address(0) && paths[hash].tokenOut == address(0)) return 0;
        else return hash;
    }

    /**
        Remove univ2 path from list
     */
    function removePath(bytes32 index) public onlyOwner {
        require(paths[index].tokenIn != address(0) && paths[index].tokenOut != address(0), "NON_EXIST_PATH");

        PathInfo memory path = paths[index];
        // Delete path record from mapping
        delete paths[index];

        // Remove index in the list
        for (uint256 i = 0; i < pathBytes.length; i++) {
            if (pathBytes[i] == index) {
                pathBytes[i] = pathBytes[pathBytes.length - 1];
                pathBytes.pop();
                break;
            }
        }

        emit RemoveUniV3Path(index, path);
    }

    /**
        Get input token from path
     */
    function pathFrom(bytes32 index) public view override returns (address) {
        return paths[index].tokenIn;
    }

    /**
        Get output token from path
     */
    function pathTo(bytes32 index) public view override returns (address) {
        return paths[index].tokenOut;
    }

    /**
        Uniswap V3 Swap 
     */
    function swap(
        address _from,
        address _to,
        bytes32 _index,
        uint256 _amount
    ) external override onlyExchange{
        PathInfo storage _path = paths[_index];

        // Check Path from and to
        require(pathFrom(_index) == _from, "INVALID_FROM_ADDRESS");
        require(pathTo(_index) == _to, "INVALID_TO_ADDRESS");

        uint256 balance = getBalance(_from, address(this));

        require(balance >= _amount, "INSUFFICIENT_TOKEN_TRANSFERED");

        IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router.ExactInputSingleParams({
            tokenIn: _from,
            tokenOut: _to,
            fee: _path.fee,
            recipient: address(this),
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        uint256 output;

        // If fromToken is weth, no need to approve
        if (_from != weth) {
            // Approve token
            IERC20(_from).approve(router, 0);
            IERC20(_from).approve(router, _amount);

            output = IUniswapV3Router(router).exactInputSingle(params);
        } else {
            output = IUniswapV3Router(router).exactInputSingle{value: _amount}(params);
        }

        // If toTOken is weth, withdraw ETH from it
        if (_to == weth) {
            IWeth(weth).withdraw(output);
            TransferHelper.safeTransferETH(exchange, output);
        } else {
            // Transfer output token to exchnage
            TransferHelper.safeTransfer(_to, exchange, output);
        }
    }

    function getBalance(address asset, address account) internal view returns (uint256) {
        if (address(asset) == address(weth)) return address(account).balance;
        else return IERC20(asset).balanceOf(account);
    }
}