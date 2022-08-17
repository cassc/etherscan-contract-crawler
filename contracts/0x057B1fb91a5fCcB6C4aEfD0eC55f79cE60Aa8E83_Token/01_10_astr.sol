// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract Token is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    address public allocationContract;

    uint256 public startBlock;
    uint256 public blocks;
    uint256 public endBlock;
    uint256 public tgeAmount;

    //Keep track of all pairs
    mapping(address => bool) public pairs;

    // Events
    event SetPairAddress(address pair);
    event SetStartBlock(uint256 startBlock);
    event SetSellLimitTime(uint256 blocks);

    function initialize(address _allocationContract) external initializer {
        __ERC20_init("Astra DAO", "ASTRA");
        __ERC20Burnable_init();
        __Ownable_init();
        __Pausable_init();
        allocationContract = _allocationContract;
        _mint(allocationContract, 100000000000000 * uint256(10)**decimals());
        tgeAmount = 2000000000000 * uint256(10)**decimals();
    }

    // Pause tokens
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause token
    function unpause() external onlyOwner {
        _unpause();
    }

    // Mint new token
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Add new pair for which we need to implement Antibot check
    function setPairAddress(address _pair) external onlyOwner {
        require(!pairs[_pair], "Pair already addded");
        pairs[_pair] = true;
        emit SetPairAddress(_pair);
    }

    // Buy/Sell start time for Astra tokens
    function setStartBlock(uint256 _startBlock) external onlyOwner {
        startBlock = _startBlock;
        emit SetStartBlock(_startBlock);
    }

    // Time period for which admin want to implement the antibot check
    function setSellLimitTime(uint256 _blocks) external onlyOwner {
        blocks = _blocks;
        endBlock = block.number.add(_blocks);
        emit SetSellLimitTime(_blocks);
    }

    // Verify of the transfer between pairs address matches the anitbot mechanism condition
    function verifyBuySellConditions(
        address from,
        address to,
        uint256 amount
    ) internal view {
        if (pairs[from] || pairs[to]) {
            require(startBlock < block.number, "Token not available for trade");
            if (endBlock > block.number) {
                require(
                    amount <=
                        block.number.sub(startBlock).mul(tgeAmount).div(blocks),
                    "Trade amount reached"
                );
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        verifyBuySellConditions(from, to, amount);
    }
}