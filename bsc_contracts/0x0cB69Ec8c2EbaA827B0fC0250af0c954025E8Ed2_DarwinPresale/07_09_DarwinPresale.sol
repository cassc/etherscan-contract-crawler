// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {IDarwinPresale} from "./interface/IDarwinPresale.sol";
import {IDarwin} from "./interface/IDarwin.sol";

/// @title Darwin Presale
contract DarwinPresale is IDarwinPresale, ReentrancyGuard, Ownable {
    /// @notice Min BNB deposit per user
    uint256 public constant RAISE_MIN = .1 ether;
    /// @notice Max BNB deposit per user
    uint256 public constant RAISE_MAX = 4_000 ether;
    /// @notice Max number of BNB to be raised
    uint256 public constant HARDCAP = 140_000 ether;
    /// @notice Amount of Darwin to be sent to the LP if hardcap reached
    uint256 public constant LP_AMOUNT = 1e25; // 10,000,000 Darwin
    /// @notice % of raised BNB to be sent to Wallet1
    uint256 public constant WALLET1_PERCENTAGE = 30;
    /// @notice % of raised BNB to be added to Wallet1 percentage at the end of the presale
    uint256 public constant WALLET1_ADDITIONAL_PERCENTAGE = 5;
    /// @notice % of raised BNB to be sent to Wallet2
    uint256 public constant WALLET2_PERCENTAGE = 20;

    /// @notice The Darwin token
    IERC20 public darwin;
    /// @notice Timestamp of the presale start
    uint256 public presaleStart;

    /// @notice Timestamp of the presale end
    uint256 public presaleEnd;

    address public wallet1;
    address public wallet2;

    enum Status {
        QUEUED,
        ACTIVE,
        SUCCESS
    }

    struct PresaleStatus {
        uint256 raisedAmount; // Total BNB raised
        uint256 soldAmount; // Total Darwin sold
        uint256 numBuyers; // Number of unique participants
    }

    /// @notice Mapping of total BNB deposited by user
    mapping(address => uint256) public userDeposits;

    PresaleStatus public status;

    IUniswapV2Router02 private router;
    bool private _isInitialized;

    modifier isInitialized() {
        if (!_isInitialized) {
            revert NotInitialized();
        }
        _;
    }

    /// @dev Initializes the Darwin Protocol address
    /// @param _darwin The Darwin Protocol address
    function init(
        address _darwin
    ) external onlyOwner {
        if (_isInitialized) revert AlreadyInitialized();
        if (_darwin == address(0)) revert ZeroAddress();

        darwin = IERC20(_darwin);
        IDarwin(_darwin).pause();

        _setWallet1(0x0bF1C4139A6168988Fe0d1384296e6df44B27aFd);
        _setWallet2(0xBE013CeAB3611Dc71A4f150577375f8Cb8d9f6c3);
    }

    /// @dev Initializes the presale start date, and sets presale end date to 90 days after it
    function startPresale() external onlyOwner {
        if (_isInitialized) revert AlreadyInitialized();
        _isInitialized = true;

        presaleStart = block.timestamp;
        presaleEnd = presaleStart + (90 days);
    }

    /// @notice Deposits BNB into the presale
    /// @dev Emits a UserDeposit event
    /// @dev Emits a RewardsDispersed event
    function userDeposit() external payable nonReentrant isInitialized {

        if (presaleStatus() != Status.ACTIVE) {
            revert PresaleNotActive();
        }

        uint256 base = userDeposits[msg.sender];

        if (msg.value < RAISE_MIN || base + msg.value > RAISE_MAX) {
            revert InvalidDepositAmount();
        }

        if (base == 0) {
            // new depositer
            ++status.numBuyers;
        }

        userDeposits[msg.sender] += msg.value;

        uint256 darwinAmount = calculateDarwinAmount(msg.value);

        status.raisedAmount += msg.value;
        status.soldAmount += darwinAmount;

        uint256 wallet1Amount = (msg.value * WALLET1_PERCENTAGE) / 100;
        _transferBNB(wallet1, wallet1Amount);

        if (!darwin.transfer(msg.sender, darwinAmount)) {
            revert TransferFailed();
        }

        emit UserDeposit(msg.sender, msg.value, darwinAmount);
    }

    /// @notice Set the presale end date to `_endDate`
    /// @param _endDate The new presale end date
    function setPresaleEndDate(uint256 _endDate) external onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        if (_endDate < block.timestamp || _endDate < presaleStart || _endDate > presaleEnd) {
            revert InvalidEndDate();
        }
        presaleEnd = _endDate;
        emit PresaleEndDateSet(_endDate);
    }

    /// @notice Set addresses for Wallet1 and Wallet2
    /// @param _wallet1 The new Wallet1 address
    /// @param _wallet2 The new Wallet2 address
    function setWallets(
        address _wallet1,
        address _wallet2
    ) external onlyOwner {
        if (_wallet1 == address(0) || _wallet2 == address(0)) {
            revert ZeroAddress();
        }
        _setWallet1(_wallet1);
        _setWallet2(_wallet2);
    }

    /// @notice Allocates presale funds to LP, Wallet2, and Wallet1
    /// @dev The unsold darwin tokens are sent back to the owner
    function provideLpAndWithdrawTokens() external onlyOwner {
        if (wallet1 == address(0) || wallet2 == address(0)) {
            revert ZeroAddress();
        }
        if (presaleStatus() != Status.SUCCESS) {
            revert PresaleNotEnded();
        }

        IDarwin(address(darwin)).unPause();
        IDarwin(address(darwin)).setLive();

        uint256 balance = address(this).balance;

        uint256 wallet2Amount = (status.raisedAmount * WALLET2_PERCENTAGE) / 100;
        uint256 wallet1Amount = (status.raisedAmount * WALLET1_ADDITIONAL_PERCENTAGE) / 100;

        uint256 lp = balance - wallet2Amount - wallet1Amount; // 45%

        // set the price of darwin in the lp to be the price of the next stage of funding
        uint nextStage = _getCurrentStage() + 1;
        uint darwinDepositRate;
        uint darwinToDeposit;
        if(nextStage == 9) {
            //darwinDepositRate = 15_873;
            darwinToDeposit = LP_AMOUNT;
        } else {
            (darwinDepositRate, ,) = _getStageDetails(nextStage);
            darwinToDeposit = (lp * darwinDepositRate);
        }

        _addLiquidity(address(darwin), darwinToDeposit, lp);
        
        _transferBNB(wallet2, wallet2Amount);
        _transferBNB(wallet1, wallet1Amount);

        if (!darwin.transfer(wallet1, darwin.balanceOf(address(this)))) {
            revert TransferFailed();
        }

        emit LpProvided(lp, darwinToDeposit);
    }

    /// @notice Changes the router address.
    /// @dev Only callable by the owner. Useful when we want to set the router to DarwinSwap's one, since we're deploying it during presale.
    /// @param _router the new router address.
    function setRouter(address _router) external onlyOwner {
        router = IUniswapV2Router02(_router);
        emit RouterSet(_router);
    }

    /// @notice Returns the current stage of the presale
    /// @return stage The current stage of the presale
    function getCurrentStage() external view returns (uint256 stage) {
        stage = _getCurrentStage();
    }

    function tokensDepositedAndOwned(
        address account
    ) external view returns (uint256, uint256) {
        uint256 deposited = userDeposits[account];
        uint256 owned = darwin.balanceOf(account);
        return (deposited, owned);
    }

    /// @notice Returns the number of tokens left to raise on the current stage
    /// @return tokensLeft The number of tokens left to raise on the current stage
    function baseTokensLeftToRaiseOnCurrentStage()
        public
        view
        returns (uint256 tokensLeft)
    {
        (, , uint256 stageCap) = _getStageDetails(_getCurrentStage());
        tokensLeft = stageCap - status.raisedAmount;
    }

    /// @notice Returns the current presale status
    /// @return The current presale status
    function presaleStatus() public view returns (Status) {
        if (!_isInitialized) {
            return Status.QUEUED;
        }

        // solhint-disable-next-line not-rely-on-time
        if (status.raisedAmount >= HARDCAP || block.timestamp > presaleEnd) {
            return Status.SUCCESS; // Wonderful, presale has ended
        }

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= presaleStart && block.timestamp <= presaleEnd) {
            return Status.ACTIVE; // ACTIVE - Deposits enabled, now in Presale
        }

        return Status.QUEUED; // QUEUED - Awaiting start block
    }

    /// @notice Calculates the number of tokens that can be bought with `bnbAmount` BNB
    /// @param bnbAmount The number of BNB to be deposited
    /// @return The number of Darwin to be purchased with `bnbAmount` BNB
    function calculateDarwinAmount(
        uint256 bnbAmount
    ) public view returns (uint256) {
        if (bnbAmount > HARDCAP - status.raisedAmount) {
            revert AmountExceedsHardcap();
        }
        uint256 tokensLeft = baseTokensLeftToRaiseOnCurrentStage();
        if (bnbAmount < tokensLeft) {
            return ((bnbAmount * _getCurrentRate()));
        } else {
            uint256 stage = _getCurrentStage();
            uint256 darwinAmount;
            uint256 rate;
            uint256 stageAmount;
            uint256 stageCap;
            uint amountRaised = status.raisedAmount;
            while (bnbAmount > 0) {
                (rate, stageAmount, stageCap) = _getStageDetails(stage);
                uint amountLeftInStage = stageCap - amountRaised;
                if (bnbAmount <= amountLeftInStage) {
                    darwinAmount += (bnbAmount * rate);
                    bnbAmount = 0;
                    break;
                }

                amountRaised += amountLeftInStage;
                darwinAmount += (amountLeftInStage * rate);
                bnbAmount -= amountLeftInStage;
                
                ++stage;
            }

            return darwinAmount;
        }
    }

    function _transferBNB(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function _setWallet1(address _wallet1) internal {
        wallet1 = _wallet1;
        emit Wallet1Set(_wallet1);
    }

    function _setWallet2(address _wallet2) internal {
        wallet2 = _wallet2;
        emit Wallet2Set(_wallet2);
    }

    function _addLiquidity(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 bnbAmount
    ) private {
        // approve token transfer to cover all possible scenarios
        if (!IERC20(tokenAddress).approve(address(router), tokenAmount)) {
            revert ApproveFailed();
        }

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            tokenAddress, // token
            tokenAmount, // amountTokenDesired
            0, // amountTokenMin (slippage is unavoidable)
            0, // amountETHMin (slippage is unavoidable)
            owner(), // to (Recipient of the liquidity tokens.)
            block.timestamp + 600 // deadline (10 mins.)
        );
    }

    function _getCurrentRate() private view returns (uint256 rate) {
        (rate, , ) = _getStageDetails(_getCurrentStage());
    }

    function _getCurrentStage() private view returns (uint256) {
        uint raisedAmount = status.raisedAmount;
        if (raisedAmount > 117_164 ether) {
            return 8;
        } else if (raisedAmount > 96_690 ether) {
            return 7;
        } else if (raisedAmount > 78_135 ether) {
            return 6;
        } else if (raisedAmount > 61_170 ether) {
            return 5;
        } else if (raisedAmount > 45_545 ether) {
            return 4;
        } else if (raisedAmount > 31_063 ether) {
            return 3;
        } else if (raisedAmount > 17_569 ether) {
            return 2;
        } else if (raisedAmount > 5_000 ether) {
            return 1;
        } else {
            return 0;
        }
    }

    function _getStageDetails(
        uint256 stage
    ) private pure returns (uint256, uint256, uint256) {
        assert(stage <= 8);
        if (stage == 0) {
            return (500, 5_000 ether, 5_000 ether);
        } else if (stage == 1) {
            return (470, 12_569 ether, 17_569 ether);
        } else if (stage == 2) {
            return (440, 13_494 ether, 31_063 ether);
        } else if (stage == 3) {
            return (410, 14_482 ether, 45_545 ether);
        } else if (stage == 4) {
            return (380, 15_625 ether, 61_170 ether);
        } else if (stage == 5) {
            return (350, 16_925 ether, 78_135 ether);
        } else if (stage == 6) {
            return (320, 18_555 ether, 96_690 ether);
        } else if (stage == 7) {
            return (290, 20_474 ether, 117_164 ether);
        } else {
            return (261, 22_745 ether, 140_000 ether); //old: 26_131
        }
    }
}