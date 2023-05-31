// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract DroomCoin is ERC20Permit, Ownable {
    uint256 public constant TOTAL_SUPPLY = 69_000_000_000 ether;

    address public UNISWAP_V2_PAIR;
    uint256 public maxWalletAmount = 138_000_000 ether;

    bool public limitsEnabled = true;

    mapping(address => bool) private blacklist;

    constructor() ERC20Permit("Droom Coin") ERC20("Droom Coin", "DROOM") {
        _mint(msg.sender, TOTAL_SUPPLY);
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

    function updateLimitStatus(
        bool _status,
        uint256 _newMaxPerWallet
    ) public onlyOwner {
        limitsEnabled = _status;
        maxWalletAmount = _newMaxPerWallet;
    }

    function setUniswapPair(address _uniswapPair) external onlyOwner {
        UNISWAP_V2_PAIR = _uniswapPair;
    }

    function isBlacklisted(address _wallet) public view returns (bool) {
        return blacklist[_wallet];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(amount > 0, "amount must be greater than 0");
        require(
            (!isBlacklisted(to) && !isBlacklisted(from)) || to == owner(),
            "TRADING NOT ACTIVE"
        );

        if (UNISWAP_V2_PAIR == address(0)) {
            require(from == owner() || to == owner(), "TRADING NOT ACTIVE");
            return;
        }

        if (limitsEnabled && from == UNISWAP_V2_PAIR) {
            require(
                super.balanceOf(to) + amount <= maxWalletAmount,
                "Too much DROOM"
            );
        }
    }
}