// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract DAD is ERC20, Ownable, ERC20Burnable {
    uint256 public amountLimitPerTrade = 1000 * 1e8;
    uint256 public timeLimitPerTrade = 300; // seconds

    bool public isAntiBotEnabled = false;
    address public uniswapV2Pair;
    address private router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public controller;

    mapping(address => bool) internal isBlacklisted;
    mapping(address => bool) internal isRouterExchange;
    mapping(address => uint256) internal lastBuy;
    mapping(address => bool) internal firstBuy;

    constructor() ERC20("Diamond Alpha Token", "DAD") {
        // Init IUniswapV2Router02
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        isRouterExchange[uniswapV2Pair] = true;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /**
     * @dev mint DAD token
     * @param _account the address for minting to
     * @param _amount the amount of token to mint
     */
    function mint(address _account, uint256 _amount) public {
        require(msg.sender == controller, "DAD: Only controllers");
        _mint(_account, _amount);
    }

    function setController(address _newController) public onlyOwner {
        controller = _newController;
    }

    /**
     * @notice enableAntiBot.
     */
    function enableAntiBot() public onlyOwner {
        isAntiBotEnabled = true;
    }

    /**
     * @notice disableAntiBot.
     */
    function disableAntiBot() public onlyOwner {
        isAntiBotEnabled = false;
    }

    /**
     * @notice addRouterExchange.
     */
    function addRouterExchange(address _addr) public onlyOwner {
        isRouterExchange[_addr] = true;
    }

    /**
     * @notice removeRouterExchange.
     */
    function removeRouterExchange(address _addr) public onlyOwner {
        isRouterExchange[_addr] = false;
    }

    /**
     * @notice isRouterExchangeAddress.
     */
    function isRouterExchangeAddress(address _addr) public view returns (bool) {
        return isRouterExchange[_addr];
    }

    /**
     * @notice setAmountLimitPerTrade.
     */
    function setAmountLimitPerTrade(uint256 _amount) public onlyOwner {
        amountLimitPerTrade = _amount;
    }

    /**
     * @notice setTimeLimitPerTrade.
     */
    function setTimeLimitPerTrade(uint256 _amount) public onlyOwner {
        timeLimitPerTrade = _amount;
    }

    /**
     * @notice  add blacklists a token.
     */
    function blacklistAddress(address _addr) public onlyOwner {
        isBlacklisted[_addr] = true;
    }

    /**
     * @notice unBlacklistAddress.
     */
    function unBlacklistAddress(address _addr) public onlyOwner {
        isBlacklisted[_addr] = false;
    }

    /**
     * @notice getBlacklistToken.
     */
    function getBlacklistToken(address _addr) public view returns (bool) {
        return isBlacklisted[_addr];
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!isBlacklisted[from], "This user is blacklisted");
        require(!isBlacklisted[to], "This user is blacklisted");
        if (isAntiBotEnabled) {
            if (isRouterExchange[from]) {
                if (timeLimitPerTrade > 0) {
                    if (firstBuy[to]) {
                        require(
                            block.timestamp >= lastBuy[to] + timeLimitPerTrade,
                            "This user exceeded the purchase time"
                        );
                    }
                }
                if (amountLimitPerTrade > 0) {
                    require(
                        amount <= amountLimitPerTrade,
                        "This user excess amount"
                    );
                }
            }
        }
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        if (isAntiBotEnabled && isRouterExchange[from]) {
            lastBuy[to] = block.timestamp;
            firstBuy[to] = true;
        }
    }
}