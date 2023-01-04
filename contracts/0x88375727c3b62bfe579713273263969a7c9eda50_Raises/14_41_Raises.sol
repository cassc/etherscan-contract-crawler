// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";

import {RaiseParams, Raise, RaiseState, RaiseTokens, RaiseTimestamps, Phase, FeeSchedule} from "./structs/Raise.sol";
import {TierParams, TierType, Tier} from "./structs/Tier.sol";
import {RaiseValidator} from "./libraries/validators/RaiseValidator.sol";
import {TierValidator} from "./libraries/validators/TierValidator.sol";
import {Phases} from "./libraries/Phases.sol";
import {IRaises} from "./interfaces/IRaises.sol";
import {IProjects} from "./interfaces/IProjects.sol";
import {IMinter} from "./interfaces/IMinter.sol";
import {ITokens} from "./interfaces/ITokens.sol";
import {ITokenAuth} from "./interfaces/ITokenAuth.sol";
import {ITokenDeployer} from "./interfaces/ITokenDeployer.sol";
import {IControllable} from "./interfaces/IControllable.sol";
import {IPausable} from "./interfaces/IPausable.sol";
import {Controllable} from "./abstract/Controllable.sol";
import {Pausable} from "./abstract/Pausable.sol";
import {RaiseToken} from "./libraries/RaiseToken.sol";
import {Fees} from "./libraries/Fees.sol";
import {ETH} from "./constants/Constants.sol";

/// @title Raises - Crowdfunding mint module
/// @notice Patrons interact with this contract to mint and redeem raise tokens
/// in support of projects.
contract Raises is IRaises, Controllable, Pausable, ReentrancyGuard {
    using RaiseValidator for RaiseParams;
    using TierValidator for TierParams;
    using Phases for Raise;
    using Fees for FeeSchedule;
    using SafeERC20 for IERC20;
    using Address for address payable;

    string public constant NAME = "Raises";
    string public constant VERSION = "0.0.1";

    address public creators;
    address public projects;
    address public minter;
    address public deployer;
    address public tokens;
    address public tokenAuth;

    FeeSchedule public feeSchedule = FeeSchedule({fanFee: 500, brandFee: 2500});

    // projectId => totalRaises
    mapping(uint32 => uint32) public totalRaises;
    // projectId => raiseId => Raise
    mapping(uint32 => mapping(uint32 => Raise)) public raises;
    // projectId => raiseId => Tier[]
    mapping(uint32 => mapping(uint32 => Tier[])) public tiers;
    // projectId => raiseId => tierId => minter address => count
    mapping(uint32 => mapping(uint32 => mapping(uint32 => mapping(address => uint256)))) public mints;

    // token address => accrued protocol fees
    mapping(address => uint256) public fees;

    modifier onlyCreators() {
        if (msg.sender != creators) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) Controllable(_controller) {}

    /// @inheritdoc IRaises
    function create(uint32 projectId, RaiseParams memory params, TierParams[] memory _tiers)
        external
        override
        onlyCreators
        whenNotPaused
        returns (uint32 raiseId)
    {
        if (!IProjects(projects).exists(projectId)) {
            revert NotFound();
        }

        params.validate(tokenAuth);

        raiseId = ++totalRaises[projectId];

        // Deploy tokens
        address fanToken = ITokenDeployer(deployer).deploy();
        address brandToken = ITokenDeployer(deployer).deploy();

        _saveRaise(projectId, raiseId, fanToken, brandToken, feeSchedule, params);
        _saveTiers(projectId, raiseId, fanToken, brandToken, _tiers);

        emit CreateRaise(projectId, raiseId, params, _tiers, fanToken, brandToken);
    }

    /// @inheritdoc IRaises
    function update(uint32 projectId, uint32 raiseId, RaiseParams memory params, TierParams[] memory _tiers)
        external
        override
        onlyCreators
        whenNotPaused
    {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);

        // Check that raise status is active
        if (raise.state != RaiseState.Active) revert RaiseInactive();

        // Check that raise has not started
        if (block.timestamp >= raise.timestamps.presaleStart) revert RaiseHasStarted();

        params.validate(tokenAuth);

        address fanToken = raise.tokens.fanToken;
        address brandToken = raise.tokens.brandToken;

        _saveRaise(projectId, raiseId, fanToken, brandToken, raise.feeSchedule, params);
        _saveTiers(projectId, raiseId, fanToken, brandToken, _tiers);

        emit UpdateRaise(projectId, raiseId, params, _tiers);
    }

    /// @inheritdoc IRaises
    function mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (uint256 tokenId)
    {
        return _mint(projectId, raiseId, tierId, amount, new bytes32[](0));
    }

    /// @inheritdoc IRaises
    function mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount, bytes32[] memory proof)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (uint256 tokenId)
    {
        return _mint(projectId, raiseId, tierId, amount, proof);
    }

    /// @inheritdoc IRaises
    function settle(uint32 projectId, uint32 raiseId) external override whenNotPaused {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);

        // Check that raise status is active
        if (raise.state != RaiseState.Active) revert RaiseInactive();

        // Check that raise has ended
        if (raise.phase() != Phase.Ended) revert RaiseNotEnded();

        // Effects
        if (raise.raised >= raise.goal) {
            // If the raise has met its goal, transition to Funded
            emit SettleRaise(projectId, raiseId, raise.state = RaiseState.Funded);

            // Add this raise's fees to global fee balance
            fees[raise.currency] += raise.fees;
        } else {
            // Otherwise, transition to Cancelled
            emit SettleRaise(projectId, raiseId, raise.state = RaiseState.Cancelled);
        }
    }

    /// @inheritdoc IRaises
    function cancel(uint32 projectId, uint32 raiseId) external override onlyCreators whenNotPaused {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);
        if (raise.state != RaiseState.Active) revert RaiseInactive();

        // Effects
        emit CancelRaise(projectId, raiseId, raise.state = RaiseState.Cancelled);
    }

    /// @inheritdoc IRaises
    function close(uint32 projectId, uint32 raiseId) external override onlyCreators whenNotPaused {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);
        if (raise.state != RaiseState.Active) revert RaiseInactive();
        if (raise.raised < raise.goal) revert RaiseGoalNotMet();

        // Effects
        // Transition to Funded
        emit CloseRaise(projectId, raiseId, raise.state = RaiseState.Funded);

        // Add this raise's fees to global fee balance
        fees[raise.currency] += raise.fees;
    }

    /// @inheritdoc IRaises
    function withdraw(uint32 projectId, uint32 raiseId, address receiver)
        external
        override
        nonReentrant
        onlyCreators
        whenNotPaused
    {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);

        // Check that raise has been cancelled
        if (raise.state != RaiseState.Funded) revert RaiseNotFunded();

        // Effects

        // Store withdrawal amount
        uint256 amount = raise.balance;

        // Clear raise balance
        raise.balance = 0;

        // Interactions
        // Get raise currency
        address currency = raise.currency;
        if (currency == ETH) {
            // If currency is ETH, send ETH to receiver
            payable(receiver).sendValue(amount);
        } else {
            // If currency is ERC20, transfer tokens to reciever
            IERC20(currency).safeTransfer(receiver, amount);
        }
        emit WithdrawRaiseFunds(projectId, raiseId, receiver, currency, amount);
    }

    /// @inheritdoc IRaises
    function redeem(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount)
        external
        override
        nonReentrant
        whenNotPaused
    {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);

        // Check that raise has been cancelled
        if (raise.state != RaiseState.Cancelled) revert RaiseNotCancelled();

        // Get the tier if it exists
        if (tierId >= tiers[projectId][raiseId].length) revert NotFound();
        Tier storage tier = tiers[projectId][raiseId][tierId];

        // Effects
        // Calculate refund amount
        uint256 refund = amount * tier.price;

        // Calculate protocol fee and creator take
        (uint256 protocolFee, uint256 creatorTake) = raise.feeSchedule.calculate(tier.tierType, refund);

        // Deduct refund from balance and fees
        raise.balance -= Math.min(raise.balance, creatorTake);
        raise.fees -= protocolFee;

        // Interactions
        // Burn token (reverts if caller is not owner or approved)
        uint256 tokenId = RaiseToken.encode(tier.tierType, projectId, raiseId, tierId);
        ITokens(tokens).token(tokenId).burn(msg.sender, tokenId, amount);

        // Get raise currency
        address currency = raise.currency;
        if (currency == ETH) {
            // If currency is ETH, send ETH to caller
            payable(msg.sender).sendValue(refund);
        } else {
            // If currency is ERC20, transfer tokens to caller
            IERC20(currency).safeTransfer(msg.sender, refund);
        }
        emit Redeem(projectId, raiseId, tierId, msg.sender, amount, currency, refund);
    }

    /// @inheritdoc IRaises
    function withdrawFees(address currency, address receiver) external override nonReentrant onlyController {
        // Checks
        uint256 balance = fees[currency];

        // Revert if fee balance is zero
        if (balance == 0) revert ZeroBalance();

        // Effects

        // Clear fee balance
        fees[currency] = 0;

        // Interactions
        if (currency == ETH) {
            // If currency is ETH, send ETH to receiver
            payable(receiver).sendValue(balance);
        } else {
            // If currency is ERC20, transfer tokens to receiver
            IERC20(currency).safeTransfer(receiver, balance);
        }
        emit WithdrawFees(receiver, currency, balance);
    }

    function setFeeSchedule(FeeSchedule calldata newFeeSchedule) external override onlyController {
        newFeeSchedule.validate();
        emit SetFeeSchedule(feeSchedule, newFeeSchedule);
        feeSchedule = newFeeSchedule;
    }

    /// @inheritdoc IPausable
    function pause() external override onlyController {
        _pause();
    }

    /// @inheritdoc IPausable
    function unpause() external override onlyController {
        _unpause();
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address _contract)
        external
        override (Controllable, IControllable)
        onlyController
    {
        if (_contract == address(0)) revert ZeroAddress();
        else if (_name == "creators") _setCreators(_contract);
        else if (_name == "projects") _setProjects(_contract);
        else if (_name == "minter") _setMinter(_contract);
        else if (_name == "deployer") _setDeployer(_contract);
        else if (_name == "tokens") _setTokens(_contract);
        else if (_name == "tokenAuth") _setTokenAuth(_contract);
        else revert InvalidDependency(_name);
    }

    /// @inheritdoc IRaises
    function getRaise(uint32 projectId, uint32 raiseId) external view override returns (Raise memory) {
        return _getRaise(projectId, raiseId);
    }

    /// @inheritdoc IRaises
    function getPhase(uint32 projectId, uint32 raiseId) external view override returns (Phase) {
        return _getRaise(projectId, raiseId).phase();
    }

    /// @inheritdoc IRaises
    function getTiers(uint32 projectId, uint32 raiseId) external view override returns (Tier[] memory) {
        // Check that project and raise exist
        _getRaise(projectId, raiseId);
        return tiers[projectId][raiseId];
    }

    function _setCreators(address _creators) internal {
        emit SetCreators(creators, _creators);
        creators = _creators;
    }

    function _setProjects(address _projects) internal {
        emit SetProjects(projects, _projects);
        projects = _projects;
    }

    function _setMinter(address _minter) internal {
        emit SetMinter(minter, _minter);
        minter = _minter;
    }

    function _setDeployer(address _deployer) internal {
        emit SetDeployer(deployer, _deployer);
        deployer = _deployer;
    }

    function _setTokens(address _tokens) internal {
        emit SetTokens(tokens, _tokens);
        tokens = _tokens;
    }

    function _setTokenAuth(address _tokenAuth) internal {
        emit SetTokenAuth(tokenAuth, _tokenAuth);
        tokenAuth = _tokenAuth;
    }

    function _getRaise(uint32 projectId, uint32 raiseId) internal view returns (Raise storage raise) {
        // Check that project exists
        if (totalRaises[projectId] == 0) revert NotFound();

        // Get the raise if it exists
        raise = raises[projectId][raiseId];
        if (raise.projectId == 0) revert NotFound();
    }

    function _mint(uint32 projectId, uint32 raiseId, uint32 tierId, uint256 amount, bytes32[] memory proof)
        internal
        returns (uint256 tokenId)
    {
        // Checks
        Raise storage raise = _getRaise(projectId, raiseId);

        // Check that raise status is active
        if (raise.state != RaiseState.Active) revert RaiseInactive();

        Phase phase = raise.phase();
        // Check that raise has started
        if (phase == Phase.Scheduled) revert RaiseNotStarted();

        // Check that raise has not ended
        if (phase == Phase.Ended) revert RaiseEnded();

        // Get the tier if it exists
        if (tierId >= tiers[projectId][raiseId].length) revert NotFound();
        Tier storage tier = tiers[projectId][raiseId][tierId];

        // In presale phase, user must provide a valid proof
        if (
            phase == Phase.Presale
                && !MerkleProof.verify(proof, tier.allowListRoot, keccak256(abi.encodePacked(msg.sender)))
        ) revert InvalidProof();

        // Check that tier has remaining supply
        if (tier.minted + amount > tier.supply) revert RaiseSoldOut();

        // Check that caller will not exceed limit per address
        if (mints[projectId][raiseId][tierId][msg.sender] + amount > tier.limitPerAddress) {
            revert AddressMintedMaximum();
        }

        // Calculate mint price.
        uint256 mintPrice = amount * tier.price;

        // Get the currency for this raise. Save for use later.
        address currency = raise.currency;

        if (currency == ETH) {
            // If currency is ETH, msg.value must be mintPrice
            if (msg.value != mintPrice) revert InvalidPaymentAmount();
        } else {
            // If currency is not ETH, msg.value must be zero
            if (msg.value != 0) revert InvalidPaymentAmount();

            // Check that currency has not been removed from the ERC20 allowlist
            if (ITokenAuth(tokenAuth).denied(currency)) revert InvalidCurrency();
        }

        // Calculate total raised
        uint256 totalRaised = raise.raised + mintPrice;

        // If there is a raise maximum, check that payment does not exceed it
        if (raise.max != 0 && totalRaised > raise.max) revert ExceedsRaiseMaximum();

        // Effects

        // Increment per-caller mint count
        mints[projectId][raiseId][tierId][msg.sender] += amount;

        // Increment tier minted count
        tier.minted += amount;

        // Increase raised amount
        raise.raised = totalRaised;

        // Calculate protocol fee and creator take
        (uint256 protocolFee, uint256 creatorTake) = raise.feeSchedule.calculate(tier.tierType, mintPrice);

        // Increase balances
        raise.balance += creatorTake;
        raise.fees += protocolFee;

        // Interactions
        // If currency is not ETH, transfer tokens from caller
        if (currency != ETH) {
            IERC20(currency).safeTransferFrom(msg.sender, address(this), mintPrice);
        }

        // Encode token ID
        tokenId = RaiseToken.encode(tier.tierType, projectId, raiseId, tierId);

        // Mint token to caller
        IMinter(minter).mint(msg.sender, tokenId, amount, "");

        // Emit event
        emit Mint(projectId, raiseId, tierId, msg.sender, amount, proof);
    }

    function _saveRaise(
        uint32 projectId,
        uint32 raiseId,
        address fanToken,
        address brandToken,
        FeeSchedule memory _feeSchedule,
        RaiseParams memory params
    ) internal {
        raises[projectId][raiseId] = Raise({
            currency: params.currency,
            goal: params.goal,
            max: params.max,
            timestamps: RaiseTimestamps({
                presaleStart: params.presaleStart,
                presaleEnd: params.presaleEnd,
                publicSaleStart: params.publicSaleStart,
                publicSaleEnd: params.publicSaleEnd
            }),
            state: RaiseState.Active,
            projectId: projectId,
            raiseId: raiseId,
            tokens: RaiseTokens({fanToken: fanToken, brandToken: brandToken}),
            feeSchedule: _feeSchedule,
            raised: 0,
            balance: 0,
            fees: 0
        });
    }

    function _saveTiers(
        uint32 projectId,
        uint32 raiseId,
        address fanToken,
        address brandToken,
        TierParams[] memory _tiers
    ) internal {
        delete tiers[projectId][raiseId];
        for (uint256 i; i < _tiers.length;) {
            TierParams memory tierParams = _tiers[i];
            tierParams.validate();
            tiers[projectId][raiseId].push(
                Tier({
                    tierType: tierParams.tierType,
                    price: tierParams.price,
                    supply: tierParams.supply,
                    limitPerAddress: tierParams.limitPerAddress,
                    allowListRoot: tierParams.allowListRoot,
                    minted: 0
                })
            );

            // Register token
            uint256 tokenId = RaiseToken.encode(tierParams.tierType, projectId, raiseId, uint32(i));
            address token = tierParams.tierType == TierType.Fan ? fanToken : brandToken;
            ITokenDeployer(deployer).register(tokenId, token);

            unchecked {
                ++i;
            }
        }
    }
}