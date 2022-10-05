/*
 * Global Market Exchange 
 * Official Site  : https://globalmarket.host
 * Private Sale   : https://globalmarketinc.io
 * Email          : [email protected]
 * Telegram       : https://t.me/gmekcommunity
 * Development    : Digichain Development Technology
 * Dev Is         : Tommy Chain & Team
 * Powering new equity blockchain on decentralized real and virtual projects
 * It is a revolutionary blockchain, DeFi and crypto architecture technology project
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/Pausable.sol";

import "./PresaleGmexRefundVault.sol";
import "./GmexToken.sol";

contract PresaleGmexV2 is Initializable, OwnableUpgradeable, Pausable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // The vault that will store the BUSD until the goal is reached
    PresaleGmexRefundVault public vault;

    // The block number of when the presale starts
    uint256 public startTime;

    // The block number of when the presale ends
    uint256 public endTime;

    uint256 public startingPrice;
    uint256 public closingPrice;

    GmexToken public gmexToken;
    IERC20Upgradeable public busd;

    // Set token claimable or not
    bool public tokenClaimable;

    // The amount of BUSD raised
    uint256 public busdRaised;

    // The amount of tokens raised
    uint256 public tokensRaised;

    // If the presale wasn't successful, this will be true and users will be able
    // to claim the refund of their BUSD
    bool public isRefunding;

    // If the presale has ended or not
    bool public isEnded;

    // The number of transactions
    uint256 public numberOfTransactions;

    // The amount of tokens claimed
    uint256 public tokensClaimed;

    // How much each user paid for the presale
    mapping(address => uint256) public presaleBalances;

    // How many tokens each user got for the presale
    mapping(address => uint256) public tokenToBeTransferred;

    // To indicate how much token will be received
    event TokenToBeTransferred(
        address indexed buyer,
        uint256 amountDeposited,
        uint256 amountOfTokens
    );

    // To indicate busd has been deposited by buyer
    event BUSDDeposited(address indexed buyer, uint256 amountDeposited);

    // To indicate buyer has claimed refund
    event RefundClaimed(address indexed buyer, uint256 claimedBUSD);

    // To indicate buyer has claimed token
    event TokenClaimed(address indexed buyer, uint256 claimedToken);

    // Indicates if the refund is enabled
    event RefundEnabled();

    // Indicates if the presale has ended
    event Finalized();

    modifier runningPreSaleOnly() {
        require(
            block.timestamp >= startTime && block.timestamp < endTime,
            "Presale has not started or already ended."
        );
        _;
    }

    function initialize(
        GmexToken _gmexToken,
        IERC20Upgradeable _busd,
        PresaleGmexRefundVault _vault
    ) public initializer {
        __Ownable_init();
        __PausableUpgradeable_init();
        gmexToken = _gmexToken;
        busd = _busd;
        vault = _vault;
        startTime = 2190266100; // May 25th 2022, 12 am (UTC)
        endTime = 3399866100; // May 30th 2022, 12 am (UTC)
        startingPrice = 1.5 ether;
        closingPrice = 10000 ether;
        tokenClaimable = false;
        busdRaised = 0;
        tokensRaised = 0;
        isRefunding = false;
        isEnded = false;
        tokensClaimed = 0;
    }

    function getPrice() public view returns (uint256) {
        // if presale has not yet started
        if (block.timestamp < startTime) {
            return startingPrice;
        }

        uint256 daysPassed = (block.timestamp.sub(startTime)).mul(1e20).div(
            1 days
        );

        uint256 duration = ((endTime.sub(startTime)).mul(1e20)).div(1 days);
        return (
            startingPrice.add(
                (((closingPrice.sub(startingPrice)).mul(daysPassed))).div(
                    duration
                )
            )
        );
    }

    function buyTokensWithBUSD(uint256 _amount)
        public
        runningPreSaleOnly
        whenNotPaused
    {
        require(_amount > 0, "Amount should be greater than 0");
        require(_amount <= busd.balanceOf(msg.sender), "BUSD is not enough");

        uint256 price = getPrice();
        uint256 tokens = (_amount.mul(1e18)).div(price);

        busdRaised = busdRaised.add(_amount);
        tokensRaised = tokensRaised.add(tokens);

        // keep a record of how many busd has investor deposited
        presaleBalances[msg.sender] = presaleBalances[msg.sender].add(_amount);
        emit BUSDDeposited(msg.sender, _amount);

        // Keep a record of how many tokens investor gets
        tokenToBeTransferred[msg.sender] = tokenToBeTransferred[msg.sender].add(
            tokens
        );
        emit TokenToBeTransferred(msg.sender, _amount, tokens);
        numberOfTransactions = numberOfTransactions.add(1);

        vault.deposit(msg.sender, _amount);
    }

    /// @notice Allow to update Presale start date
    /// @param _startTime Starttime of Presale
    function setStartDate(uint256 _startTime) public onlyOwner {
        require(
            block.timestamp < _startTime,
            "Can only update future start time"
        );
        require(endTime > _startTime, "End time should be greater");
        startTime = _startTime;
    }

    /// @notice Allow to extend Presale end date
    /// @param _endTime Endtime of Presale
    function setEndDate(uint256 _endTime) public onlyOwner {
        require(block.timestamp < _endTime, "Can only update future end time");
        require(startTime < _endTime, "End time should be greater");
        endTime = _endTime;
    }

    /// @notice Check if the presale has ended and enables refunds only in case the
    /// goal hasn't been reached
    /// call this method after presale has ended
    function checkCompletedPresale() public {
        require(
            !isEnded,
            "Presale has ended and required action has been taken."
        );

        if (hasEnded()) {
            vault.close();
            isEnded = true;
            emit Finalized();
        }
    }

    /// @notice If presale is unsuccessful, owner can enable refund.
    function enableRefund() public onlyOwner whenNotPaused {
        require(hasEnded(), "Presale has not ended");
        require(!isRefunding, "Required action has been taken.");

        vault.enableRefunds();
        isRefunding = true;
        emit RefundEnabled();
    }

    /// @notice If refund is enabled, investors can claim refunds here
    function claimRefund() public whenNotPaused {
        require(hasEnded() && isRefunding, "Refund not available");
        require(presaleBalances[msg.sender] > 0, "No amount to be refunded");

        uint256 claimedBUSD = presaleBalances[msg.sender];

        busdRaised = busdRaised.sub(presaleBalances[msg.sender]);
        tokensRaised = tokensRaised.sub(tokenToBeTransferred[msg.sender]);

        presaleBalances[msg.sender] = 0;
        tokenToBeTransferred[msg.sender] = 0;

        vault.refund(msg.sender);

        emit RefundClaimed(msg.sender, claimedBUSD);
    }

    /// @notice Public function to check BUSD deposited
    function depositedBUSD() public view returns (uint256) {
        return presaleBalances[msg.sender];
    }

    /// @notice Public function to check token to be claimed
    function tokenToBeClaimed() public view returns (uint256) {
        return tokenToBeTransferred[msg.sender];
    }

    /// @notice Public function to check if the presale has ended or not
    function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }

    /// @notice decides if investors can claim tokens or not, usually enabled after token is vested
    function setTokenClaimable(bool _claimable) public onlyOwner {
        tokenClaimable = _claimable;
    }

    function claimGmexToken() public whenNotPaused {
        require(hasEnded(), "Presale not ended");
        require(!isRefunding, "Cannot claim token in Refunding state");
        require(
            tokenClaimable,
            "Token is not claimable right now. Will be available after vesting."
        );
        require(
            tokenToBeTransferred[msg.sender] > 0,
            "No Tokens to be claimed"
        );
        require(
            gmexToken.balanceOf(address(this)) >=
                tokenToBeTransferred[msg.sender],
            "Balance not sufficient"
        );
        uint256 tokens = tokenToBeTransferred[msg.sender];
        tokensRaised = tokensRaised.sub(tokens);
        tokensClaimed = tokensClaimed.add(tokens);

        tokenToBeTransferred[msg.sender] = 0;
        vault.tokenClaimed(msg.sender);
        gmexToken.transfer(msg.sender, tokens);

        emit TokenClaimed(msg.sender, tokens);
    }

    function withdrawBUSDFromVault() public onlyOwner {
        vault.withdrawBUSD();
    }

    /// @notice Update Gmex Token Contract Address only if updates are made in GmexToken contract.
    function updateGmexTokenAddress(GmexToken _gmexToken) public onlyOwner {
        gmexToken = _gmexToken;
    }

    /// @notice Update Wallet Address that claims collected BUSD
    function updateWalletAddress(address _wallet) public onlyOwner {
        vault.updateWalletAddress(_wallet);
    }

    /// @notice Approve transfer of BUSD from Vault to Owner Address
    function approveOwner(
        address tokenAddress,
        address spender,
        uint256 amount
    ) public onlyOwner whenNotPaused returns (bool) {
        return vault.approve(tokenAddress, spender, amount);
    }
}