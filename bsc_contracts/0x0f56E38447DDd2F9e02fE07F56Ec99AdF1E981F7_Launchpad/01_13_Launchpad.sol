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
        bool revoked;
    }

    address[] public routers;
    
    mapping (address => PoolInfo) public poolMap;
    address[] public pools;

    // bool public isPublic;
    mapping (address => bool) public whitelist;

    uint public price;
    uint public bnbFee = 400; // 4%
    uint public tokenFee;
    address public bnbFeeWallet = 0xA8ED4Bf2CB36C648Dbef85dD7c5A3611A22062e0;
    address public tokenFeeWallet = 0xa2a24766E8ad90E078373dAF802726dEEBd6d6e3;

    constructor(address _novationRouter, address _pcsRouter) {
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
        // if (!isPublic) require (whitelist[_token], "!approved");
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

        uint before = IERC20(_token).balanceOf(address(pool));
        uint saleAmount = _args.salePrice*_args.hardCap/1e18;
        IERC20(_token).safeTransferFrom(msg.sender, address(pool), saleAmount);
        require (IERC20(_token).balanceOf(address(pool)) - before >= saleAmount, "!sale token amount");
        
        poolMap[address(pool)] = PoolInfo({
            pool: address(pool),
            token: _token,
            urls: _urls,
            owner: msg.sender,
            createdAt: block.timestamp, 
            revoked: false
        });
        pools.push(address(pool));

        pool.transferOwnership(owner());

        if (price > 0) {
            address(bnbFeeWallet).call{value: msg.value}("");
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
            createdAt: block.timestamp, 
            revoked: false
        });

        whitelist[pool.token()] = true;
    }

    function updatePoolInfo(address _pool, string calldata _urls) external {
        require (poolMap[_pool].pool != address(0), "!exists");
        require (poolMap[_pool].owner == msg.sender, "!owner");
        require (bytes(_urls).length <= 1024, "!urls size");
        poolMap[_pool].urls = _urls;
    }

    function setRevoked(address _pool, bool _revoked) external onlyOwner {
        require (poolMap[_pool].pool != address(0), "!exists");
        poolMap[_pool].revoked = _revoked;
    }

    function approveToken(address _token, bool _flag) external onlyOwner {
        whitelist[_token] = _flag;
    }

    // function togglePublic() external onlyOwner {
    //     isPublic = !isPublic;
    // }

    function addRouter(address _router) external onlyOwner {
        for (uint i = 0; i < routers.length; i++) {
            if (routers[i] == _router) revert("already existing router");
        }
        
        routers.push(_router);
    }

    function updatePrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setFee(uint _bnbFee, uint _tokenFee) external onlyOwner {
        bnbFee = _bnbFee;
        tokenFee = _tokenFee;
    }

    function setFeeWallets(address _bnbWallet, address _tokenWallet) external onlyOwner {
        bnbFeeWallet = _bnbWallet;
        tokenFeeWallet = _tokenWallet;
    }

    function timestamp() external view returns (uint) {
        return block.timestamp;
    }
}