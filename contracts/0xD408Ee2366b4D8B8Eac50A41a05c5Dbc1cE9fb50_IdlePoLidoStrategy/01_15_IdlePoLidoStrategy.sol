// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../interfaces/IIdleCDOStrategy.sol";
import "../../interfaces/IERC20Detailed.sol";
import "../../interfaces/IStMatic.sol";
import "../../interfaces/IPoLidoNFT.sol";
import "../../interfaces/IWstETH.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @author Idle Labs Inc.
/// @title IdlePoLidoStrategy
/// @notice IIdleCDOStrategy to deploy funds in Idle Finance
/// @dev This contract should not have any funds at the end of each tx.
/// The contract is upgradable, to add storage slots, add them after the last `###### End of storage VXX`
contract IdlePoLidoStrategy is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IIdleCDOStrategy {
    using SafeERC20Upgradeable for IERC20Detailed;
    using SafeERC20Upgradeable for IStMATIC;

    /// ###### Storage V1
    /// @notice seconds in year
    uint256 private constant SECONDS_IN_YEAR = 365 * 24 * 60 * 60;
    /// @notice address of the strategy used
    address public override strategyToken;
    /// @notice underlying token address
    address public override token;
    /// @notice one underlying token. MATIC has 18 decimals.
    uint256 public constant override oneToken = 10**18;
    /// @notice decimals of the underlying asset
    uint256 public constant override tokenDecimals = 18;

    /// @notice LDO contract (manually distributed as rewards)
    address public constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;
    /// @notice Matic contract
    IERC20Detailed public constant MATIC = IERC20Detailed(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);

    /// @notice stMatic contract
    IStMATIC public constant stMatic = IStMATIC(0x9ee91F9f426fA633d227f7a9b000E28b9dfd8599);

    address public whitelistedCDO;
    address public constant TREASURY = 0xFb3bD022D5DAcF95eE28a6B07825D4Ff9C5b3814;

    /// ###### End of storage V1

    // Used to prevent initialization of the implementation contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        token = address(1);
    }

    // ###################
    // Initializer
    // ###################

    /// @notice can only be called once
    /// @dev Initialize the upgradable contract
    /// @param _owner owner address
    function initialize(address _owner) public initializer {
        require(token == address(0), "Initialized");
        // Initialize contracts
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        // Set basic parameters
        strategyToken = address(stMatic);
        token = address(MATIC);

        MATIC.safeApprove(address(stMatic), type(uint256).max);
        // transfer ownership
        transferOwnership(_owner);
    }

    // ###################
    // Public methods
    // ###################

    /// @dev msg.sender should approve this contract first to spend `_amount` of `token`
    /// @param _amount amount of `token` to deposit
    /// @return minted strategyTokens minted
    function deposit(uint256 _amount) external override onlyIdleCDO returns (uint256 minted) {
        if (_amount > 0) {
            /// get MATIC from msg.sender
            MATIC.safeTransferFrom(msg.sender, address(this), _amount);
            // mints stMATIC
            minted = stMatic.submit(_amount, TREASURY);
            /// transfer stMATIC to msg.sender
            stMatic.safeTransfer(msg.sender, minted);
        }
    }

    /// @dev msg.sender should approve this contract first to spend `_amount` of `strategyToken`
    /// @param _amount amount of strategyTokens to redeem
    /// @return amount of underlyings redeemed
    function redeem(uint256 _amount) external override onlyIdleCDO returns (uint256) {
        return _redeem(_amount);
    }

    /// NOTE: stkAAVE rewards are not sent back to the use but accumulated in this contract until 'pullStkAAVE' is called
    /// @dev msg.sender should approve this contract first to spend `_amount` of `strategyToken`.
    /// redeem rewards and transfer them to msg.sender
    function redeemRewards(bytes calldata) external override returns (uint256[] memory _balances) {}

    /// @dev msg.sender should approve this contract first
    /// @param _amount amount of underlying tokens to redeem
    /// @return tokenId of the NFT minted
    function redeemUnderlying(uint256 _amount) external override onlyIdleCDO returns (uint256) {
        // we are getting price before transferring so price of msg.sender
        (uint256 amountToRedeem, , ) = stMatic.convertMaticToStMatic(_amount);
        return _redeem(amountToRedeem);
    }

    // ###################
    // Internal
    // ###################

    /// @dev msg.sender should approve this contract first to spend `_amount` of `strategyToken`
    /// @param _amount amount of strategyTokens to redeem
    /// @return _redeemed amount of underlyings redeemed
    function _redeem(uint256 _amount) internal returns (uint256 _redeemed) {
        if (_amount > 0) {
            // get stMATIC from msg.sender
            stMatic.safeTransferFrom(msg.sender, address(this), _amount);

            // send request to withdraw stMATIC and receive an nft which can be used later to claim the amount.
            stMatic.requestWithdraw(_amount, TREASURY);

            IPoLidoNFT poLidoNFT = stMatic.poLidoNFT();
            // transfer nft to msg.sender
            uint256[] memory tokenIds = poLidoNFT.getOwnedTokens(address(this));

            // NOTE: assume last token is the one we just minted.
            uint256 tokenId = tokenIds[tokenIds.length - 1];
            poLidoNFT.safeTransferFrom(address(this), msg.sender, tokenId);

            _redeemed = stMatic.getMaticFromTokenId(tokenId);
        }
    }

    // ###################
    // Views
    // ###################

    /// @return net price in underlyings of 1 strategyToken
    function price() public view override returns (uint256) {
        (uint256 balanceInMATIC, , ) = stMatic.convertStMaticToMatic(oneToken);
        return balanceInMATIC;
    }

    /// @dev values returned by this method should be taken as an imprecise estimation.
    ///      For client integration something more complex should be done to have a more precise
    ///      estimate (eg. computing APR using historical APR data).
    /// @return apr : net apr
    function getApr() external view override returns (uint256 apr) {
        // Not available
    }

    /// @return tokens array of reward token addresses
    function getRewardTokens() external pure override returns (address[] memory tokens) {
        tokens = new address[](1);
        tokens[0] = LDO;
        return tokens;
    }

    // ###################
    // Protected
    // ###################

    /// @notice Allow the CDO to pull stkAAVE rewards
    /// @return _bal amount of stkAAVE transferred
    function pullStkAAVE() external override returns (uint256 _bal) {}

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

    /// @dev Emergency method
    /// @param to receiver address
    /// @param tokenId nft
    function transferNft(address to, uint256 tokenId) external onlyOwner nonReentrant {
        stMatic.poLidoNFT().safeTransferFrom(address(this), to, tokenId);
    }

    /// @notice allow to update address whitelisted to pull stkAAVE rewards
    function setWhitelistedCDO(address _cdo) external onlyOwner {
        require(_cdo != address(0), "IS_0");
        whitelistedCDO = _cdo;
    }

    modifier onlyIdleCDO() {
        require(msg.sender == whitelistedCDO, "Only IdleCDO can call");
        _;
    }
}