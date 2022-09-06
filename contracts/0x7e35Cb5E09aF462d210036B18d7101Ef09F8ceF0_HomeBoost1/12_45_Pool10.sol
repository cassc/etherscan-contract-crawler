// contracts/Pool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../ERC20/ERC20UpgradeableFromERC777.sol";
import '../@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './../PropTokens/PropToken0.sol';
import './../LTVGuidelines.sol';
import './../PoolUtils/PoolUtils0.sol';
import './../PoolStaking/PoolStaking0.sol';
import './../PoolStakingRewards/PoolStakingRewards0.sol';

import "../@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract Pool10 is Initializable, ERC20UpgradeableFromERC777, IERC721ReceiverUpgradeable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    struct Loan{
        uint256 loanId;
        address borrower;
        uint256 interestRate;
        uint256 principal;
        uint256 interestAccrued;
        uint256 timeLastPayment;
    }

    address servicer;
    address ERCAddress;
    address[] servicerAddresses;
    /* Adding a variable above this line (not reflected in Pool0) will cause contract storage conflicts */

    uint256 poolLent;
    uint256 poolBorrowed;
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
    address poolStakingRewardAddress; // contract responsible for determining the rewards for staking bHome

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

    function initializePool9() public {
        require(msg.sender == servicer, "unapproved sender");
        _status = _NOT_ENTERED;
    }

    /*****************************************************
    *       POOL STRUCTURE / UPGRADABILITY FUNCTIONS
    ******************************************************/

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
        return (servicer, ERCAddress, poolLent, (poolLent + PoolUtils0(poolUtilsAddress).getPoolInterestAccrued()), poolBorrowed, loanCount);
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
        //temp interestAccrued calculation because this is a read function
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

        uint256 interestPerSecond = loan.principal.mul(loan.interestRate).div(31104000);
        uint256 interestAccrued = interestPerSecond.mul(secondsSincePayment).div(100000000);
        return interestAccrued.add(loan.interestAccrued);
    }   


    /*****************************************************
    *                LENDING/BORROWING FUNCTIONS
    ******************************************************/

    /*
    *   @dev Function getProportionalPoolTokens calculates how many new hc_pool tokens to mint when value is added to the pool based on proportional value
    *   @param recepient The address of the wallet receiving the newly minted hc_pool tokens
    *   @param amount The amount to be minted
    */
    function getProportionalPoolTokens(uint256 amount) private view returns (uint256) {
        //check if this is first deposit
        if (poolLent == 0) {
            return amount;
        } else {
            //Calculate proportional to total value
            uint256 new_hc_pool = amount.mul(super.totalSupply()).div(poolLent);
            return new_hc_pool;
        }
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
        //USDC on Ropsten only right now
        IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);
        uint256 newTokensMinted = getProportionalPoolTokens(amount);
        poolLent = poolLent.add(amount);

        super._mint(msg.sender, newTokensMinted);

        return newTokensMinted;
    }

    /**
    *   @dev Function redeem burns the sender's hcPool tokens and transfers the usdc back to them
    *   @param amount The amount of hc_pool to be redeemed
    */
    function redeem(
        uint256 amount
    ) public nonReentrant {
        //check to see if sender has enough hc_pool to redeem
        require(balanceOf(msg.sender) >= amount);

        //check to make sure there is liquidity available in the pool to withdraw
        uint256 tokenPrice = poolLent.mul(1000000).div(super.totalSupply());
        uint256 erc20ValueOfTokens = amount.mul(tokenPrice).div(1000000);
        require(erc20ValueOfTokens <= (poolLent - poolBorrowed));

        //burn hcPool first
        super._burn(msg.sender, amount);
        poolLent = poolLent.sub(erc20ValueOfTokens);
        IERC20Upgradeable(ERCAddress).transfer(msg.sender, erc20ValueOfTokens);
    }

    /**
    *   @dev Function borrow creates a new Loan, moves the USDC to Borrower, and returns the loan ID and fixed Interest Rate
    *   - Also creates an origination fee for the Servicer in HC_Pool
    *   @param amount The size of the potential loan in (probably usdc).
    *   @param maxRate The size of the potential loan in (probably usdc).
    *   EDITED in pool1 to also require a PropToken
    *   EDITED in pool1 - borrower param was removed and msg.sender is new recepient of USDC
    *   EDITED in pool2 - propToken data is oulled and LTV of loan is required before loan can process
    */
    function borrow(uint256 amount, uint256 maxRate, uint256 propTokenId) public nonReentrant {
        //for v2 require this address is approved to transfer propToken 
        require(PropToken0(propTokenContractAddress).getApproved(propTokenId) == address(this), "pool not approved to move egg");
        //also require msg.sender is owner of token
        require(PropToken0(propTokenContractAddress).ownerOf(propTokenId) == msg.sender, "msg.sender not egg owner");

        //check the requested interest rate is still available
        uint256 fixedInterestRate = uint256(PoolUtils0(poolUtilsAddress).getInterestRate(amount));
        require(fixedInterestRate <= maxRate, "interest rate no longer avail");

        //require the propToken approved has a lien value less than or equal to the requested loan size
        uint256 lienAmount = PropToken0(propTokenContractAddress).getLienValue(propTokenId);
        require(lienAmount >= amount, "loan larger that egg value");

        //require that LTV of propToken is less than LTV required by oracle
        uint256 LTVRequirement = LTVGuidelines(LTVOracleAddress).getMaxLTV();
        (, , uint256[] memory SeniorLiens, uint256 HomeValue, , ,) = PropToken0(propTokenContractAddress).getPropTokenData(propTokenId);
        for (uint i = 0; i < SeniorLiens.length; i++) {
            lienAmount = lienAmount.add(SeniorLiens[i]);
        }
        require(lienAmount.mul(100).div(HomeValue) < LTVRequirement, "LTV too high");


        //first take the propToken
        PropToken0(propTokenContractAddress).safeTransferFrom(msg.sender, address(this), propTokenId);

        //create new Loan
        Loan memory newLoan = Loan(loanCount, msg.sender, fixedInterestRate, amount, 0, block.timestamp);
        loans.push(newLoan);
        userLoans[msg.sender].push(loanCount);

        //map new loanID to Token ID
        loanToPropToken[loanCount] = propTokenId;

        //update system variables
        loanCount = loanCount.add(1);
        poolBorrowed = poolBorrowed.add(amount);

        //finally move the USDC
        IERC20Upgradeable(ERCAddress).transfer(msg.sender, amount);

        //then mint HC_Pool for the servicer (fixed 0.5% origination is better than standard 2.5%)
        uint256 newTokensMinted = getProportionalPoolTokens(amount.div(200));
        super._mint(servicer, newTokensMinted);
        super._mint(daoAddress, newTokensMinted);
    }

    /**
    *   @dev Function repay repays a specific loan
    *   - payment is first deducted from the interest then principal.
    *   - the servicer_fee is deducted from the interest repayment and servicer is compensated in hc_pool
    *   - repayer must have first approved fromsfers on behalf
    *   @param loanId The loan to be repayed
    *   @param amount The amount of the ERC20 token to repay the loan with
    *   EDITED - Pool1 returns propToken when principal reaches 0
    */

    function repay(uint256 loanId, uint256 amount) public nonReentrant {        
        //interestAmountRepayed keeps track of how much of the loan was returned to the pool to calculate servicer fee(treated as cash investment)
        uint256 interestAmountRepayed = amount;

        uint256 currentInterest = getLoanAccruedInterest(loanId);
        if(currentInterest > amount) {
            //if the payment is less than the interest accrued on the loan, just deduct amount from interest
            //deduct amount FIRST (to make sure they have available balance), then reduce loan amount
            IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);
            loans[loanId].interestAccrued = currentInterest.sub(amount);
        } else {
            //if the amount borrow is repaying is greater than interest accrued, deduct the rest from principal
            interestAmountRepayed = currentInterest;
            uint256 amountAfterInterest = amount.sub(currentInterest);

            if(loans[loanId].principal > amountAfterInterest) {
                //deduct amount from Borrower and reduce the principal
                IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), amount);
                //return the repayed principal to the 'borrowable' amount
                poolBorrowed = poolBorrowed.sub(amountAfterInterest);
                loans[loanId].principal = loans[loanId].principal.sub(amountAfterInterest);
            } else {
                //deduct totalLoanValue
                uint256 totalLoanValue = loans[loanId].principal.add(currentInterest);
                IERC20Upgradeable(ERCAddress).transferFrom(msg.sender, address(this), totalLoanValue);
                //return the repayed principal to the 'borrowable' amount
                poolBorrowed = poolBorrowed.sub(loans[loanId].principal);
                loans[loanId].principal = 0;
                //Send PropToken back to borrower
                PropToken0(propTokenContractAddress).safeTransferFrom(address(this), loans[loanId].borrower, loanToPropToken[loanId]);
            }

            //set interest accrued to 0 AFTER successful erc20 transfer
            loans[loanId].interestAccrued = 0;
        }

        //last payment timestamp is only updated AFTER  successful erc20 transfer
        loans[loanId].timeLastPayment = block.timestamp;

        //servicer fee is treated as cash investment in the pool as the percentage interest
        //calculate how much of payment goes to servicer here
        uint256 servicerFeeInERC = servicerFeePercentage.mul(interestAmountRepayed).div(loans[loanId].interestRate);
        uint256 newTokensMinted = getProportionalPoolTokens(servicerFeeInERC).div(2);

        //treat repayed interest as new money Lent into the pool
        poolLent = poolLent.add(interestAmountRepayed);

        super._mint(servicer, newTokensMinted);
        super._mint(daoAddress, newTokensMinted);
    }

    /*****************************************************
    *                Staking FUNCTIONS
    ******************************************************/

    /**  
    *   @dev Function stake transfers users bHOME to the poolStaking contract
    */
    function stake(uint256 amount) public returns (bool) {
        require(balanceOf(msg.sender) >= amount, "not enough to stake");

        transfer(poolStakingAddress, amount);
        bool successfulStake = PoolStakingRewards0(poolStakingRewardAddress).stake(msg.sender, amount);
        require(successfulStake, "Stake failed");

        return successfulStake;
    }

    function linkPoolStaking(address _poolStakingAddress) public {
        require(msg.sender == servicer, "unapproved sender");
        poolStakingAddress = _poolStakingAddress;
    }

    function linkPoolStakingReward(address _poolStakingRewardAddress) public {
        require(msg.sender == servicer, "unapproved sender");
        poolStakingRewardAddress = _poolStakingRewardAddress;
    }

    /**  
    *   @dev Function lendAndStake calls both the Lend and Stake functions in one call
    *   @param amount is amount of USDC to be deposited
    *   @return the bool from stake that reprents successful stake
    */
    function lendAndStake(uint256 amount) public returns (bool) {
        uint256 newPoolTokens = lend(amount);
        return stake(newPoolTokens);
    }

    /**  
    *   @dev Function getVersion returns current upgraded version
    */
    function getVersion() public pure returns (uint) {
        return 10;
    }

    function onERC721Received(address, address, uint256, bytes memory ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}