// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IBalancer.sol";
import "../utils/TransferHelper.sol";
import "../interfaces/IRouter.sol";

contract BalancerV2 is IRouter, Ownable {
    using SafeMath for uint256;

    string public constant version = "BalancerV2 1";

    address public balancerVault;

    address public exchange;

    address public weth;

    // Struct Pool info for Balancer
    struct SingleSwapInfo {
        bytes32 poolId;
        address assetIn;
        address assetOut;
    }

    mapping(bytes32 => SingleSwapInfo) public singleSwapInfos;

    // Array for path indices
    bytes32[] public pathBytes;

    event AddBalancerSwap(bytes32 hash, SingleSwapInfo assets);

    event RemoveBalancerSwap(bytes32 hash, SingleSwapInfo assets);

    constructor(
        address _balancerVault,
        address _exchange,
        address _weth
    ) {
        balancerVault = _balancerVault;
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
        add balancer swaps and assets 
     */
    function addPath(SingleSwapInfo memory _swap) public onlyOwner returns (bytes32) {
        // Generate hash index for path
        bytes32 hash = keccak256(abi.encodePacked(_swap.poolId, _swap.assetIn, _swap.assetOut));

        // Duplication check
        require(
            singleSwapInfos[hash].assetIn == address(0) && singleSwapInfos[hash].assetOut == address(0),
            "ALREADY_EXIST_PATH"
        );

        singleSwapInfos[hash] = _swap;

        pathBytes.push(hash);

        emit AddBalancerSwap(hash, _swap);

        return hash;
    }

    function getPathIndex(SingleSwapInfo memory _swap) public view returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(_swap.poolId, _swap.assetIn, _swap.assetOut));

        if (singleSwapInfos[hash].assetIn == address(0) && singleSwapInfos[hash].assetOut == address(0)) return 0;
        else return hash;
    }

    /**
        Remove univ2 path from list
     */
    function removePath(bytes32 index) public onlyOwner {
        require(
            singleSwapInfos[index].assetIn != address(0) || singleSwapInfos[index].assetOut == address(0),
            "NON_EXIST_PATH"
        );

        // TempSave for assets info
        SingleSwapInfo memory _swap = singleSwapInfos[index];

        // Delete path record from mapping
        delete singleSwapInfos[index];

        // Remove index in the list
        for (uint256 i = 0; i < pathBytes.length; i++) {
            if (pathBytes[i] == index) {
                pathBytes[i] = pathBytes[pathBytes.length - 1];
                pathBytes.pop();
                break;
            }
        }

        emit RemoveBalancerSwap(index, _swap);
    }

    /**
        Get input token from path
     */
    function pathFrom(bytes32 index) public view override returns (address) {
        address from = address(singleSwapInfos[index].assetIn);
        return from == address(0) ? weth : from;
    }

    /**
        Get output token from path 
     */
    function pathTo(bytes32 index) public view override returns (address) {
        address to = address(singleSwapInfos[index].assetOut);
        return to == address(0) ? weth : to;
    }

    function swap(
        address _from,
        address _to,
        bytes32 _index,
        uint256 _amount
    ) external override onlyExchange {
        // Check Path from and to
        require(pathFrom(_index) == _from, "INVALID_FROM_ADDRESS");
        require(pathTo(_index) == _to, "INVALID_TO_ADDRESS");

        // Require token amount transfered
        require(getBalance(_from, address(this)) >= _amount, "INSUFFICIENT_TOKEN_TRANSFERED");

        // Get Swaps and assets info from registered
        SingleSwapInfo memory _swap = singleSwapInfos[_index];

        // Create SingleSwap structure
        SingleSwap memory singleSwap = SingleSwap({
            poolId: _swap.poolId,
            assetIn: IAsset(_swap.assetIn),
            assetOut: IAsset(_swap.assetOut),
            kind: SwapKind.GIVEN_IN,
            amount: _amount,
            userData: ""
        });

        // Create fund structure
        FundManagement memory funds = FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(exchange)),
            toInternalBalance: false
        });

        uint256 limit = 0;

        console.log("Asset: ", _swap.assetIn, _swap.assetOut);
        // Call batch swap in balancer
        if (_from == weth)
            IBalancer(balancerVault).swap{value: _amount}(singleSwap, funds, limit, block.timestamp + 3600);
        else {
            // Approve NoteToken to balancer Vault
            IERC20(_from).approve(balancerVault, 0);
            IERC20(_from).approve(balancerVault, _amount);
            IBalancer(balancerVault).swap(singleSwap, funds, limit, block.timestamp + 3600);
        }
    }

    function getBalance(address asset, address account) internal view returns (uint256) {
        if (address(asset) == address(weth) || address(asset) == address(0)) return address(account).balance;
        else return IERC20(asset).balanceOf(account);
    }
}