// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@divergencetech/ethier/contracts/utils/OwnerPausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CatCoin is OwnerPausable, ERC20Burnable, ERC20Pausable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY = 10_000_000_000 ether;
    uint256 public constant TRADE_REWARD_SUPPLY = 3_000_000_000 ether;
    uint256 public constant FARM_SUPPLY = 3_000_000_000 ether;
    uint256 public constant ECOSYSTEM_SUPPLY = 2_000_000_000 ether;
    uint256 public constant LP_SUPPLY = 1_000_000_000 ether;
    uint256 public constant DAO_SUPPLY = 1_000_000_000 ether;

    address public constant TRADE_REWARD_WALLET = 0x99999ca5293f20Bf666bDf317316eB83a4863A81;
    address public constant FARM_WALLET = 0x88888DEf0530b0929Cbf89c4eFEe8E8E7b1E72f3;
    address public constant ECOSYSTEM_WALLET = 0x777777Ddc1BBB94b290ded24620d561F37252AfE;
    address public constant LP_WALLET = 0x6666664cAa65fEd051Eae583089d46FB65b6c420;
    address public constant DAO_WALLET = 0x444444E98bB29547A5019c073F0069f3c1B348bF;

    constructor() ERC20("CatCoin", " CAT") {
        require(MAX_SUPPLY == TRADE_REWARD_SUPPLY + FARM_SUPPLY + ECOSYSTEM_SUPPLY + LP_SUPPLY + DAO_SUPPLY);

        _mint(TRADE_REWARD_WALLET, TRADE_REWARD_SUPPLY);
        _mint(FARM_WALLET, FARM_SUPPLY);
        _mint(ECOSYSTEM_WALLET, ECOSYSTEM_SUPPLY);
        _mint(LP_WALLET, LP_SUPPLY);
        _mint(DAO_WALLET, DAO_SUPPLY);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        Address.sendValue(to, amount);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}