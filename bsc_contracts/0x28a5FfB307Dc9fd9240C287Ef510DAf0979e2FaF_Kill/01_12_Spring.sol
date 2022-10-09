// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./ITokenForLiquidityManager.sol";
import "./ILiquidityManager.sol";
import "./external/IPancakeRouter02.sol";
import "./OwnersUpgradeable.sol";

contract Kill is
    ERC20Upgradeable,
    OwnersUpgradeable,
    ITokenForLiquidityManager
{
    bool public isOpenToTrading = false;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public whitelist;

    address public busd;
    address public liquidityPair;
    IPancakeRouter02 public lpRouter;
    address public treasury;
    address public team;
    uint256 public sellTax; // 4 decimals. 500 = 0.05 = 5%
    uint256 public liquidatePercentOfSellTax; // 4 decimals. 1000 = 0.1 = 10%

    ILiquidityManager public liquidityManager;

    function initialize(
        address _busd,
        address _lpRouter,
        address _treasury
    ) public initializer {
        __ERC20_init_unchained("Kill", "KILL");
        __Owners_init_unchained();

        busd = _busd;
        lpRouter = IPancakeRouter02(_lpRouter);
        treasury = _treasury;

        whitelist[msg.sender] = true;
        sellTax = 1000;
        liquidatePercentOfSellTax = 5000;
    }

    function mint(uint256 _amount, address _to) external onlyOwners {
        require(_amount > 0, "Amount too low");
        _mint(_to, _amount);
    }

    function setOpenToTrading(bool _isOpen) external onlyOwners {
        isOpenToTrading = _isOpen;
    }

    function setTreasury(address _treasury) external onlyOwners {
        treasury = _treasury;
    }

    function setTeam(address _team) external onlyOwners {
        team = _team;
    }

    function setSellTax(uint256 _sellTax) external onlyOwners {
        require(_sellTax <= 2500, "Cannot be more than 25%");
        sellTax = _sellTax;
    }
    function setliquidatePercentOfSellTax(uint256 _liquidatePercentOfSellTax) external onlyOwners {
        require(_liquidatePercentOfSellTax <= 9999, "Cannot be than 99% of the tax");
        liquidatePercentOfSellTax = _liquidatePercentOfSellTax;
    }
    // @dev You may only set it once! Be careful!
    function setLiquidityManager(address _liquidityManager)
        external
        onlyOwners
    {
        require(address(liquidityManager) == address(0), "LM was already set");
        liquidityManager = ILiquidityManager(_liquidityManager);
        whitelist[_liquidityManager] = true;
    }

    function setLiquidityPair(address _liquidityPair) external onlyOwners {
        liquidityPair = _liquidityPair;
    }

    function setBlacklist(address[] calldata _addresses, bool _new)
        external
        onlyOwners
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklist[_addresses[i]] = _new;
        }
    }

    function setWhitelist(address[] calldata _addresses, bool _new)
        external
        onlyOwners
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _new;
        }
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        if (_from == address(0) || isOwner[_from]) {
            return;
        }

        require(!blacklist[_from] && !blacklist[_to], "Kill: Blacklisted");
        if (!isOpenToTrading) {
            require(
                whitelist[_from] && whitelist[_to],
                "Kill: Trading closed"
            );
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override(ERC20Upgradeable, IERC20Upgradeable) returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transferFrom(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount)
        public
        override(ERC20Upgradeable, IERC20Upgradeable)
        returns (bool)
    {
        _transferFrom(msg.sender, to, amount);
        return true;
    }

    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == liquidityPair || to == liquidityPair) {
            // interacting with LP
            if (
                liquidityPair == to && !whitelist[from] && from != address(this)
            ) {
                // apply sell tax
                uint256 feeAmount = (amount * sellTax) / 1e4;
                amount -= feeAmount;
                if (feeAmount > 0) {
                    // send fee SPR to LM
                    uint256 liquidateFeeAmount = (feeAmount *
                        liquidatePercentOfSellTax) / 1e4;
                    if (liquidateFeeAmount > 0) {
                        _transfer(from, address(this), liquidateFeeAmount);
                        liquidateSellFee(liquidateFeeAmount);
                    }
                    _transfer(
                        from,
                        address(liquidityManager),
                        feeAmount - liquidateFeeAmount
                    );
                }
            }
        } else if (address(liquidityManager) != address(0)) {
            // other transfers
            liquidityManager.stabilize();
        }

        _transfer(from, to, amount);
    }

    function liquidateSellFee(uint256 tokenAmount) private {
        // sell SPR on pancake, receive BUSD
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = busd;
        _approve(address(this), address(lpRouter), tokenAmount/2);
        lpRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount/2,
            0, // accept any amount of tokens
            path,
            treasury, // send BUSD directly to treasury
            block.timestamp
        );
        _approve(address(this), address(lpRouter), tokenAmount/2);
        lpRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount/2,
            0, // accept any amount of tokens
            path,
            team, // send BUSD directly to team
            block.timestamp
        );
    }

    function approveForLiquidityManger(address _liquidityPair, uint256 _amount)
        external
    {
        require(
            msg.sender == address(liquidityManager),
            "Only LM is allowed to call this"
        );
        _approve(_liquidityPair, address(liquidityManager), _amount);
    }
}