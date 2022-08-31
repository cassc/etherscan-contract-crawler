//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./libraries/EthereumVerifier.sol";
import "./libraries/ProofParser.sol";
import "./libraries/Utils.sol";

import "./interfaces/IMaticStaking.sol";
import "./interfaces/IPolygonPool.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IBondToken.sol";
import "./interfaces/IDepositManager.sol";
import "./interfaces/IRootChainManager.sol";
import "./interfaces/IPolygonERC20Predicate.sol";

contract MaticStaking is
    IMaticStaking,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    address private _operator;

    // PolygonPool
    IPolygonPool private _pool;
    // StakeFi Cross-chain
    IBridge private _bridge;

    // Polygon chain id(137/80001)
    uint256 private _toChainId;

    // Matic token on Ethereum
    address private _matic;
    // aMATICb
    address private _bondToken;
    // aMATICc
    address private _certToken;

    // Matic POS variables
    IPolygonERC20Predicate private _maticPredicate;
    IRootChainManager private _rootChainManager;
    IDepositManager private _depositManager;

    address private _ankrToken;

    /**
     * Modifiers
     */

    modifier onlyOperator() {
        require(msg.sender == _operator, "Access: only operator");
        _;
    }

    function initialize(
        address operator,
        address maticAddress,
        address ankrToken,
        address bondToken,
        address certToken,
        address rootManager,
        address maticPredicate,
        address depositManager,
        address pool,
        address bridge,
        uint256 toChainId
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        _operator = operator;
        _matic = maticAddress;
        _ankrToken = ankrToken;
        _bondToken = bondToken;
        _certToken = certToken;
        _maticPredicate = IPolygonERC20Predicate(maticPredicate);
        _rootChainManager = IRootChainManager(rootManager);
        _depositManager = IDepositManager(depositManager);
        _pool = IPolygonPool(pool);
        _bridge = IBridge(bridge);
        _toChainId = toChainId;
        // give an approval to pool to spend
        IERC20Upgradeable(_matic).approve(pool, type(uint256).max);
        IERC20Upgradeable(_bondToken).approve(pool, type(uint256).max);
        IERC20Upgradeable(_certToken).approve(pool, type(uint256).max);
        IERC20Upgradeable(_ankrToken).approve(pool, type(uint256).max);
        // give an approval to bridge to spend
        IERC20Upgradeable(_bondToken).approve(bridge, type(uint256).max);
        IERC20Upgradeable(_certToken).approve(bridge, type(uint256).max);
        // give an approval to depositManager to spend
        IERC20Upgradeable(_matic).approve(depositManager, type(uint256).max);
    }

    function startExit(bytes calldata data) external override {
        _maticPredicate.startExitWithBurntTokens(data);
        emit StartedExit(data);
    }

    function stake(
        address receiver,
        uint256 amount,
        bool isRebasing
    ) external override onlyOperator {
        _rootChainManager.processExits(_matic);
        //   delegate via StakeFi PolygonPool
        address token;
        if (isRebasing) {
            token = _bondToken;
            _pool.stakeAndClaimBonds(amount);
        } else {
            token = _certToken;
            _pool.stakeAndClaimCerts(amount);
            amount = (amount * IBondToken(_bondToken).ratio()) / 1e18;
        }
        // transfer tokens across the bridge
        _bridge.deposit(token, _toChainId, receiver, amount);
        emit Staked(receiver, amount, isRebasing);
    }

    function unstake(
        bytes calldata encodedProof,
        bytes calldata rawReceipt,
        bytes memory proofSignature,
        bytes memory signature,
        uint256 fee,
        uint256 useBeforeBlock
    ) external onlyOperator {
        bool isRebasing;
        EthereumVerifier.State memory state;
        {
            // get info about receipt
            uint256 receiptOffset;
            assembly {
                receiptOffset := add(0x4, calldataload(36))
            }
            (state, ) = EthereumVerifier.parseTransactionReceipt(receiptOffset);
            // withdraw from bridge
            _bridge.withdraw(encodedProof, rawReceipt, proofSignature);
        }
        if (state.toToken == _bondToken) {
            isRebasing = true;
            _pool.unstakeBonds(
                state.totalAmount,
                fee,
                useBeforeBlock,
                signature
            );
        } else if (state.toToken == _certToken) {
            _pool.unstakeCerts(
                state.totalAmount,
                fee,
                useBeforeBlock,
                signature
            );
        }
        emit Unstaked(state.toAddress, state.totalAmount, isRebasing, fee);
    }

    // executes after unbond time by the operator
    function unstakeAcrossToPolygon(uint256 amount) external onlyOperator {
        require(amount > 0, "amount should be greater than 0");
        _depositManager.depositERC20ForUser(_matic, _operator, amount);
        emit UnstakedAcrossToPolygon(_operator, amount);
    }

    function changeBondToken(address bondToken) external onlyOwner {
        require(bondToken != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(bondToken),
            "non-contract address"
        );
        _bondToken = bondToken;
        emit BondTokenChanged(bondToken);
    }

    function changeCertToken(address certToken) external onlyOwner {
        require(certToken != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(certToken),
            "non-contract address"
        );
        _certToken = certToken;
        emit CertTokenChanged(certToken);
    }

    function changeAnkrToken(address ankrToken) external onlyOwner {
        require(ankrToken != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(ankrToken),
            "non-contract address"
        );
        _ankrToken = ankrToken;
        emit AnkrTokenChanged(ankrToken);
    }

    function changePool(address pool) external onlyOwner {
        require(pool != address(0), "zero address");
        require(AddressUpgradeable.isContract(pool), "non-contract address");
        IERC20Upgradeable(_bondToken).approve(
            address(_pool),
            type(uint256).min
        );
        IERC20Upgradeable(_certToken).approve(
            address(_pool),
            type(uint256).min
        );
        IERC20Upgradeable(_matic).approve(address(_pool), type(uint256).min);
        IERC20Upgradeable(_ankrToken).approve(
            address(_pool),
            type(uint256).min
        );
        _pool = IPolygonPool(pool);
        IERC20Upgradeable(_matic).approve(pool, type(uint256).max);
        IERC20Upgradeable(_bondToken).approve(pool, type(uint256).max);
        IERC20Upgradeable(_certToken).approve(pool, type(uint256).max);
        IERC20Upgradeable(_ankrToken).approve(pool, type(uint256).max);
        emit PolygonPoolChanged(pool);
    }

    function changeBridge(address bridge) external onlyOwner {
        require(bridge != address(0), "zero address");
        require(AddressUpgradeable.isContract(bridge), "non-contract address");
        IERC20Upgradeable(_bondToken).approve(
            address(_bridge),
            type(uint256).min
        );
        IERC20Upgradeable(_certToken).approve(
            address(_bridge),
            type(uint256).min
        );
        _bridge = IBridge(bridge);
        IERC20Upgradeable(_bondToken).approve(bridge, type(uint256).max);
        IERC20Upgradeable(_certToken).approve(bridge, type(uint256).max);
        emit BridgeChanged(bridge);
    }

    function changeDepositManager(address depositManager) external onlyOwner {
        require(depositManager != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(depositManager),
            "non-contract address"
        );
        IERC20Upgradeable(_matic).approve(
            address(_depositManager),
            type(uint256).min
        );
        _depositManager = IDepositManager(depositManager);
        IERC20Upgradeable(_matic).approve(
            address(_depositManager),
            type(uint256).max
        );
        emit DepositManagerChanged(depositManager);
    }

    function changeMaticPredicate(address maticPredicate) external onlyOwner {
        require(maticPredicate != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(maticPredicate),
            "non-contract address"
        );
        _maticPredicate = IPolygonERC20Predicate(maticPredicate);
        emit MaticPredicateChanged(maticPredicate);
    }

    function changeRootChainManager(address rootChainManager)
        external
        onlyOwner
    {
        require(rootChainManager != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(rootChainManager),
            "non-contract address"
        );
        _rootChainManager = IRootChainManager(rootChainManager);
        emit RootChainManagerChanged(rootChainManager);
    }

    function changeToChainId(uint256 toChainId) external onlyOwner {
        require(toChainId != 0, "zero chain id");
        _toChainId = toChainId;
        emit ToChainIdChanged(toChainId);
    }

    function changeOperator(address operator) external onlyOwner {
        require(operator != address(0), "zero address");
        _operator = operator;
        emit OperatorChanged(operator);
    }
}