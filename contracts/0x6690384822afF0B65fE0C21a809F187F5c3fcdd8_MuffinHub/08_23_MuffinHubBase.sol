// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/hub/IMuffinHubBase.sol";
import "./interfaces/common/IERC20Minimal.sol";
import "./libraries/Pools.sol";

abstract contract MuffinHubBase is IMuffinHubBase {
    error FailedBalanceOf();
    error NotEnoughTokenInput();

    /// @param locked           1 means locked. 0 or 2 means unlocked.
    /// @param protocolFeeAmt   Amount of token accrued as the protocol fee
    struct TokenData {
        uint8 locked;
        uint248 protocolFeeAmt;
    }

    struct Pair {
        address token0;
        address token1;
    }

    /// @inheritdoc IMuffinHubBase
    address public governance;
    /// @dev Default tick spacing of new pool
    uint8 internal defaultTickSpacing = 100;
    /// @dev Default protocl fee of new pool (base 255)
    uint8 internal defaultProtocolFee = 0;
    /// @dev Whitelist of swap fees that LPs can choose to create a pool
    uint24[] internal defaultAllowedSqrtGammas = [99900, 99800, 99700, 99600, 99499]; // 20, 40, 60, 80, 100 bps

    /// @dev Pool-specific default tick spacing
    mapping(bytes32 => uint8) internal poolDefaultTickSpacing;
    /// @dev Pool-specific whitelist of swap fees
    mapping(bytes32 => uint24[]) internal poolAllowedSqrtGammas;

    /// @dev Mapping of poolId to pool state
    mapping(bytes32 => Pools.Pool) internal pools;
    /// @inheritdoc IMuffinHubBase
    mapping(address => mapping(bytes32 => uint256)) public accounts;
    /// @inheritdoc IMuffinHubBase
    mapping(address => TokenData) public tokens;
    /// @inheritdoc IMuffinHubBase
    mapping(bytes32 => Pair) public underlyings;

    /// @dev We blacklist TUSD legacy address on Ethereum to prevent TUSD from getting exploited here.
    /// In general, tokens with multiple addresses are not supported here and will cost losts of fund.
    address internal constant TUSD_LEGACY_ADDRESS = 0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;

    /// @notice Maximum number of tiers each pool can technically have. This number might vary in different networks.
    function maxNumOfTiers() external pure returns (uint256) {
        return MAX_TIERS;
    }

    /// @dev Get token balance of this contract
    function getBalance(address token) private view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this))
        );
        if (!success || data.length != 32) revert FailedBalanceOf();
        return abi.decode(data, (uint256));
    }

    /// @dev "Lock" the token so the token cannot be used as input token again until unlocked
    function getBalanceAndLock(address token) internal returns (uint256) {
        require(token != TUSD_LEGACY_ADDRESS);

        TokenData storage tokenData = tokens[token];
        require(tokenData.locked != 1); // 1 means locked
        tokenData.locked = 1;
        return getBalance(token);
    }

    /// @dev "Unlock" the token after ensuring the contract reaches an expected token balance
    function checkBalanceAndUnlock(address token, uint256 balanceMinimum) internal {
        if (getBalance(token) < balanceMinimum) revert NotEnoughTokenInput();
        tokens[token].locked = 2;
    }

    /// @dev Hash (owner, accRefId) as the key for the internal account
    function getAccHash(address owner, uint256 accRefId) internal pure returns (bytes32) {
        require(accRefId != 0);
        return keccak256(abi.encode(owner, accRefId));
    }

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }
}