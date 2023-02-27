// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../sale/Timed.sol';
import './WithWhitelist.sol';
import './WithLevelsSale.sol';
import '../sale/Withdrawable.sol';
import './WithInventory.sol';
import './WithSaleData.sol';

contract LaunchpadINO is
    Adminable,
    ReentrancyGuard,
    Timed,
    Withdrawable,
    WithInventory,
    WithSaleData,
    WithWhitelist,
    WithLevelsSale
{
    using SafeERC20 for IERC20;
    using LevelsLibrary for LevelsState;

    string public id;

    event TokensPurchased(address indexed beneficiary, uint256 value, uint256 amount, bytes32 tokenId);
    event UserRefunded(address indexed beneficiary, uint256 value, uint256 amount, bool refunded);

    constructor(
        string memory _id,
        address _fundToken,
        address _fundsReceiver,
        ILevelManager _levelManager,
        uint256 _minAllowedLevelMultiplier,
        uint256[] memory _timeline,
        address[] memory _admins
    )
        Timed(_timeline)
        WithLevelsSale(_levelManager, _minAllowedLevelMultiplier)
        Withdrawable(_fundToken, _fundsReceiver)
    {
        id = _id;

        for (uint256 i = 0; i < _admins.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, _admins[i]);
        }
    }

    receive() external payable {
        revert('Sale: This presale requires tokenId use buyTokens(tokenId, amount)');
    }

    /**
     * Accepts payments in native currency and in ERC20 tokens, depends on "fundByTokens" flag.
     * The fund token must be first approved to be transferred by presale contract for the calculated value.
     */
    function buyTokens(bytes32 tokenId, uint256 amount) public payable ongoingSale nonReentrant {
        uint256 value = getPurchaseValue(tokenId, amount);
        uint256 normalizedValue = currencyDecimals < 18 ? value * (10**(18 - currencyDecimals)) : value;

        if (fundByTokens) {
            require(fundToken.allowance(msg.sender, address(this)) >= normalizedValue, 'Sale: fund token not approved');
        } else {
            require(
                msg.value == value,
                string(abi.encodePacked('Sale: Price and sent value do not match, you need to send exactly ', value))
            );
        }

        internalBuyTokens(tokenId, amount);

        if (fundByTokens) {
            fundToken.safeTransferFrom(msg.sender, address(this), normalizedValue);
        }
    }

    function internalBuyTokens(bytes32 tokenId, uint256 amount) private {
        uint256 maxAllocation = checkBuyAllowanceGetAllocation();

        address account = _msgSender();
        InventoryItem memory item = getItem(tokenId);
        uint256 value = getPurchaseValue(tokenId, amount);

        // user's total contribution reached more than his level allocation 6x * base allocation (calculated as total raise / weights)

        require(amount > 0, 'Sale: amount of tokens to buy must be more than 0');
        require(value > 0, 'Sale: price for tokens must be more than 0');
        require(
            item.limit == 0 || balanceOf(account, tokenId) < item.limit,
            'Sale: you reached the limit of this kind of items per wallet'
        );
        require(item.sold + amount <= item.supply, 'Sale: not enough supply');
        require(contributed[account] + value <= maxAllocation, 'Sale: total contribution exceeds your allocation');

        item.sold += amount;
        item.raised += value;
        inventory.items[inventory.index[tokenId]] = item;
        balances[account][tokenId] += amount;
        contributed[account] += value;
        participants = participants + 1;

        // Store the first and last block numbers to simplify data collection later
        if (firstPurchaseBlockN == 0) {
            firstPurchaseBlockN = block.number;
        }
        lastPurchaseBlockN = block.number;

        emit TokensPurchased(account, value, amount, tokenId);
    }

    function checkBuyAllowanceGetAllocation() private view returns (uint256) {
        address account = _msgSender();
        uint256 levelAllocation = getUserLevelAllocation(account);
        uint256 userWlAllocation = getUserWlAllocation(account);

        // Public sale with no whitelist or levels
        if (!whitelistEnabled && !levelsState.levelsEnabled) {
            // Use the default whitelist allocation as the public limit
            return wlAllocation;
        }

        // User whitelisted, consider his level allocation too
        if (whitelistEnabled && whitelisted[msg.sender]) {
            if (levelAllocation > 0 && levelsOpenAll()) {
                (, , uint256 fcfsAllocation, ) = getUserLevelState(account);
                require(fcfsAllocation > 0, 'Sale: user does not have FCFS allocation');
                levelAllocation = fcfsAllocation;
            }

            return levelAllocation + userWlAllocation;
        }

        if (whitelistEnabled && !levelsState.levelsEnabled) {
            revert('Sale: not in the whitelist');
        }

        // Check user level if levels enabled and user was not whitelisted
        return
            levelsState.validateAllowanceGetAllocation(
                account,
                levelAllocation,
                levelsOpenAll(),
                getFcfsAllocationMultiplier()
            );
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    // Old methods
    uint256 public rate = 0;

    function tokensForSale() public view returns (uint256) {
        return totalItemsAmount();
    }

    function tokensSold() public view returns (uint256) {
        return totalItemsSold();
    }

    function raised() public view returns (uint256) {
        return totalRaised();
    }

    function getMinMaxLimits() external view returns (uint256, uint256) {
        return (0, wlAllocation);
    }

    function maxSell() external view returns (uint256) {
        return wlAllocation;
    }
}