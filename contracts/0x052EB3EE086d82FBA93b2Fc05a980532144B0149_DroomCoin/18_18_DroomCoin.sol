// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract DroomCoin is ERC20Permit, Ownable {
    uint256 public constant TOTAL_SUPPLY = 69_000_000_000 ether;
    uint256 public constant PRESALE_SUPPLY = 20_700_000_000 ether;

    IUniswapV2Factory constant UNISWAP_V2_FACTORY =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    address public immutable UNISWAP_V2_PAIR;
    uint256 public maxWalletAmount = 138_000_000 ether;
    uint256 public deadblockCount = 5;
    uint256 public deadblockExpiration;

    bool public limitsEnabled;
    bool public tradingActive;

    mapping(address => bool) private whitelist;
    mapping(address => bool) private blacklist;

    constructor() ERC20Permit("Droom Coin") ERC20("Droom Coin", "DROOM") {
        _mint(msg.sender, TOTAL_SUPPLY);
        _addWhitelistAddress(msg.sender, true);
        _addWhitelistAddress(address(0xdead), true);

        UNISWAP_V2_PAIR = UNISWAP_V2_FACTORY.createPair(
            address(this),
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        );
    }

    function newMaxPerWallet(uint256 _newMaxPerWallet) external onlyOwner {
        maxWalletAmount = _newMaxPerWallet;
    }

    function _addWhitelistAddress(
        address _newWhitelist,
        bool _excluded
    ) internal {
        whitelist[_newWhitelist] = _excluded;
    }

    function addWhitelistAddress(
        address _newWhitelist,
        bool _excluded
    ) external onlyOwner {
        whitelist[_newWhitelist] = _excluded;
    }

    function fuckMEV(
        address[] calldata _botList,
        bool status
    ) external onlyOwner {
        for (uint256 i; i < _botList.length; ) {
            addBlacklistAddress(_botList[i], status);
            unchecked {
                i++;
            }
        }
    }

    function addBlacklistAddress(
        address _newBlacklist,
        bool _banned
    ) public onlyOwner {
        blacklist[_newBlacklist] = _banned;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function updateMaxWalletAmount(uint256 newAmount) external onlyOwner {
        maxWalletAmount = newAmount;
    }

    function updateTradingStatus(bool _active) public onlyOwner {
        tradingActive = _active;
        updateLimitStatus(true);

        deadblockExpiration = block.number + deadblockCount;
    }

    function updateLimitStatus(bool _status) public onlyOwner {
        limitsEnabled = _status;
    }

    function isBlacklisted(address _wallet) public view returns (bool) {
        return blacklist[_wallet];
    }

    function isWhitelisted(address _wallet) public view returns (bool) {
        return whitelist[_wallet];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, "amount must be greater than 0");

        if (!tradingActive) {
            require(
                isWhitelisted(from) || isWhitelisted(to),
                "transfers are not yet active"
            );
        }

        if (limitsEnabled) {
            //when buy
            if (from == UNISWAP_V2_PAIR && !isWhitelisted(to)) {
                if (block.number < deadblockExpiration) {
                    addBlacklistAddress(to, true);
                }
            } else if (to == UNISWAP_V2_PAIR && !isWhitelisted(from)) {
                //when sell
                if (block.number < deadblockExpiration) {
                    addBlacklistAddress(from, true);
                }
            }

            if (
                to != UNISWAP_V2_PAIR &&
                !isWhitelisted(to) &&
                !isWhitelisted(from)
            ) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "amount exceeds wallet limit"
                );
            }
        }

        super._transfer(from, to, amount);
    }
}