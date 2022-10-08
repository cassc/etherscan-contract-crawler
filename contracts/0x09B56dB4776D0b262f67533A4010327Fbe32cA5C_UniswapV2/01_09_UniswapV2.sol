// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IUniswapV2Router.sol";
import "../utils/TransferHelper.sol";
import "../interfaces/IRouter.sol";

contract UniswapV2 is IRouter, Ownable {
    using SafeMath for uint256;

    string public constant version = "UniswapV2 1";

    address public weth;

    address public exchange;

    // Array for path indices
    bytes32[] public pathBytes;

    struct RouterInfo {
        address router;
        address[] path;
    }

    // Paths mapping for uni/sushi swap
    mapping(bytes32 => RouterInfo) public paths;

    event AddUniV2Path(bytes32 hash, address router, address[] path);

    event RemoveUniV2Path(bytes32 hash, address router, address[] path);

    constructor(address _weth, address _exchange) {
        weth = _weth;
        exchange = _exchange;
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
        Add univ2 path to list
     */
    function addPath(address _router, address[] memory _path) public onlyOwner returns (bytes32) {
        // Generate hash index for path
        bytes32 hash = keccak256(abi.encodePacked(_router, _path));

        // Duplication check
        require(paths[hash].path.length == 0, "ALREADY_EXIST_PATH");

        pathBytes.push(hash);

        // Register path
        pathBytes.push(hash);
        paths[hash].path = _path;
        paths[hash].router = _router;

        emit AddUniV2Path(hash, _router, _path);

        return hash;
    }

    function getPathIndex(address _router, address[] memory _path) public view returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(_router, _path));

        if (paths[hash].path.length == 0) return 0;
        else return hash;
    }

    /**
        Remove univ2 path from list
     */
    function removePath(bytes32 index) public onlyOwner {
        require(paths[index].path.length != 0, "NON_EXIST_PATH");

        address[] memory path = paths[index].path;

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

        emit RemoveUniV2Path(index, paths[index].router, path);
    }

    /**
        Get input token from path
     */
    function pathFrom(bytes32 index) public view override returns (address) {
        return paths[index].path[0];
    }

    /**
        Get output token from path
     */
    function pathTo(bytes32 index) public view override returns (address) {
        return paths[index].path[paths[index].path.length - 1];
    }

    function swap(
        address _from,
        address _to,
        bytes32 _index,
        uint256 _amount
    ) external override onlyExchange {
        // Get Router Address
        address router = paths[_index].router;

        // Check Path from and to
        require(pathFrom(_index) == _from, "INVALID_FROM_ADDRESS");
        require(pathTo(_index) == _to, "INVALID_TO_ADDRESS");

        uint256 balance = getBalance(_from, address(this));

        console.log("From token: ", _from, paths[_index].path[0], paths[_index].path[1]);
        console.log("balance: ", getBalance(_from, address(this)), _amount);
        require(balance >= _amount, "INSUFFICIENT_TOKEN_TRANSFERED");

        // If fromToken is weth, no need to approve
        if (_from != weth) {
            // Approve token
            IERC20(_from).approve(router, 0);
            IERC20(_from).approve(router, _amount);
        }

        // Ignore front-running
        if (_to == weth) {
            // If target token is Weth
            IUniswapV2Router(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                _amount,
                0,
                paths[_index].path,
                address(exchange),
                block.timestamp + 3600
            );
        } else if (_from == weth) {
            IUniswapV2Router(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
                0,
                paths[_index].path,
                address(exchange),
                block.timestamp + 3600
            );
        } else {
            IUniswapV2Router(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                paths[_index].path,
                address(exchange),
                block.timestamp + 3600
            );
        }
    }

    function getBalance(address asset, address account) internal view returns (uint256) {
        if (address(asset) == address(weth)) return address(account).balance;
        else return IERC20(asset).balanceOf(account);
    }
}