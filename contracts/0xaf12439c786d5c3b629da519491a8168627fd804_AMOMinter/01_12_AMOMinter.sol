// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAgToken.sol";
import "../interfaces/IAMO.sol";
import "../interfaces/IAMOMinter.sol";
import "../interfaces/ICoreBorrow.sol";

/// @title AMOMinter
/// @author Angle Core Team
/// @notice Manages Algorithmic Market Operations (AMOs) of the Angle Protocol
/// @dev This contract supports AMOs on the protocol's native agTokens and on any ERC20 token
/// @dev Inspired from https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Frax/FraxAMOMinter.sol
contract AMOMinter is Initializable, IAMOMinter {
    using SafeERC20 for IERC20;

    /// @notice `coreBorrow` used to check roles
    ICoreBorrow public coreBorrow;
    /// @notice Array of all supported AMOs
    IAMO[] public amoList;
    /// @notice Maps an AMO to whether it is whitelisted
    mapping(IAMO => uint256) public amosWhitelist;
    /// @notice Maps an AMO to whether an address can call the `sendToAMO`/`receiveFromAMO` functions associated to it
    mapping(IAMO => mapping(address => uint256)) public amosWhitelistCaller;
    /// @notice Maps an AMO to whether it is whitelisted or not for a particular token
    mapping(IAMO => mapping(IERC20 => uint256)) public amosWhitelistToken;
    /// @notice Maps each AMO to the list of tokens it currently supports
    mapping(IAMO => IERC20[]) public amoTokens;
    /// @notice Max amount borrowable by each `(AMO,token)` pair
    mapping(IAMO => mapping(IERC20 => uint256)) public borrowCaps;
    /// @notice AMO debt to the AMOMinter for a given token
    mapping(IAMO => mapping(IERC20 => uint256)) public amoDebts;

    uint256[42] private __gap;

    // =============================== Events ======================================

    event AMOAdded(IAMO indexed amo);
    event AMOMinterUpdated(address indexed _amoMinter);
    event AMORemoved(IAMO indexed amo);
    event AMORightOnTokenAdded(IAMO indexed amo, IERC20 indexed token);
    event AMORightOnTokenRemoved(IAMO indexed amo, IERC20 indexed token);
    event BorrowCapUpdated(IAMO indexed amo, IERC20 indexed token, uint256 borrowCap);
    event CoreBorrowUpdated(ICoreBorrow indexed _coreBorrow);
    event Recovered(address indexed tokenAddress, address indexed to, uint256 amountToRecover);

    // =============================== Errors ======================================

    error AMOAlreadyAdded();
    error AMONonExistent();
    error AMONotWhitelisted();
    error AMOTokenDebtNotRepaid();
    error AMOWhitelisted();
    error BorrowCapReached();
    error IncompatibleLengths();
    error NoRightsOnToken();
    error NotApprovedCaller();
    error NotGovernor();
    error SupportedTokensNotRemoved();
    error ZeroAddress();

    // =============================== Initialisation ==============================

    /// @notice Initializes the `AMOMinter` contract and the access control
    /// @param coreBorrow_ Address of the associated `CoreBorrow` contract needed for checks on roles
    function initialize(ICoreBorrow coreBorrow_) public initializer {
        if (address(coreBorrow_) == address(0)) revert ZeroAddress();
        coreBorrow = coreBorrow_;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // =============================== Modifiers ===================================

    /// @notice Checks whether the `msg.sender` has the governor role or not
    modifier onlyGovernor() {
        if (!coreBorrow.isGovernor(msg.sender)) revert NotGovernor();
        _;
    }

    /// @notice Checks whether the `msg.sender` has the guardian role or not
    modifier onlyApproved(IAMO amo) {
        if (!coreBorrow.isGovernorOrGuardian(msg.sender) && amosWhitelistCaller[amo][msg.sender] != 1)
            revert NotApprovedCaller();
        _;
    }

    // ========================= View Functions ====================================

    /// @inheritdoc IAMOMinter
    function isGovernor(address admin) external view returns (bool) {
        return coreBorrow.isGovernor(admin);
    }

    /// @inheritdoc IAMOMinter
    function isApproved(address admin) external view returns (bool) {
        return (coreBorrow.isGovernorOrGuardian(admin) || amosWhitelistCaller[IAMO(msg.sender)][admin] == 1);
    }

    /// @inheritdoc IAMOMinter
    function callerDebt(IERC20 token) external view returns (uint256) {
        return amoDebts[IAMO(msg.sender)][token];
    }

    /// @notice Returns the list of all AMOs supported by this contract
    function allAMOAddresses() external view returns (IAMO[] memory) {
        return amoList;
    }

    /// @notice Returns the list of all the tokens supported by a given AMO
    function allAMOTokens(IAMO amo) external view returns (IERC20[] memory) {
        return amoTokens[amo];
    }

    // ============================== External function ============================

    /// @notice Lets someone reimburse the debt of an AMO on behalf of this AMO
    /// @param tokens Addresses of tokens for which debt should be reduced
    /// @param amounts Amounts of debt reduction to perform
    /// @dev Caller should have approved the `AMOMinter` contract and have enough tokens in balance
    /// @dev We typically expect this function to be called by governance to balance gains and losses
    /// between AMOs
    function repayDebtFor(
        IAMO[] memory amos,
        IERC20[] memory tokens,
        uint256[] memory amounts
    ) external {
        if (tokens.length != amos.length || tokens.length != amounts.length || tokens.length == 0)
            revert IncompatibleLengths();
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].safeTransferFrom(msg.sender, address(this), amounts[i]);
            // Keep track of the changed debt
            amoDebts[amos[i]][tokens[i]] -= amounts[i];
        }
    }

    // ======================== Only Approved for AMO Functions ====================

    /// @inheritdoc IAMOMinter
    function sendToAMO(
        IAMO amo,
        IERC20[] memory tokens,
        bool[] memory isStablecoin,
        uint256[] memory amounts,
        bytes[] memory data
    ) external onlyApproved(amo) {
        if (tokens.length != isStablecoin.length || tokens.length != amounts.length || tokens.length == 0)
            revert IncompatibleLengths();
        // First fill the tank for the AMO
        for (uint256 i = 0; i < tokens.length; i++) {
            // Checking if `token` has been whitelisted for `amo`
            if (amosWhitelistToken[amo][tokens[i]] != 1) revert NoRightsOnToken();
            // Keeping track of the changed debt and making sure you aren't lending more than the borrow cap
            if (amoDebts[amo][tokens[i]] + amounts[i] > borrowCaps[amo][tokens[i]]) revert BorrowCapReached();
            amoDebts[amo][tokens[i]] += amounts[i];
            // Minting the token to the AMO or simply transferring collateral to it
            if (isStablecoin[i]) IAgToken(address(tokens[i])).mint(address(amo), amounts[i]);
            else tokens[i].transfer(address(amo), amounts[i]);
        }
        // Then notify to the AMO that the tank was filled
        IAMO(amo).push(tokens, amounts, data);
    }

    /// @inheritdoc IAMOMinter
    function receiveFromAMO(
        IAMO amo,
        IERC20[] memory tokens,
        bool[] memory isStablecoin,
        uint256[] memory amounts,
        address[] memory to,
        bytes[] memory data
    ) external onlyApproved(amo) {
        if (
            tokens.length != isStablecoin.length ||
            tokens.length != amounts.length ||
            tokens.length != to.length ||
            tokens.length == 0
        ) revert IncompatibleLengths();
        // First notify that we want to recover tokens
        uint256[] memory amountsAvailable = IAMO(amo).pull(tokens, amounts, data);
        // Then empty the tank of the amo
        for (uint256 i = 0; i < tokens.length; i++) {
            // No need to check if the token is whitelisted for the AMO, because otherwise there will be
            // an underflow when updating `amoDebts`
            uint256 amount = amounts[i] <= amountsAvailable[i] ? amounts[i] : amountsAvailable[i];
            // Burn the agToken from the AMO or simply transfer it to this address
            if (isStablecoin[i])
                IAgToken(address(tokens[i])).burnSelf(amount, address(amo));
                // Transfer the collateral to the AMO
            else tokens[i].safeTransferFrom(address(amo), to[i], amount);
            // Keep track of the changed debt
            amoDebts[amo][tokens[i]] -= amount;
        }
    }

    // =============================== AMO Management ==============================

    /// @notice Adds an AMO to the whitelist
    /// @param amo Address of the AMO to be whitelisted
    function addAMO(IAMO amo) public onlyGovernor {
        if (address(amo) == address(0)) revert ZeroAddress();
        if (amosWhitelist[amo] == 1) revert AMOAlreadyAdded();
        amosWhitelist[amo] = 1;
        amoList.push(amo);
        emit AMOAdded(amo);
    }

    /// @notice Removes an AMO from whitelist
    /// @param amo Address of the AMO to be removed
    /// @dev To be successfully removed the AMO should no longer be associated to a token
    function removeAMO(IAMO amo) public onlyGovernor {
        if (address(amo) == address(0)) revert ZeroAddress();
        if (amosWhitelist[amo] != 1) revert AMONonExistent();
        if (amoTokens[amo].length > 0) revert SupportedTokensNotRemoved();
        // Removing the whitelisting first
        delete amosWhitelist[amo];

        // Deletion from `amoList` list then
        IAMO[] memory amoAllowed = amoList;
        uint256 amoListLength = amoAllowed.length;
        for (uint256 i = 0; i < amoListLength - 1; i++) {
            if (amoAllowed[i] == amo) {
                // Replace the `amo` to remove with the last of the list
                amoList[i] = amoList[amoListLength - 1];
                break;
            }
        }
        // Remove last element in array
        amoList.pop();

        emit AMORemoved(amo);
    }

    /// @notice Adds right for `token` to the `amo`
    /// @param amo Address of the AMO which will have rights on `token`
    /// @param token Address of the token to be whitelisted for the `amo`
    function addTokenRightToAMO(
        IAMO amo,
        IERC20 token,
        uint256 borrowCap
    ) public onlyGovernor {
        if (address(token) == address(0)) revert ZeroAddress();
        if (amosWhitelistToken[amo][token] == 1) revert AMOWhitelisted();
        if (amosWhitelist[amo] != 1) addAMO(amo);
        amosWhitelistToken[amo][token] = 1;
        amoTokens[amo].push(token);
        borrowCaps[amo][token] = borrowCap;
        amo.setToken(token);
        emit AMORightOnTokenAdded(amo, token);
        emit BorrowCapUpdated(amo, token, borrowCap);
    }

    /// @notice Removes the right on `token` from the `amo`
    /// @param amo Address of the AMO who will lose rights on `token`
    /// @param token Address of the `token`
    function removeTokenRightFromAMO(IAMO amo, IERC20 token) public onlyGovernor {
        if (amosWhitelistToken[amo][token] != 1) revert AMONotWhitelisted();
        if (amoDebts[amo][token] > 0) revert AMOTokenDebtNotRepaid();
        // Removing the whitelisting first
        delete amosWhitelistToken[amo][token];
        // Resetting borrow cap
        delete borrowCaps[amo][token];

        // Deletion from `amoTokens[amo]` loop
        IERC20[] memory tokenAllowed = amoTokens[amo];
        uint256 amoTokensLength = tokenAllowed.length;
        for (uint256 i = 0; i < amoTokensLength - 1; i++) {
            if (tokenAllowed[i] == token) {
                // Replace the `amo` to remove with the last of the list
                amoTokens[amo][i] = amoTokens[amo][amoTokensLength - 1];
                break;
            }
        }
        // Removing the last element in an array
        amoTokens[amo].pop();
        amo.removeToken(token);

        emit AMORightOnTokenRemoved(amo, token);
        emit BorrowCapUpdated(amo, token, 0);
    }

    /// @notice Toggles the approval right for an address on an AMO
    /// @param amo Address of the AMO
    /// @param whitelistCaller Address of the caller that needs right on send / receive
    /// functions associated to the AMo
    function toggleCallerToAMO(IAMO amo, address whitelistCaller) public onlyGovernor {
        if (address(whitelistCaller) == address(0)) revert ZeroAddress();
        if (amosWhitelist[amo] != 1) revert AMONonExistent();
        amosWhitelistCaller[amo][whitelistCaller] = 1 - amosWhitelistCaller[amo][whitelistCaller];
    }

    // =============================== Setters =====================================

    /// @notice Sets the borrow cap for a given token and a given amo
    /// @param amo AMO concerned by the change
    /// @param token Token associated to the AMO
    /// @param borrowCap New borrow cap value
    function setBorrowCap(
        IAMO amo,
        IERC20 token,
        uint256 borrowCap
    ) external onlyGovernor {
        if (amosWhitelistToken[amo][token] != 1) revert AMONotWhitelisted();
        borrowCaps[amo][token] = borrowCap;
        emit BorrowCapUpdated(amo, token, borrowCap);
    }

    /// @notice Changes the AMOMinter contract and propagates this change to all underlying AMO contracts
    /// @param amoMinter Address of the new `amoMinter` contract
    function setAMOMinter(address amoMinter) external onlyGovernor {
        if (amoMinter == address(0)) revert ZeroAddress();
        IAMO[] memory amoAllowed = amoList;
        for (uint256 i = 0; i < amoAllowed.length; i++) {
            amoAllowed[i].setAMOMinter(amoMinter);
        }
        emit AMOMinterUpdated(amoMinter);
    }

    /// @notice Sets a new `coreBorrow` contract
    /// @dev This function should typically be called on all treasury contracts after the `setCore`
    /// function has been called on the `CoreBorrow` contract
    /// @dev One sanity check that can be performed here is to verify whether at least the governor
    /// calling the contract is still a governor in the new core
    function setCoreBorrow(ICoreBorrow _coreBorrow) external onlyGovernor {
        if (!_coreBorrow.isGovernor(msg.sender)) revert NotGovernor();
        coreBorrow = ICoreBorrow(_coreBorrow);
        emit CoreBorrowUpdated(_coreBorrow);
    }

    // =============================== Generic functions ===========================

    /// @notice Recovers any ERC20 token
    /// @dev Can be used to withdraw bridge tokens for them to be de-bridged on mainnet
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyGovernor {
        IERC20(tokenAddress).safeTransfer(to, amountToRecover);
        emit Recovered(tokenAddress, to, amountToRecover);
    }

    /// @notice Generic function to execute arbitrary calls with the contract
    function execute(address _to, bytes calldata _data) external onlyGovernor returns (bool, bytes memory) {
        //solhint-disable-next-line
        (bool success, bytes memory result) = _to.call(_data);
        return (success, result);
    }
}