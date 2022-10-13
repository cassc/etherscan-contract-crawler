//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./PresalePool.sol";

contract Launchpad is Ownable {
    using SafeERC20 for IERC20;

    struct PoolInfo {
        address pool;
        address token;
        string urls;
        address owner;
        uint createdAt;
    }

    address[] public routers;
    
    mapping (address => PoolInfo) public poolMap;
    address[] public pools;

    bool public isPublic;
    mapping (address => bool) public whitelist;

    uint public price;
    address public feeWallet;

    constructor(address _novationRouter, address _pcsRouter) {
        feeWallet = msg.sender;
        routers.push(_novationRouter);
        routers.push(_pcsRouter);
    }

    function poolCount() external view returns (uint) {
        return pools.length;
    }

    function getPools(address _owner) external view returns (address[] memory) {
        uint count = _owner == address(0) ? pools.length : 0;
        if (_owner != address(0)) {
            for (uint i = 0; i < pools.length; i++) {
                if (poolMap[pools[i]].owner == _owner) count++;
            }
        }
        if (count == 0) return new address[](0);

        address[] memory poolList = new address[](count);
        uint index = 0;
        for (uint i = 0; i < pools.length; i++) {
            if (_owner != address(0) && poolMap[pools[i]].owner != _owner) {
                continue;
            }
            poolList[index] = poolMap[pools[i]].pool;
            index++;
        }

        return poolList;
    }

    function deploy(
        address _token,
        string calldata _urls,
        PoolParam calldata _args, 
        address[] calldata _whitelist,
        uint _router
    ) external payable {
        if (price > 0) {
            require (msg.value >= price, "!paid");
        }
        if (!isPublic) require (whitelist[_token], "!approved");
        require (bytes(_urls).length <= 1024, "!urls size");
        require (_router < routers.length, "!router index");

        PresalePool pool = new PresalePool(
            _token, 
            routers[_router],
            msg.sender
        );

        pool.initialize(
            _args, 
            _whitelist
        );

        IERC20(_token).safeTransferFrom(msg.sender, address(pool), _args.salePrice*_args.hardCap/1e18);
        
        pools.push(address(pool));
        pool.transferOwnership(owner());

        poolMap[address(pool)] = PoolInfo({
            pool: address(pool),
            token: _token,
            urls: _urls,
            owner: msg.sender,
            createdAt: block.timestamp
        });

        if (price > 0) {
            address(feeWallet).call{value: msg.value}("");
        }
    }

    function addPool(address _pool, string calldata _urls) external onlyOwner {
        require (poolMap[_pool].pool == address(0), "existing");
        require (bytes(_urls).length <= 1024, "!urls size");
        IPool pool = IPool(_pool);

        pools.push(_pool);
        poolMap[_pool] = PoolInfo({
            pool: _pool,
            token: pool.token(),
            urls: _urls,
            owner: pool.tokenOwner(),
            createdAt: block.timestamp
        });

        whitelist[_pool] = true;
    }

    function approveToken(address _token, bool _flag) external onlyOwner {
        whitelist[_token] = _flag;
    }

    function togglePublic() external onlyOwner {
        isPublic = !isPublic;
    }

    function addRouter(address _router) external onlyOwner {
        for (uint i = 0; i < routers.length; i++) {
            if (routers[i] == _router) revert("already existing router");
        }
        
        routers.push(_router);
    }

    function updatePrice(uint _price) external onlyOwner {
        price = _price;
    }

    function updateFeeWallet(address _wallet) external onlyOwner {
        feeWallet = _wallet;
    }

    function timestamp() external view returns (uint) {
        return block.timestamp;
    }
}