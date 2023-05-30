//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./IStrat.sol";
import "./IVault.sol";
import "./DividendToken.sol";
import "./Timelock.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract Vault is Ownable, Pausable, DividendToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Detailed;

    IERC20Detailed public underlying;
    IStrat public strat;
    address public harvester;
    uint constant MAX_FEE = 10000;
    uint public performanceFee = 0; // 0% of profit
    // if depositLimit = 0 then there is no deposit limit
    uint public depositLimit;
    uint public lastDistribution;
    Timelock public timelock;

    modifier onlyHarvester {
        require(msg.sender == harvester);
        _;
    }

    constructor(IERC20Detailed underlying_, IERC20 reward_, address harvester_, string memory name_, string memory symbol_)
    DividendToken(reward_, name_, symbol_, underlying_.decimals())
    {
        underlying = underlying_;
        harvester = harvester_;
        depositLimit = 20000 * (10**underlying_.decimals()); // 20k initial deposit limit
        timelock = new Timelock(msg.sender, 2 days);
        _pause(); // paused until a strategy is connected
    }

    function calcTotalValue() public returns (uint underlyingAmount) {
        return strat.calcTotalValue();
    }

    function deposit(uint amount) public whenNotPaused {
        if(depositLimit > 0) { // if deposit limit is 0, then there is no deposit limit
            require(totalSupply().add(amount) <= depositLimit);
        }
        underlying.safeTransferFrom(msg.sender, address(strat), amount);
        strat.invest();
        _mint(msg.sender, amount);
    }

    function withdraw(uint amount) public {
        _burn(msg.sender, amount);
        strat.divest(amount);
        underlying.safeTransfer(msg.sender, amount);
    }

    function underlyingYield() public returns (uint) {
        return calcTotalValue().sub(totalSupply());
    }

    function unclaimedProfit(address user) public view returns (uint256) {
        return withdrawableDividendOf(user);
    }

    function claim() public {
        withdrawDividend(msg.sender);
    }

    // Used to claim on behalf of certain contracts e.g. Uniswap pool
    function claimOnBehalf(address recipient) public {
        require(msg.sender == harvester || msg.sender == owner());
        withdrawDividend(recipient);
    }

    function pauseDeposits(bool trigger) public onlyOwner {
        if(trigger) _pause();
        else _unpause();
    }

    function changeHarvester(address harvester_) public onlyOwner {
        harvester = harvester_;
    }

    function changePerformanceFee(uint fee_) public onlyOwner {
        require(fee_ <= MAX_FEE);
        performanceFee = fee_;
    }

    // The owner has to wait 2 days to confirm changing the strat.
    // This protects users from an upgrade to a malicious strategy
    // Users must watch the timelock contract on Etherscan for any transactions
    function setStrat(IStrat strat_, bool force) public {
        if(address(strat) != address(0)) {
            require(msg.sender == address(timelock));
            uint prevTotalValue = strat.calcTotalValue();
            strat.divest(prevTotalValue);
            underlying.safeTransfer(address(strat_), underlying.balanceOf(address(this)));
            strat_.invest();
            if(!force) {
                require(strat_.calcTotalValue() >= prevTotalValue);
                require(strat.calcTotalValue() == 0);
            }
        } else {
            require(msg.sender == owner());
            _unpause();
        }
        strat = strat_;
    }

    // if limit == 0 then there is no deposit limit
    function setDepositLimit(uint limit) public onlyOwner {
        depositLimit = limit;
    }

    // Any tokens (other than the target) that are sent here by mistake are recoverable by the owner
    function sweep(address _token) external onlyOwner {
        require(_token != address(target));
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function harvest(uint amount) public onlyHarvester returns (uint afterFee) {
        require(amount <= underlyingYield(), "Amount larger than generated yield");
        strat.divest(amount);
        if(performanceFee > 0) {
            uint fee = amount.mul(performanceFee).div(MAX_FEE);
            afterFee = amount.sub(fee);
            underlying.safeTransfer(owner(), fee);
        } else {
            afterFee = amount;
        }
        underlying.safeTransfer(harvester, afterFee);
    }

    function distribute(uint amount) public onlyHarvester {
        distributeDividends(amount);
        lastDistribution = block.timestamp;
    }

}