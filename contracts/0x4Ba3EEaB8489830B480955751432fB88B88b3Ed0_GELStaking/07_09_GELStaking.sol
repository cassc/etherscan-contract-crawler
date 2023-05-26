// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    EnumerableMapUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGelato} from "./interfaces/IGelato.sol";

// solhint-disable max-states-count
// solhint-disable not-rely-on-time

contract GELStaking is Proxied, ReentrancyGuardUpgradeable {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    // solhint-disable var-name-mixedcase
    IERC20 public immutable GEL;
    IGelato public immutable GELATO;
    // solhint-enable var-name-mixedcase

    uint256 public minStake;
    uint256 public withdrawalLockPeriod;

    mapping(address executorSigner => address manager) public manager;
    mapping(bytes32 id => uint256 amount) public pendingWithdrawal;

    EnumerableMapUpgradeable.AddressToUintMap private _stakes;

    event LogIncreaseStake(
        address indexed executorSigner,
        address indexed sender,
        uint256 newStake
    );

    event LogDecreaseStake(
        bytes32 indexed id,
        address indexed executorSigner,
        address indexed sender,
        uint256 newStake
    );

    event LogUnstake(
        bytes32 indexed id,
        address indexed executorSigner,
        address indexed sender
    );

    event LogMoveStake(
        address indexed oldExecutorSigner,
        address indexed newExecutorSigner,
        address indexed sender,
        uint256 newStake
    );

    event LogWithdraw(
        bytes32 indexed id,
        address indexed executorSigner,
        address indexed sender,
        address to,
        uint256 amount
    );

    modifier isSenderOrTheirManager(address _executorSigner) {
        require(
            (msg.sender == _executorSigner ||
                msg.sender == manager[_executorSigner]),
            "GELStaking.isSenderExecutorSignerOrHisManager"
        );
        _;
    }

    modifier isUnlocked(uint256 _timestamp) {
        require(
            _timestamp + withdrawalLockPeriod < block.timestamp,
            "GELStaking.isUnlocked"
        );
        _;
    }

    constructor(IERC20 _gel, IGelato _gelato) {
        GEL = _gel;
        GELATO = _gelato;
    }

    function initialize(
        uint256 _minStake,
        uint256 _withdrawalLockPeriod
    ) external onlyProxyAdmin initializer {
        __ReentrancyGuard_init();
        minStake = _minStake;
        withdrawalLockPeriod = _withdrawalLockPeriod;
    }

    function setMinStake(uint256 _minStake) external onlyProxyAdmin {
        minStake = _minStake;
    }

    function setWithdrawalLockPeriod(
        uint256 _withdrawalLockPeriod
    ) external onlyProxyAdmin {
        withdrawalLockPeriod = _withdrawalLockPeriod;
    }

    function setManager(address _manager) external {
        manager[msg.sender] = _manager;
    }

    /// @dev use setManager before increaseStake
    function administerManager(
        address _executorSigner,
        address _manager
    ) external onlyProxyAdmin {
        manager[_executorSigner] = _manager;
    }

    // TODO: add stake with permit
    function increaseStake(
        address _executorSigner,
        uint256 _amount
    ) external nonReentrant {
        require(
            GELATO.isExecutorSigner(_executorSigner),
            "GELStaking.increaseStake: executorSigner"
        );

        (, uint256 currentStake) = _stakes.tryGet(_executorSigner);

        // Admin or Manager must be able to add small amounts
        // as incremental, vested GEL incentives
        if (!_isAdminOrTheirManager(msg.sender)) {
            require(
                currentStake + _amount >= minStake,
                "GELStaking.increaseStake: minStake"
            );
        }

        GEL.transferFrom(msg.sender, address(this), _amount);

        uint256 newStake = currentStake + _amount;

        _stakes.set(_executorSigner, newStake);

        emit LogIncreaseStake(_executorSigner, msg.sender, newStake);
    }

    function decreaseStake(
        address _executorSigner,
        uint256 _amount
    ) external isSenderOrTheirManager(_executorSigner) nonReentrant {
        uint256 newStake = _stakes.get(_executorSigner) - _amount;

        require(newStake >= minStake, "GELStaking.decreaseStake: minStake");

        bytes32 id = getWithdrawalId(_executorSigner, block.timestamp);

        // if multiple decreaseStake in same block, they share id
        pendingWithdrawal[id] += _amount;
        _stakes.set(_executorSigner, newStake);

        emit LogDecreaseStake(id, _executorSigner, msg.sender, newStake);
    }

    function unstake(
        address _executorSigner
    ) external isSenderOrTheirManager(_executorSigner) nonReentrant {
        // before unstaking, an executorSigner should be removed from the diamond whitelist
        require(
            !GELATO.isExecutorSigner(_executorSigner),
            "GELStaking.unstake: executorSigner"
        );

        bytes32 id = getWithdrawalId(_executorSigner, block.timestamp);

        uint256 amount = _stakes.get(_executorSigner);

        _stakes.remove(_executorSigner);
        pendingWithdrawal[id] += amount;

        emit LogUnstake(id, _executorSigner, msg.sender);
    }

    function moveStake(
        address _oldExecutorSigner,
        address _newExecutorSigner
    ) external isSenderOrTheirManager(_oldExecutorSigner) nonReentrant {
        uint256 oldStake = _stakes.get(_oldExecutorSigner);

        require(
            GELATO.isExecutorSigner(_newExecutorSigner),
            "GELStaking.moveStake: executorSigner"
        );

        _stakes.remove(_oldExecutorSigner);
        (, uint256 newStake) = _stakes.tryGet(_newExecutorSigner);
        uint256 combinedStake = oldStake + newStake;
        _stakes.set(_newExecutorSigner, combinedStake);

        emit LogMoveStake(
            _oldExecutorSigner,
            _newExecutorSigner,
            msg.sender,
            combinedStake
        );
    }

    function withdraw(
        address _executorSigner,
        uint256 _timestamp,
        address _to
    )
        external
        isSenderOrTheirManager(_executorSigner)
        isUnlocked(_timestamp)
        nonReentrant
    {
        bytes32 id = getWithdrawalId(_executorSigner, _timestamp);
        uint256 amount = pendingWithdrawal[id];

        require(amount > 0, "GELStaking.withdraw: amount");
        require(_to != address(0), "GELStaking.withdraw: _to is zero address");

        delete pendingWithdrawal[id];

        GEL.transfer(_to, amount);

        emit LogWithdraw(id, _executorSigner, msg.sender, _to, amount);
    }

    function stakers() external view returns (address[] memory s) {
        s = new address[](_stakes.length());
        for (uint256 i; i < _stakes.length(); i++) {
            (address executorSigner, ) = _stakes.at(i);
            s[i] = executorSigner;
        }
    }

    function numberOfStakers() external view returns (uint256) {
        return _stakes.length();
    }

    function isStaker(address _executorSigner) external view returns (bool) {
        return _stakes.contains(_executorSigner);
    }

    function getTotalStakedAmount() external view returns (uint256) {
        uint256 totalStakedAmount;
        for (uint256 i; i < _stakes.length(); i++) {
            (, uint256 amount) = _stakes.at(i);
            totalStakedAmount += amount;
        }
        return totalStakedAmount;
    }

    function getStake(address _executorSigner) public view returns (uint256) {
        (, uint256 amount) = _stakes.tryGet(_executorSigner);
        return amount;
    }

    function getWithdrawalId(
        address _executorSigner,
        uint256 _timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_executorSigner, _timestamp));
    }

    function _isAdminOrTheirManager(
        address _address
    ) private view returns (bool) {
        return _address == _proxyAdmin() || _address == manager[_proxyAdmin()];
    }
}