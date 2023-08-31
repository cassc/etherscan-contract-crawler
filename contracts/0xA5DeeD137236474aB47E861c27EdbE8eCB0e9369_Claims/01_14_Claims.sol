// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Utils} from "./Utils.sol";

interface DopPreSale {
    function rounds(
        uint8 round
    ) external view returns (uint256 startTime, uint256 endTime, uint256 price);
}

contract Claims is AccessControl, Utils {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice Thrown when input arrays length doesnot match
    error ArgumentsLengthMismatch();

    /// @notice Thrown when no amounts are zero
    error ZeroClaimAmount();

    /// @notice Thrown when input array length is zero
    error InvalidData();

    /// @notice Thrown when zero address is passed while updating to new value
    error ZeroAddress();

    /// @notice Thrown when same value is passed while updating any variable
    error IdenticalValues();

    /// @notice Thrown when claiming before round ends
    error RoundNotEnded();

    /// @notice Thrown when round is not Enabled
    error RoundNotEnabled();

    /// @notice Thrown when COMMISSIONS_MANAGER wants to set claim while claim enable
    error WaitForRoundDisable();

    bytes32 public constant COMMISSIONS_MANAGER =
        keccak256("COMMISSIONS_MANAGER");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    ///@notice The address of dop token presale contract
    DopPreSale public dopPreSale;

    ///@notice The address of the USDT token
    IERC20 public immutable USDT;

    /// @member amountEth The Eth amount
    /// @member amountUsd The Usd amount
    struct Info {
        uint256 amountEth;
        uint256 amountUsd;
    }

    /// @notice mapping gives amount to claim in each round
    mapping(address => mapping(uint8 => Info)) public toClaim;

    /// @notice mapping stores the access of a round
    mapping(uint8 => bool) public isEnabled;

    /* ========== EVENTS ========== */
    event ClaimSet(
        address[] indexed to,
        uint8 indexed round,
        uint256[] amountsEth,
        uint256[] amountsUsd
    );
    event FundsClaimed(
        address indexed by,
        uint256 amountEth,
        uint256 amountUsd
    );
    event RoundEnableUpdated(bool oldAccess, bool newAccess);
    event DopPreSaleUpdated(address oldDopPreSale, address newDopPreSale);

    /// @dev Constructor.
    /// @param usdt The address of usdt contract
    constructor(IERC20 usdt) {
        if (address(usdt) == address(0)) {
            revert ZeroAddress();
        }
        USDT = usdt;
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(COMMISSIONS_MANAGER, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Person with COMMISSIONS_MANAGER role will call this and set amounts to addresses in a round
    /// @param to The array of addresses
    /// @param round The round value
    /// @param amountsEth The amounts is array of amounts of the to addresses
    /// @param amountsUsd The amounts is array of amounts of the to addresses
    function setClaim(
        address[] calldata to,
        uint8 round,
        uint256[] calldata amountsEth,
        uint256[] calldata amountsUsd
    ) external onlyRole(COMMISSIONS_MANAGER) {
        if (isEnabled[round]) {
            revert WaitForRoundDisable();
        }
        uint256 toLength = to.length;
        if (toLength == 0) {
            revert InvalidData();
        }
        if (
            toLength != amountsEth.length &&
            amountsEth.length != amountsUsd.length
        ) {
            revert ArgumentsLengthMismatch();
        }
        for (uint256 i; i < toLength; i = uncheckedInc(i)) {
            Info storage infoClaim = toClaim[to[i]][round];
            if (amountsEth[i] > 0) {
                infoClaim.amountEth = amountsEth[i];
            }
            if (amountsUsd[i] > 0) {
                infoClaim.amountUsd = amountsUsd[i];
            }
        }
        emit ClaimSet({
            to: to,
            round: round,
            amountsEth: amountsEth,
            amountsUsd: amountsUsd
        });
    }

    /// @notice The addresses set for claim will claim their amounts
    /// @param round The round in which they can claim
    function claim(uint8 round) external {
        if (!isEnabled[round]) {
            revert RoundNotEnabled();
        }
        (, uint256 endTime, ) = dopPreSale.rounds(round);
        if (block.timestamp < endTime) {
            revert RoundNotEnded();
        }
        Info memory info = toClaim[msg.sender][round];
        if (info.amountEth == 0 && info.amountUsd == 0) {
            revert ZeroClaimAmount();
        }
        delete toClaim[msg.sender][round];
        if (info.amountEth > 0) {
            payable(msg.sender).sendValue(info.amountEth);
        }
        if (info.amountUsd > 0) {
            USDT.safeTransfer(msg.sender, info.amountUsd);
        }
        emit FundsClaimed({
            by: msg.sender,
            amountEth: info.amountEth,
            amountUsd: info.amountUsd
        });
    }

    /// @notice Changes dopPreSale contract to a new address
    /// @param dopPreSaleAddress The new dopPresale contract address
    function updatePreSaleAddress(
        DopPreSale dopPreSaleAddress
    ) external onlyRole(ADMIN_ROLE) {
        if (address(dopPreSaleAddress) == address(0)) {
            revert ZeroAddress();
        }
        if (dopPreSale == dopPreSaleAddress) {
            revert IdenticalValues();
        }
        emit DopPreSaleUpdated({
            oldDopPreSale: address(dopPreSale),
            newDopPreSale: address(dopPreSaleAddress)
        });
        dopPreSale = dopPreSaleAddress;
    }

    /// @notice Changes the access of contract to true or false, When true , user's function
    /// interactions will be suspended
    /// @param round The round number that will be enabled or disabled
    /// @param decision The access decision for the round
    function updateEnable(
        uint8 round,
        bool decision
    ) public onlyRole(COMMISSIONS_MANAGER) {
        bool oldAccess = isEnabled[round];
        if (oldAccess == decision) {
            revert IdenticalValues();
        }
        emit RoundEnableUpdated({oldAccess: oldAccess, newAccess: decision});
        isEnabled[round] = decision;
    }

    receive() external payable {}
}