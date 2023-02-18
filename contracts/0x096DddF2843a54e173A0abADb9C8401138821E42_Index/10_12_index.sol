// SPDX-License-Identifier:MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
import "./interfaces/IIndexStruct.sol";

interface IDexAggregator {
    function bestrateswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
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

contract Index is Ownable, Initializable, ReentrancyGuard, IndexStruct {
    using SafeERC20 for IERC20;

    ///@notice Stores the current state of the index contract
    State public state;

    ///@notice structure that stores the fee information(treasury addresses and fee amounts)
    feeData private FeeData;

    ///@notice stores address of the dex aggregator contract
    address public dex;

    ///@notice stores the address of the p token
    address public ptoken;

    ///@notice stores the address of the management treasury contract
    address public managementfeegetter;

    ///@notice stores the address of the performance treasury contract
    address public performancefeegetter;

    ///@notice stores the maximum ptoken deposit allowed in the contract
    uint256 public maxdeposit;

    ///@notice stores the total number withdrawals happened
    uint256 public totalwithdrawals;

    /// @notice stores the token holding time
    uint256 public maturitytime;

    /// @notice stores the ending time for deposit
    uint256 public depositendtime;

    /// @notice stores the starting time of the index
    uint256 public startingtime;

    /// @notice stores the total ptoken deposit by the user
    uint256 public totaldeposit;

    ///@notice stores the total ptoken deposit by the user after deducting the management fees
    uint256 public totaldepositafterfee;

    ///@notice stores the total ptoken after sell
    uint256 public totalptokenaftersell;

    ///@notice stores the addresses of the depositors
    address[] public depositors;

    ///@notice stores the addresses of the reward tokens
    address[] public rewardtokens;

    ///@notice stores the addresses of the current tokens
    address[] public tokenscurrent;

    ///@notice stores the percentage fo the current tokens
    uint16[] public percentagescurrent;

    ///@notice stores the percentage fo the previous tokens
    uint16[] public percentagesprevious;

    ///@notice stores the current amounts of the tokens after the complete purchase
    uint[] public tokenscurrentamount;

    ///@notice stores  the previous amount of the token
    uint[] public tokenspreviousamount;

    ///@notice stores the addresses of the previous tokens
    address[] public tokensprevious;

    ///@notice mapping to store staking state of the tokens
    mapping(address => bool) tokenstaked;

    ///@notice mapping to store user data
    mapping(address => Depositor) Users;

    event depositEvent(uint amount, address depositor);

    event purchaseEvent(
        uint amountin,
        uint[] amountout,
        address ptoken,
        address[] currenttokens
    );

    event updateIndexFundEvent(
        address[] currenttokens,
        uint16[] percentagescurrent,
        address[] previoustokens,
        uint16[] percentagesprevious
    );

    event rebalanceSellEvent(
        uint[] amountsin,
        uint[] amountsout,
        uint amountoutsum,
        address[] previoustokens,
        address ptoken
    );

    event rebalancePurchaseEvent(
        uint amountin,
        uint[] amountout,
        address ptoken,
        address[] currentokens
    );

    event sellEvent(
        uint[] amountsin,
        uint[] amountsout,
        uint amountoutsum,
        address[] currenttokens,
        address ptoken
    );

    event distributebeforepurchaseEvent(uint numberofwithdrawers);

    event distributeEvent(uint numberofwithdrawers);

    ///@notice modifier to check purchase
    modifier purchasedCheck() {
        if (!state.purchased) revert("Not purchased ");
        _;
    }
    ///@notice modifier to check updation
    modifier updatedCheck() {
        if (!state.updated) revert("Not updated");
        require(state.updated, "Not purchased");
        _;
    }
    /// @notice modifier to check selling
    modifier soldCheck() {
        require(state.sold, "Not sold yet");
        _;
    } ///@notice modifier to check the staked state
    modifier stakedCheck() {
        require(state.staked, "Not staked yet");
        _;
    }

    ///@notice it will add reward token address in the rewardtokens address array
    ///@param token the address of the reward token
    function addrewardtokens(address token) external onlyOwner {
        rewardtokens.push(token);
    }

    ///@notice it will return the states of the index contract
    function returnstates()
        external
        view
        onlyOwner
        returns (State memory currentstate)
    {
        currentstate = state;
    }

    /// @notice This function will update the index configuration with new percentages and tokens
    /// @param _percentages The percentage array for the tokens
    /// @param _tokens The address array of the tokens
    function udpateindex(
        uint16[] memory _percentages,
        address[] memory _tokens
    ) external onlyOwner purchasedCheck {
        tokensprevious = tokenscurrent;
        tokenscurrent = _tokens;
        percentagesprevious = percentagescurrent;
        percentagescurrent = _percentages;
        state.updated = true;
        emit updateIndexFundEvent(
            tokenscurrent,
            percentagescurrent,
            tokensprevious,
            percentagesprevious
        );
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
    function getPreviousTokensInfo()
        external
        view
        returns (address[] memory, uint16[] memory)
    {
        return (tokensprevious, percentagesprevious);
    }

    ///@notice will be used to deposit the amount of ptoken in the contract
    ///@param amount the total amount deposited by the user on the contract
    ///@param depositer the address of the depositer
    function deposit(
        uint256 amount,
        address depositer
    ) external onlyOwner nonReentrant {
        require(block.timestamp <= depositendtime, "depost time limit passed");
        require(
            totaldeposit + amount <= maxdeposit,
            "amount should be lesser than maxdeposit"
        );

        uint256 fees = (FeeData.managementFeeBasisPoint * amount) / 10_000;
        Users[depositer].amount += amount;
        totaldeposit += amount;
        totaldepositafterfee += amount - fees;
        IERC20(ptoken).safeTransfer(FeeData.managementFeeAddress, fees);

        if (Users[depositer].status == false) {
            depositors.push(depositer);
            Users[depositer].status = true;
        }

        emit depositEvent(amount, depositer);
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
    function tokensbalances(
        address[] memory _tokens
    ) internal view returns (uint256[] memory) {
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
    function _purchase(
        uint256 _amount,
        uint256[] calldata _slippageallowed
    ) internal returns (uint[] memory amounts) {
        uint amount;
        IERC20(ptoken).safeIncreaseAllowance(dex, _amount);
        uint256 numoftokens = tokenscurrent.length;
        uint16[] memory percentages = new uint16[](numoftokens);
        address[] memory tokens = new address[](numoftokens);
        amounts = new uint[](numoftokens);
        tokens = tokenscurrent;
        percentages = percentagescurrent;

        for (uint256 i; i < numoftokens; i++) {
            amount = IDexAggregator(dex).bestrateswap(
                ptoken,
                tokens[i],
                ((_amount * percentagescurrent[i]) / 10000),
                address(this),
                _slippageallowed[i]
            );
            amounts[i] = amount;
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
    ) internal returns (uint[] memory amounts, uint sum) {
        uint256 numoftokens = _tokens.length;

        address[] memory tokens = new address[](numoftokens);
        amounts = new uint[](numoftokens);
        tokens = _tokens;
        uint amount;
        for (uint256 i; i < numoftokens; i++) {
            IERC20(tokens[i]).safeIncreaseAllowance(dex, _amounts[i]);
            amount = IDexAggregator(dex).bestrateswap(
                tokens[i],
                ptoken,
                _amounts[i],
                address(this),
                _slippageallowed[i]
            );
            sum += amount;
            amounts[i] = amount;
        }
    }

    /// @notice Will purchase/swap the index tokens in place of ptokens for the index contract
    /// @param _amount The amount of p token that we want to use for purchase/swap index tokens
    /// @param _slippageallowed The array of slippage percentages
    function purchase(
        uint256 _amount,
        uint256[] calldata _slippageallowed
    ) external onlyOwner {
        console.log("time", block.timestamp, depositendtime);
        require(
            block.timestamp > depositendtime,
            "deposit period,no purchase allowed"
        );
        require(!state.purchased, "already purchased");
        require(
            _amount <= checkbalancebytoken(ptoken, address(this)),
            "Amount should be less than balance"
        );

        uint[] memory amounts;

        amounts = _purchase(_amount, _slippageallowed);

        if (checkbalancebytoken(ptoken, address(this)) < 10) {
            state.purchased = true;
            maturitytime += block.timestamp;
        }

        emit purchaseEvent(_amount, amounts, ptoken, tokenscurrent);
    }

    ///@notice main sell function with required checks for selling tokens
    /// @param _amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    /// @param _slippageallowed The array of slippage percentages
    function sell(
        uint256[] calldata _amounts,
        uint256[] calldata _slippageallowed
    ) external onlyOwner purchasedCheck {
        require(!state.staked, "staked state");
        require(!state.updated, "updated state");
        require(block.timestamp > maturitytime, "The index has not ended yet");
        require(
            _amounts.length == _slippageallowed.length &&
                _amounts.length == tokenscurrent.length,
            "uneven array length"
        );
        uint purchasetokensum;
        uint[] memory amounts;

        (amounts, purchasetokensum) = _sell(
            tokenscurrent,
            _amounts,
            _slippageallowed
        );

        bool flag;

        uint256 num_current_tokens = tokenscurrent.length;
        address[] memory tokens = new address[](num_current_tokens);
        tokens = tokenscurrent;

        for (uint256 i; i < num_current_tokens; ++i) {
            if (checkbalancebytoken(tokens[i], address(this)) != 0) {
                flag = true;

                break;
            }
        }
        if (!flag) {
            state.sold = true;
            totalptokenaftersell = checkbalancebytoken(ptoken, address(this));
        }

        emit sellEvent(_amounts, amounts, purchasetokensum, tokens, ptoken);
    }

    ///@notice it will sell/swap reward tokens for ptokens
    /// @param _amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    /// @param _slippageallowed The array of slippage percentages
    function sellrewardtokens(
        uint256[] calldata _amounts,
        uint256[] calldata _slippageallowed
    ) external onlyOwner purchasedCheck {
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
            state.rewardtokensold = true;
        }
    }

    ///@notice it will distribute ptokens according to users deposit
    function distributeamount(
        uint numofwithdrawers
    ) external onlyOwner soldCheck {
        uint256 lengthd = depositors.length;

        require(
            numofwithdrawers + totalwithdrawals <= lengthd,
            "Greater than number of withdrawers"
        );
        uint256 _totalbalance = totalptokenaftersell;

        uint256 percentage;

        address[] memory _depositors = new address[](lengthd);
        _depositors = depositors;
        uint256 i = totalwithdrawals;

        for (; i < numofwithdrawers + totalwithdrawals; i++) {
            percentage =
                (Users[depositors[i]].amount * 10000000000) /
                totaldeposit;
            IERC20(ptoken).safeTransfer(
                _depositors[i],
                (percentage * _totalbalance) / 10000000000
            );
        }
        totalwithdrawals = i;
    }

    ///@notice it will distribute ptokens according to users deposit
    function performaneFeesTransfer() external onlyOwner soldCheck {
        uint256 _totaldeposit = totaldeposit;
        uint256 _totalbalance = checkbalancebytoken(ptoken, address(this));

        if (_totalbalance > _totaldeposit) {
            uint256 interest = _totalbalance - _totaldeposit;
            uint256 fees = (interest * FeeData.performanceFeeBasisPoint) /
                10_000;
            IERC20(ptoken).safeTransfer(performancefeegetter, fees);
            _totalbalance -= fees;
        }
        state.performancefeestransfer = true;
    }

    /// @notice Will sell/swap the previous index tokens for ptokens for the index contract
    /// @param _amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    /// @param slippageallowed The array of slippage percentages
    function rebalancesell(
        uint256[] calldata _amounts,
        uint256[] calldata slippageallowed
    ) external onlyOwner {
        require(
            block.timestamp > depositendtime,
            "time period should be between deposit and ending"
        );
        require(
            _amounts.length == slippageallowed.length &&
                _amounts.length == tokensprevious.length,
            "uneven array length"
        );
        require(state.updated, "not updated");
        uint purchasetokensum;
        uint[] memory amounts;

        (amounts, purchasetokensum) = _sell(
            tokensprevious,
            _amounts,
            slippageallowed
        );
        bool flag;

        uint256 numoftokens = tokensprevious.length;

        address[] memory tokens = new address[](numoftokens);
        tokens = tokensprevious;

        for (uint256 i; i < numoftokens; i++) {
            if (checkbalancebytoken(tokens[i], address(this)) != 0) {
                flag = true;
                break;
            }
        }
        if (!flag) {
            state.soldprevafterupdate = true;
        }
        emit rebalanceSellEvent(
            _amounts,
            amounts,
            purchasetokensum,
            tokensprevious,
            ptoken
        );
    }

    /// @notice Will purchase/swap the updated index tokens in place of ptokens for the index contract
    /// @param amount The amount of p token that we want to use for purchase/swap index tokens
    /// @param slippageallowed The array of slippage percentages
    function rebalancepurchase(
        uint256 amount,
        uint256[] calldata slippageallowed
    ) external onlyOwner {
        require(state.soldprevafterupdate, "all tokens not sold yet");
        require(
            amount <= IERC20(ptoken).balanceOf(address(this)),
            "Amount should be less than balance"
        );
        uint[] memory amounts;

        amounts = _purchase(amount, slippageallowed);
        if (checkbalancebytoken(ptoken, address(this)) < 10) {
            state.updated = false;
            state.soldprevafterupdate = false;
        }
        emit rebalancePurchaseEvent(amount, amounts, ptoken, tokenscurrent);
    }

    /// @notice This function will check the supplied inputs, creates a new index fund contract
    ///inside the indexInstanceArray
    /// @param _percentages The percentage array for the tokens
    /// @param _tokens The address array of the tokens
    /// @param _thresholdamount The minimum amount allowed for deposit in index contract
    /// @param _indexendingtime The time after the purchase till which we can't sell the tokens
    /// @param _ptoken The base token of the index contract
    /// @param _dex  The address of the dex contract
    function initialize(
        uint16[] memory _percentages,
        address[] memory _tokens,
        uint256 _thresholdamount,
        uint256 _depositendingtime,
        uint256 _indexendingtime,
        address _ptoken,
        address _dex,
        feeData memory _feedata
    ) external initializer {
        percentagescurrent = _percentages;
        tokenscurrent = _tokens;
        tokensprevious = _tokens;
        maxdeposit = _thresholdamount;
        depositendtime = block.timestamp + _depositendingtime;
        maturitytime = _indexendingtime;
        dex = _dex;
        ptoken = _ptoken;
        FeeData = _feedata;
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
    function approvetoken(
        address _stakingContract,
        address token
    ) public onlyOwner {
        uint256 balance;

        balance = checkbalancebytoken(token, address(this));

        require(balance > 0, "amount is 0");
        //IERC(token).approve(_stakingContract, balance);
        IERC20(token).safeApprove(_stakingContract, balance);
    }

    ///@notice function to call any contract function given target address and data
    ///@param target The address of the contract of which we want to call the function of
    ///@param data The call data of the function which we want to call
    function FunctionCall(
        address target,
        bytes memory data
    ) external onlyOwner {
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
    ) external onlyOwner purchasedCheck {
        require(!state.updated, "index is in updation state");
        approvetoken(target, token);
        Address.functionCall(target, data);
        tokenstaked[token] = true;
        state.staked = true;
    }

    ///@notice function to unstake the purchased tokens
    ///@param token The address of the token that we want to unstake
    ///@param target The address of the staking contract from where we want to unstake our token
    ///@param data The call data of the unstake/withdraw
    function unstake(
        address token,
        address target,
        bytes memory data
    ) external onlyOwner stakedCheck {
        Address.functionCall(target, data);
        tokenstaked[token] = false;

        uint256 numoftokens = tokenscurrent.length;
        address[] memory tokens = new address[](numoftokens);
        tokens = tokenscurrent;
        bool flag;
        for (uint256 i; i < numoftokens; ++i) {
            if (tokenstaked[tokens[i]] == true) {
                flag = true;
                break;
            }
        }
        if (!flag) {
            state.staked = false;
        }
    }

    ///@notice it will set the performance fee treasury for the index contract
    ///@param _managementfeeaddress The address of the management fee treasury
    function setmanagementfeeaddress(
        address _managementfeeaddress
    ) external onlyOwner {
        managementfeegetter = _managementfeeaddress;
    }

    ///@notice it will set the performance fee treasury for the index contract
    ///@param _performancefeeaddress The address of the performance fee treasury
    function setperformancefeeaddress(
        address _performancefeeaddress
    ) external onlyOwner {
        performancefeegetter = _performancefeeaddress;
    }

    ///@notice it will return the total deposit in the index contract
    function gettotaldeposit() public view returns (uint256) {
        return totaldeposit;
    }

    ///@notice it will return the deposit of the user
    ///@param depositer the address of the depositor
    function getdepositbyuser(address depositer) public view returns (uint256) {
        return Users[depositer].amount;
    }

    ///@notice it will distribute the to the number of withdrawers before purchase state
    ///@param numofwithdrawers the number of withdrawers that we want to distribute before purchase
    function distributebeforepurchase(
        uint numofwithdrawers
    ) external onlyOwner {
        uint256 lengthd = depositors.length;

        require(
            numofwithdrawers + totalwithdrawals <= lengthd,
            "Greater than number of withdrawers"
        );

        uint256 _totalbalance = totaldepositafterfee;

        uint256 percentage;

        address[] memory _depositors = new address[](lengthd);

        _depositors = depositors;

        uint256 i = totalwithdrawals;

        for (; i < numofwithdrawers + totalwithdrawals; i++) {
            percentage =
                (Users[depositors[i]].amount * 10000000000) /
                totaldeposit;

            IERC20(ptoken).safeTransfer(
                _depositors[i],
                (percentage * _totalbalance) / 10000000000
            );
        }

        totalwithdrawals = i;
        emit distributebeforepurchaseEvent(numofwithdrawers);
    }

    ///@notice it will update the dex address
    ///@param _dex the address of the dex
    function updatedex(address _dex) external onlyOwner {
        dex = _dex;
    }

    ///@notice the number of users left to withdraw
    function userlefttowithdraw() external view returns (uint users) {
        return depositors.length - totalwithdrawals;
    }

    ///@notice the number of users left to withdraw
    function updatepurchasestate() external onlyOwner {
        maturitytime += block.timestamp;
        state.purchased = true;
    }

    ///@notice udpates the updated state
    function updatetokenupdatestate() external onlyOwner {
        state.updated = true;
    }

    ///@notice updates rebalance purchase state
    function updaterebalancepurchasestate() external onlyOwner {
        state.updated = false;
        state.soldprevafterupdate = false;
    }

    ///@notice updates sell state t
    function updatesellstate() external onlyOwner {
        totalptokenaftersell = checkbalancebytoken(ptoken, address(this));
        state.sold = true;
    }

    ///@notice udpates the rebalance sell state
    function updaterebalancesellstate() external onlyOwner {
        state.soldprevafterupdate = true;
    }

    ///@notice returns balance of the caller address given token address
    ///@param _token the adddress of the token of which we want to check balance of
    ///@param _whose the address of which we want to check balance of
    function checkbalancebytoken(
        address _token,
        address _whose
    ) internal view returns (uint256) {
        return IERC20(_token).balanceOf(_whose);
    }
}