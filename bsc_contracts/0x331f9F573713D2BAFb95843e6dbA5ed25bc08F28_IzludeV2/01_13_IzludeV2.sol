//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IByalan.sol";
import "./interfaces/IFeeKafra.sol";
import "./interfaces/IIzludeV2.sol";
import "./interfaces/IAllocKafra.sol";

import "../libraries/Math.sol";

contract IzludeV2 is IIzludeV2, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_WITHDRAW_FEE = 1000; // 10%

    address public immutable override prontera;
    IByalan public override byalan;
    IERC20 public immutable override want;
    uint256 public override totalSupply;

    address public override feeKafra;
    address public override allocKafra;
    address public tva;

    event UpgradeStrategy(address implementation);
    event SetFeeKafra(address kafra);
    event SetAllocKafra(address kafra);
    event SetTVA(address tva);

    constructor(
        address _prontera,
        IByalan _byalan,
        address _tva
    ) {
        prontera = _prontera;
        byalan = _byalan;
        want = IERC20(byalan.want());
        tva = _tva;
    }

    modifier onlyProntera() {
        require(msg.sender == prontera, "!prontera");
        _;
    }

    function setFeeKafra(address _feeKafra) external onlyOwner {
        feeKafra = _feeKafra;
        emit SetFeeKafra(_feeKafra);
    }

    function setAllocKafra(address _allocKafra) external onlyOwner {
        allocKafra = _allocKafra;
        emit SetAllocKafra(_allocKafra);
    }

    function setTva(address _tva) external {
        require(tva == msg.sender, "!TVA");
        tva = _tva;
        emit SetTVA(_tva);
    }

    /**
     * @dev It calculates the total underlying value of {token} held by the system.
     * It takes into account the izlude contract balance, the strategy contract balance
     *  and the balance deployed in other contracts as part of the strategy.
     */
    function balance() public view override returns (uint256) {
        return want.balanceOf(address(this)) + byalan.balanceOf();
    }

    function calculateWithdrawFee(uint256 amount, address user) public view override returns (uint256) {
        if (feeKafra == address(0)) {
            return 0;
        }
        return Math.min(IFeeKafra(feeKafra).calculateWithdrawFee(amount, user), _calculateMaxWithdrawFee(amount));
    }

    function _calculateMaxWithdrawFee(uint256 amount) private pure returns (uint256) {
        return (amount * MAX_WITHDRAW_FEE) / 10000;
    }

    function checkAllocation(uint256 amount, address user) private view {
        require(
            allocKafra == address(0) ||
                IAllocKafra(allocKafra).canAllocate(amount, byalan.balanceOf(), byalan.balanceOfMasterChef(), user),
            "capacity limit reached"
        );
    }

    function deposit(address user, uint256 amount) external override onlyProntera returns (uint256 jellopy) {
        byalan.beforeDeposit();

        uint256 poolBefore = balance();
        want.safeTransferFrom(msg.sender, address(this), amount);
        earn();
        checkAllocation(amount, user);

        if (totalSupply == 0) {
            jellopy = amount;
        } else {
            jellopy = (amount * totalSupply) / poolBefore;
        }
        totalSupply += jellopy;
    }

    /**
     * @dev Function to send funds into the strategy and put them to work. It's primarily called
     * by the izlude's deposit() function.
     */
    function earn() public {
        want.safeTransfer(address(byalan), want.balanceOf(address(this)));
        byalan.deposit();
    }

    /**
     * @param jellopy amount of user's share
     */
    function _withdraw(address user, uint256 jellopy) private returns (uint256) {
        uint256 r = (balance() * jellopy) / totalSupply;
        totalSupply -= jellopy;

        uint256 b = want.balanceOf(address(this));
        if (b < r) {
            uint256 amount = r - b;
            byalan.withdraw(amount);
            uint256 _after = want.balanceOf(address(this));
            uint256 diff = _after - b;
            if (diff < amount) {
                r = b + diff;
            }
        }

        uint256 fee = calculateWithdrawFee(r, user);
        if (fee > 0) {
            r -= fee;
            want.safeTransfer(address(feeKafra), fee);
            IFeeKafra(feeKafra).distributeWithdrawFee(want, user);
        }
        want.safeTransfer(msg.sender, r);
        return r;
    }

    function withdraw(address user, uint256 jellopy) external override onlyProntera returns (uint256) {
        return _withdraw(user, jellopy);
    }

    function upgradeStrategy(address implementation) external {
        require(tva == msg.sender, "!TVA");
        require(address(this) == IByalan(implementation).izlude(), "invalid byalan");
        require(want == IERC20(byalan.want()), "invalid byalan want");

        // retire old byalan
        byalan.retireStrategy();

        // new byalan
        byalan = IByalan(implementation);
        earn();

        emit UpgradeStrategy(implementation);
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address token) external onlyOwner {
        require(token != address(want), "!want");

        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}