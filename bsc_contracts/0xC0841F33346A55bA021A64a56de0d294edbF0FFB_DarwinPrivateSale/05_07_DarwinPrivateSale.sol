// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IDarwinPresale} from "./interface/IDarwinPresale.sol";
import {IDarwin} from "./interface/IDarwin.sol";

/// @title Darwin Presale
contract DarwinPrivateSale is IDarwinPresale, ReentrancyGuard, Ownable {
    /// @notice Min BNB deposit per user
    uint256 public constant RAISE_MIN = .1 ether;
    /// @notice Max number of DARWIN to be sold
    uint256 public constant DARWIN_HARDCAP = 250_000 ether;
    /// @notice How many DARWIN are sold for each BNB invested
    uint256 public constant DARWIN_PER_BNB = 600;

    /// @notice The Darwin token
    IERC20 public darwin;
    /// @notice Timestamp of the presale start
    uint256 public presaleStart;
    /// @notice Timestamp of the presale end
    uint256 public presaleEnd;

    address public wallet1;

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

    bool private _isInitialized;

    modifier isInitialized() {
        if (!_isInitialized) {
            revert NotInitialized();
        }
        _;
    }

    /// @dev Initializes the darwin address and presale start date, and sets presale end date to 90 days after it
    /// @param _darwin The darwin token address
    /// @param _presaleStart The presale start date
    function init(
        address _darwin,
        uint256 _presaleStart
    ) external onlyOwner {
        if (_isInitialized) revert AlreadyInitialized();
        _isInitialized = true;
        if (_darwin == address(0)) revert ZeroAddress();
        // solhint-disable-next-line not-rely-on-time
        if (_presaleStart < block.timestamp) revert InvalidStartDate();
        darwin = IERC20(_darwin);
        IDarwin(address(darwin)).pause();
        _setWallet1(0x0bF1C4139A6168988Fe0d1384296e6df44B27aFd);
        presaleStart = _presaleStart;
        presaleEnd = _presaleStart + (14 days);
    }

    /// @notice Deposits BNB into the presale
    /// @dev Emits a UserDeposit event
    /// @dev Emits a RewardsDispersed event
    function userDeposit() external payable nonReentrant isInitialized {

        if (presaleStatus() != Status.ACTIVE) {
            revert PresaleNotActive();
        }

        if (msg.value < RAISE_MIN) {
            revert InvalidDepositAmount();
        }

        if (userDeposits[msg.sender] == 0) {
            // new depositer
            ++status.numBuyers;
        }

        userDeposits[msg.sender] += msg.value;

        uint256 darwinAmount = msg.value * DARWIN_PER_BNB;

        status.raisedAmount += msg.value;
        status.soldAmount += darwinAmount;

        _transferBNB(wallet1, msg.value);

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

    /// @notice Set address for Wallet1
    /// @param _wallet1 The new Wallet1 address
    function setWallet1(
        address _wallet1
    ) external onlyOwner {
        if (_wallet1 == address(0)) {
            revert ZeroAddress();
        }
        _setWallet1(_wallet1);
    }

    /// @dev Sends any unsold Darwin or dust BNB to Wallet 1
    function withdrawUnsoldDarwin() external onlyOwner {
        if (wallet1 == address(0)) {
            revert ZeroAddress();
        }
        if (presaleStatus() != Status.SUCCESS) {
            revert PresaleNotEnded();
        }

        // Send any dust BNB to Wallet 1
        if (address(this).balance > 0) {
            _transferBNB(wallet1, address(this).balance);
        }

        // Send any unsold Darwin to Wallet 1
        if (darwin.balanceOf(address(this)) > 0) {
            darwin.transfer(wallet1, darwin.balanceOf(address(this)));
        }
    }

    function tokensDepositedAndOwned(
        address account
    ) external view returns (uint256, uint256) {
        uint256 deposited = userDeposits[account];
        uint256 owned = darwin.balanceOf(account);
        return (deposited, owned);
    }

    /// @notice Returns the number of Darwin left to sold on the current stage
    /// @return tokensLeft The number of tokens left to sold on the current stage
    /// @dev The name of the function has been left unmodified to not cause mismatches with the frontend (we're using DarwinPresale typechain there)
    function baseTokensLeftToRaiseOnCurrentStage()
        public
        view
        returns (uint256 tokensLeft)
    {
        tokensLeft = DARWIN_HARDCAP - status.soldAmount;
    }

    /// @notice Returns the current presale status
    /// @return The current presale status
    function presaleStatus() public view returns (Status) {
        // solhint-disable-next-line not-rely-on-time
        if (status.soldAmount >= DARWIN_HARDCAP || block.timestamp > presaleEnd) {
            return Status.SUCCESS; // Wonderful, presale has ended
        }

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= presaleStart && block.timestamp <= presaleEnd) {
            return Status.ACTIVE; // ACTIVE - Deposits enabled, now in Presale
        }

        return Status.QUEUED; // QUEUED - Awaiting start block
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
}