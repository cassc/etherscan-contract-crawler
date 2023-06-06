// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//////////////////////////////////
//  telegram: t.me/devcoinwtf   //
//  website: devcoin.wtf        //
//  twitter: @devcoinwtf        //
//////////////////////////////////
contract Dev is Ownable, ERC20 {
    bool public limited;
    bool public antibot = true;
    uint256 public constant INITIAL_SUPPLY = 420_690_000_000_000 * 10**18;
    uint256 public constant INITIAL_MAX_HOLD = INITIAL_SUPPLY / 40;
    address public uniswapV2Pair;

    /** List of detected bots */
    mapping(address => bool) private bots;
    /** Used to watch for sandwiches */
    mapping(address => uint256) private _lastBlockTransfer;

    event botDetected(address _bot);

    constructor() ERC20("Dev Coin", "DEV") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function setRule(bool _limited, address _uniswapV2Pair) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setAntiBot(bool _antibot) external onlyOwner {
        antibot = _antibot;
    }

    function updateBot(address _bot, bool status) external onlyOwner {
        bots[_bot] = status;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (uniswapV2Pair == address(0)) {
            require(
                from == owner() ||
                    to == owner() ||
                    msg.sender == owner() ||
                    tx.origin == owner(),
                "trading is not started"
            );
            return;
        }
        if (from == uniswapV2Pair) {
            // so it is a buy
            if (limited) {
                require(
                    super.balanceOf(to) + amount <= INITIAL_MAX_HOLD,
                    "Forbidden"
                );
            }
            if (antibot && _isContract(to) ) {
                // a bot is buying...
                bots[to] = true;
                emit botDetected(to);
            }
            _lastBlockTransfer[to] = block.number;
        } else if (antibot && bots[from]) {
            // a sell from a bot...
            revert("No bots today");
        } else {
            // Watch for sandwich trx
            if (block.number == _lastBlockTransfer[from]) {
                revert("Too fast");
            }
        }
    }

    /**
     * Checks if address is contract
     * @param _address Address in question
     * @dev Contract will have codesize
     */
    function _isContract(address _address) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }
}