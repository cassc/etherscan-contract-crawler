// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/** @title Token Transfer.
 * @notice It is a contract for ERC20 & native token transfer system
 */
contract TokenTransfer is ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant MAX_RECEIVERS = 1000;

    // Vesting variables
    struct VestingWallet {
        address vestingCreator;
        address vestingAddress;
        address tokenAddress;
        uint256 vestingAmount;
        uint256 claimDate;
        uint256 amountClaimed;
        bool isVestingValid;
    }
    uint256 private _currentVestingId;
    mapping(uint256 => VestingWallet) public vestingWallet;
    mapping(address => uint256[]) private userVestingIds;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not the admin");
        _;
    }

    event TransferSucceeded(
        address indexed sender,
        address indexed token,
        uint256 totalAmount,
        address[] receivers,
        uint256[] amount,
        string systemType
    );

    event TransferSingleSucceeded(
        address indexed sender,
        address indexed token,
        address sourceWallet,
        address receiver,
        uint256 amount,
        string systemType
    );

    event MultiSourceTransferSucceeded(
        address indexed sender,
        address indexed token,
        uint256 totalAmount,
        address[] sourceWallets,
        address[] receivers,
        uint256[] amount,
        string systemType
    );

    event VestingWalletAdded(
        address indexed sender,
        address indexed token,
        uint256 amount,
        address vestingWallet,
        uint256 claimDate,
        uint256 vestingId
    );
    event VestingWalletRemoved(address indexed sender, uint256 vestingId);
    event UserClaimedVesting(
        address indexed sender,
        address indexed token,
        uint256 vestingId,
        uint256 amountClaimed
    );

    /**
     * @notice Constructor
     * @dev Initialize supported interface
     */
    function initialize() public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AccessControlUpgradeable.__AccessControl_init();

        // Initializes role for admin addresses
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getVestingClaimTime(
        uint256 _vestingId
    ) external view returns (uint256) {
        require(_vestingId <= _currentVestingId, "Vesting id is invalid");
        VestingWallet memory vestingInfo = vestingWallet[_vestingId];
        require(
            vestingInfo.vestingAmount > 0,
            "This wallet is not permitted for this vesting id"
        );
        return vestingInfo.claimDate;
    }

    function getVestingIds(
        address _vestingWallet
    ) external view returns (uint256[] memory) {
        return userVestingIds[_vestingWallet];
    }

    function multiSend(
        address tokenAddress,
        address[] calldata receiverAddresses,
        uint256[] calldata value,
        string calldata systemType
    ) external payable onlyAdmin nonReentrant {
        require(
            receiverAddresses.length <= MAX_RECEIVERS,
            "Number of receivers exceed limited!"
        );
        uint256 amountToSend;
        for (uint256 i = 0; i < receiverAddresses.length; i++) {
            amountToSend += value[i];
        }
        if (tokenAddress == address(0)) {
            require(
                amountToSend <= msg.value,
                "Native token value is not enough!"
            );
            for (uint256 i = 0; i < receiverAddresses.length; i++) {
                (bool sent, ) = payable(receiverAddresses[i]).call{
                    value: value[i]
                }("");
                require(sent, "Failed to send native!");
            }
        } else {
            IERC20Upgradeable ERC20Token = IERC20Upgradeable(tokenAddress);
            require(
                amountToSend <= ERC20Token.balanceOf(msg.sender),
                "Sender balance is not enough!"
            );
            for (uint256 i = 0; i < receiverAddresses.length; i++) {
                ERC20Token.safeTransferFrom(
                    msg.sender,
                    receiverAddresses[i],
                    value[i]
                );
            }
        }

        emit TransferSucceeded(
            msg.sender,
            tokenAddress,
            amountToSend,
            receiverAddresses,
            value,
            systemType
        );
    }

    function multiSendFromMultiSource(
        address tokenAddress,
        address[] calldata sourceAddresses,
        address[] calldata receiverAddresses,
        uint256[] calldata value,
        string calldata systemType
    ) external onlyAdmin {
        require(
            sourceAddresses.length == receiverAddresses.length,
            "Invalid data"
        );
        require(
            receiverAddresses.length <= MAX_RECEIVERS,
            "Number of receivers exceed limited!"
        );
        uint256 amountToSend;

        require(tokenAddress != address(0), "Sending native is not supported");

        IERC20Upgradeable ERC20Token = IERC20Upgradeable(tokenAddress);
        for (uint256 i = 0; i < receiverAddresses.length; i++) {
            require(
                value[i] <= ERC20Token.balanceOf(sourceAddresses[i]),
                "Sender balance is not enough!"
            );

            ERC20Token.safeTransferFrom(
                sourceAddresses[i],
                receiverAddresses[i],
                value[i]
            );
            amountToSend += value[i];
        }

        emit MultiSourceTransferSucceeded(
            msg.sender,
            tokenAddress,
            amountToSend,
            sourceAddresses,
            receiverAddresses,
            value,
            systemType
        );
    }

    function transferToken(
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata systemType
    ) external payable nonReentrant {
        if (tokenAddress == address(0)) {
            require(amount <= msg.value, "Native token value is not enough!");
            (bool sent, ) = payable(receiver).call{value: amount}("");
            require(sent, "Failed to send native!");
        } else {
            IERC20Upgradeable ERC20Token = IERC20Upgradeable(tokenAddress);
            require(
                amount <= ERC20Token.balanceOf(msg.sender),
                "Sender balance is not enough!"
            );

            ERC20Token.safeTransferFrom(msg.sender, receiver, amount);
        }

        emit TransferSingleSucceeded(
            msg.sender,
            tokenAddress,
            msg.sender,
            receiver,
            amount,
            systemType
        );
    }

    function addVestingWallet(
        address _vestingAddress,
        uint256 _amount,
        uint256 _claimDate,
        address _tokenAddress
    ) external payable nonReentrant onlyAdmin {
        require(
            _claimDate > block.timestamp,
            "Claim date must be greater than current time"
        );
        require(_amount > 0, "Vesting amount must be greater than 0");
        require(_vestingAddress != address(0), "Zero address not allowed");

        // Increase vesting id
        _currentVestingId++;
        vestingWallet[_currentVestingId] = VestingWallet(
            msg.sender,
            _vestingAddress,
            _tokenAddress,
            _amount,
            _claimDate,
            0,
            true
        );

        userVestingIds[_vestingAddress].push(_currentVestingId);

        if (_tokenAddress == address(0)) {
            require(_amount <= msg.value, "Native token value is not enough!");
        } else {
            IERC20Upgradeable ERC20Token = IERC20Upgradeable(_tokenAddress);
            require(
                _amount <= ERC20Token.balanceOf(msg.sender),
                "Sender balance is not enough!"
            );

            ERC20Token.safeTransferFrom(msg.sender, address(this), _amount);
        }
        emit VestingWalletAdded(
            msg.sender,
            _tokenAddress,
            _amount,
            _vestingAddress,
            _claimDate,
            _currentVestingId
        );
    }

    function removeVesting(uint256 _vestingId) external nonReentrant onlyAdmin {
        require(_vestingId <= _currentVestingId, "Invalid vesting id");
        VestingWallet storage vestingInfo = vestingWallet[_vestingId];
        require(
            vestingInfo.vestingAddress != address(0),
            "Vesting has been removed"
        );
        require(
            vestingInfo.claimDate > block.timestamp,
            "Current time has exceeded claim time"
        );
        uint256 _vestingAmount = vestingInfo.vestingAmount;
        vestingInfo.vestingAddress = address(0);
        vestingInfo.isVestingValid = false;
        vestingInfo.vestingAmount = 0;

        if (vestingInfo.tokenAddress == address(0)) {
            require(
                address(this).balance >= _vestingAmount,
                "Native token value is not enough!"
            );
            (bool sent, ) = payable(vestingInfo.vestingCreator).call{
                value: _vestingAmount
            }("");
            require(sent, "Failed to send native!");
        } else {
            IERC20Upgradeable ERC20Token = IERC20Upgradeable(
                vestingInfo.tokenAddress
            );
            require(
                _vestingAmount <= ERC20Token.balanceOf(address(this)),
                "Sender balance is not enough!"
            );

            ERC20Token.safeTransfer(vestingInfo.vestingCreator, _vestingAmount);
        }
        emit VestingWalletRemoved(msg.sender, _vestingId);
    }

    function claimVesting(
        uint256 _vestingId,
        uint256 _amountToClaim
    ) external nonReentrant {
        VestingWallet storage vestingInfo = vestingWallet[_vestingId];
        require(
            msg.sender == vestingInfo.vestingAddress,
            "Address is unauthorized to claim vesting token"
        );
        require(_vestingId <= _currentVestingId, "Invalid vesting id");
        require(vestingInfo.isVestingValid == true, "Vesting has been removed");
        require(block.timestamp >= vestingInfo.claimDate, "Too soon to claim");
        require(
            vestingInfo.amountClaimed + _amountToClaim <=
                vestingInfo.vestingAmount,
            "Amount to claim exceed claimable amount"
        );

        vestingInfo.amountClaimed += _amountToClaim;

        if (vestingInfo.tokenAddress == address(0)) {
            require(
                address(this).balance >= _amountToClaim,
                "Native token value is not enough!"
            );
            (bool sent, ) = payable(msg.sender).call{value: _amountToClaim}("");
            require(sent, "Failed to send native!");
        } else {
            IERC20Upgradeable ERC20Token = IERC20Upgradeable(
                vestingInfo.tokenAddress
            );
            require(
                _amountToClaim <= ERC20Token.balanceOf(address(this)),
                "Sender balance is not enough!"
            );

            ERC20Token.safeTransfer(msg.sender, _amountToClaim);
        }
        emit UserClaimedVesting(
            msg.sender,
            vestingInfo.tokenAddress,
            _vestingId,
            _amountToClaim
        );
    }
}