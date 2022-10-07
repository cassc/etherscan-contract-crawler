// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ROSE is ERC20 {

    address private constant BURN_ADDR = 0x000000000000000000000000000000000000dEaD;
    uint256 private constant DENOMINATOR = 10000;

    address public router;
    address public pair;
    address public token;
    address public vault;

    address public nodeAddr;
    address public collegeAddr;
    address public ecoAddr;
    address public marketAddr;

    address public operator;
    address public liquidityProvider;

    bool public trade;
    uint256 public gasPrice = 20 gwei;
    uint256 public startBlock;
    mapping(address => bool) public blacklist;

    mapping(address => bool) public excludedFee; 

    uint256 public inTax = 500;
    uint256 public outTax = 700;
    uint256 public inFee;
    uint256 public outFee;

    mapping(address => bool) public whitelist;
    mapping(uint256 => uint256) public frequency;

    constructor(
        string memory name,
        string memory symbol,
        address _router,
        address _token,
        address _nodeAddr,
        address _collegeAddr,
        address _ecoAddr,
        address _marketAddr
    ) ERC20(name, symbol) {
        _mint(msg.sender, 999e18);

        router = _router;
        pair = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(address(this), _token);
        token = _token;
        vault = address(new Vault());
        nodeAddr = _nodeAddr;
        collegeAddr = _collegeAddr;
        ecoAddr = _ecoAddr;
        marketAddr = _marketAddr;

        operator = msg.sender;
        liquidityProvider = msg.sender;
        excludedFee[msg.sender] = true;
        excludedFee[address(this)] = true;
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

    function setBlacklist(address addr, bool status) external {
        if(operator == msg.sender) {
            blacklist[addr] = status;
        }
    }

    function setTrade(bool _trade) external {
        if(liquidityProvider == msg.sender) {
            trade = _trade;
            startBlock = block.number + 60; // 3 minutes 60
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
        if(account == address(this) || account == pair || excludedFee[account]) {
            return;
        }
        if(startBlock != 0 && block.number > startBlock + 600) { // 30 minutes 600
            return;
        }
        require(5e18 >= balanceOf(account), "exceed LimitAmount"); 
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
        if(!trade) {
            require(from != pair && to != pair, "trade closed");
        }

        address addr = from != pair ? from : to;
        require(!blacklist[addr], "in blacklist");

        if(!excludedFee[from] && from != pair) {
            require(balanceOf(from) * 99 / 100 >= amount, "1% of the token is reserved");
        }
        
        if(from == pair || to == pair) {
            require(tx.origin == addr, "delegate failed");
            frequency[block.number]++;
            require(frequency[block.number] <= 10, "frequent transactions");
            if(block.number < startBlock) {
                require(whitelist[addr], "protection period");
            } else if(tx.gasprice >= gasPrice || block.number <= startBlock + 2) {
                blacklist[addr] = true;
            }

            if(!excludedFee[addr]) {
                uint fee;
                if(from == pair) {
                    fee = amount * inTax / DENOMINATOR;
                    inFee += fee;
                } else {
                    fee = amount * outTax / DENOMINATOR;
                    outFee += fee;
                }
                amount -= fee;
                super._transfer(from, address(this), fee);
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
            // 0.1 / 5
            _transfer(address(this), BURN_ADDR, bal * 200 / DENOMINATOR);
            // 2.5 / 5
            _transfer(address(this), pair, bal * 5000 / DENOMINATOR);
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
                uint256 marketAmount = outFee * 200 / DENOMINATOR;
                uint256 marketPct = marketAmount * 1e18 / (inFee + outFee);
                IERC20(token).transfer(marketAddr, marketPct * balance / 1e18);
                balance = IERC20(token).balanceOf(address(this));
                // 0.9 / 2.4
                uint256 nodeFee = balance * 90 / 240;
                // 0.5 / 2.4
                uint256 collegeFee = balance * 50 / 240;
                
                IERC20(token).transfer(nodeAddr, nodeFee);
                IERC20(token).transfer(collegeAddr, collegeFee);
                // 1 / 2.4
                IERC20(token).transfer(ecoAddr, IERC20(token).balanceOf(address(this)));
                delete inFee;
                delete outFee;
            }
        }
    }


}

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