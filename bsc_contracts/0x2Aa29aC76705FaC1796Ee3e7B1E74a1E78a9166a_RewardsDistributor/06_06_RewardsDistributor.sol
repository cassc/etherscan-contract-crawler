//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

pragma solidity ^0.8.17;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface IDividendDistributor {
    function deposit() external payable;

    function getUnpaidEarnings(
        address shareHolder
    ) external view returns (uint256);

    function getClaimedDividends(
        address shareHolder
    ) external view returns (uint256);

    function claimDividend(bool swapTo8Bit) external;

    function setRewardToken(address newToken) external;
}

interface Staking {
    function getTotalStaked(
        address _staker,
        uint256 _poolId
    ) external view returns (uint256);
}

contract RewardsDistributor is IDividendDistributor, Ownable {
    using SafeMath for uint256;

    IDEXRouter public router;
    address public token;
    IERC20 public rewardToken;
    Staking public stakingContract;
    address public tokenpair;

    struct Share {
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    mapping(address => uint256) public shareholderClaims;
    mapping(address => bool) public excluded;
    mapping(address => Share) public shares;
    mapping(address => uint) public costumeShares;
    mapping(address => uint) public lastBalance;
    mapping(address => uint) public lastRates;
    bool status = false;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public lastPoolBalance;
    uint public devShare;

    event updatedShares(uint256 indexed oldShares);

    constructor(
        address _token,
        address _rewardToken,
        address _stakingContract,
        address _router,
        address _lockContract
    ) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        //get token's pair
        IDEXFactory factory = IDEXFactory(router.factory());
        tokenpair = factory.getPair(_token, router.WETH());

        //set up contracts
        token = _token;
        rewardToken = IERC20(_rewardToken);
        stakingContract = Staking(_stakingContract);
        lastPoolBalance = IERC20(token).balanceOf(tokenpair);
        totalShares = IERC20(token).totalSupply();
        devShare = 20;

        //exclude lock and pair
        excludeFromRewards(tokenpair);
        excludeFromRewards(_lockContract);
        // excludeFromRewards(_lockWallet);
    }

    function excludeFromRewards(address holder) public onlyOwner {
        uint rewards = getUnpaidEarnings(holder);
        if (rewards > 0) {
            rewardToken.transfer(owner(), rewards);
        }
        uint oldShares = totalShares;
        totalShares -= getShares(holder);
        excluded[holder] = true;
        emit updatedShares(oldShares);
    }

    function setTotalShares(uint ts) external onlyOwner {
        totalShares = ts;
    }

    function setClaimingStatus(bool _status) external onlyOwner {
        status = _status;
    }

    function setDevShare(uint _percent) public onlyOwner {
        devShare = _percent;
    }

    function deposit() public payable {
        if (msg.value == 0) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = IDEXRouter(router).WETH();
        path[1] = address(rewardToken);
        uint256 beforeBalance = rewardToken.balanceOf(address(this));
        IDEXRouter(router).swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        //BTC Fees
        uint256 receivedTokens = rewardToken.balanceOf(address(this)) -
            beforeBalance;
        uint256 devBTC = (receivedTokens * devShare) / 100;
        rewardToken.transfer(owner(), devBTC);
        receivedTokens -= devBTC;

        uint poolBalance = IERC20(token).balanceOf(tokenpair);
        totalShares = totalShares.add(lastPoolBalance).sub(poolBalance);
        lastPoolBalance = poolBalance;

        //increase ratio
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(receivedTokens).div(totalShares)
        );
    }

    function distributeDividend(address shareholder, bool swapTo8Bit) internal {
        if (getShares(shareholder) == 0) {
            return;
        }
        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            if (swapTo8Bit) {
                uint256 eb = IERC20(token).balanceOf(address(this));
                SwapTo8Bit(amount);
                uint256 received8Bit = IERC20(token).balanceOf(address(this)) -
                    eb;
                IERC20(token).transfer(shareholder, received8Bit);
            } else {
                rewardToken.transfer(shareholder, amount);
            }
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            lastBalance[shareholder] = getShares(shareholder);
            lastRates[shareholder] = dividendsPerShare;

            shares[shareholder].totalExcluded = getCumulativeDividends(
                getShares(shareholder)
            );
        }
    }

    /// claim rewards
    function claimDividend(bool swapTo8Bit) external {
        distributeDividend(msg.sender, swapTo8Bit);
    }

    /// get total earnings (paid) of a share holder
    function getClaimedDividends(
        address shareHolder
    ) external view returns (uint256) {
        return shares[shareHolder].totalRealised;
    }

    /// get unpaid earnings(unpaid) of a share holder
    function getUnpaidEarnings(
        address shareholder
    ) public view returns (uint256) {
        if (getShares(shareholder) == 0) {
            return 0;
        }
        uint256 shareholderTotalDividends = getCumulativeDividends(
            getShares(shareholder)
        );
        uint256 shareholderTotalExcluded = getShares(shareholder)
            .mul(lastRates[shareholder])
            .div(dividendsPerShareAccuracyFactor);

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    //100 * 2 = 200
    //80 * 2.1 => 168
    //100 - 80 => 20 * 0.1 => 2

    /// get total dividends of a holder (claimed and unclaimed)
    function getCumulativeDividends(
        uint256 share
    ) internal view returns (uint256) {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    /// swap reward token to base token
    function SwapTo8Bit(uint256 btcAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(rewardToken);
        path[1] = IDEXRouter(router).WETH();
        path[2] = address(token);

        rewardToken.approve(address(router), ~uint256(0));
        IERC20(token).approve(address(router), ~uint256(0));

        IDEXRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            btcAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /// Get total staking amounts of holder, this is because we also want to reward stakers
    function getStakingAmounts(address holder) public view returns (uint256) {
        uint totalStaking;
        for (uint i = 0; i < 3; i++) {
            totalStaking += stakingContract.getTotalStaked(holder, i);
        }
        return totalStaking;
    }

    /// Get total staking amounts of holder + total staked
    function getShares(address holder) public view returns (uint256) {
        if (excluded[holder]) {
            return 0;
        }
        uint staking = getStakingAmounts(holder);
        return IERC20(token).balanceOf(holder) + staking;
    }

    /// withdraw stuck ETH in the contract, only owner
    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transfering ETH failed");
    }

    /// withdraw tokens from the contract, only owner
    function withdrawStuckTokens(address erc20_token) external onlyOwner {
        bool success = IERC20(erc20_token).transfer(
            msg.sender,
            IERC20(erc20_token).balanceOf(address(this))
        );
        require(success, "trasfering tokens failed!");
    }

    /// approve another address to spend contract tokens
    function approveSpenderForToken(
        address spender,
        address _token,
        uint _amount
    ) external onlyOwner {
        IERC20(_token).approve(spender, _amount);
    }

    /// change reward token
    function setRewardToken(address _newToken) public onlyOwner {
        rewardToken = IERC20(_newToken);
    }

    /// change base token
    function setToken(address _newToken) public onlyOwner {
        token = _newToken;
    }

    /// update rewards ratio upon receiving ether
    receive() external payable {
        if (msg.sender != address(router)) {
            deposit();
        }
    }
}