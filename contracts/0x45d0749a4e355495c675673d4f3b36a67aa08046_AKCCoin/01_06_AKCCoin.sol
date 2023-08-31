// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AKCCoin is ERC20, Ownable {
    mapping(address => bool) public isLiquidityPair;
    mapping(address => bool) public isBanned;

    uint256 public reserveAllocation;
    address public tribeManager;

    uint256 public openTime = 1648486800 - 120;
    uint256 public buyLimit = 1000 ether;
    mapping(address => uint256) public whitelistedUserToBought;
    mapping(address => bool) public isWhiteListed;

    /**
     * @dev Events
     */
    event SetTribeManagerEvent(address indexed core);

    constructor(
        address[] memory _wallets,
        uint256[] memory _amounts,
        address[] memory _wlWallets,
        uint256 _reserveAllocation
    ) ERC20("Alpha Coins", "$AKC") {
        require(_wallets.length > 0 && _amounts.length > 0, "NO WALLETS OR BALANCES PROVIDED");
        require(_wallets.length == _amounts.length, "WALLETS DO NOT MATCH AMOUNTS");
        for (uint256 i = 0; i < _wallets.length; i++) {
            _mint(_wallets[i], _amounts[i]);
        }

        reserveAllocation = _reserveAllocation;
        addToWhitelist(_wlWallets);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBanned[from] && !isBanned[to], "FROM OR TO IS BANNED");

        // WL buy limit
        if (block.timestamp < openTime) {
            if (isLiquidityPair[from] && !isLiquidityPair[to]) {
                require(isWhiteListed[to], "RECIPIENT NOT WHITELISTED");
                require(amount + whitelistedUserToBought[to] <= buyLimit, "CANNOT BUY MORE THAN LIMIT ON WL SALE");
                whitelistedUserToBought[to] += amount;
            }        
        }

        // Sell tax
        uint256 toTransfer = amount;
        if (
            from != tribeManager && 
            isLiquidityPair[to] &&             
            reserveAllocation > 0 && 
            reserveAllocation < 100) {
                uint256 toManager = amount * reserveAllocation / 100;
                toTransfer = amount - toManager;
                super._transfer(from, tribeManager, toManager);
        }
        
        super._transfer(from, to, toTransfer);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        if (spender != tribeManager) {
            super._spendAllowance(owner, spender, amount);
        }       
    }

    /** ONLY OWNER */
    function setTribeManager(address managerAddress)
        external
        onlyOwner {
            tribeManager = managerAddress;
            emit SetTribeManagerEvent(managerAddress);
        }

    function setIsBanned(address user, bool shouldBan) 
        external 
        onlyOwner {
        isBanned[user] = shouldBan;
    }

    function setIsLiquidityPair(address pair, bool isLiq)
        external 
        onlyOwner {
            isLiquidityPair[pair] = isLiq;
        }

    function addToWhitelist(address[] memory users)
        public
        onlyOwner {
            for (uint i = 0; i < users.length; i++) {
                isWhiteListed[users[i]] = true;
            }
        }
    
    function removeFromWhitelist(address user)
        external 
        onlyOwner {
            isWhiteListed[user] = false;
        }

    function setOpenTime(uint256 newTime)
        external
        onlyOwner {
            openTime = newTime;
        }

    function setBuyLimit(uint256 limit)
        external
        onlyOwner {
            buyLimit = limit;
        }
    
    function setReserveAllocation(uint256 newAllocation)
        external 
        onlyOwner {
            reserveAllocation = newAllocation;
        }

    function withdrawEth(uint256 percentage, address _to)
        external
        onlyOwner
    {
        payable(_to).transfer((address(this).balance * percentage) / 100);
    }

    function withdrawERC20(
        uint256 percentage,
        address _erc20Address,
        address _to
    ) external onlyOwner {
        uint256 amountERC20 = ERC20(_erc20Address).balanceOf(address(this));
        ERC20(_erc20Address).transfer(_to, (amountERC20 * percentage) / 100);
    }
}