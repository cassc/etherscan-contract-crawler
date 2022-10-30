// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract CFZY is ERC20 {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    uint256 private constant DENOMINATOR = 10000;

    address public router;
    address public pair;
    address public token;
    address public vault;

    address public marketAddr;
    address public market2Addr;
    address public market3Addr;

    address public operator;
    address public liquidityProvider;

    bool public trade;
    uint256 public gasPrice = 20 gwei;
    uint256 public startBlock;
    EnumerableSet.AddressSet private blacklist;

    mapping(address => bool) public excludedFee; 

    uint256 public marketFee;
    uint256 public market2Fee;
    uint256 public market3Fee;
    uint256 public lpFee;

    mapping(address => bool) public whitelist;

    constructor(
        string memory name,
        string memory symbol,
        address _router,
        address _token,
        address _marketAddr,
        address _market2Addr,
        address _market3Addr
    ) ERC20(name, symbol) {
        _mint(msg.sender, 1314e18);

        router = _router;
        pair = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(address(this), _token);
        token = _token;
        vault = address(new Vault());
        marketAddr = _marketAddr;
        market2Addr = _market2Addr;
        market3Addr = _market3Addr;

        operator = msg.sender;
        liquidityProvider = msg.sender;
        excludedFee[msg.sender] = true;
    }

    function setMarketAddr(address _marketAddr, address _market2Addr, address _market3Addr) external {
        if(operator == msg.sender) {
            marketAddr = _marketAddr;
            market2Addr = _market2Addr;
            market3Addr = _market3Addr;
        }
    }

    function setOperator(address _operator) external {
        if(operator == msg.sender) {
            operator = _operator;
            excludedFee[_operator] = true;
        }
    }

    function setLiquidityProvider(address _liquidityProvider) external {
        if(operator == msg.sender) {
            liquidityProvider = _liquidityProvider;
            excludedFee[_liquidityProvider] = true;
        }
    }

    function setExcludedFee(address addr, bool status) external {
        if(operator == msg.sender) {
            excludedFee[addr] = status;
        }
    }

    function addBlacklist(address account) public {
        if(operator == msg.sender) {
            blacklist.add(account);
        }
    }

    function multipleAddBlacklist(address[] calldata accounts) external {
        for(uint i = 0; i < accounts.length; i++) {
            addBlacklist(accounts[i]);
        }
    }

    function removeBlacklist(address account) public {
        if(operator == msg.sender) {
            blacklist.remove(account);
        }
    }

    function multipleRemoveBlacklist(address[] calldata accounts) external {
        for(uint i = 0; i < accounts.length; i++) {
            removeBlacklist(accounts[i]);
        }
    }

    function getBlacklist() external view returns(address[] memory list) {
        uint length = blacklist.length();
        list = new address[](length);
        for(uint i = 0; i < length; i++) {
            list[i] = blacklist.at(i);
        }
    }

    function setTrade(bool _trade) external {
        if(liquidityProvider == msg.sender) {
            trade = _trade; 
            startBlock = block.number + 40; // 2 minutes 40
        }
    }

    function setWhitelist(address[] calldata addrs, bool status) external {
        if(operator == msg.sender) {
            for(uint i = 0; i < addrs.length; i++) {
                whitelist[addrs[i]] = status;
            }
        }
    }

    function _checkLimit(address account) private view {
        if(block.number < startBlock && account != pair) {
            require(10e18 >= balanceOf(account), "exceed LimitAmount"); 
        }
    }

    function isAddLiquidity() private view returns(bool) {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        address token0 = IUniswapV2Pair(pair).token0();
        uint256 balance = IUniswapV2Pair(token).balanceOf(pair);
        if(token0 == token) {
            return balance > reserve0;
        } else {
            return balance > reserve1;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if(from == address(this) || from == liquidityProvider || to == liquidityProvider) {
            super._transfer(from, to, amount);
            return;
        }

        if(startBlock == 0 && isAddLiquidity() && to == pair) {
            super._transfer(from, to, amount);
            return;
        }

        address addr = from != pair ? from : to;
        require(!blacklist.contains(addr), "in blacklist");

        if(from != pair) {
            require(balanceOf(from) * 99 / 100 >= amount, "1% of the token is reserved");
        }
        
        if(from == pair || to == pair) {
            require(trade, "trade closed");
            require(tx.origin == addr, "delegate failed");
            if(block.number < startBlock) {
                require(whitelist[addr], "protection period");
            } else if(tx.gasprice >= gasPrice || block.number <= startBlock + 2) {
                blacklist.add(addr);
            }

            if(!excludedFee[addr]) {
                uint fee;
                if(from == pair) {
                    // buy
                    uint256 tempLpFee = amount * 300 / DENOMINATOR;
                    uint256 tempMarketFee = amount * 150 / DENOMINATOR;
                    uint256 tempMarke3tFee = amount * 50 / DENOMINATOR;
                    lpFee += tempLpFee;
                    marketFee += tempMarketFee;
                    market3Fee += tempMarke3tFee;
                    fee = tempLpFee + tempMarketFee + tempMarke3tFee;
                } else {
                    if(block.number < startBlock + 600) {
                        uint tempAmount = amount * 3000 / DENOMINATOR;
                        super._transfer(from, market2Addr, tempAmount);
                        amount -= tempAmount;
                    } else {
                        uint256 tempLpFee = amount * 400 / DENOMINATOR;
                        uint256 tempMarket2Fee = amount * 250 / DENOMINATOR;
                        uint256 tempMarke3tFee = amount * 50 / DENOMINATOR;
                        lpFee += tempLpFee;
                        market2Fee += tempMarket2Fee;
                        market3Fee += tempMarke3tFee;
                        fee = tempLpFee + tempMarket2Fee + tempMarke3tFee;
                    }
                }
                amount -= fee;
                if(fee > 0) {
                    super._transfer(from, address(this), fee);
                }
            }

        } else {
            swap();
        }
        super._transfer(from, to, amount);
        _checkLimit(to);
    }

    function swap() private {
        uint256 bal = balanceOf(address(this));
        if(bal > 0) {
            _transfer(address(this), pair, lpFee);
            IUniswapV2Pair(pair).sync();
            bal = balanceOf(address(this));
            _approve(address(this), router, bal);

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = token;

            IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(bal, 0, path, vault, block.timestamp);
            Vault(vault).withdraw(token);

            uint256 balance = IERC20(token).balanceOf(address(this));
            if(balance > 0) {
                uint256 totalMarketFee = marketFee + market2Fee + market3Fee;
                IERC20(token).transfer(market3Addr, balance * market3Fee / totalMarketFee);
                IERC20(token).transfer(market2Addr, balance * market2Fee / totalMarketFee);
                IERC20(token).transfer(marketAddr, IERC20(token).balanceOf(address(this)));
            }
            delete lpFee;
            delete marketFee;
            delete market2Fee;
            delete market3Fee;
        }
    }


}

// 币名称：CFZY

// 总量：1314

// 买：5%
//        1.5%营销1
//        0.5%营销3
//        3%LP

// 卖：7%
//       2.5%营销2
//       0.5%营销3
//       4%LP


// 开盘前30分钟卖滑点30%（进营销钱包）
//  10个市值账户买卖为零
//  13个白名单（最高10枚）（2分钟时间）
// 私募出来的要提前打底池（开交易前加池子不收费）
//  杀两个区块，杀高gas, 禁止合约调用
//  卖币，转账最多只能卖99%

contract Vault {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _owner) external {
        if(owner == msg.sender) {
            owner = _owner;
        }
    }

    function withdraw(address token) external {
        if(owner == msg.sender) {
            uint256 bal = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(msg.sender, bal);
        }
    }
}