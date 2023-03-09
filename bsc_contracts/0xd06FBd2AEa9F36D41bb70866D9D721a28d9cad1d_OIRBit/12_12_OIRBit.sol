// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract OIRBit is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) private bots;

    IUniswapV2Router02 public uniswapV2Router;

    address public treasuryAddress;

    bool public isOpen;
    bool private inSwap;

    uint256 public fee; //1000 = 10%
    uint256 public maxFee; //1000 = 10%
    uint256 public swapToNative; //1000 = 10%

    event SetFee(address indexed user, uint256 indexed newFee);
    event WithdrawToTreasury(address indexed user);

    error AddressIsZero();
    error AlreadyOpen();
    error Bot();
    error ExceedsMaxFee(uint256 maxFee);
    error FailedSendingFunds();
    error FromAddressIsZero();
    error InconsistenArrayLengths();
    error NewOwnerIsAddressZero();
    error NotOpen();
    error SamePairAddress();
    error ToAddressIsZero();
    error TreasuryIsZero();

    modifier NotZeroAddress(address value) {
        if (value == address(0)) revert AddressIsZero();
        _;
    }

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function initialize(
        address treasury,
        uint256 _fee
    ) public NotZeroAddress(treasury) initializer {
        ERC20Upgradeable.__ERC20_init("OIRBit", "OIR");
        OwnableUpgradeable.__Ownable_init();

        uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E //PCS - BSC
        );
        treasuryAddress = treasury;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[treasuryAddress] = true;

        fee = _fee;
        maxFee = 1000;

        _mint(_msgSender(), 125000 ether);
    }

    receive() external payable {}

    function editBots(
        address[] calldata bots_,
        bool[] calldata values
    ) external onlyOwner {
        if (bots_.length != values.length) revert InconsistenArrayLengths();
        unchecked {
            for (uint i; i < bots_.length; ++i) {
                bots[bots_[i]] = values[i];
            }
        }
    }

    function excludeFromFee(
        address account,
        bool value
    ) external NotZeroAddress(account) onlyOwner {
        isExcludedFromFee[account] = value;
    }

    function openTrading() external onlyOwner {
        if (isOpen) revert AlreadyOpen();
        isOpen = true;
    }

    /*     function setFee(uint256 value) external onlyOwner {
        if (value > maxFee) revert ExceedsMaxFee(maxFee);
        fee = value;
        emit SetFee(_msgSender(), value);
    } */

    function setSwapToNativePercent(uint256 value) external onlyOwner {
        swapToNative = value;
    }

    function setTreasuryAddress(
        address value
    ) external NotZeroAddress(value) onlyOwner {
        isExcludedFromFee[treasuryAddress] = false;
        treasuryAddress = value;
        isExcludedFromFee[value] = true;
    }

    function withdrawToTreasury() external onlyOwner {
        address treasury = treasuryAddress;
        if (treasury == address(0)) revert TreasuryIsZero();
        _swapTokensForEth((balanceOf(address(this)) * swapToNative) / 1e4);
        IERC20Upgradeable(address(this)).safeTransfer(
            treasury,
            balanceOf(address(this))
        );
        uint256 bal = address(this).balance;
        (bool sent, ) = treasury.call{value: bal}("");
        if (!sent) revert FailedSendingFunds();
        emit WithdrawToTreasury(_msgSender());
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _spendAllowance(sender, _msgSender(), amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0)) revert NewOwnerIsAddressZero();
        isExcludedFromFee[owner()] = false;
        isExcludedFromFee[newOwner] = true;
        _transferOwnership(newOwner);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        IUniswapV2Router02 router = uniswapV2Router;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        address owner = owner();
        bool isOwner = from == owner || to == owner;
        if (!isOpen && !isOwner) revert NotOpen();
        if (from == address(0)) revert FromAddressIsZero();
        if (to == address(0)) revert ToAddressIsZero();
        if (!isOwner && (bots[from] || bots[to])) revert Bot();

        if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            uint256 feeAmount = (amount * fee) / 10000;
            amount -= feeAmount;
            super._transfer(from, address(this), feeAmount);
        }

        super._transfer(from, to, amount);
    }
}