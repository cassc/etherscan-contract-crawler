// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits & Kevin
// Burns CZUSD, tracks locked liquidity, trades to BNB and sends to Kevin for running green miners
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./czodiac/CZUsd.sol";
import "./libs/AmmLibrary.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IAmmPair.sol";
import "./interfaces/IAmmRouter02.sol";

contract DIVIPOOL is
    ERC20PresetFixedSupply,
    AccessControlEnumerable,
    KeeperCompatibleInterface
{
    using SafeERC20 for IERC20;
    using Address for address payable;
    bytes32 public constant MANAGER = keccak256("MANAGER");
    bytes32 public constant SAFE_GRANTER_ROLE = keccak256("SAFE_GRANTER_ROLE");
    address public devWallet =
        address(0x041de5De35fbAf9749A2320f8D8a7674CD50e7bd);

    uint256 public burnBPS = 1000;
    uint256 public maxBurnBPS = 2500;
    mapping(address => bool) public isExempt;

    IAmmPair public ammCzusdPair;
    IAmmRouter02 public ammRouter =
        IAmmRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    CZUsd public czusd = CZUsd(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    IERC20 public busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    uint256 public baseCzusdLocked = 15000 ether;
    uint256 public totalCzusdSpent;
    uint256 public lockedCzusdTriggerLevel = 100 ether;
    uint256 public czusdSanityLimit = 1200 ether;

    bool public tradingOpen;

    mapping(address => bool) safeContracts;

    constructor()
        ERC20PresetFixedSupply(
            "DIVI POOL",
            "DIVIPOOL",
            300000000 ether,
            msg.sender
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SAFE_GRANTER_ROLE, msg.sender);
        _grantRole(MANAGER, msg.sender);
        _grantRole(MANAGER, devWallet);

        MANAGER_setIsExempt(msg.sender, true);
        MANAGER_setIsExempt(devWallet, true);

        ammCzusdPair = IAmmPair(
            IAmmFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73).createPair(
                address(this),
                address(czusd)
            )
        );
    }

    function lockedCzusd() public view returns (uint256 lockedCzusd_) {
        bool czusdIsToken0 = ammCzusdPair.token0() == address(czusd);
        (uint112 reserve0, uint112 reserve1, ) = ammCzusdPair.getReserves();
        uint256 lockedLP = ammCzusdPair.balanceOf(address(this));
        uint256 totalLP = ammCzusdPair.totalSupply();

        uint256 lockedLpCzusdBal = ((czusdIsToken0 ? reserve0 : reserve1) *
            lockedLP) / totalLP;
        uint256 lockedLpTokenBal = ((czusdIsToken0 ? reserve1 : reserve0) *
            lockedLP) / totalLP;

        if (lockedLpTokenBal == totalSupply()) {
            lockedCzusd_ = lockedLpCzusdBal;
        } else {
            lockedCzusd_ =
                lockedLpCzusdBal -
                (
                    AmmLibrary.getAmountOut(
                        totalSupply() - lockedLpTokenBal,
                        lockedLpTokenBal,
                        lockedLpCzusdBal
                    )
                );
        }
    }

    function availableWadToSend() public view returns (uint256) {
        return lockedCzusd() - baseCzusdLocked - totalCzusdSpent;
    }

    function isOverTriggerLevel() public view returns (bool) {
        return lockedCzusdTriggerLevel <= availableWadToSend();
    }

    function checkUpkeep(bytes calldata)
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = isOverTriggerLevel();
    }

    function performUpkeep(bytes calldata) external override {
        uint256 wadToSend = availableWadToSend();
        totalCzusdSpent += wadToSend;
        require(wadToSend < czusdSanityLimit, "TKN: Exceed sanity limit");
        czusd.mint(address(this), wadToSend);
        czusd.approve(address(ammRouter), wadToSend);
        address[] memory path = new address[](2);
        path[0] = address(czusd);
        path[1] = address(busd); //BUSD
        ammRouter.swapExactTokensForTokens(
            czusd.balanceOf(address(this)),
            0,
            path,
            devWallet,
            block.timestamp
        );
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "TKN: transfer from the zero address");
        require(recipient != address(0), "TKN: transfer to the zero address");

        //Handle burn
        if (isExempt[sender] || isExempt[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            require(tradingOpen, "TKN: Not open");
            uint256 burnAmount = (amount * burnBPS) / 10000;
            if (burnAmount > 0) super._burn(sender, burnAmount);
            super._transfer(sender, recipient, amount - burnAmount);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (
            safeContracts[_msgSender()] &&
            from != address(0) &&
            to != address(0)
        ) {
            _approve(from, _msgSender(), amount);
        }
    }

    function MANAGER_setIsExempt(address _for, bool _to)
        public
        onlyRole(MANAGER)
    {
        isExempt[_for] = _to;
    }

    function MANAGER_setBps(uint256 _toBps) public onlyRole(MANAGER) {
        require(_toBps <= maxBurnBPS, "TKN: Burn too high");
        burnBPS = _toBps;
    }

    function MANAGER_setDevWallet(address _to) public onlyRole(MANAGER) {
        devWallet = _to;
    }

    function ADMIN_openTrading() external onlyRole(DEFAULT_ADMIN_ROLE) {
        tradingOpen = true;
    }

    function ADMIN_recoverERC20(address tokenAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(tokenAddress).transfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function ADMIN_withdraw(address payable _to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _to.sendValue(address(this).balance);
    }

    function ADMIN_setBaseCzusdLocked(uint256 _to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseCzusdLocked = _to;
    }

    function ADMIN_setLockedCzusdTriggerLevel(uint256 _to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lockedCzusdTriggerLevel = _to;
    }

    function ADMIN_setCzusdSanityLimit(uint256 _to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        czusdSanityLimit = _to;
    }

    function ADMIN_setAmmRouter(IAmmRouter02 _to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ammRouter = _to;
    }

    function ADMIN_setCzusd(CZUsd _to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        czusd = _to;
    }

    function ADMIN_setMaxBurnBps(uint256 _to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxBurnBPS = _to;
    }

    function SAFE_GRANTER_ROLE_setContractSafe(address _for)
        external
        onlyRole(SAFE_GRANTER_ROLE)
    {
        safeContracts[_for] = true;
    }

    function SAFE_GRANTER_ROLE_setContractUnsafe(address _for)
        external
        onlyRole(SAFE_GRANTER_ROLE)
    {
        safeContracts[_for] = false;
    }
}