// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/utils/Whitelist.sol";

/**
 * @title Automatic Private sale
 * @author Michael Araque
 * @notice A contract that manages a Public Private Sale, purchase, claiming and vesting time
 */

contract FoxtrotPrivateSale is Whitelist {
    enum InvestorTrace {
        CLAIMED,
        LOCKED,
        TOTAL,
        BUSD_INVESTED
    }

    enum ContractDates {
        CLAIM_START,
        SALE_START,
        SALE_END,
        VESTING_PERIOD
    }

    mapping(address => bool) private firstClaim;
    mapping(address => mapping(InvestorTrace => uint256)) private accounting;
    mapping(ContractDates => uint256) private dates;

    event UpdatePrivateSaleStatus(bool isOpen);
    event ClaimToken(address tokenAddress, uint256 tokenAmount);
    event Invest(address investor, uint256 busdAmount, uint256 tokenAmount);

    address public busdContract;
    address public tokenContract;
    address public companyVault;

    bool public isPrivateSaleOpen;
    bool public isClaimEnabled;
    uint256 private tokensSoldCounter;
    uint256 public totalBusdInvested;

    uint256 private immutable TGE_PERCENT = 8;
    uint256 private immutable AFTER_TGE_BLOCK_TIME = 90 days;
    uint256 private immutable FXD_PRICE = 25000000000000000 wei;
    uint256 private immutable MIN_BUSD_ACCEPTED = 1 ether;
    uint256 private constant MAX_AMOUNT_TOKEN = 32_250_000 ether;

    constructor(address _companyVault, address _busdContract) {
        companyVault = _companyVault;
        busdContract = _busdContract;
        tokenContract = address(0);
        Whitelist.isWhitelistEnabled = true;

        tokensSoldCounter = MAX_AMOUNT_TOKEN;

        dates[ContractDates.SALE_START] = 1665504776;
        dates[ContractDates.VESTING_PERIOD] = 360 days;

        isPrivateSaleOpen = true;
    }

    /**
     * @dev This function allows to invest in the private sale
     * @param amount Amount in BUSD to be invested in wei format
     */
    function invest(uint256 amount) public onlyWhitelisted {
        require(isPrivateSaleOpen, "FXD: Private Sale is closed");

        require(
            IERC20(busdContract).balanceOf(msg.sender) >= amount,
            "FXD: Insufficient BUSD"
        );
        require(
            IERC20(busdContract).allowance(msg.sender, address(this)) >= amount,
            "FXD: First grant allowance"
        );
        require(
            block.timestamp >= dates[ContractDates.SALE_START],
            "FXD: Private Sale not started yet"
        );

        if (Whitelist.isWhitelistEnabled) {
            require(
                accounting[msg.sender][InvestorTrace.BUSD_INVESTED] <=
                    Whitelist.amount[msg.sender] &&
                    amount <= Whitelist.amount[msg.sender] &&
                    accounting[msg.sender][InvestorTrace.BUSD_INVESTED] +
                        amount <=
                    Whitelist.amount[msg.sender],
                "FXD: Private Sale purchase limit"
            );
        }

        if (tokensSoldCounter >= getTokenAmount(MIN_BUSD_ACCEPTED, FXD_PRICE))
            require(amount >= MIN_BUSD_ACCEPTED, "FXD: Minimum amount 1 BUSD");

        uint256 tokensAmount = getTokenAmount(amount, FXD_PRICE);
        require(
            tokensSoldCounter > 0 && tokensSoldCounter >= tokensAmount,
            "FXD: Private complete"
        );

        handleInvestment(msg.sender, tokensAmount, amount);
        SafeERC20.safeTransferFrom(
            IERC20(busdContract),
            msg.sender,
            companyVault,
            amount
        );

        emit Invest(msg.sender, amount, tokensAmount);
    }

    /**
     * @notice This method is added to handle extremly rare cases where
     *         investor can't invest directly on Dapp
     * @param to Investor address
     * @param amount Amount to be invested in wei
     */
    function manualInvest(address to, uint256 amount) public onlyOwner {
        uint256 tokensAmount = getTokenAmount(amount, FXD_PRICE);
        handleInvestment(to, tokensAmount, amount);
        emit Invest(to, amount, tokensAmount);
    }

    /**
     * @param from Investor address
     * @param tokensAmount Amount to be invested in wei
     * @param busdAmount Amount in BUSD to be invested in wei format
     */
    function handleInvestment(
        address from,
        uint256 tokensAmount,
        uint256 busdAmount
    ) internal {
        tokensSoldCounter -= tokensAmount;
        totalBusdInvested += busdAmount;
        accounting[from][InvestorTrace.BUSD_INVESTED] += busdAmount;
        accounting[from][InvestorTrace.LOCKED] += tokensAmount;
        accounting[from][InvestorTrace.TOTAL] += tokensAmount;
    }

    /**
     * @dev ClaimToken Emit event
     * @notice This method is the main method to claim tokens
     */
    function claim() external onlyWhitelisted {
        require(isClaimEnabled, "FXD: Claim status inactive");
        require(
            accounting[msg.sender][InvestorTrace.LOCKED] > 0,
            "FXD: Already claimed your tokens"
        );

        if (!isElegibleForFirstClaim(msg.sender))
            require(
                block.timestamp >= dates[ContractDates.CLAIM_START],
                "FXD: Can't claim, 90 days cliff"
            );

        uint256 claimableTokens = handleClaim(msg.sender);
        SafeERC20.safeTransfer(
            IERC20(tokenContract),
            msg.sender,
            claimableTokens
        );

        emit ClaimToken(tokenContract, claimableTokens);
    }

    /**
     * @param from Address of the investor
     * @return uint256 Returns the total claimable amount of tokens
     */
    function handleClaim(address from) internal returns (uint256) {
        uint256 claimableTokens = getClaimableAmountOfTokens(from);

        if (isElegibleForFirstClaim(from) && isClaimEnabled) {
            firstClaim[msg.sender] = true;
        }

        accounting[from][InvestorTrace.LOCKED] -= claimableTokens;
        accounting[from][InvestorTrace.CLAIMED] += claimableTokens;

        return claimableTokens;
    }

    /**
     * @notice This method is a little middleware that handle if the investor
     *         is elegible for first claim
     * @param investor Address of the investor
     */
    function isElegibleForFirstClaim(address investor)
        public
        view
        returns (bool)
    {
        return !firstClaim[investor];
    }

    /**
     * @param from Address of the investor
     * @return uint256 Returns the total amount of token tha the investor can claim
     */
    function getClaimableAmountOfTokens(address from)
        public
        view
        returns (uint256)
    {
        uint256 _TGEPercent = getTGEPercent(from);

        if (
            isElegibleForFirstClaim(from) &&
            isClaimEnabled &&
            dates[ContractDates.CLAIM_START] != 0
        ) {
            return _TGEPercent;
        } else if (
            block.timestamp < dates[ContractDates.CLAIM_START] ||
            dates[ContractDates.CLAIM_START] == 0
        ) {
            return 0;
        } else if (
            block.timestamp >=
            dates[ContractDates.CLAIM_START] +
                dates[ContractDates.VESTING_PERIOD]
        ) {
            return accounting[from][InvestorTrace.LOCKED];
        } else {
            uint256 amount = (((accounting[from][InvestorTrace.TOTAL] -
                _TGEPercent) *
                (block.timestamp - dates[ContractDates.CLAIM_START])) /
                dates[ContractDates.VESTING_PERIOD]) -
                (totalClaimedOf(from) - _TGEPercent);
            return amount;
        }
    }

    /**
     * @dev This method is used to calculate the amount of tokens that available on his
     *      account in the TGE event
     * @param from Address of the investor
     */
    function getTGEPercent(address from)
        internal
        view
        virtual
        returns (uint256)
    {
        return (accounting[from][InvestorTrace.TOTAL] * TGE_PERCENT) / 100;
    }

    /**
     * @notice Enabled first claim and active cliff time of 3 months
     */
    function changeClaimStatus() external onlyOwner returns (bool) {
        require(!isClaimEnabled, "FXD: Claim already enabled");
        isClaimEnabled = true;
        dates[ContractDates.CLAIM_START] =
            block.timestamp +
            AFTER_TGE_BLOCK_TIME;
        return true;
    }

    /**
     * @notice This method returns the exact date when the tokens
     *         start to vesting
     */
    function claimStartAt() external view returns (uint256) {
        return dates[ContractDates.CLAIM_START];
    }

    /**
     * @param from Address of the wallet that previously invested
     * @return uint256 Returns the total amount of tokens that are locked
     */
    function totalLockedOf(address from) public view returns (uint256) {
        return accounting[from][InvestorTrace.LOCKED];
    }

    /**
     * @param from Address of the wallet that previously invested
     * @return uint256 Returns the amount of tokens that were already claimed
     */
    function totalClaimedOf(address from) public view returns (uint256) {
        return accounting[from][InvestorTrace.CLAIMED];
    }

    /**
     * @param from Address of the wallet that previously invested
     * @return uint256 Returns the the total amount of tokens
     */
    function totalOf(address from) public view returns (uint256) {
        return accounting[from][InvestorTrace.TOTAL];
    }

    /**
     * @param from Address of the wallet that previously invested
     * @return uint256 Returns the amount of tokens that can be claimed
     */
    function availableOf(address from) external view returns (uint256) {
        return getClaimableAmountOfTokens(from);
    }

    /**
     * @param from Address of the wallet that previously invested
     * @return uint256 Returns the total of BUSD invested by the investor
     */
    function totalBusdInvestedOf(address from) public view returns (uint256) {
        return accounting[from][InvestorTrace.BUSD_INVESTED];
    }

    /**
     * @param from Address of the investor
     * @return total Total of buyed tokens by the investor
     * @return claimed Total of tokens that were already claimed
     * @return locked Total of tokens that are locked
     * @return available Total of tokens that can be claimed
     */
    function investorAccounting(address from)
        external
        view
        returns (
            uint256 total,
            uint256 claimed,
            uint256 locked,
            uint256 available,
            uint256 busd
        )
    {
        total = totalOf(from);
        claimed = totalClaimedOf(from);
        locked = totalLockedOf(from);
        available = getClaimableAmountOfTokens(from);
        busd = totalBusdInvestedOf(from);
    }

    /**
     * @param from Address of the investor
     * @return uint256 Returns the total amount of tokens that the investor has invested
     */
    function historicalBalance(address from) external view returns (uint256) {
        return (accounting[from][InvestorTrace.LOCKED] +
            accounting[from][InvestorTrace.CLAIMED]);
    }

    /**
     * @param amount Amount in wei
     * @param tokenPrice Price of the token in wei
     * @return uint256 Amount without decimals
     */
    function getTokenAmount(uint256 amount, uint256 tokenPrice)
        internal
        pure
        returns (uint256)
    {
        return (amount / tokenPrice) * (10**18);
    }

    /**
     * @notice This method is a helper function that allows to close the private sale manually
     */
    function setSaleEnd() external onlyOwner {
        isPrivateSaleOpen = false;
        emit UpdatePrivateSaleStatus(false);
    }

    /**
     * @notice This method is a helper function that allows to open the private sale manually
     */
    function openPrivateSale() external onlyOwner {
        isPrivateSaleOpen = true;
        emit UpdatePrivateSaleStatus(true);
    }

    /**
     * @return bool Show is the privatesale is open or closed
     */
    function showPrivateSaleStatus() external view returns (bool) {
        return isPrivateSaleOpen;
    }

    /**
     * @param fxdToken Contract address of FXD Token
     */
    function setContractToken(address fxdToken)
        external
        onlyOwner
        returns (bool)
    {
        tokenContract = fxdToken;
        return true;
    }

    /**
     * @param token Address of the contract
     * @return uint256 Return balance of the tokens contained in this address
     */
    function balance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice This method allow the owner of the contract to transfer specific
     *         amount of non Foxtrot tokens to a specific address manually
     * @param token Address of the token contract
     * @param receiver Address of the wallet that will receive the tokens
     * @param amount Amount of tokens to be transfered
     */
    function withdraw(
        address token,
        address receiver,
        uint256 amount
    ) external onlyOwner returns (bool) {
        require(
            token != tokenContract,
            "FXD: You can't withdraw Foxtrot Tokens"
        );
        IERC20 Token = IERC20(token);
        require(
            Token.balanceOf(address(this)) >= amount,
            "FXD: Insufficient amount"
        );
        Token.transfer(receiver, amount);
        return true;
    }

    /**
     * @notice Return all excess tokens in the Private Sale Contract
     *         to the Foxtrot Command (FXD) Contract
     */
    function purgeNonSelledTokens() external onlyOwner {
        SafeERC20.safeTransfer(
            IERC20(tokenContract),
            tokenContract,
            tokensSoldCounter
        );
    }
}