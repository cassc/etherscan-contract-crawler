// contracts/Pool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../ERC20/ERC20UpgradeableFromERC777Rewardable.sol";
import './../@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './../PropTokens/PropToken0.sol';
import './../LTVGuidelines.sol';
import './../PoolUtils/PoolUtils0.sol';
import './../PoolStaking/PoolStaking4.sol';
import './../PoolStakingRewards/PoolStakingRewards3.sol';
import './../HomeBoost/HomeBoost0.sol';
import './../CurveInterface/ICurvePool.sol';

import "./../@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
import './../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';
// import "../../node_modules/hardhat/console.sol";


contract Pool14 is Initializable, ERC20UpgradeableFromERC777Rewardable, IERC721ReceiverUpgradeable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    event Borrow(address indexed borrower, uint64 indexed property, uint64 indexed loan, uint128 amount, uint64 rate);
    event Repay(address indexed payer, uint64 indexed loan, uint128 principal, uint128 interest, uint128 principalPaid, uint128 interestPaid);

    struct Loan{
        uint256 loanId;
        address borrower;
        uint256 interestRate;
        uint256 principal;
        uint256 interestAccrued;
        uint256 timeLastPayment;
    }

    address servicer;

    // Address of the ERC-20 contract used as liquidity supply. USDC for now.
    address ERCAddress;

    address[] servicerAddresses;
    /* Adding a variable above this line (not reflected in Pool0) will cause contract storage conflicts */

    uint256 poolLent; // Deprecated in Pool14. Now always set to 0.
    uint256 poolBorrowed; // Deprecated in Pool14. Now always set to 0.
    mapping(address => uint256[]) userLoans;
    Loan[] loans;
    uint256 loanCount;

    uint constant servicerFeePercentage = 1000000;
    uint constant baseInterestPercentage = 1000000;
    uint constant curveK = 120000000;

    /* Pool1 variables introduced here */
    string private _name;
    string private _symbol;
    mapping(uint256 => uint256) loanToPropToken;
    address propTokenContractAddress;

    /* Pool2 variables introduced here */
    address LTVOracleAddress;

    /* Pool3 variables introduced here */
    address poolUtilsAddress;
    address baconCoinAddress;
    address poolStakingAddress;

    /* Pool 8 variables introduced here */
    address daoAddress;

    /*  Pool 9 variables introduced here
        storage for nonReentrant modifier
        modifier and variables could not be imported via inheratance given upgradability rules */
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    /* pool10 variables added here */
    address poolStakingRewardAddress; // contract responsible for determining the rewards for staking HOME

    /*  Pool 11 variables introduced here */
    bool airdropLocked;

    /* Pool 13 variables here */
    address homeBoostAddress;

    /* Pool 14 variables here */
    address curvePoolAddress;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /*****************************************************
    *       POOL STRUCTURE / UPGRADABILITY FUNCTIONS
    ******************************************************/
    function initializePool14(address _curvePoolAddress) public {
        require(msg.sender == servicer);

        curvePoolAddress = _curvePoolAddress;

        poolLent = 0; // poolLent is now deprecated
        poolBorrowed = 0; // poolBorrowed is now deprecated
    }


    function lockAirdorp() public {
        require(msg.sender == servicer);
        airdropLocked = true;
    }

    function passServicerRights(address _servicer) public {
        require(msg.sender == servicer);
        servicer = _servicer;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns(string memory) {
        return _symbol;
    }

    function decimals() public pure override returns(uint8) {
        return 6;
    }

    /*****************************************************
    *                GETTER FUNCTIONS
    ******************************************************/
    /**
    *   @dev Function getContractData() returns a lot of variables about the contract
    */
    function getContractData() public view returns (address, address, uint256, uint256, uint256, uint256) {
        return (
            servicer,
            ERCAddress,
            0,
            PoolUtils0(poolUtilsAddress).getPoolInterestAccrued(),
            totalSupply(),
            loanCount);
    }

    /*
    *   @dev Function getLoanCount() returns how many active loans there are
    */
    function getLoanCount() public view returns (uint256) {
        return loanCount;
    }

    /**
    *   @dev Function getSupplyableTokenAddress() returns the contract address of ERC20 this pool accepts (ususally USDC)
    */
    function getSupplyableTokenAddress() public view returns (address) {
        return ERCAddress;
    }

    /**
    *   @dev Function getServicerAddress() returns the address of this pool's servicer
    */
    function getServicerAddress() public view returns (address) {
        return servicer;
    }

    /**
    *   @dev Function getLoanDetails() returns an all the raw details about a loan
    *   @param loanId is the id for the loan we're looking up
    *   EDITED in pool1 to also return PropToken ID
    */
    function getLoanDetails(uint256 loanId) public view returns (uint256, address, uint256, uint256, uint256, uint256, uint256) {
        Loan memory loan = loans[loanId];
        uint256 interestAccrued = getLoanAccruedInterest(loanId);
        uint256 propTokenID = loanToPropToken[loanId];
        return (loan.loanId, loan.borrower, loan.interestRate, loan.principal, interestAccrued, loan.timeLastPayment, propTokenID);
    }

    /**
    *   @dev Function getLoanAccruedInterest() calculates and returns the amount of interest accrued on a given loan
    *   @param loanId is the id for the loan we're looking up
    */
    function getLoanAccruedInterest(uint256 loanId) public view returns (uint256) {
        Loan memory loan = loans[loanId];
        uint256 secondsSincePayment = block.timestamp.sub(loan.timeLastPayment);

        // 31,104,000 is number of seconds per year (360 * 24 * 60 * 60)
        uint256 interestPerSecond = loan.principal.mul(loan.interestRate).div(31_104_000);

        // Interest rates are stored in fixed point as numbers and not percentages.
        // For example, 12% is 12_000000 (12.0) not 0_120000 (0.12).
        // To do math with them, you often need to divide by 100 (100_000000) after.

        // Divide by 100 for interest rate adjustment and 1_000000 for fixed point adjustment.
        uint256 interestAccrued = interestPerSecond.mul(secondsSincePayment).div(100_000000);

        return interestAccrued.add(loan.interestAccrued);
    }


    /*****************************************************
    *                LENDING/BORROWING FUNCTIONS
    ******************************************************/

    function lendPool(
        uint256 amountUsdc,
        uint256 expectedHomeCoin
    ) public nonReentrant returns (uint256) {
        IERC20Upgradeable usdcCoin = IERC20Upgradeable(ERCAddress);
        usdcCoin.transferFrom(msg.sender, address(this), amountUsdc);
        usdcCoin.approve(curvePoolAddress, amountUsdc);
        
        ICurve curve = ICurve(curvePoolAddress);
        // 2 is USDC. 0 is HomeCoin. All of this is terrible.
        uint256 rez = curve.exchange_underlying(2, 0, amountUsdc, expectedHomeCoin, msg.sender);

        return rez;
    }


    /**
    *   @dev Function lend moves assets on the (probably usdc) contract to our own balance
    *   - Before calling: an approve(address _spender (proxy), uint256 _value (0xffff)) function call must be made on remote contract
    *   @param amount The amount of USDC to be transferred
    *   @return the amount of poolTokens created
    */
    function lend(
        uint256 amount
    ) public nonReentrant returns (uint256) {
        require(false, "lend is disabled. Use lendPool");
    }

    function redeemPool(
        uint256 amountHome,
        uint256 expectedUsdc
    ) public nonReentrant returns (uint256) {
        require(balanceOf(msg.sender) >= amountHome, "HOME balance insufficient");

        super._transfer(msg.sender, address(this), amountHome);
        super._approve(address(this), curvePoolAddress, amountHome);

        ICurve curve = ICurve(curvePoolAddress);
        // 2 is USDC. 0 is HomeCoin. All of this is terrible.
        uint256 rez = curve.exchange_underlying(0, 2, amountHome, expectedUsdc, msg.sender);

        return rez;
    }


    /**
    *   @dev Function redeem burns the sender's hcPool tokens and transfers the usdc back to them
    *   @param amount The amount of hc_pool to be redeemed
    */
    function redeem(
        uint256 amount
    ) public nonReentrant {
        require(false, "Use redeemPool");
    }

    /**
    *   @dev Function borrow creates a new Loan, moves the USDC to Borrower, and returns the loan ID and fixed Interest Rate
    *   - Also creates an origination fee for the Servicer in HC_Pool
    *   @param amount The size of the potential loan in (probably usdc).
    *   @param fixedInterestRate The rate for the loan.
    *   EDITED in pool1 to also require a PropToken
    *   EDITED in pool1 - borrower param was removed and msg.sender is new recepient of USDC
    *   EDITED in pool2 - propToken data is oulled and LTV of loan is required before loan can process
    *   EDITED in pool14 - now lends HOME instead of USDC
    */
    function borrow(uint256 amount, uint256 fixedInterestRate, uint256 propTokenId) public nonReentrant {
        // require this address is approved to transfer propToken
        require(PropToken0(propTokenContractAddress).getApproved(propTokenId) == address(this), "pool not approved to move egg");

        // [TODO] Consider upgrading PropToken to trust the PoolCore always so approval doesn't have to be done.
        // also require msg.sender is owner of token.
        require(PropToken0(propTokenContractAddress).ownerOf(propTokenId) == msg.sender, "msg.sender not egg owner");

        // [TODO] Change the interest rate calculation code. Remove the AMM.
        // check the requested interest rate is still available
        // uint256 fixedInterestRate = uint256(PoolUtils0(poolUtilsAddress).getInterestRate(amount));
        // require(fixedInterestRate <= maxRate, "interest rate no longer avail");

        // require the propToken approved has a lien value less than or equal to the requested loan size
        uint256 lienAmount = PropToken0(propTokenContractAddress).getLienValue(propTokenId);
        require(lienAmount >= amount, "loan larger that egg value");

        // require that LTV of propToken is less than LTV required by oracle
        uint256 LTVRequirement = LTVGuidelines(LTVOracleAddress).getMaxLTV();
        (, , uint256[] memory SeniorLiens, uint256 HomeValue, , ,) = PropToken0(propTokenContractAddress).getPropTokenData(propTokenId);
        for (uint i = 0; i < SeniorLiens.length; i++) {
            lienAmount = lienAmount.add(SeniorLiens[i]);
        }
        require(lienAmount.mul(100).div(HomeValue) < LTVRequirement, "LTV too high");

        // create new Loan
        loans.push(Loan(loanCount, msg.sender, fixedInterestRate, amount, 0, block.timestamp));

        // index the loan to the wallet
        userLoans[msg.sender].push(loanCount);

        // map new Loan ID to Token ID
        loanToPropToken[loanCount] = propTokenId;
        loanCount = loanCount.add(1);

        // take the propToken and hold it in the Pool
        PropToken0(propTokenContractAddress).safeTransferFrom(msg.sender, address(this), propTokenId);

        // Finally mint HOME. 99% to the borrower. 0.5% to servicer. 0.5% to DAO.
        super._mint(msg.sender, amount.mul(99).div(100));
        super._mint(servicer, amount.div(200));
        super._mint(daoAddress, amount.div(200));

        emit Borrow(msg.sender, uint64(propTokenId), uint64(loanCount.sub(1)), uint128(amount), uint64(fixedInterestRate));
    }

    /**
    *   @dev Function repay repays a specific loan
    *   - payment is first deducted from the interest then principal.
    *   - the servicer_fee is deducted from the interest repayment and servicer is compensated in hc_pool
    *   - repayer must have first approved fromsfers on behalf
    *   @param loanId The loan to be repayed
    *   @param amount The amount of the ERC20 token to repay the loan with
    *   EDITED in Pool1 - returns propToken when principal reaches 0
    *   EDITED in pool14 - repayments done in HOME instead of USDC
    */
    function repay(uint256 loanId, uint256 amount) public nonReentrant {
        require(amount > 0, "Can't make a 0 payment.");
        require(loanId < loanCount, "Loan to repay must exist.");

        Loan storage currentLoan = loans[loanId];

        uint256 currentInterest = getLoanAccruedInterest(loanId);
        uint256 currentPrincipal = currentLoan.principal;

        require(currentPrincipal > 0, "Loan must still be active.");

        // Default repayments amounts if the payment doesn't cover all the interest accrued.
        uint256 interestRepaid = amount;
        uint256 principalRepaid = 0;

        // if the payment amount is greater than accrued interest, deduct the rest from principal.
        if (currentInterest < amount) {
            interestRepaid = currentInterest;

            // If the principal payment is larger than the principal left on the loan,
            // payoff the whole loan and leave the return the rest of the payment.
            principalRepaid = amount.sub(interestRepaid);
            if (currentPrincipal < principalRepaid) {
                principalRepaid = currentPrincipal;
            }
        }

        // loan data is updated first before token movement.
        currentLoan.timeLastPayment = block.timestamp;
        currentLoan.principal = currentPrincipal.sub(principalRepaid);
        currentLoan.interestAccrued = currentInterest.sub(interestRepaid);

        // calculate how much of payment goes to servicer here.
        // 1% of the loan split between the servicer and DAO.
        uint256 servicerFee = servicerFeePercentage.mul(interestRepaid).div(currentLoan.interestRate);

        // Transfer HOME proportional to the payment and distribute
        super._transfer(msg.sender, servicer, servicerFee.div(2));
        super._transfer(msg.sender, daoAddress, servicerFee.div(2));

        // Send the remaining interest to the DAO for distribution to HOME holders
        super._transfer(msg.sender, daoAddress, interestRepaid.sub(servicerFee));

        // Burn HOME for the principal repaid to maintain the principal/HOME invariant.
        if (principalRepaid > 0) {
            super._burn(msg.sender, principalRepaid);
        }

        // [TODO] Think about the case where the prop token could be used to get multiple loans
        // [TODO] and there's a separate function to retrieve the token and tests that the balance is 0.
        // [TODO] For now, the prop token can only be used to get one loan. This makes extra draws impossible.

        // If the loan is paid off. Return the PropToken back to borrower.
        if (currentLoan.principal == 0) {
            PropToken0(propTokenContractAddress).safeTransferFrom(address(this), currentLoan.borrower, loanToPropToken[loanId]);
        }

        emit Repay(msg.sender, uint64(loanId), uint128(currentPrincipal), uint128(currentInterest), uint128(principalRepaid), uint128(interestRepaid));

    }

    /*****************************************************
    *                Staking FUNCTIONS
    ******************************************************/

    /**
    *   @dev Function stake transfers users HOME to the poolStaking contract
    */
    function stake(uint256 amount) public returns (bool) {
        require(balanceOf(msg.sender) >= amount, "not enough to stake");

        transfer(poolStakingAddress, amount);
        bool successfulStake = PoolStakingRewards3(poolStakingRewardAddress).stake(msg.sender, amount);
        require(successfulStake, "Stake failed");

        return successfulStake;
    }

    function boost(uint256 amount, uint16 level, bool autoRenew) public returns (bool){
        require(balanceOf(msg.sender) >= amount, "Not enough to boost");

        // Deposit the funds with the staking contract so they can still earn Bacon.
        // Send all tokens to the staking contract to hold them for the user.
        // Only stake a proportion so the boost earns the appropraite amount of Bacon.
        uint256 amountToStake = HomeBoost0(homeBoostAddress).getStakeAmount(level, amount);

        transfer(poolStakingAddress, amountToStake);
        bool successfulStake = PoolStakingRewards3(poolStakingRewardAddress).stake(msg.sender, amountToStake);

        // Send any remaining unstaked amounts to the boost contract for holding.
        if (amountToStake < amount) {
            transfer(homeBoostAddress, amount - amountToStake);
        }

        // Create the boost
        bool successfulBoost = HomeBoost0(homeBoostAddress).mint(msg.sender, amount, level, autoRenew);

        require(successfulStake && successfulBoost, "Boost failed");

        return successfulStake && successfulBoost;
    }

    /**
    *   @dev Function getVersion returns current upgraded version
    */
    function getVersion() public pure returns (uint) {
        return 14;
    }

    function onERC721Received(address, address, uint256, bytes memory ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function claimRewards() public returns (uint256) {
        // 1% Rewards [div by 100]
        uint256 unstakedRewards = super.getAndClearReward(msg.sender).div(100);

        uint256 stakedRewards = PoolStakingRewards3(poolStakingRewardAddress).getAndClearReward(msg.sender).div(100);

        uint256 rewards = unstakedRewards + stakedRewards;

        super._transfer(daoAddress, msg.sender, rewards);

        return rewards;
    }

    function transferBoostRewards(address wallet, uint256 amount) public {
        require(msg.sender == homeBoostAddress, "invalid sender");

        super._transfer(daoAddress, wallet, amount);
    }

    function transferUSDC(address wallet, uint256 amount) public {
        require(msg.sender == servicer, "invalid sender");
        IERC20Upgradeable usdcCoin = IERC20Upgradeable(ERCAddress);

        usdcCoin.transfer(wallet, amount);
    }

    /**
    * @dev Function burn burns HOME
    * @param amount is the amount of HOME to burn
    */
    function burn(uint256 amount) public {
        super._burn(msg.sender, amount);
    }
}