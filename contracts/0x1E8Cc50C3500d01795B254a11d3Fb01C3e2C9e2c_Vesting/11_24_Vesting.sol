// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./libraries/ExceptionsLibrary.sol";
import "./interfaces/registry/IRegistry.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IVesting.sol";

contract Vesting is Initializable, IVesting {
    using SafeERC20Upgradeable for IToken;

    // CONSTANTS

    /// @notice Denominator for shares
    uint256 private constant DENOM = 100 * 10 ** 4;

    // STORAGE

    /// @notice Registry contract
    IRegistry public registry;

    /// @notice Mapping of TGE addresses to total amount of tokens vested there
    mapping(address => uint256) public totalVested;

    /// @notice Mapping (tge, account) to amount of tokens vested to that account in TGE
    mapping(address => mapping(address => uint256)) public vested;

    /// @notice Mapping (tge, account) to amount of already claimed vested tokens to that account in TGE
    mapping(address => mapping(address => uint256)) public claimed;

    /// @notice Mapping of TGE addresses to flags if claim TVL is reached for TGE
    /// @dev Users can claim their tokens only if claim TVL was reached.
    mapping(address => bool) public claimTVLReached;

    /// @notice Mapping (tge, account) to amount of resolved tokens in TGE
    mapping(address => mapping(address => uint256)) public resolved;

    // EVENTS

    /**
     * @dev Event emitted on token vesting.
     * @param tge TGE address
     * @param account Claimer address
     * @param amount Amount of vested tokens
     */
    event Vested(address tge, address account, uint256 amount);

    /**
     * @dev Event emitted on vested tokens recall
     * @param tge TGE address
     * @param account User address
     * @param amount Amount of recalled tokens
     */
    event Recall(address tge, address account, uint256 amount);

    /**
     * @dev Event emitted on token claim.
     * @param tge TGE address
     * @param account Claimer address
     * @param amount Amount of claimed tokens
     */
    event Claimed(address tge, address account, uint256 amount);

    /**
     * @dev Event emitted on vesting cancellation for account by resolver
     * @param tge TGE address
     * @param account Account address
     * @param amount Amount of burnt tokens
     */
    event Cancelled(address tge, address account, uint256 amount);

    // MODIFIERS

    modifier onlyTGE() {
        require(
            registry.typeOf(msg.sender) == IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    modifier onlyManager() {
        IService service = registry.service();
        require(
            service.hasRole(service.SERVICE_MANAGER_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier onlyResolverOrTGE(address tge) {
        if (msg.sender != tge) {
            address[] memory resolvers = ITGE(tge)
                .getInfo()
                .vestingParams
                .resolvers;
            bool isResolver;
            for (uint256 i = 0; i < resolvers.length; i++) {
                if (resolvers[i] == msg.sender) {
                    isResolver = true;
                    break;
                }
            }
            require(isResolver, ExceptionsLibrary.NOT_RESOLVER);
        }
        _;
    }

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract initializer
     * @param registry_ Protocol registry address
     */
    function initialize(IRegistry registry_) external initializer {
        registry = registry_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @notice Vests token to given account (only called by TGE)
     * @param to Address to vest tokens to
     * @param amount Amount of tokens to vest
     */
    function vest(address to, uint256 amount) external onlyTGE {
        totalVested[msg.sender] += amount;
        vested[msg.sender][to] += amount;

        emit Vested(msg.sender, to, amount);
    }

    /**
     * @notice Set's claim TVL reached for TGE (only called by manager)
     * @param tge Adddress of the TGE
     */
    function setClaimTVLReached(address tge) external onlyManager {
        require(
            ITGE(tge).state() == ITGE.State.Successful,
            ExceptionsLibrary.WRONG_STATE
        );
        claimTVLReached[tge] = true;
    }

    /**
     * @notice Cancels vesting for given account in given tge, burning all remaining tokens (only called by TGE resolver or TGE)
     * @param tge TGE address
     * @param account Account address
     */
    function cancel(
        address tge,
        address account
    ) external onlyResolverOrTGE(tge) {
        uint256 amount = vestedBalanceOf(tge, account);

        vested[tge][account] -= amount;
        totalVested[tge] -= amount;

        resolved[tge][account] += amount;

        emit Cancelled(tge, account, amount);
    }

    /**
     * @notice Claims unlocked tokens from given TGE
     * @param tge TGE to claim from
     */
    function claim(address tge) external {
        uint256 amount = claimableBalanceOf(tge, msg.sender);
        require(amount > 0, ExceptionsLibrary.CLAIM_NOT_AVAILABLE);

        claimed[tge][msg.sender] += amount;
        totalVested[tge] -= amount;

        address token = ITGE(tge).token();
        uint256 tokenId = ITGE(tge).tokenId();
        if (ITGE(tge).isERC1155TGE()) {
            ITokenERC1155(token).setTGEVestedTokens(
                ITokenERC1155(token).getTotalTGEVestedTokens(tokenId) - amount,
                tokenId
            );

            ITokenERC1155(token).mint(msg.sender, tokenId, amount);
        } else {
            IToken(token).setTGEVestedTokens(
                IToken(token).getTotalTGEVestedTokens() - amount
            );

            IToken(token).mint(msg.sender, amount);
        }
        emit Claimed(tge, msg.sender, amount);
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @notice Gets vesting params for TGE
     * @param tge TGE address
     */
    function vestingParams(
        address tge
    ) public view returns (VestingParams memory) {
        return ITGE(tge).getInfo().vestingParams;
    }

    /**
     * @notice Validates vesting params for TGE
     * @param params Vesting params
     * @return True if params are valid (reverts otherwise)
     */
    function validateParams(
        VestingParams memory params
    ) public pure returns (bool) {
        require(
            params.cliffShare + params.spans * params.spanShare <= DENOM,
            ExceptionsLibrary.SHARES_SUM_EXCEEDS_ONE
        );
        return true;
    }

    /**
     * @notice Gets total unlocked balance of account in TGE (including already claimed tokens)
     * @param tge TGE address
     * @param account Account address
     */
    function unlockedBalanceOf(
        address tge,
        address account
    ) public view returns (uint256) {
        // In active or failed TGE nothing is unlocked
        if (ITGE(tge).state() != ITGE.State.Successful) {
            return 0;
        }

        // Is claim TVL is non-zero and is not reached, nothing is unlocked
        VestingParams memory params = vestingParams(tge);
        if (params.claimTVL > 0 && !claimTVLReached[tge]) {
            return 0;
        }

        // Determine unlocked amount
        uint256 tgeEnd = ITGE(tge).getEnd();
        if (block.number < tgeEnd + params.cliff) {
            // If cliff is not exceeded, nothing is unlocked yet
            return 0;
        } else if (
            block.number <
            tgeEnd + params.cliff + params.spans * params.spanDuration
        ) {
            // If cliff is reached, but not all the period passed, calculate vested amount
            uint256 spansUnlocked = (block.number - tgeEnd - params.cliff) /
                params.spanDuration;
            uint256 totalShare = params.cliffShare +
                spansUnlocked *
                params.spanShare;
            return (vested[tge][account] * totalShare) / DENOM;
        } else {
            // Otherwise everything is unlocked
            return vested[tge][account];
        }
    }

    /**
     * @notice Gets claimable balance of account in TGE
     * @param tge TGE address
     * @param account Account address
     */
    function claimableBalanceOf(
        address tge,
        address account
    ) public view returns (uint256) {
        return unlockedBalanceOf(tge, account) - claimed[tge][account];
    }

    /**
     * @notice Gets remaining vested balance of account in TGE (all unclaimed tokens, even locked)
     * @param tge TGE address
     * @param account Account address
     */
    function vestedBalanceOf(
        address tge,
        address account
    ) public view returns (uint256) {
        return vested[tge][account] - claimed[tge][account];
    }
}