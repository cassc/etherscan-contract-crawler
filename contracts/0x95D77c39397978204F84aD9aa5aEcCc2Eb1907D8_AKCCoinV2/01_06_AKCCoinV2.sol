// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AKCCoinV2 is ERC20, Ownable {
    mapping(address => bool) public isLiquidityPair;
    mapping(address => bool) public isBanned;

    uint256 public reserveAllocation;
    address public tribeManager;

    constructor(
        address[] memory _wallets,
        uint256[] memory _amounts,
        uint256 _reserveAllocation
    ) ERC20("Alpha Kongs Coin", "AKC") {
        require(_wallets.length > 0 && _amounts.length > 0, "NO WALLETS OR BALANCES PROVIDED");
        require(_wallets.length == _amounts.length, "WALLETS DO NOT MATCH AMOUNTS");
        for (uint256 i = 0; i < _wallets.length; i++) {
            _mint(_wallets[i], _amounts[i]);
        }

        reserveAllocation = _reserveAllocation;
    }

    function mint(uint256 amount, address to) external {
        require(msg.sender == tribeManager, "Sender needs to be tribe manager");
        require(tribeManager != address(0), "Tribe manager not set");
        _mint(to, amount);
    }

    function burn(uint256 amount, address from) external {
        require(msg.sender == tribeManager, "Sender needs to be tribe manager");
        require(tribeManager != address(0), "Tribe manager not set");
        _burn(from, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBanned[from] && !isBanned[to], "FROM OR TO IS BANNED");

        // Sell tax
        // Only works when selling
        // Transfer part of the sell to tribemanager
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