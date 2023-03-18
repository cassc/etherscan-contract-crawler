// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IDividendPayingToken.sol";
import "./IterableMapping.sol";

/// @notice The Pack dividend tracker contract
contract PackDividendTracker is ERC20, ERC20Burnable, AccessControl, IDividendPayingToken {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using IterableMapping for IterableMapping.Map;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 constant internal MAGNITUDE = 2 ** 128;

    /// @notice Dividend tracker administration role
    bytes32 public constant TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");

    IterableMapping.Map private tokenHoldersMap;
    mapping(address => int256) private magnifiedDividendCorrections;
    mapping(address => uint256) private withdrawnDividends;
    mapping(address => bool) private excludedFromDividends;
    IUniswapV2Router02 private uniswapRouter;
    uint256 private magnifiedDividendPerShare;
    uint256 private minimumTokenBalanceForDividends;
    address[][] private ethToRewardPath = new address[][](2);

    /// @notice The total dividends distributed in ETH
    uint256 public totalDividendsDistributed;
    /// @notice The index of the last processed wallet
    uint256 public lastProcessedIndex;
    /// @notice The current token used for rewards
    address[] public rewardTokens;

    event ExcludeFromDividends(address indexed account);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() ERC20("Pack_Dividend_Tracker", "Pack_Dividend_Tracker") {
        minimumTokenBalanceForDividends = 1 * (10 ** 18);

        _grantRole(DEFAULT_ADMIN_ROLE, 0x3ed182236F5D4754769A1CC182C5A07D17d4722b);
        _grantRole(TOKEN_ADMIN_ROLE, 0x3ed182236F5D4754769A1CC182C5A07D17d4722b);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TOKEN_ADMIN_ROLE, msg.sender);

        excludeFromDividends(address(this), true);
        excludeFromDividends(address(0x000000000000000000000000000000000000dEaD), true);
        excludeFromDividends(address(0), true);
        excludeFromDividends(msg.sender, true);
    }

    /// @notice Received funds are calculated and added to total dividends distributed
    receive() external payable {
        distributeDividends();
    }

    /// @notice Grants a user token administrator role
    /// @param user The user to give the token administrator role to
    function setTokenAdminRole(address user) public onlyRole(TOKEN_ADMIN_ROLE) {
        _grantRole(TOKEN_ADMIN_ROLE, user);
    }

    /// @notice Adds incoming funds to the dividends per share
    function distributeDividends() public onlyRole(TOKEN_ADMIN_ROLE) payable {
        require(totalSupply() > 0, "No supply");
        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(MAGNITUDE) / totalSupply());
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return dividends The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view returns (uint256 dividends) {
        return withdrawableDividendOf(_owner);
    }

    /// @notice View the amount of dividend that a address has withdrawn
    /// @param _owner The address of the token holder.
    /// @return dividends The amount of dividends that `_owner` has withdrawn
    function withdrawnDividendOf(address _owner) public view returns (uint256 dividends) {
        return withdrawnDividends[_owner];
    }

    /// @notice The reward tokens to pay out dividends in
    /// @param tokens The token addresses of the rewards (use 0x0 for < 3)
    function setRewardTokens(address[] memory tokens) public onlyRole(TOKEN_ADMIN_ROLE) {
        require(tokens.length <=3, "max 3 rewards");
        delete ethToRewardPath;
        for(uint256 i = 0; i < tokens.length; i++){
            if(tokens[i] != address(0)){
                address[] memory path = new address[](2);
                path[0] = uniswapRouter.WETH();
                path[1] = address(tokens[i]);
                ethToRewardPath.push(path);
            }
        }
        rewardTokens = tokens;
    }

    /// @notice The uniswap router to use for internal swaps
    /// @param router The uniswap swap router
    function setUniswapRouter(IUniswapV2Router02 router) public onlyRole(TOKEN_ADMIN_ROLE) {
        uniswapRouter = router;
        excludeFromDividends(address(uniswapRouter), true);
    }

    function _transfer(address, address, uint256) internal pure virtual override {
        require(false, "No transfers");
    }

    /// @notice Excludes a wallet from dividends
    /// @param account The address to exclude from dividends
    /// @param value true if the address should be excluded from dividends, false otherwise
    function excludeFromDividends(address account, bool value) public onlyRole(TOKEN_ADMIN_ROLE) {
        excludedFromDividends[account] = value;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
    }

    /// @notice Set the minimum amount of token required to earn dividends
    /// @param newValue The minimum amount of token required to earn dividends
    function setTokenBalanceForDividends(uint256 newValue) external onlyRole(TOKEN_ADMIN_ROLE) {
        minimumTokenBalanceForDividends = newValue;
    }

    /// @notice Gets the index of the last processed wallet
    /// @return index The index of the last wallet that was paid dividends
    function getLastProcessedIndex() external view returns (uint256 index) {
        return lastProcessedIndex;
    }

    /// @notice Gets the number of dividend tracking token holders
    /// @return holders The number of dividend tracking token holders
    function getNumberOfTokenHolders() external view returns (uint256 holders) {
        return tokenHoldersMap.size();
    }
    /// @notice Allows retrieval of any ERC20 token that was sent to the contract address
    /// @return success true if the transfer succeeded, false otherwise
    function rescueToken(address tokenAddress) external onlyRole(TOKEN_ADMIN_ROLE) returns (bool success) {
        return ERC20(tokenAddress).transfer(msg.sender, ERC20(tokenAddress).balanceOf(address(this)));
    }

    /// @notice Gets account information by address
    /// @param _account The account to get information for
    /// @return account The account retrieved
    /// @return index The index of the account in the iterable mapping
    /// @return iterationsUntilProcessed The number of wallets left to process before this wallet
    /// @return withdrawableDividends The amount of dividends this account can withdraw
    /// @return totalDividends The total dividends this account has earned
    function getAccount(address _account)
    public view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableDividends,
        uint256 totalDividends) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = 0;
        if (index >= 0) {
            if (SafeCast.toUint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(SafeCast.toInt256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.size() > lastProcessedIndex ? tokenHoldersMap.size().sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(SafeCast.toInt256(processesUntilEndOfArray));
            }
        }
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
    }

    /// @notice Gets account information by index
    /// @param _index The index to get information for
    /// @return account The account retrieved
    /// @return index The index of the account in the iterable mapping
    /// @return iterationsUntilProcessed The number of wallets left to process before this wallet
    /// @return withdrawableDividends The amount of dividends this account can withdraw
    /// @return totalDividends The total dividends this account has earned
    function getAccountAtIndex(uint256 _index)
    public view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableDividends,
        uint256 totalDividends) {
        if (_index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, 0, 0, 0, 0);
        }
        return getAccount(tokenHoldersMap.getKeyAtIndex(_index));
    }

    /// @notice Sets the balance of dividend tracking tokens for an account
    /// @param account The account to set the balance for
    /// @param newBalance The new balance to set for the account.
    function setBalance(address payable account, uint256 newBalance) external onlyRole(TOKEN_ADMIN_ROLE) {
        if (excludedFromDividends[account]) {
            return;
        }
        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }
        processAccount(account, true);
    }

    /// @notice This function uses a set amount of gas to process dividends for as many wallets as it can
    /// @param gas The amount of gas to use for processing dividends
    /// @return numProcessed The number of wallets processed
    /// @return numClaims The number of actual claims sent
    /// @return lastIndex The index of the last wallet processed
    function process(uint256 gas) public onlyRole(TOKEN_ADMIN_ROLE) returns (uint256 numProcessed, uint256 numClaims, uint256 lastIndex) {
        uint256 numberOfTokenHolders = tokenHoldersMap.size();

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;
            if (_lastProcessedIndex >= tokenHoldersMap.size()) {
                _lastProcessedIndex = 0;
            }
            address account = tokenHoldersMap.getKeyAtIndex(_lastProcessedIndex);

            if (processAccount(payable(account), true)) {
                claims++;
            }

            iterations++;
            uint256 newGasLeft = gasleft();
            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }
            gasLeft = newGasLeft;
        }
        lastProcessedIndex = _lastProcessedIndex;
        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) internal returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
        emit Claim(account, amount, automatic);
        return amount > 0;
    }

    function claimReward() external returns (bool) {
        uint256 amount = _withdrawDividendOfUser(payable(msg.sender));
        emit Claim(msg.sender, amount, false);
        return amount > 0;
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        uint256 perToken = _withdrawableDividend.div(ethToRewardPath.length);
        uint256 amount = 0;
        for(uint256 i = 0; i < ethToRewardPath.length; i++){
            if (perToken > 0) {
                withdrawnDividends[user] = withdrawnDividends[user].add(perToken);
                emit DividendWithdrawn(user, perToken);
                amount.add(swapETHForTokensAndWithdrawDividend(user, ethToRewardPath[i], perToken));
            }
        }
        return amount;
    }

    function swapETHForTokensAndWithdrawDividend(address holder, address[] memory rewardPath, uint256 ethAmount) private returns (uint256) {
        try uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value : ethAmount}(
            0, // accept any amount of tokens
            rewardPath,
            address(holder),
            block.timestamp
        ) {
            return ethAmount;
        } catch {
            withdrawnDividends[holder] = withdrawnDividends[holder].sub(ethAmount);
        }
        return 0;
    }

    /// @notice The total accumulated dividends for a address
    /// @param _owner The address to query for accumulated dividends
    /// @return accumulated The total dividends currently accumulated (total - withdrawn)
    function accumulativeDividendOf(address _owner) public view returns (uint256 accumulated) {
        return SafeCast.toUint256(SafeCast.toInt256(magnifiedDividendPerShare.mul(balanceOf(_owner)))
        .add(magnifiedDividendCorrections[_owner])) / (MAGNITUDE);
    }
    /// @notice The total withdrawable dividends for a address
    /// @param _owner The address to query for accumulated dividends
    /// @return withdrawable The total dividends currently withdrawable (total - withdrawn)
    function withdrawableDividendOf(address _owner) public view returns (uint256 withdrawable) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub(SafeCast.toInt256(magnifiedDividendPerShare.mul(value)));
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add(SafeCast.toInt256(magnifiedDividendPerShare.mul(value)));
    }
}