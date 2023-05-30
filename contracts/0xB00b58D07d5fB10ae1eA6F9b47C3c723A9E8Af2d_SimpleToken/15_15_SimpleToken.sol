// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleToken is ERC20, ERC20Permit, Ownable {
    /// @dev limits enabled when liquidity is added. disabled by admin after sometime
    bool public limitsEnabled;

    /// @dev max ammount a wallet can hold in bootstrap mode
    uint256 public maxHoldingAmount;

    /// @dev min amount a wallet should hold in bootstrap mode
    uint256 public minHoldingAmount;

    /// @dev when to unfreeze the token
    uint256 public unlockBy;

    /// @dev a blacklist for all the sniper bots. once the admin revokes his dignity, nobody else can get added here.
    mapping(address => bool) public blacklists;

    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _lpSupply,
        uint256 _bondingSupply
    ) ERC20(_name, _symbol) ERC20Permit(_symbol) {
        _mint(_owner, _bondingSupply);
        _mint(address(this), _lpSupply);
        _transferOwnership(_owner);
    }

    /// @notice add liquidity and set limits
    function addLiquidity(
        IUniswapV2Router02 _router,
        uint256 _freezeDuration,
        uint256 _maxHoldingAmount,
        uint256 _minHoldingAmount
    ) external payable onlyOwner {
        // add liquidity and send lp back to the owner
        _approve(address(this), address(_router), balanceOf(address(this)));
        _router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            msg.value,
            msg.sender,
            block.timestamp
        );

        // enable limits and unlock time
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
        unlockBy = block.timestamp + _freezeDuration;
        limitsEnabled = true;
    }

    /// @notice blacklist function used to ban sniper bots. Called only by admin.
    function blacklist(address _address) external onlyOwner {
        blacklists[_address] = true;
    }

    /// @notice admin renounces everything. disables any checks and revokes token ownership.
    function renounceEverything() external onlyOwner {
        limitsEnabled = false;
        maxHoldingAmount = 0;
        minHoldingAmount = 0;
        unlockBy = 0;
        _transferOwnership(address(0));
    }

    /// @dev a check for the blacklist and for wallet balances when limits are enabled.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[from] && !blacklists[to], "no dignity");
        if (limitsEnabled) {
            require(
                block.timestamp > unlockBy &&
                    balanceOf(to) + amount <= maxHoldingAmount &&
                    balanceOf(to) + amount >= minHoldingAmount,
                "too much or too less"
            );
        }
    }
}