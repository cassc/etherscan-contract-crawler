// SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IDexAggregator {
    function bestrateswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 allowedslippage
    ) external returns (uint256);

    function getRates(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint8 flag
    ) external view returns (uint256[] memory, uint8);
}

contract Index is Ownable, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    ///@notice state to signify that configuration update has taken place
    bool public updated;
    ///@notice state to signify that index tokens are sold/swapped for ptokens
    bool public sold;
    ///@notice state to signify that tokens are staked or not
    bool public staked;
    ///@notice state to signify that tokens are unstaked or not
    bool public unstaked;
    ///@notice state to signify that previous index tokens are sold/swapped for ptoken after update
    bool public soldprevafterupdate;
    ///@notice state to signify that reward tokens are sold/swapped for ptoken
    bool public rewardtokensold;
    ///@notice state to signify the purchases state of the index contract
    bool public purchased;
    ///@notice stores address of the dex contract
    address public dex;
    ///@notice stores the address of the p token
    address public ptoken;
    ///@notice stores the address of the management treasury contract
    address public managementfeegetter;
    ///@notice stores the address of the performance treasury contract
    address public performancefeegetter;
    ///@notice stores the maximum deposit allowed in the
    uint256 public maxdeposit;
    /// @notice stores the token holding time
    uint256 public maturitytime;
    /// @notice stores the ending time for deposit
    uint256 public depositendtime;
    /// @notice stores the total deposit by the user
    uint256 public totaldeposit;
    ///@notice stores the deposit balance of the user
    mapping(address => uint256) depositerbalances;
    ///@notice stores the addresses of the depositors
    address[] public depositors;
    ///@notice stores the addresses of the reward tokens
    address[] public rewardtokens;
    ///@notice stores the addresses of the current tokens
    address[] public tokenscurrent;
    ///@notice stores the percentage fo the current tokens
    uint16[] public percentagescurrent;
    ///stores the addresses of the previous tokens
    address[] public tokensprevious;
    ///@notice mapping to store staking state of the tokens
    mapping(address => bool) tokenstaked;
    ///@notice modifier to check purchase
    modifier purchasedcheck() {
        if (!purchased) revert("Not purchased ");
        _;
    }
    ///@notice modifier to check updation
    modifier updatedcheck() {
        if (!updated) revert("Not updated");
        require(updated, "Not purchased");
        _;
    }
    /// @notice modifier to check selling
    modifier soldcheck() {
        require(sold, "Not sold yet");
        _;
    } ///@notice modifier to check the staked state
    modifier stakedcheck() {
        require(staked, "Not staked yet");
        _;
    }

    ///@notice it will add reward token address in the rewardtokens address array
    ///@param token the address of the reward token
    function addrewardtokens(address token) external onlyOwner {
        rewardtokens.push(token);
    }

    ///@notice it will return the states of the index contract
    function returnstates() external view onlyOwner returns (bool[5] memory) {
        return [purchased, updated, soldprevafterupdate, staked, sold];
    }

    /// @notice This function will update the index configuration with new percentages and tokens
    /// @param _percentages The percentage array for the tokens
    /// @param _tokens The address array of the tokens
    function udpateindex(uint16[] memory _percentages, address[] memory _tokens)
        external
        onlyOwner
        purchasedcheck
        nonReentrant
    {
        require(!staked, "tokens staked");
        tokensprevious = tokenscurrent;
        tokenscurrent = _tokens;
        percentagescurrent = _percentages;
        updated = true;
    }

    ///@notice returns index current tokens info
    function getCurrentTokensInfo()
        external
        view
        returns (address[] memory, uint16[] memory)
    {
        return (tokenscurrent, percentagescurrent);
    }

    ///@notice returns index previous tokens info
    function getPreviousTokensInfo() external view returns (address[] memory) {
        return (tokensprevious);
    }

    ///@notice returns balance of the caller address given token address
    ///@param _token the adddress of the token of which we want to check balance of
    ///@param _whose the address of which we want to check balance of
    function checkbalancebytoken(address _token, address _whose)
        internal
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(_whose);
    }

    ///@notice will be used to deposit the amount of ptoken in the contract
    ///@param amount the total amount deposited by the user on the contract
    ///@param depositer the address of the depositer
    function deposit(uint256 amount, address depositer)
        external
        onlyOwner
        nonReentrant
    {
        require(block.timestamp <= depositendtime, "depost time limit passed");

        require(
            totaldeposit + amount <= maxdeposit,
            "amount should be greater than minimlum"
        );

        uint256 fees = (amount * 5) / 100;
        uint256 amountin = amount - fees;
        depositerbalances[depositer] += amountin;
        totaldeposit += amountin;
        depositors.push(depositer);
        SafeERC20.safeTransfer(IERC20(ptoken), managementfeegetter, fees);
    }

    ///@notice it returns the current tokens of the index contract
    function currenttokenbalance()
        external
        view
        onlyOwner
        returns (uint256[] memory)
    {
        return tokensbalances(tokenscurrent);
    }

    ///@notice it returns the balance of the reward tokens for the index contract
    function rewardtokenbalance()
        external
        view
        onlyOwner
        returns (uint256[] memory)
    {
        return tokensbalances(rewardtokens);
    }

    ///@notice it returns the balance of the previous tokens for the index contract
    function previoustokenbalance()
        external
        view
        onlyOwner
        returns (uint256[] memory)
    {
        return tokensbalances(tokensprevious);
    }

    ///@notice it returns the ptokenbalance of the index contract
    function ptokenbalance() external view onlyOwner returns (uint256) {
        return checkbalancebytoken(ptoken, address(this));
    }

    ///@notice it will return the balance of tokens for the index
    ///@param _tokens the address array of the tokens that we want to know balance of
    function tokensbalances(address[] memory _tokens)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 numberoftokens = _tokens.length;
        address[] memory tokens = new address[](numberoftokens);
        uint256[] memory balancearray = new uint256[](numberoftokens);

        tokens = _tokens;

        for (uint256 i; i < numberoftokens; i++) {
            balancearray[i] = checkbalancebytoken(tokens[i], address(this));
        }

        return balancearray;
    }

    ///@notice internal function to purchase the current tokens
    ///@param _amount The amount of token that we want to use for purchasing ptoken
    ///@param _slippageallowed The amount of slippage allowed for swap
    function _purchase(uint256 _amount, uint256[] calldata _slippageallowed)
        internal
    {
        SafeERC20.safeIncreaseAllowance(IERC20(ptoken), dex, _amount);
        uint256 numoftokens = tokenscurrent.length;
        uint16[] memory percentages = new uint16[](numoftokens);
        address[] memory tokens = new address[](numoftokens);
        tokens = tokenscurrent;
        percentages = percentagescurrent;
        uint256 amount;
        for (uint256 i; i < numoftokens; ) {
            (amount) = IDexAggregator(dex).bestrateswap(
                ptoken,
                tokens[i],
                ((_amount * percentagescurrent[i]) / 1000),
                0,
                address(this),
                _slippageallowed[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    ///@notice internal function to sell the tokens for getting ptokens
    ///@param _tokens The tokens that we want to sell/swap for ptokens
    ///@param _amounts The amounrs of the token that we want sell/swap for ptokens
    ///@param _slippageallowed The array of percentage of slippage allowed
    function _sell(
        address[] memory _tokens,
        uint256[] calldata _amounts,
        uint256[] calldata _slippageallowed
    ) internal {
        uint256 numoftokens = _tokens.length;

        address[] memory tokens = new address[](numoftokens);
        tokens = _tokens;

        for (uint256 i; i < numoftokens; ) {
            SafeERC20.safeIncreaseAllowance(
                IERC20(tokens[i]),
                dex,
                _amounts[i]
            );
            IDexAggregator(dex).bestrateswap(
                tokens[i],
                ptoken,
                _amounts[i],
                0,
                address(this),
                _slippageallowed[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Will purchase/swap the index tokens in place of ptokens for the index contract
    /// @param _amount The amount of p token that we want to use for purchase/swap index tokens
    /// @param _slippageallowed The array of slippage percentages
    function purchase(uint256 _amount, uint256[] calldata _slippageallowed)
        external
        onlyOwner
    {
        require(
            block.timestamp > depositendtime,
            "deposit period,no purchase allowed"
        );
        require(!purchased, "already purchased");
        require(
            _amount <= IERC20(ptoken).balanceOf(address(this)),
            "Amount should be less than balance"
        );

        _purchase(_amount, _slippageallowed);
        if (checkbalancebytoken(ptoken, address(this)) == 0) {
            purchased = true;
            maturitytime += block.timestamp;
        }
    }

    ///@notice main sell function with required checks for selling tokens
    /// @param _amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    /// @param _slippageallowed The array of slippage percentages
    function sell(
        uint256[] calldata _amounts,
        uint256[] calldata _slippageallowed
    ) external onlyOwner purchasedcheck {
        require(!updated && !staked, "staked or updated");
        require(block.timestamp > maturitytime, "The index has not ended yet");
        require(
            _amounts.length == _slippageallowed.length &&
                _amounts.length == tokenscurrent.length,
            "uneven array length"
        );

        _sell(tokenscurrent, _amounts, _slippageallowed);

        bool flag;

        uint256 n = tokenscurrent.length;
        address[] memory tokens = new address[](n);
        tokens = tokenscurrent;

        for (uint256 i; i < n; ++i) {
            if (checkbalancebytoken(tokens[i], address(this)) != 0) {
                flag = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!flag) {
            sold = true;
        }
    }

    ///@notice it will sell/swap reward tokens for ptokens
    /// @param _amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    /// @param _slippageallowed The array of slippage percentages
    function sellrewardtokens(
        uint256[] calldata _amounts,
        uint256[] calldata _slippageallowed
    ) external onlyOwner purchasedcheck {
        bool flag;

        uint256 n = rewardtokens.length;
        address[] memory tokens = new address[](n);
        tokens = rewardtokens;

        _sell(tokens, _amounts, _slippageallowed);

        for (uint256 i; i < n; ++i) {
            if (checkbalancebytoken(tokens[i], address(this)) != 0) {
                flag = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!flag) {
            rewardtokensold = true;
        }
    }

    ///@notice it will distribute ptokens according to users deposit
    function distributeamount() external onlyOwner soldcheck {
        uint256 _totaldeposit = totaldeposit;
        uint256 _totalbalance = checkbalancebytoken(ptoken, address(this));

        if (_totalbalance > _totaldeposit) {
            uint256 interest = _totalbalance - _totaldeposit;
            uint256 fees = (interest * 10) / 100;

            IERC20(ptoken).safeTransfer(performancefeegetter, fees);
            _totalbalance -= fees;
        }

        uint256 percentage;
        uint256 lengthd = depositors.length;
        address[] memory _depositors = new address[](lengthd);
        _depositors = depositors;

        for (uint256 i; i < lengthd; i++) {
            percentage =
                (depositerbalances[depositors[i]] * 100) /
                totaldeposit;

            IERC20(ptoken).safeTransfer(
                _depositors[i],
                (percentage * _totalbalance) / 100
            );
        }
    }

    /// @notice Will sell/swap the previous index tokens for ptokens for the index contract
    /// @param amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    /// @param slippageallowed The array of slippage percentages
    function rebalancesell(
        uint256[] calldata amounts,
        uint256[] calldata slippageallowed
    ) external onlyOwner {
        require(
            block.timestamp > depositendtime,
            "time period should be between deposit and ending"
        );

        require(
            amounts.length == slippageallowed.length &&
                amounts.length == tokensprevious.length,
            "uneven array length"
        );
        require(updated, "not updated");

        _sell(tokensprevious, amounts, slippageallowed);
        bool flag;

        uint256 numoftokens = tokensprevious.length;

        address[] memory tokens = new address[](numoftokens);
        tokens = tokensprevious;

        for (uint256 i; i < numoftokens; ) {
            if (checkbalancebytoken(tokens[i], address(this)) != 0) {
                flag = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!flag) {
            soldprevafterupdate = true;
        }
    }

    /// @notice Will purchase/swap the updated index tokens in place of ptokens for the index contract
    /// @param amount The amount of p token that we want to use for purchase/swap index tokens
    /// @param slippageallowed The array of slippage percentages
    function rebalancepurchase(
        uint256 amount,
        uint256[] calldata slippageallowed
    ) external onlyOwner nonReentrant {
        require(soldprevafterupdate, "all tokens not sold yet");
        require(
            amount <= IERC20(ptoken).balanceOf(address(this)),
            "Amount should be less than balance"
        );

        _purchase(amount, slippageallowed);

        if (checkbalancebytoken(ptoken, address(this)) < 10) {
            updated = false;
            soldprevafterupdate = false;
        }
    }

    /// @notice This function will check the supplied inputs, creates a new index fund contract
    ///inside the indexInstanceArray
    /// @param _percentages The percentage array for the tokens
    /// @param _tokens The address array of the tokens
    /// @param _thresholdamount The minimum amount allowed for deposit in index contract
    /// @param _indexendingtime The time after the purchase till which we can't sell the tokens
    /// @param _ptoken The base token of the index contract
    /// @param _dex  The address of the dex contract
    /// @param _management The address of the management treasury contract
    /// @param _performance The address of the _performance treasury contract
    function initialize(
        uint16[] memory _percentages,
        address[] memory _tokens,
        uint256 _thresholdamount,
        uint256 _depositendingtime,
        uint256 _indexendingtime,
        address _ptoken,
        address _dex,
        address _management,
        address _performance
    ) external initializer {
        percentagescurrent = _percentages;
        tokenscurrent = _tokens;
        tokensprevious = _tokens;
        maxdeposit = _thresholdamount;
        depositendtime = block.timestamp + _depositendingtime;
        maturitytime = _indexendingtime;
        dex = _dex;
        ptoken = _ptoken;
        managementfeegetter = _management;
        performancefeegetter = _performance;
        _transferOwnership(msg.sender);
    }

    ///@notice will return the purchase token for the index contract
    function getpurchasetoken()
        external
        view
        onlyOwner
        returns (address _ptoken)
    {
        _ptoken = ptoken;
    }

    ///@notice function to  update the owner of the index contract
    ///@param newowner the address of the new owner
    function updateindexowner(address newowner) external onlyOwner {
        transferOwnership(newowner);
    }

    ///@notice function to approve token for staking contract
    ///@param _stakingContract The address of the staking contract
    ///@param token The address of the token that we want to stake
    function approvetoken(address _stakingContract, address token)
        public
        onlyOwner
    {
        uint256 balance;

        balance = IERC20(token).balanceOf(address(this));

        require(balance > 0, "amount is 0");
        //IERC(token).approve(_stakingContract, balance);
        SafeERC20.safeApprove(IERC20(token), _stakingContract, balance);
    }

    ///@notice function to call any contract function given target address and data
    ///@param target The address of the contract of which we want to call the function of
    ///@param data The call data of the function which we want to call
    function FunctionCall(address target, bytes memory data)
        external
        onlyOwner
    {
        Address.functionCall(target, data);
    }

    ///@notice function to approve and stake the purchased token
    ///@param token The address of the token that we want to unstake
    ///@param target The address of the staking contract from where we want to unstake our token
    ///@param data The call data of the unstake/withdraw
    function stakewithapprove(
        address token,
        address target,
        bytes memory data
    ) external onlyOwner purchasedcheck {
        require(!updated, "index is in updation state");
        approvetoken(target, token);
        Address.functionCall(target, data);
        tokenstaked[token] = true;
        staked = true;
    }

    ///@notice function to unstake the purchased tokens
    ///@param token The address of the token that we want to unstake
    ///@param target The address of the staking contract from where we want to unstake our token
    ///@param data The call data of the unstake/withdraw
    function unstake(
        address token,
        address target,
        bytes memory data
    ) external onlyOwner stakedcheck {
        Address.functionCall(target, data);
        tokenstaked[token] = false;

        uint256 numoftokens = tokenscurrent.length;
        address[] memory tokens = new address[](numoftokens);
        tokens = tokenscurrent;
        bool flag;
        for (uint256 i; i < numoftokens; ) {
            if (tokenstaked[tokens[i]] == true) {
                flag = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!flag) {
            staked = false;
        }
    }

    ///@notice it will set the performance fee treasury for the index contract
    ///@param _managementfeeaddress The address of the management fee treasury
    function setmanagementfeeaddress(address _managementfeeaddress)
        external
        onlyOwner
    {
        managementfeegetter = _managementfeeaddress;
    }

    ///@notice it will set the performance fee treasury for the index contract
    ///@param _performancefeeaddress The address of the performance fee treasury
    function setperformancefeeaddress(address _performancefeeaddress)
        external
        onlyOwner
    {
        performancefeegetter = _performancefeeaddress;
    }

    ///@notice it will return the total deposit in the index contract
    function gettotaldeposit() public view returns (uint256) {
        return totaldeposit;
    }

    ///@notice it will return the deposit of the user
    ///@param depositer the address of the depositor
    function getdepositbyuser(address depositer) public view returns (uint256) {
        return depositerbalances[depositer];
    }
}