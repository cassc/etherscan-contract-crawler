// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JediCoin is ERC20Burnable, Ownable {

    address public uniswapV2Pair;
    bool public isBanActive;
    mapping(address => bool) public banned;

    event BanBot(address indexed _address, bool _isBanned);
    event SetPair(address indexed _address);
    event BanDesactivated();

    constructor() ERC20("JediCoin", "JEDI") {
        uint _totalSupply = 369 * 1e9 * 1e18;
        isBanActive = true;

        _mint(msg.sender, _totalSupply);
    }

    /// @notice Internal function to add or remove bot address to the banned list
    /// @param _bot Bot address to add/remove from the banned list
    /// @param _isBanned Bool value to set the bot address ban status
    function _banBotStatus(address _bot, bool _isBanned) internal {
        banned[_bot] = _isBanned;
        
        emit BanBot(_bot, _isBanned);
    }

    /// @notice Ban bot address
    /// @param _bot Address to add to the banned list
    function banBot(address _bot) external onlyOwner {
        _banBotStatus(_bot, true);
    }

    /// @notice Unban bot address
    /// @param _bot Address to remove from banned list
    function unbanBot(address _bot) external onlyOwner {
        _banBotStatus(_bot, false);
    }
    
    /// @notice Ban a list of bot addresses
    /// @param _bots Array of addresses to add to the banned list
    function banBots(address[] calldata _bots) external onlyOwner {
        for (uint i = 0; i < _bots.length; i++) {
            _banBotStatus(_bots[i], true);
        }
    }

    /// @notice Unban a list of bot addresses
    /// @param _bots Array of addresses to remove from the banned list
    function unbanBots(address[] calldata _bots) external onlyOwner {
        for (uint i = 0; i < _bots.length; i++) {
            _banBotStatus(_bots[i], false);
        }
    }

    /// @notice Set rule for trading
    /// @param _uniswapV2Pair UniswapV2Pair address
    function setPair(address _uniswapV2Pair) external onlyOwner {
            uniswapV2Pair = _uniswapV2Pair;

            emit SetPair(_uniswapV2Pair);
    }

    /// @notice Desactivate ban
    function desactivateBan() external onlyOwner {
            isBanActive = false;

            emit BanDesactivated();
    }

    /// @notice Leaves the contract without owner 
    function renounceOwnership() override public virtual onlyOwner {
        require(!isBanActive, "JediCoin: ban is still active");
        require(uniswapV2Pair != address(0), "JediCoin: uniswapV2Pair is not set");
        _transferOwnership(address(0));
    }


    /// @notice Hook that is called before any transfer of tokens.
    /// @param from Sender address
    /// @param to Recipient address
    /// @param amount Amount of tokens to transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        /// @dev If from or to is address(0) or owner, or trading is not limited, don't run this hook
        if (!isBanActive || from == address(0) || from == owner() || to == owner()) return;

        require(uniswapV2Pair != address(0), "JediCoin: trading has not started yet");

        /// @dev If from or to is banned, revert the transaction
        require(!banned[from] && !banned[to], "JediCoin: this address is banned");

    }

}