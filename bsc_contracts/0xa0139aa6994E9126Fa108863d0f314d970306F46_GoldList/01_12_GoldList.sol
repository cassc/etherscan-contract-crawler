//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-0.8/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-0.8/utils/Counters.sol";
import "@openzeppelin/contracts-0.8/access/AccessControl.sol";

/// @title SRG Gold List
/// @author IllumiShare SRG
/// @notice IllumiShare Community Gold List Contract
contract GoldList is Ownable, AccessControl, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /* ========== EVENTS ========== */

    event GoldListAddition(address _address, bool status);
    event BatchGoldListAddition(address[] addresses, bool[] status);
    event GoldListRevoked();
    event TokensClaimed(uint256 amount);

    event AddedStableCoin(address stableCoinAddress);
    event RemovedStableCoin(address stableCoinAddress);

    /* ========= LOCAL & STATE VARIABLES ========= */

    // struct GoldMember {
    //     address goldMemberAddress;
    //     bool status;
    // }

    address public immutable srgToken;
    Counters.Counter public goldNumber;

    mapping(address => bool) public goldList;

    mapping(uint256 => address) public goldMembers;

    mapping(address => bool) public stableTokensAccepted;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _srgToken,
        address admin,
        address multiSigWallet,
        address[] memory acceptedStableCoins
    ) {
        srgToken = _srgToken;
        _setupRole(ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        transferOwnership(multiSigWallet);

        for (uint8 i = 0; i < acceptedStableCoins.length; i++) {
            stableTokensAccepted[acceptedStableCoins[i]] = true;
            emit AddedStableCoin(acceptedStableCoins[i]);
        }
    }

    /* ========== ADMIN & OWNER FUNCTIONS ========== */

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

    function claimTokensWithStable(address erc20, uint256 amount)
        external
        nonReentrant
    {
        require(goldList[_msgSender()], "Caller is not in Gold list");

        require(stableTokensAccepted[erc20], "Token not allowed");
        // Price 0.12 usd
        uint256 srgTokens = (amount * 100) / 12;
        // Transfer stable token
        IERC20(erc20).transferFrom(_msgSender(), owner(), amount);

        IERC20(srgToken).transfer(_msgSender(), srgTokens);

        emit TokensClaimed(srgTokens);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _;
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    function addAcceptedStableCoin(address erc20) external onlyOwner {
        stableTokensAccepted[erc20] = true;
        emit AddedStableCoin(erc20);
    }

    function removeAcceptedStableCoin(address erc20) external onlyOwner {
        stableTokensAccepted[erc20] = false;
        emit RemovedStableCoin(erc20);
    }

    function addAdmin(address newAdmin) external onlyOwner {
        _setupRole(ADMIN_ROLE, newAdmin);
    }

    function revokeAdmin(address revokedAdmin) external onlyOwner {
        revokeRole(ADMIN_ROLE, revokedAdmin);
    }

    function getGoldMembers()
        external
        view
        onlyAdmin
        returns (address[] memory)
    {
        address[] memory goldMemberList = new address[](goldNumber.current());

        for (uint256 i = 0; i < goldNumber.current(); i++) {
            address goldMemberAddress = goldMembers[i];

            if (goldList[goldMemberAddress]) {
                goldMemberList[i] = goldMemberAddress;
            }
        }

        return goldMemberList;
    }
}