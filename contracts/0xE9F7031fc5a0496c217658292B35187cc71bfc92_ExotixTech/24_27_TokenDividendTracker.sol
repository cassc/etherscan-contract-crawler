import "./DividendPayingToken.sol";
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
contract TokenDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    struct MAP {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    MAP private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    uint256 public minimumTokenBalanceForDividends1;
    uint256 public minimumTokenBalanceForDividends2;

    event ExcludeFromDividends(address indexed account);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor(
        address _rewardToken1Address,
        address _rewardToken2Address,
        uint256 _minimumTokenBalanceForDividends1,
        uint256 _minimumTokenBalanceForDividends2
    )
        DividendPayingToken(
            "Exotix_Dividend_Tracker",
            "Exotix_Dividend_Tracker",
            _rewardToken1Address,
            _rewardToken2Address
        )
    {
        minimumTokenBalanceForDividends1 = _minimumTokenBalanceForDividends1;
        minimumTokenBalanceForDividends2 = _minimumTokenBalanceForDividends2;
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "DT: FORBIDDEN");
    }

    function withdrawDividend1() public pure override {
        require(
            false,
            "DT: CLAIM."
        );
    }

    function withdrawDividend2() public pure override {
        require(
            false,
            "DT: CLAIM."
        );
    }

    function setminimumTokenBalanceForDividends1(uint256 val) external onlyOwner {
        minimumTokenBalanceForDividends1 = val;
    }
    
    function setminimumTokenBalanceForDividends2(uint256 val) external onlyOwner {
        minimumTokenBalanceForDividends2 = val;
    }


    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        MAPRemove(account);

        emit ExcludeFromDividends(account);
    }


    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function isExcludedFromDividends(address account)
        public
        view
        returns (bool)
    {
        return excludedFromDividends[account];
    }

    function getAccount1(address _account)
        public
        view
        returns (
            address account,
            int256 index,
            uint256 withdrawableDividends,
            uint256 totalDividends
        )
    {
        account = _account;

        index = MAPGetIndexOfKey(account);
        withdrawableDividends = withdrawableDividend1Of(account);
        totalDividends = accumulativeDividend1Of(account);
    }

    
    function getAccount2(address _account)
        public
        view
        returns (
            address account,
            int256 index,
            uint256 withdrawableDividends,
            uint256 totalDividends
        )
    {
        account = _account;

        index = MAPGetIndexOfKey(account);
        withdrawableDividends = withdrawableDividend2Of(account);
        totalDividends = accumulativeDividend2Of(account);
    }

    function getAccount1AtIndex(uint256 index)
        public
        view
        returns (
            address,
            int256,
            uint256,
            uint256
        )
    {
        if (index >= MAPSize()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                0,
                0
            );
        }

        address account = MAPGetKeyAtIndex(index);

        return getAccount1(account);
    }

    
    function getAccount2AtIndex(uint256 index)
        public
        view
        returns (
            address,
            int256,
            uint256,
            uint256
        )
    {
        if (index >= MAPSize()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                0,
                0
            );
        }

        address account = MAPGetKeyAtIndex(index);

        return getAccount2(account);
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends1) {
            _setBalance(account, newBalance);
            MAPSet(account, newBalance);
        } else {
            _setBalance(account, 0);
            MAPRemove(account);
        }

        processAccount1(account, true);
        processAccount2(account, true);
    }


    function processAccount1(address payable account, bool automatic)
        public
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividend1OfUser(account);

        if (amount > 0) {
            
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    
    function processAccount2(address payable account, bool automatic)
        public
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividend2OfUser(account);

        if (amount > 0) {
            
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    function MAPGet(address key) public view returns (uint) {
        return tokenHoldersMap.values[key];
    }

    function MAPGetIndexOfKey(address key) public view returns (int) {
        if (!tokenHoldersMap.inserted[key]) {
            return -1;
        }
        return int(tokenHoldersMap.indexOf[key]);
    }

    function MAPGetKeyAtIndex(uint index) public view returns (address) {
        return tokenHoldersMap.keys[index];
    }

    function MAPSize() public view returns (uint) {
        return tokenHoldersMap.keys.length;
    }

    function MAPSet(address key, uint val) public {
        if (tokenHoldersMap.inserted[key]) {
            tokenHoldersMap.values[key] = val;
        } else {
            tokenHoldersMap.inserted[key] = true;
            tokenHoldersMap.values[key] = val;
            tokenHoldersMap.indexOf[key] = tokenHoldersMap.keys.length;
            tokenHoldersMap.keys.push(key);
        }
    }

    function MAPRemove(address key) public {
        if (!tokenHoldersMap.inserted[key]) {
            return;
        }

        delete tokenHoldersMap.inserted[key];
        delete tokenHoldersMap.values[key];

        uint index = tokenHoldersMap.indexOf[key];
        uint lastIndex = tokenHoldersMap.keys.length - 1;
        address lastKey = tokenHoldersMap.keys[lastIndex];

        tokenHoldersMap.indexOf[lastKey] = index;
        delete tokenHoldersMap.indexOf[key];

        tokenHoldersMap.keys[index] = lastKey;
        tokenHoldersMap.keys.pop();
    }

    function distributeDividends1() external payable override {}
    function distributeDividends2() external payable override {}
}