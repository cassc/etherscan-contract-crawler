// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../interfaces/IIdleCDOStrategy.sol";
import "../interfaces/IERC20Detailed.sol";
import "../interfaces/IERC4626.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

abstract contract ERC4626Strategy is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IIdleCDOStrategy
{
    using SafeERC20Upgradeable for IERC20Detailed;

    /// @notice underlying token address (ex: DAI)
    address public override token;

    /// @notice strategy token address (ex: fDAI)
    address public override strategyToken;

    /// @notice decimals of the underlying asset
    uint256 public override tokenDecimals;

    /// @notice one underlying token
    uint256 public override oneToken;

    /// @notice underlying ERC20 token contract
    IERC20Detailed public underlyingToken;

    /// @notice address of the IdleCDO
    address public idleCDO;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        token = address(1);
    }

    /// @notice can be only called once
    /// @param _strategyToken address of the vault token
    /// @param _token address of the underlying token
    /// @param _owner owner of this contract
    function _initialize(
        address _strategyToken,
        address _token,
        address _owner
    ) internal virtual initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        require(token == address(0), "Token is already initialized");

        //----- // -------//
        strategyToken = _strategyToken;
        token = _token;
        underlyingToken = IERC20Detailed(token);
        tokenDecimals = underlyingToken.decimals();
        oneToken = 10**(tokenDecimals); // underlying decimals
        //------//-------//

        transferOwnership(_owner);

        IERC20Detailed(_token).approve(_strategyToken, type(uint256).max);
    }

    /// @dev msg.sender should approve this contract first to spend `_amount` of `token`
    /// @param _amount amount of `token` to deposit
    /// @return shares strategyTokens minted
    function deposit(uint256 _amount) external virtual override onlyIdleCDO returns (uint256 shares) {
        if (_amount != 0) {
            // Send tokens to the strategy
            IERC20Detailed(token).safeTransferFrom(msg.sender, address(this), _amount);
            // Calls deposit function
            shares = IERC4626(strategyToken).deposit(_amount, msg.sender);
        }
    }

    /// @dev msg.sender should approve this contract first to spend `_amount` of `strategyToken`
    /// @param _shares amount of strategyTokens to redeem
    /// @return redeemed amount of underlyings redeemed
    function redeem(uint256 _shares) external virtual override onlyIdleCDO returns (uint256 redeemed) {
        return _redeem(_shares);
    }

    /// @notice Redeem Tokens
    /// @param _amount amount of underlying tokens to redeem
    /// @return redeemed amount of underlyings redeemed
    function redeemUnderlying(uint256 _amount) external virtual onlyIdleCDO returns (uint256 redeemed) {
        return _redeem(IERC4626(strategyToken).convertToShares(_amount));
    }

    function _redeem(uint256 _shares) internal virtual returns (uint256 redeemed) {
        if (_shares != 0) {
            IERC20Detailed(strategyToken).safeTransferFrom(msg.sender, address(this), _shares);
            redeemed = IERC4626(strategyToken).redeem(_shares, msg.sender, address(this));
        }
    }

    /// @notice redeem the rewards
    /// @return rewards amount of reward that is deposited to the ` strategy`
    function redeemRewards(bytes calldata data)
        public
        virtual
        onlyIdleCDO
        nonReentrant
        returns (uint256[] memory rewards)
    {}

    /// @dev deprecated method
    /// @notice pull stkedAave
    function pullStkAAVE() external override returns (uint256 pulledAmount) {}

    /// @notice net price in underlyings of 1 strategyToken
    /// @return _price denominated in decimals of underlyings
    function price() public view virtual override returns (uint256) {
        IERC4626 vault = IERC4626(strategyToken);
        return vault.convertToAssets(10**vault.decimals());
    }

    function getApr() external view virtual returns (uint256 apr);

    /// @notice This contract should not have funds at the end of each tx (except for stkAAVE), this method is just for leftovers
    /// @dev Emergency method
    /// @param _token address of the token to transfer
    /// @param value amount of `_token` to transfer
    /// @param _to receiver address
    function transferToken(
        address _token,
        uint256 value,
        address _to
    ) external onlyOwner nonReentrant {
        IERC20Detailed(_token).safeTransfer(_to, value);
    }

    /// @notice allow to update whitelisted address
    function setWhitelistedCDO(address _cdo) external onlyOwner {
        require(_cdo != address(0), "IS_0");
        idleCDO = _cdo;
    }

    /// @notice Modifier to make sure that caller os only the idleCDO contract
    modifier onlyIdleCDO() {
        require(idleCDO == msg.sender, "Only IdleCDO can call");
        _;
    }
}