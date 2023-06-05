// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract test is ERC20Permit, Ownable {
    uint256 constant BLACKLIST = 720000; // blocks
    address public immutable UNISWAP_V2_PAIR;

    mapping(address => uint256) public blacklist;

    uint256 public maxWalletAmount;
    uint256 public deadblockExpiration;

    bool public limitsEnabled;
    bool public tradingActive;

    mapping(address => bool) private _exclusionList;

    constructor() ERC20Permit("dontbuydevisintheshower") ERC20("dontbuy", "DEVS") {
        _updateExclusionList(msg.sender, true);
        _mint(msg.sender, 10_000_000_000 ether);

        UNISWAP_V2_PAIR = IUniswapV2Factory(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        ).createPair(address(this), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, "amount must be greater than 0");

        if (!tradingActive) {
            require(
                isExcluded(from) || isExcluded(to),
                "transfers are not yet active"
            );
        }

        if (isblacklist(from)) {
            require(
                block.number > blacklist[from],
                "Blacklisted sorry cuz"
            );
        }

        if (limitsEnabled) {
            if (from == UNISWAP_V2_PAIR && !isExcluded(to)) {
                if (block.number < deadblockExpiration) {
                    blacklist[to] = block.number + BLACKLIST;
                }
            } else if (to == UNISWAP_V2_PAIR && !isExcluded(from)) {
                if (block.number < deadblockExpiration) {
                    blacklist[from] = block.number + BLACKLIST;
                }
            }

            if (
                to != UNISWAP_V2_PAIR &&
                !isExcluded(to) &&
                !isExcluded(from) &&
                maxWalletAmount > 0
            ) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "amount exceeds wallet limit"
                );
            }
        }

        super._transfer(from, to, amount);
    }

    function updateTradingStatus(uint256 deadBlocks) external onlyOwner {
        updateLimitsEnabled(true);

        tradingActive = true;

        if (deadblockExpiration == 0) {
            deadblockExpiration = block.number + deadBlocks;
        }
    }

    function updateExclusionList(
        address[] calldata addresses,
        bool value
    ) public onlyOwner {
        for (uint256 i; i < addresses.length; ) {
            _updateExclusionList(addresses[i], value);
            unchecked {
                i++;
            }
        }
    }

    function _updateExclusionList(address account, bool value) private {
        _exclusionList[account] = value;
    }

    function isExcluded(address account) public view returns (bool) {
        return _exclusionList[account];
    }

    function updateBlackList(
        address[] calldata addresses,
        uint256 blockNumber
    ) external onlyOwner {
        for (uint256 i; i < addresses.length; ) {
            blacklist[addresses[i]] = blockNumber;
            unchecked {
                i++;
            }
        }
    }

    function isblacklist(address account) public view returns (bool) {
        return !isExcluded(account) && blacklist[account] > 0;
    }

    function updateMaxWalletAmount(uint256 newAmount) external onlyOwner {
        maxWalletAmount = newAmount;
    }

    function updateLimitsEnabled(bool enabled) public onlyOwner {
        limitsEnabled = enabled;
    }
}