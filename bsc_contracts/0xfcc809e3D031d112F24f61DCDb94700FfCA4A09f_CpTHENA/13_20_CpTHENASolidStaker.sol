// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVeToken.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/ISolidlyFactory.sol";
import "../interfaces/ICpTHENAConfigurator.sol";
import "../interfaces/ISolidlyRouter.sol";
import "../interfaces/ICpTHENAProxy.sol";

contract CpTHENASolidStaker is ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Addresses used
    ICpTHENAProxy public proxy;
    ICpTHENAConfigurator public configurator;
    IERC20Upgradeable public want;
    IVeToken public ve;
    IVoter public solidVoter;
    ISolidlyRouter public router;

    // Max Lock time, Max variable used for reserve split and the reserve rate.
    uint16 public constant MAX = 10000;
    uint256 public constant MAX_RATE = 1e18;

    address public keeper;
    address public voter;
    address public polWallet;
    address public daoWallet;

    // Our on chain events.
    event CreateLock(address indexed user, uint256 veTokenId, uint256 amount, uint256 unlockTime);
    event NewManager(address _keeper, address _voter, address _polWallet, address _daoWallet);
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event MergeNFT(uint256 from, uint256 to);

    // Checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(
            msg.sender == owner() || msg.sender == keeper,
            "CpTHENASolidStaker: MANAGER_ONLY"
        );
        _;
    }

    // Checks that caller is either owner or keeper.
    modifier onlyVoter() {
        require(msg.sender == voter, "CpTHENASolidStaker: VOTER_ONLY");
        _;
    }

    function init(
        string memory _name,
        string memory _symbol,
        address _proxy,
        address _keeper,
        address _voter,
        address _polWallet,
        address _daoWallet,
        address _configurator
    ) public initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        
        configurator = ICpTHENAConfigurator(_configurator);
        proxy = ICpTHENAProxy(_proxy);
        
        solidVoter = IVoter(proxy.solidVoter());
        ve = IVeToken(solidVoter._ve());
        want = IERC20Upgradeable(ve.token());

        router = ISolidlyRouter(proxy.router());

        keeper = _keeper;
        voter = _voter;
        polWallet = _polWallet;
        daoWallet = _daoWallet;
    }

    function depositVe(uint256 _tokenId) external nonReentrant whenNotPaused {
        require(!configurator.isPausedDepositVe(), "CpTHENA: PAUSED");
        uint256 mainTokenId = proxy.mainTokenId();
        uint256 reserveTokenId = proxy.reserveTokenId();
        require(mainTokenId > 0 && reserveTokenId > 0, "CpTHENA: NOT_ASSIGNED");
        uint256 currentPeg = getCurrentPeg();
        require(currentPeg >= configurator.maxPeg(), "CpTHENA: NOT_MINT_WITH_UNDER_PEG");
        lock();
        (uint256 _lockedAmount, ) = ve.locked(_tokenId);
        if (_lockedAmount > 0) {
            ve.transferFrom(msg.sender, address(proxy), _tokenId);
            if (balanceOfWantInReserveVe() > requiredReserve()) {
                proxy.merge(_tokenId, mainTokenId);
            } else {
                proxy.merge(_tokenId, reserveTokenId);
            }
            
            _mint(msg.sender, _lockedAmount);
            emit Deposit(_lockedAmount);
        }
    }

    function deposit(uint256 _amount) external nonReentrant whenNotPaused {
        require(!configurator.isPausedDeposit(), "CpTHENA: PAUSED");
        uint256 mainTokenId = proxy.mainTokenId();
        uint256 reserveTokenId = proxy.reserveTokenId();
        require(mainTokenId > 0 && reserveTokenId > 0, "CpTHENA: NOT_ASSIGNED");
        lock();
        ISolidlyRouter.Routes[] memory routes = new ISolidlyRouter.Routes[](1);
        routes[0] = ISolidlyRouter.Routes({
            from: address(want),
            to: address(this),
            stable: false
        });

        address pairAddress = ISolidlyFactory(solidVoter.factory()).getPair(address(want), address(this), false);
        require(pairAddress != address(0), "CpTHENA: LP_INVALID");
        uint256 amountOut = router.getAmountsOut(_amount, routes)[routes.length];
        uint256 taxBuyingPercent = configurator.hasBuyingTax(address(this), pairAddress);
        amountOut = amountOut - amountOut * taxBuyingPercent / MAX;

        if (amountOut > _amount) {
            want.safeTransferFrom(msg.sender, address(this), _amount);
            IERC20Upgradeable(want).safeApprove(address(router), _amount);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amount,
                0,
                routes,
                msg.sender,
                block.timestamp
            );
            IERC20Upgradeable(want).safeApprove(address(router), 0);
        } else {
            uint256 _balanceBefore = balanceOfWant();
            want.safeTransferFrom(msg.sender, address(this), _amount);
            _amount = balanceOfWant() - _balanceBefore;

            if (_amount > 0) {
                _mint(msg.sender, _amount);
                uint256 wantAmount = balanceOfWant();
                want.safeTransfer(address(proxy), wantAmount);
                if (balanceOfWantInReserveVe() > requiredReserve()) {
                    proxy.increaseAmount(mainTokenId, wantAmount);
                } else {
                    proxy.increaseAmount(reserveTokenId, wantAmount);
                }
            }
        }

        emit Deposit(totalWant());
    }

    function lock() public { 
        if (configurator.isAutoIncreaseLock()) {
            proxy.increaseUnlockTime();
        }
    }

    function merge(uint256 from, uint256 to) external nonReentrant {
        uint256 mainTokenId = proxy.mainTokenId();
        uint256 reserveTokenId = proxy.reserveTokenId();
        require(to == mainTokenId || to == reserveTokenId, "CpTHENA: TO_INVALID");
        require(from != mainTokenId && from != reserveTokenId, "CpTHENA: FROM_INVALID");
        ve.transferFrom(address(this), address(proxy), from);
        proxy.merge(from, to);
        emit MergeNFT(from, to); 
    }

    function withdraw(uint256 _amount) external nonReentrant {
        uint256 redeemTokenId = proxy.redeemTokenId();
        require(redeemTokenId > 0, "CpTHENA: NOT_ASSIGNED");
        uint256 lastVoted = solidVoter.lastVoted(redeemTokenId);
        require(block.timestamp > lastVoted + configurator.minDuringTimeWithdraw(), "CpTHENA: PAUSED_AFTER_VOTE");

        uint256 withdrawableAmount = withdrawableBalance();
        require(withdrawableAmount > MAX_RATE && _amount < withdrawableAmount - MAX_RATE, "CpTHENA: INSUFFICIENCY_AMOUNT_OUT");
        _burn(msg.sender, _amount);
        uint256 redeemFeePercent = configurator.redeemFeePercent();
        if (redeemFeePercent > 0) {
            uint256 redeemFeeAmount = (_amount * redeemFeePercent) / MAX;
            if (redeemFeeAmount > 0) {
                _amount = _amount - redeemFeeAmount;
                // mint fee
                _mint(polWallet, redeemFeeAmount);
            }
        }

        if (ve.voted(redeemTokenId)) {
            proxy.resetVote(redeemTokenId);
        }

        uint256 tokenIdForUser = proxy.splitWithdraw(_amount);
        ve.transferFrom(address(this), msg.sender, tokenIdForUser);
        emit Withdraw(_amount);
    }

    function totalWant() public view returns (uint256) {
        return balanceOfWantInMainVe() + balanceOfWantInReserveVe() + balanceOfWant();
    }

    function lockInfo(uint256 _tokenId)
        public
        view
        returns (
            uint256 endTime,
            uint256 secondsRemaining
        )
    {
        (, endTime) = ve.locked(_tokenId);
        secondsRemaining = endTime > block.timestamp
            ? endTime - block.timestamp
            : 0;
    }

    function requiredReserve() public view returns (uint256 reqReserve) {
        reqReserve = balanceOfWantInMainVe() * configurator.reserveRate() / MAX;
    }

    function withdrawableBalance() public view returns (uint256) {
        return proxy.withdrawableBalance();
    }

    function balanceOfWantInMainVe() public view returns (uint256 wants) {
        return proxy.balanceOfWantInMainVe();
    }

    function balanceOfWantInReserveVe() public view returns (uint256 wants) {
        return proxy.balanceOfWantInReserveVe();
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function resetVote(uint256 _tokenId) external onlyVoter {
        proxy.resetVote(_tokenId);
    }

    function createReserveLock(
        uint256 _amount,
        uint256 _lock_duration
    ) external onlyManager {
        require(_amount > 0, "CpTHENA: ZERO_AMOUNT");
        want.safeTransferFrom(address(msg.sender), address(proxy), _amount);
        proxy.createReserveLock(_amount, _lock_duration);
        _mint(msg.sender, _amount);

        emit CreateLock(msg.sender, proxy.reserveTokenId(), _amount, _lock_duration);
    }

    function createMainLock(
        uint256 _amount,
        uint256 _lock_duration
    ) external onlyManager {
        require(_amount > 0, "CpTHENA: ZERO_AMOUNT");
        want.safeTransferFrom(address(msg.sender), address(proxy), _amount);
        proxy.createMainLock(_amount, _lock_duration);
        _mint(msg.sender, _amount);

        emit CreateLock(msg.sender, proxy.mainTokenId(), _amount, _lock_duration);
    }

    // Pause deposits
    function pause() public onlyManager {
        _pause();
    }

    // Unpause deposits
    function unpause() external onlyManager {
        _unpause();
    }

    function getCurrentPeg() public view returns (uint256) {
        address pairAddress = ISolidlyFactory(solidVoter.factory()).getPair(address(want), address(this), false);
        require(pairAddress != address(0), "CpTHENA: LP_INVALID");
        IPairFactory pair = IPairFactory(pairAddress);
        address token0 = pair.token0();
        (uint256 _reserve0, uint256 _reserve1, ) = pair.getReserves();
        if (token0 == address(this)) {
            return _reserve1 * MAX_RATE / _reserve0;
        } else {
            return _reserve0 * MAX_RATE / _reserve1;
        }
    }

    function setManager(
        address _keeper,
        address _voter,
        address _polWallet,
        address _daoWallet
    ) external onlyManager {
        keeper = _keeper;
        voter = _voter;
        polWallet = _polWallet;
        daoWallet = _daoWallet;
        emit NewManager(_keeper, _voter, _polWallet, _daoWallet);
    }

    function setSolidVoter(address _solidVoter) external onlyManager {
        proxy.setSolidVoter(_solidVoter);
        solidVoter = IVoter(_solidVoter);
    }

    function setVeDist(address _veDist) external onlyManager {
        proxy.setVeDist(_veDist);
    }
}