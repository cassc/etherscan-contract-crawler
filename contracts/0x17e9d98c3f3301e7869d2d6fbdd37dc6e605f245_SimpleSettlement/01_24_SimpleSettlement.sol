// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external libraries
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

// interfaces
import {IERC20, IHnToken} from "../interfaces/IHnToken.sol";
import {IAssetRegistry} from "../interfaces/IAssetRegistry.sol";
import {IAuctionVault} from "../interfaces/IAuctionVault.sol";
import {IMarginEngine} from "../interfaces/IMarginEngine.sol";

// libraries
import {ActionUtil} from "../libraries/ActionUtil.sol";

import "../config/types.sol";
import "../config/errors.sol";
import "../config/constants.sol";

contract SimpleSettlement is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using ActionUtil for ActionArgs[];
    using ActionUtil for BatchExecute[];
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    address public immutable ME_CASH;

    address public immutable ME_PHYSICAL;

    /*///////////////////////////////////////////////////////////////
                            Storage V1
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => bool) public noncesUsed;

    mapping(address => address) public wrapToken;

    mapping(address => address) public unWrapToken;

    /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/

    event TokenMapSet(address indexed token0, address token1);

    event SettledBid(uint256 nonce, address indexed vault, address indexed counterparty);

    event SettledBids(uint256[] nonces, address[] vaults, address indexed counterparty);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _meCash, address _mePhysical) initializer {
        if (_meCash == address(0) || _mePhysical == address(0)) revert BadAddress();

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();

        ME_CASH = _meCash;
        ME_PHYSICAL = _mePhysical;
    }

    function initialize(address _owner) external initializer {
        if (_owner == address(0)) revert BadAddress();

        _transferOwnership(_owner);
        __ReentrancyGuard_init_unchained();
    }

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Withdraws cross chain token from the margin account and burns it to initiate transfer on a native chain
     * @param _marginEngine is the address of the margin engine
     * @param _collateralId is the id of the collateral
     * @param _amount is the amount of the collateral to withdraw
     * @param _recipient is the address of the recipient on a native chain
     */
    function burn(address _marginEngine, uint8 _collateralId, uint256 _amount, string calldata _recipient) external {
        IMarginEngine marginEngine = IMarginEngine(_marginEngine);

        // remove collateral from the margin account
        ActionArgs[] memory actions = new ActionArgs[](1);
        actions[0] =
            ActionArgs({action: REMOVE_COLLATERAL_ACTION, data: abi.encode(uint80(_amount), address(this), _collateralId)});

        marginEngine.execute(msg.sender, actions);

        IAssetRegistry assetRegistry = _marginEngine == ME_CASH ? marginEngine.grappa() : marginEngine.pomace();
        (address addr,) = assetRegistry.assets(_collateralId);

        // burn tokens in order to initiate transfer on a native chain for a recipient
        IHnToken(addr).burn(_amount, _recipient);
    }

    /**
     *  @notice Exercises a token
     *  @param _tokenId is the id of the token
     *  @param _amount is the amount of the token to exercise
     */
    function exercise(uint256 _tokenId, uint256 _amount, uint8 _collateralId, uint256 _collateralAmount) external nonReentrant {
        IMarginEngine marginEngine = IMarginEngine(ME_PHYSICAL);

        // pull collateral from the market maker
        (address collateralToken,) = marginEngine.pomace().assets(_collateralId);
        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), _collateralAmount);

        // deposit collateral into the margin account
        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] =
            ActionArgs({action: ADD_COLLATERAL_ACTION, data: abi.encode(address(this), _collateralAmount, _collateralId)});
        actions[1] = ActionArgs({action: EXERCISE_TOKEN_ACTION, data: abi.encode(_tokenId, uint64(_amount))});

        marginEngine.execute(msg.sender, actions);
    }

    /**
     * @notice bulk revoke from margin account
     * @dev revokes access to margin accounts
     * @param _marginEngine address of margin engine
     * @param _subAccounts array of sub-accounts to itself from
     */
    function revokeMarginAccountAccess(address _marginEngine, address[] calldata _subAccounts) external {
        _checkOwner();

        IMarginEngine marginEngine = IMarginEngine(_marginEngine);

        for (uint256 i; i < _subAccounts.length;) {
            marginEngine.revokeSelfAccess(_subAccounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    function setTokenMap(address _token0, address _token1) external {
        _checkOwner();

        if (_token0 == address(0) && _token1 != address(0)) revert BadAddress();
        if (_token0 != address(0) && _token1 == address(0)) revert BadAddress();

        wrapToken[_token0] = _token1;
        unWrapToken[_token1] = _token0;

        emit TokenMapSet(_token0, _token1);
    }

    /**
     * @notice Settles a single bid
     * @param _bid is the signed data type containing bid information
     * @param _collaterals array of erc20 token addresses needed to collateralize options
     * @param _amounts array of (counterparty) deposit amounts for each collateral + premium (if applicable)
     */
    function settle(Bid calldata _bid, address[] calldata _collaterals, uint256[] calldata _amounts) external nonReentrant {
        _assertBidValid(_bid);

        IMarginEngine marginEngine = IAuctionVault(_bid.vault).marginEngine();
        bool isCashSettled = address(marginEngine) == ME_CASH;

        // verify if options not yet minted
        bool hasLongs = _checkForLongsOrVerify(marginEngine, IAuctionVault(_bid.vault), _bid.options);

        // deposit actions from counterparty
        ActionArgs[] memory bActions = _createDeposits(_collaterals, _amounts, isCashSettled, marginEngine);

        // mint or transfer actions from vault/margin account
        (ActionArgs[] memory sActions, ActionArgs[] memory bMints) =
            _createMintsOrTransfers(_bid.vault, msg.sender, _bid.options, _bid.weights, isCashSettled, hasLongs);
        bActions = bActions.concat(bMints);

        // premium transfer
        if (_bid.premium != 0) {
            ActionArgs memory premiumAction = _createPremiumTransfer(_bid.vault, _bid.premiumId, _bid.premium, isCashSettled);

            if (_bid.premium > 0) bActions = bActions.append(premiumAction);
            else sActions = sActions.append(premiumAction);
        }

        BatchExecute[] memory batch;

        // batch execute vault actions
        if (sActions.length > 0) batch = batch.append(BatchExecute(_bid.vault, sActions));

        // batch execute counterparty actions
        if (bActions.length > 0) batch = batch.append(BatchExecute(msg.sender, bActions));

        emit SettledBid(_bid.nonce, _bid.vault, msg.sender);

        marginEngine.batchExecute(batch);
    }

    /**
     * @notice Settles a several bids
     * @param _bids is array of signed data types containing bid information
     * @param _collaterals array of erc20 token addresses needed to collateralize options
     * @param _amounts array of (counterparty) deposit amounts for each collateral + premium (if applicable)
     */
    function settleBatch(Bid[] calldata _bids, address[] calldata _collaterals, uint256[] calldata _amounts)
        external
        nonReentrant
    {
        IAuctionVault vault = IAuctionVault(_bids[0].vault);
        IMarginEngine marginEngine = vault.marginEngine();

        bool isCashSettled = address(marginEngine) == ME_CASH;

        // deposit actions from counterparty
        ActionArgs[] memory depositActions = _createDeposits(_collaterals, _amounts, isCashSettled, marginEngine);

        (BatchExecute[] memory batch, ActionArgs[] memory bActions) = _setupBidActionsBulk(marginEngine, _bids);

        // batch execute counterparty actions
        if (depositActions.length > 0 || bActions.length > 0) {
            batch = batch.append(BatchExecute(msg.sender, depositActions.concat(bActions)));
        }

        marginEngine.batchExecute(batch);
    }

    /**
     * @notice Wraps token in margin account
     * @param _marginEngine address of margin engine
     * @param _subAccount account in which the tokens will be swapped
     * @param _collateralId the id of the asset to be wrapped
     * @param _amount the amount of the asset to be wrapped
     */
    function wrap(address _marginEngine, address _subAccount, uint8 _collateralId, uint256 _amount) external nonReentrant {
        IMarginEngine marginEngine = IMarginEngine(_marginEngine);

        bool isCashSettled = address(marginEngine) == ME_CASH;
        IAssetRegistry assetRegistry = isCashSettled ? marginEngine.grappa() : marginEngine.pomace();

        // withdraw underlying from margin account
        ActionArgs[] memory actions = new ActionArgs[](1);
        actions[0] =
            ActionArgs({action: REMOVE_COLLATERAL_ACTION, data: abi.encode(uint80(_amount), address(this), _collateralId)});
        marginEngine.execute(_subAccount, actions);

        (address underlying,) = assetRegistry.assets(_collateralId);

        // wrap underlying
        (address wrapper, uint256 amount) = _wrapToken(underlying, _amount, isCashSettled);
        if (wrapper == address(0)) revert BadAddress();

        _collateralId = assetRegistry.assetIds(wrapper);

        // deposit wrapped token to margin account
        actions[0] = ActionArgs({action: ADD_COLLATERAL_ACTION, data: abi.encode(address(this), uint80(amount), _collateralId)});
        marginEngine.execute(_subAccount, actions);
    }

    /**
     * @notice Withdraws token from margin account
     * @param _marginEngine address of margin engine
     * @param _collateralId the id of the asset to be withdrawn
     * @param _amount the amount of the asset to be withdrawn
     * @param _v The recovery byte of the signature
     * @param _r is the r value of the signature
     * @param _s is the s value of the signature
     */
    function withdraw(address _marginEngine, uint8 _collateralId, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s)
        external
        nonReentrant
    {
        IMarginEngine marginEngine = IMarginEngine(_marginEngine);

        IAssetRegistry assetRegistry = _marginEngine == ME_CASH ? marginEngine.grappa() : marginEngine.pomace();
        (address wrapper,) = assetRegistry.assets(_collateralId);
        address underlying = unWrapToken[wrapper];

        address receiver = address(this);
        if (underlying == address(0)) receiver = msg.sender;

        ActionArgs[] memory actions = new ActionArgs[](1);
        actions[0] = ActionArgs({action: REMOVE_COLLATERAL_ACTION, data: abi.encode(uint80(_amount), receiver, _collateralId)});
        marginEngine.execute(msg.sender, actions);

        if (underlying != address(0)) IHnToken(wrapper).withdrawTo(msg.sender, _amount, _v, _r, _s);
    }

    /*///////////////////////////////////////////////////////////////
                                View Functions
    //////////////////////////////////////////////////////////////*/

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Bulk created bid related actions (verification of options, mints, premium transfers)
     */
    function _setupBidActionsBulk(IMarginEngine _marginEngine, Bid[] calldata _bids)
        internal
        returns (BatchExecute[] memory batch, ActionArgs[] memory bActions)
    {
        uint256 bidCount = _bids.length;

        uint256[] memory nonces = new uint256[](bidCount);
        address[] memory vaults = new address[](bidCount);

        bool isCashSettled = address(_marginEngine) == ME_CASH;

        for (uint256 i; i < bidCount;) {
            _assertBidValid(_bids[i]);

            // verify if options not yet minted
            bool hasLongs = _checkForLongsOrVerify(_marginEngine, IAuctionVault(_bids[i].vault), _bids[i].options);

            // mint or transfer actions from vault/margin account
            (ActionArgs[] memory sActions, ActionArgs[] memory bMints) =
                _createMintsOrTransfers(_bids[i].vault, msg.sender, _bids[i].options, _bids[i].weights, isCashSettled, hasLongs);
            if (bMints.length > 0) bActions = bActions.concat(bMints);

            // premium transfer
            if (_bids[i].premium != 0) {
                ActionArgs memory premiumAction =
                    _createPremiumTransfer(_bids[i].vault, _bids[i].premiumId, _bids[i].premium, isCashSettled);

                if (_bids[i].premium > 0) bActions = bActions.append(premiumAction);
                else sActions = sActions.append(premiumAction);
            }

            // batch execute vault actions
            if (sActions.length > 0) batch = batch.append(BatchExecute(_bids[i].vault, sActions));

            nonces[i] = _bids[i].nonce;
            vaults[i] = _bids[i].vault;

            unchecked {
                ++i;
            }
        }

        emit SettledBids(nonces, vaults, msg.sender);
    }

    /**
     * @notice Helper function to transfer premium action
     * @dev    Assumes premium payer has collateral in margin account
     * @return action encoded transfer instruction
     */
    function _createPremiumTransfer(address _to, uint8 _premiumId, int256 _premium, bool _isCashSettled)
        internal
        view
        returns (ActionArgs memory)
    {
        if (_premium < 0) {
            _to = msg.sender;
            _premium *= -1;
        }

        return ActionArgs({
            action: _isCashSettled ? CASH_TRANSFER_COLLATERAL_ACTION : PHYSICAL_TRANSFER_COLLATERAL_ACTION,
            data: abi.encode(uint80(uint256(_premium)), _to, _premiumId)
        });
    }

    /**
     * @notice Helper function to setup deposit collateral actions
     * @dev    Assumes  has collateral in margin account
     * @return actions array of collateral deposits for counterparty
     */
    function _createDeposits(
        address[] memory _collaterals,
        uint256[] memory _amounts,
        bool _isCashSettled,
        IMarginEngine _marginEngine
    ) internal returns (ActionArgs[] memory actions) {
        if (_collaterals.length == 0) return actions;

        if (_collaterals.length != _amounts.length) revert LengthMismatch();

        IAssetRegistry assetRegistry = _isCashSettled ? _marginEngine.grappa() : _marginEngine.pomace();

        actions = new ActionArgs[](_collaterals.length);

        for (uint256 i; i < _collaterals.length;) {
            (address wrapper, uint256 amount) = _wrapToken(_collaterals[i], _amounts[i], _isCashSettled);
            uint8 collateralId = assetRegistry.assetIds(wrapper);

            actions[i] =
                ActionArgs({action: ADD_COLLATERAL_ACTION, data: abi.encode(address(this), uint80(amount), collateralId)});

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Helper function to setup mint options action
     * @return vault array of option mints for vault
     * @return counterparty array of option mints for counterparty
     */
    function _createMintsOrTransfers(
        address _vault,
        address _counterparty,
        uint256[] memory _options,
        int256[] memory _weights,
        bool _isCashSettled,
        bool _hasLongs
    ) internal pure returns (ActionArgs[] memory vault, ActionArgs[] memory counterparty) {
        unchecked {
            if (_options.length != _weights.length) revert LengthMismatch();

            uint8 counterpartyAction;
            uint8 vaultAction;

            if (_isCashSettled) {
                counterpartyAction = CASH_MINT_SHORT_INTO_ACCOUNT_ACTION;
                vaultAction = _hasLongs ? CASH_TRANSFER_SHORT_ACTION : CASH_MINT_SHORT_INTO_ACCOUNT_ACTION;
            } else {
                counterpartyAction = PHYSICAL_MINT_SHORT_INTO_ACCOUNT_ACTION;
                vaultAction = _hasLongs ? PHYSICAL_TRANSFER_SHORT_ACTION : PHYSICAL_MINT_SHORT_INTO_ACCOUNT_ACTION;
            }

            for (uint256 i; i < _options.length; ++i) {
                int256 weight = _weights[i];

                if (weight == 0) continue;
                // counterparty receives negative weighted instruments (vault is short)
                // vault receives positive weighted instruments (vault long)
                if (weight < 0) {
                    vault = vault.append(
                        ActionArgs({action: vaultAction, data: abi.encode(_options[i], _counterparty, uint64(uint256(-weight)))})
                    );
                } else {
                    counterparty = counterparty.append(
                        ActionArgs({action: counterpartyAction, data: abi.encode(_options[i], _vault, uint64(uint256(weight)))})
                    );
                }
            }
        }
    }

    function _checkForLongsOrVerify(IMarginEngine _marginEngine, IAuctionVault _vault, uint256[] memory _options)
        internal
        view
        returns (bool hasLongs)
    {
        // if options not pre-minted then verify the vault is okay with what was sold
        (, Position[] memory longs,) = _marginEngine.marginAccounts(address(_vault));

        hasLongs = longs.length > 0;

        if (!hasLongs) _vault.verifyOptions(_options);
    }

    /**
     * @notice Wraps asset on the fly from market makers
     */
    function _wrapToken(address _underlying, uint256 _amount, bool _isCashSettled)
        internal
        returns (address wrapper, uint256 amount)
    {
        wrapper = wrapToken[_underlying];

        // if _underlying has no wrapper, then skip wrapping
        if (wrapper == address(0)) return (_underlying, _amount);

        IERC20 underlying = IERC20(_underlying);
        // Transfer underlying to this contract
        underlying.safeTransferFrom(msg.sender, address(this), _amount);
        // Approve wrapper to transfer underlying to itself from this contract
        underlying.approve(wrapper, _amount);

        IHnToken hnToken = IHnToken(wrapper);
        // deposits underlying to wrapper
        amount = hnToken.deposit(_amount);
        // Approving margin engine to pull wrapped tken from this contract
        hnToken.approve(_isCashSettled ? ME_CASH : ME_PHYSICAL, amount);
    }

    /**
     * @notice Asserts signatory on the data
     */
    function _assertBidValid(Bid calldata _bid) internal {
        if (_bid.expiry <= block.timestamp) revert ExpiredBid();
        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Bid(address vault,int256[] weights,uint256[] options,uint8 premiumId,int256 premium,uint256 expiry,uint256 nonce)"
                                ),
                                _bid.vault,
                                keccak256(abi.encodePacked(_bid.weights)),
                                keccak256(abi.encodePacked(_bid.options)),
                                _bid.premiumId,
                                _bid.premium,
                                _bid.expiry,
                                _bid.nonce
                            )
                        )
                    )
                ),
                _bid.v,
                _bid.r,
                _bid.s
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner()) revert Unauthorized();
            if (noncesUsed[_bid.nonce]) revert NonceAlreadyUsed();

            noncesUsed[_bid.nonce] = true;
        }
    }

    function _computeDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Hn Simple Settlement"),
                keccak256("3"),
                block.chainid,
                address(this)
            )
        );
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _checkOwner();
    }

    /**
     * @notice overrides the default _checkOwner function to revert with Unauthorized error
     */
    function _checkOwner() internal view override {
        if (owner() != _msgSender()) revert Unauthorized();
    }
}