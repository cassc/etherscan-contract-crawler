// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IBalancer.sol";
import "../utils/TransferHelper.sol";
import "../interfaces/IRouter.sol";

contract BalancerBatchV2 is IRouter, Ownable {
    using SafeMath for uint256;

    string public constant version = "BalancerBatchV2 1";

    address public balancerVault;

    address public exchange;

    address public weth;

    // Struct Pool info for Balancer
    mapping(bytes32 => bytes32[]) public poolBatchIds;

    mapping(bytes32 => IAsset[]) public balancerBatchAssets;

    // Array for path indices
    bytes32[] public pathBytes;

    event AddBalancerBatchSwap(bytes32 hash, IAsset[] assets);

    event RemoveBalancerBatchSwap(bytes32 hash, IAsset[] assets);

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
    function addPath(bytes32[] memory _pools, IAsset[] memory _assets) public onlyOwner returns (bytes32) {
        // Generate hash index for path
        bytes32 hash = keccak256(abi.encodePacked(_assets));

        // Duplication check
        require(poolBatchIds[hash].length == 0 && balancerBatchAssets[hash].length == 0, "ALREADY_EXIST_PATH");

        // for (uint8 i = 0; i < _pools.length; i++) {
        //     poolBatchIds[hash].push(_pools[i]);
        // }
        poolBatchIds[hash] = _pools;
        balancerBatchAssets[hash] = _assets;

        pathBytes.push(hash);

        emit AddBalancerBatchSwap(hash, _assets);

        return hash;
    }

    function getPathIndex(IAsset[] memory _assets) public view returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(_assets));

        if (balancerBatchAssets[hash].length == 0) return 0;
        else return hash;
    }

    /**
        Remove univ2 path from list
     */
    function removePath(bytes32 index) public onlyOwner {
        require(balancerBatchAssets[index].length != 0, "NON_EXIST_PATH");

        // TempSave for assets info
        IAsset[] memory assets = balancerBatchAssets[index];

        // Delete path record from mapping
        delete balancerBatchAssets[index];
        delete poolBatchIds[index];

        // Remove index in the list
        for (uint256 i = 0; i < pathBytes.length; i++) {
            if (pathBytes[i] == index) {
                pathBytes[i] = pathBytes[pathBytes.length - 1];
                pathBytes.pop();
                break;
            }
        }

        emit RemoveBalancerBatchSwap(index, assets);
    }

    /**
        Get input token from path
     */
    function pathFrom(bytes32 index) public view override returns (address) {
        return address(balancerBatchAssets[index][0]);
    }

    /**
        Get output token from path 
     */
    function pathTo(bytes32 index) public view override returns (address) {
        return address(balancerBatchAssets[index][balancerBatchAssets[index].length - 1]);
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
        bytes32[] memory pools = poolBatchIds[_index];
        IAsset[] memory assets = balancerBatchAssets[_index];

        uint256 length = assets.length;

        // Create fund structure
        FundManagement memory funds = FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(exchange)),
            toInternalBalance: false
        });

        // Create BalancerSwaps
        BatchSwapStep[] memory swaps = new BatchSwapStep[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            swaps[i] = BatchSwapStep({
                poolId: pools[i],
                assetInIndex: i,
                assetOutIndex: i + 1,
                amount: i == 0 ? _amount : 0,
                userData: ""
            });
        }

        // Create limit output
        int256[] memory limits = new int256[](length);

        limits[0] = int256(_amount);
        for (uint256 i = 1; i < length; i++) {
            limits[i] = int256(0);
        }

        // Approve NoteToken to balancer Vault
        IERC20(_from).approve(balancerVault, 0);
        IERC20(_from).approve(balancerVault, _amount);

        // Call batch swap in balancer
        IBalancer(balancerVault).batchSwap(0, swaps, assets, funds, limits, block.timestamp + 3600);
    }

    function getBalance(address asset, address account) internal view returns (uint256) {
        if (address(asset) == address(weth)) return address(account).balance;
        else return IERC20(asset).balanceOf(account);
    }
}