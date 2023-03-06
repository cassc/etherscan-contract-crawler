//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "hardhat/console.sol";

contract Illumipresale is Ownable, ReentrancyGuard {
    AggregatorV3Interface internal priceFeed;

    using Counters for Counters.Counter;

    event GoldListAddition(address _address, bool status);
    event BatchGoldListAddition(address[] addresses, bool[] status);
    event GoldListRevoked();
    event TokensClaimed(uint256 amount, address referralId);

    event PresaleOpened();
    event PresaleClosed();
    event SellsPaused();
    event SellsUnpaused();
    event StablecoinSellsPaused();
    event StablecoinSellsUnpaused();
    event NativeSellsPaused();
    event NativeSellsUnpaused();
    event ReferralRewardPaused();
    event ReferralRewardUnpaused();

    // Event for setting stable payment
    event StablePaymentSet(IERC20 referralStablePayment);

    event AddedStableCoin(address stableCoinAddress);
    event RemovedStableCoin(address stableCoinAddress);

    event AddBalanceToPresale(uint256 amount);
    event WithdrawBalanceToPresale(uint256 amount);

    event AddAdmin(address account);
    event RemoveAdmin(address account);

    event NativeWithdrawal(uint256 amount);

    Counters.Counter public goldNumber;

    mapping(address => bool) public goldList;

    mapping(uint256 => address) public goldMembers;

    mapping(address => bool) public stableTokensAccepted;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => bool) public adminlist;

    bool public openSell;
    bool public pausedSell;
    bool public pausedSCSell;
    bool public pausedNatSell;
    bool public referralActive;

    uint256 public presaleBalance;

    IERC20 referralStablePayment;

    /* ========== CONSTRUCTOR ========== */

    modifier onlyAdmin() {
        require(adminlist[msg.sender], "Sender must be an admin");
        _;
    }

    constructor(
        address priceFeedAddress,
        address[] memory acceptedStableCoins,
        uint256 _presaleBalance
    ) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);

        for (uint8 i = 0; i < acceptedStableCoins.length; i++) {
            stableTokensAccepted[acceptedStableCoins[i]] = true;
            emit AddedStableCoin(acceptedStableCoins[i]);
        }

        presaleBalance = _presaleBalance;
    }

    /**
     * @notice Add address to Gold List
     *
     * @param newAddress - Address of Gold Participant
     * @param status - Enable/Disable Address Gold Access
     */
    function addGoldList(address newAddress, bool status) public onlyAdmin {
        require(newAddress != address(0), "Can't add 0 address");
        goldList[newAddress] = status;
        goldMembers[goldNumber.current()] = newAddress;

        goldNumber.increment();

        emit GoldListAddition(newAddress, status);
    }

    /**
     * @notice Add batch of Addresses to Gold List
     *
     * @param goldAddresses - Array of addresses of Gold Participants
     * @param status - Arrays of Enabled/Disabled Addresses Gold Access
     */
    function addBatchGoldList(
        address[] memory goldAddresses,
        bool[] memory status
    ) external onlyAdmin {
        require(goldAddresses.length == status.length, "Length mismatch!");

        for (uint256 i = 0; i < goldAddresses.length; i++) {
            addGoldList(goldAddresses[i], status[i]);
        }

        emit BatchGoldListAddition(goldAddresses, status);
    }

    /**
     * @notice Revoke access to all Gold List
     *
     */
    function revokeGoldList() external onlyOwner {
        for (uint256 i; i < goldNumber.current(); i++) {
            address member = goldMembers[i];
            goldList[member] = false;
        }

        goldNumber._value = 0;
        emit GoldListRevoked();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claimTokensWithNative(address referralId, bool stableReward)
        external
        payable
        nonReentrant
    {
        require(
            !pausedNatSell && !pausedSCSell,
            "Presale is paused/ended or Native sell is paused"
        );
        require(goldList[msg.sender] || openSell, "Caller is not in Gold list");

        require(presaleBalance > 0, "Presale tokens have been sold");

        (, int256 price, , , ) = priceFeed.latestRoundData();

        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 srgTokenCost = 12 * 10**16;

        uint256 askedSrgTokens = (msg.value * adjustedPrice) / srgTokenCost;

        uint256 realSrgTokens = presaleBalance >= askedSrgTokens
            ? askedSrgTokens
            : presaleBalance;

        stableReward = presaleBalance >= askedSrgTokens ? stableReward : false;

        if (referralActive && referralId != address(0)) {
            _referralReward(
                referralId,
                stableReward,
                realSrgTokens,
                address(0)
            );
        }

        IERC20(address(this)).transfer(msg.sender, realSrgTokens);

        //Returning extra native coin
        if (askedSrgTokens >= presaleBalance) {
            uint256 extraValue = msg.value -
                (realSrgTokens * srgTokenCost) /
                adjustedPrice;
            (bool success, ) = msg.sender.call{value: extraValue}("");
            require(success, "Failed to send extra value back to the user");
        }

        presaleBalance -= realSrgTokens;

        emit TokensClaimed(realSrgTokens, referralId);
    }

    function claimTokensWithStable(
        address erc20,
        uint256 amount,
        address referralId,
        bool stableReward
    ) external nonReentrant {
        require(
            !pausedSell && !pausedSCSell,
            "Presale is paused/ended or StableCoins sell is paused"
        );

        require(goldList[msg.sender] || openSell, "Caller is not in Gold list");
        require(stableTokensAccepted[erc20], "Token not allowed");
        require(presaleBalance > 0, "Presale tokens have been sold");

        uint256 askedSrgTokens = (amount * 100) / 12;

        if (askedSrgTokens > presaleBalance) {
            IERC20(address(this)).transfer(msg.sender, presaleBalance);

            IERC20(erc20).transferFrom(
                msg.sender,
                owner(),
                (presaleBalance * 12) / 100
            );

            presaleBalance = 0;
        } else {
            if (referralActive && referralId != address(0)) {
                _referralReward(
                    referralId,
                    stableReward,
                    askedSrgTokens,
                    erc20
                );
            } else {
                IERC20(erc20).transferFrom(msg.sender, owner(), amount);
            }

            IERC20(address(this)).transfer(msg.sender, askedSrgTokens);

            presaleBalance -= askedSrgTokens;

            emit TokensClaimed(askedSrgTokens, referralId);
        }
    }

    function _referralReward(
        address referralId,
        bool stableReward,
        uint256 srgTokens,
        address erc20
    ) private {
        IERC20 tokenForOwner = erc20 == address(0)
            ? IERC20(referralStablePayment)
            : IERC20(erc20);
        IERC20 tokenForReferral = stableReward
            ? tokenForOwner
            : IERC20(address(this));

        uint256 amountForOwner = stableReward
            ? (srgTokens * 1176) / 10000
            : (srgTokens * 12) / 100;

        uint256 amountForReferral = stableReward
            ? (srgTokens * 24) / 10000
            : (srgTokens * 5) / 100;

        if (erc20 == address(0)) {
            tokenForReferral.transfer(referralId, amountForReferral);
        } else {
            tokenForOwner.transferFrom(msg.sender, owner(), amountForOwner);
            if (stableReward) {
                tokenForReferral.transferFrom(
                    msg.sender,
                    referralId,
                    amountForReferral
                );
            } else {
                if ((amountForReferral + srgTokens) > presaleBalance) {
                    tokenForReferral.transfer(
                        referralId,
                        presaleBalance - srgTokens
                    );
                    presaleBalance = srgTokens;
                } else {
                    tokenForReferral.transfer(referralId, amountForReferral);
                    presaleBalance -= amountForReferral;
                }
            }
        }
    }

    function withdrawNative() external payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        require(success, "Withdrawal failed.");
        emit NativeWithdrawal(address(this).balance);
    }

    function addAcceptedStableCoin(address erc20) external onlyOwner {
        stableTokensAccepted[erc20] = true;
        emit AddedStableCoin(erc20);
    }

    function removeAcceptedStableCoin(address erc20) external onlyOwner {
        stableTokensAccepted[erc20] = false;
        emit RemovedStableCoin(erc20);
    }

    function addAdminlist(address account) public onlyOwner {
        adminlist[account] = true;
        emit AddAdmin(account);
    }

    // Function to remove an address from the whitelist
    function removeAdminlist(address account) public onlyOwner {
        delete adminlist[account];
        emit RemoveAdmin(account);
    }

    // Function to open presale for everyone
    function _openSell() public onlyAdmin {
        openSell = true;
        emit PresaleOpened();
    }

    // Function to close presale
    function closeSell() public onlyAdmin {
        openSell = false;
        emit PresaleClosed();
    }

    // Function to pause sell
    function pauseSells() public onlyAdmin {
        pausedSell = true;
        emit SellsPaused();
    }

    // Function to unpause sell
    function unpauseSells() public onlyAdmin {
        pausedSell = false;
        emit SellsUnpaused();
    }

    // Function to pause stablecoin sells
    function pauseSCSell() public onlyAdmin {
        pausedSCSell = true;
        emit StablecoinSellsPaused();
    }

    // Function to unpause stablecoin sells
    function unpauseSCSell() public onlyAdmin {
        pausedSCSell = false;
        emit StablecoinSellsUnpaused();
    }

    // Function to pause native sells
    function pauseNatSell() public onlyAdmin {
        pausedNatSell = true;
        emit NativeSellsPaused();
    }

    // Function to unpause stablecoin sells
    function unpauseNatSell() public onlyAdmin {
        pausedNatSell = false;
        emit NativeSellsUnpaused();
    }

    // Function to pause referral reward
    function pauseReferral() public onlyAdmin {
        referralActive = false;
        emit ReferralRewardPaused();
    }

    // Function to unpause referral reward
    function unpauseReferral() public onlyAdmin {
        referralActive = true;
        emit ReferralRewardUnpaused();
    }

    function setStablePayment(IERC20 _referralStablePayment)
        external
        onlyAdmin
    {
        referralStablePayment = _referralStablePayment;
        emit StablePaymentSet(referralStablePayment);
    }

    /**
     * @dev this function adds more balance to the presale
     * @param amount, the amount of tokens that owner will send

     */
    function addBalanceToPresale(uint256 amount) public onlyOwner {
        IERC20(address(this)).transferFrom(msg.sender, address(this), amount);

        presaleBalance += amount;
        emit AddBalanceToPresale(amount);
    }

    /**
     * @dev this function  withdraws balance to the presale
     * @param amount, the amount of tokens that owner will withdraw

     */
    function wihdrawBalanceToPresale(uint256 amount) public onlyOwner {
        require(presaleBalance > 0, "Presale balance empty");
        IERC20(address(this)).transfer(msg.sender, amount);

        presaleBalance -= amount;
        emit WithdrawBalanceToPresale(amount);
    }
}