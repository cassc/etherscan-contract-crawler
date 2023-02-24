// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {SafeERC20, IERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {AccessControlUpgradeable} from "openzeppelin-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ILGOStakingView} from "../interfaces/ILGOStakingView.sol";
import {ITreasury} from "../interfaces/ITreasury.sol";
import {ILGOToken} from "../interfaces/ILGOToken.sol";

contract GovernanceRedemptionPoolV2 is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    struct Snapshot {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 lgoSupply;
        uint256 llpBalance;
    }

    uint256 public constant MIN_REDEEM_DURATION = 1 days;

    ILGOToken public LGO;
    IERC20 public LLP;

    ITreasury public treasury;
    ILGOStakingView public lgoView;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    Snapshot public snapshot;
    uint256 public redeemDuration;

    function initialize(address _llp, address _lgo, address _lgoView, address _treasury) external initializer {
        require(_llp != address(0), "GovernanceRedemptionPool::initialize: invalid address");
        require(_lgo != address(0), "GovernanceRedemptionPool::initialize: invalid address");
        require(_lgoView != address(0), "GovernanceRedemptionPool::initialize: invalid address");
        require(_treasury != address(0), "GovernanceRedemptionPool::initialize: invalid address");
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        LLP = IERC20(_llp);
        LGO = ILGOToken(_lgo);
        lgoView = ILGOStakingView(_lgoView);
        treasury = ITreasury(_treasury);
        redeemDuration = 2 days;
    }

    modifier onlyRedemptionActive() {
        require(isRedemptionActive(), "GovernanceRedemptionPool::onlyRedemptionActive: redemption is not active");
        _;
    }

    // =============== USER FUNCTIONS ===============

    function startNextBatch() external onlyRole(CONTROLLER_ROLE) {
        require(address(LLP) != address(0), "GovernanceRedemptionPool::startNextBatch: no llp token");
        require(address(treasury) != address(0), "GovernanceRedemptionPool::startNextBatch: no treasury set");
        require(!isRedemptionActive(), "GovernanceRedemptionPool::startNextBatch: previous batch is not completed");
        snapshot = getNextSnapshot();

        emit NextBatchStarted(block.timestamp, snapshot.startTimestamp, snapshot.endTimestamp, snapshot.lgoSupply);
    }

    function redeem(address _to, uint256 _amount) external onlyRedemptionActive nonReentrant {
        require(_to != address(0), "GovernanceRedemptionPool::redeem: invalid address");
        uint256 llpAmount = redeemable(_amount);
        require(llpAmount != 0, "GovernanceRedemptionPool::redeem: !llpAmount");
        treasury.distribute(_to, llpAmount);
        LGO.burnFrom(msg.sender, _amount);

        emit Redeemed(msg.sender, _to, _amount, address(LLP), llpAmount);
    }

    function redeemToToken(address _to, uint256 _amount, address _tokenOut, uint256 _minimumAmountOut)
        external
        onlyRedemptionActive
        nonReentrant
    {
        require(_to != address(0), "GovernanceRedemptionPool::redeemToToken: invalid address");
        uint256 llpAmount = redeemable(_amount);
        require(llpAmount != 0, "GovernanceRedemptionPool::redeemToToken: !llpAmount");
        treasury.distributeToken(_to, _tokenOut, llpAmount, _minimumAmountOut);
        LGO.burnFrom(msg.sender, _amount);

        emit Redeemed(msg.sender, _to, _amount, address(LLP), llpAmount);
    }

    // =============== VIEW FUNCTIONS ===============

    function redeemable(uint256 _lgoAmount) public view returns (uint256 amount) {
        if (isRedemptionActive() && snapshot.lgoSupply > 0 && _lgoAmount <= snapshot.lgoSupply) {
            amount = _lgoAmount * snapshot.llpBalance / snapshot.lgoSupply;
        }
    }

    function getNextSnapshot() public view returns (Snapshot memory _snapshot) {
        _snapshot = Snapshot({
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp + redeemDuration,
            lgoSupply: lgoView.estimatedLGOCirculatingSupply(),
            llpBalance: LLP.balanceOf(address(treasury))
        });
    }

    function isRedemptionActive() public view returns (bool) {
        return block.timestamp >= snapshot.startTimestamp && block.timestamp < snapshot.endTimestamp;
    }

    // =============== RESTRICTED ===============

    function setLgoStakingView(address _lgoView) external onlyRole(ADMIN_ROLE) {
        require(_lgoView != address(0), "GovernanceRedemptionPool::setLgoStakingView: invalid address");
        lgoView = ILGOStakingView(_lgoView);
        emit LGOStakingViewSet(_lgoView);
    }

    function setRedeemDuration(uint256 _duration) external onlyRole(ADMIN_ROLE) {
        require(_duration >= MIN_REDEEM_DURATION, "GovernanceRedemptionPool::setRedeemDuration: < MIN_REDEEM_DURATION");
        redeemDuration = _duration;
        emit RedeemDurationSet(_duration);
    }

    function stopRedemption() external onlyRedemptionActive onlyRole(CONTROLLER_ROLE) {
        snapshot.endTimestamp = block.timestamp;
        emit RedemptionStopped();
    }

    /* ========== EVENTS ========== */

    event RedemptionStopped();
    event RedeemDurationSet(uint256 _duration);
    event LGOStakingViewSet(address indexed _addr);
    event NextBatchStarted(uint256 _time, uint256 _start, uint256 _end, uint256 _lgoSupply);
    event Redeemed(address indexed _from, address indexed _to, uint256 _amount, address _tokenOut, uint256 _amountOut);
}