// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IRouter.sol";
import "../interface/IFactory.sol";
import "../interface/IPinkAntiBot.sol";

contract ATM88Upgradeable is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    IRouter public router;
    IERC20Upgradeable public tokenATM;
    IPinkAntiBot public pinkAntiBot;
    address public pair;

    bool public tradingEnabled;

    uint256 public genesisBlock;
    uint256 private deadline;
    uint256 private launchtax;

    address public devWallet;

    uint256 public sellFee;
    uint256 public buyFee;
    uint256 public minATM;
    bool public antiBotEnabled;

    mapping(address => bool) public exemptFee;
    mapping(address => bool) public isWhiteList;
    mapping(address => bool) private blackList;

    function initialize() public virtual initializer {
        __ATM_init();
    }

    function __ATM_init() internal initializer {
        __ERC20_init("ATM88", "ATM88");
        __Ownable_init();
        __Pausable_init();
        __ATM_init_unchained();
    }

    function __ATM_init_unchained() internal initializer {
        _mint(_msgSender(), 10_000_000 * 10 ** 18);
        tradingEnabled = false;
        devWallet = _msgSender();
        router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        tokenATM = IERC20Upgradeable(
            0xF02b31b0B6dCabd579e41A0250288608FA43F898
        );
        pair = IFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        exemptFee[address(this)] = true;
        exemptFee[address(0)] = true;
        exemptFee[devWallet] = true;
        isWhiteList[devWallet] = true;
        isWhiteList[pair] = true;
        isWhiteList[_msgSender()] = true;
        isWhiteList[address(router)] = true;
        sellFee = 50;
        buyFee = 20;
        minATM = 1_000 * 10 ** 18;

        pinkAntiBot = IPinkAntiBot(0x8EFDb3b642eb2a20607ffe0A56CFefF6a95Df002);
        pinkAntiBot.setTokenOwner(msg.sender);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!blackList[sender] && !blackList[recipient], "In black list");
        if (antiBotEnabled) {
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
        }
        uint256 feeSwap;

        if (!tradingEnabled) {
            require(
                isWhiteList[sender] && isWhiteList[recipient],
                "Not allow to trade"
            );
        } else {
            if (recipient == pair) {
                // sell ATM 88
                if (!exemptFee[sender]) {
                    uint256 balanceOfATM = tokenATM.balanceOf(sender);
                    require(balanceOfATM >= minATM, "Hold 1000 ATM to sell");
                    feeSwap = (amount * sellFee) / 1000;
                }
            } else if (sender == pair) {
                // buy ATM88
                if (!exemptFee[recipient]) {
                    feeSwap = (amount * buyFee) / 1000;
                }
            }
        }

        super._transfer(sender, recipient, amount - feeSwap);

        if (feeSwap > 0) {
            super._transfer(sender, devWallet, feeSwap);
        }
    }

    function setEnableAntiBot(bool _enable) external onlyOwner {
        antiBotEnabled = _enable;
    }

    function setSellFee(uint256 _fee) external onlyOwner {
        sellFee = _fee;
    }

    function setBuyFee(uint256 _fee) external onlyOwner {
        buyFee = _fee;
    }

    function setMinATM(uint256 _minATM) external onlyOwner {
        minATM = _minATM * 10 ** 18;
    }

    function setEnableTrading() external onlyOwner {
        tradingEnabled = !tradingEnabled;
    }

    function updateIsWhileList(address account, bool state) external onlyOwner {
        isWhiteList[account] = state;
    }

    function bulkIsWhileList(
        address[] memory accounts,
        bool state
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhiteList[accounts[i]] = state;
        }
    }

    function updateExemptFee(address _address, bool state) external onlyOwner {
        exemptFee[_address] = state;
    }

    function bulkExemptFee(
        address[] memory accounts,
        bool state
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = state;
        }
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        devWallet = newWallet;
    }

    function updateBlacklist(address account, bool state) external onlyOwner {
        blackList[account] = state;
    }

    function bulkBlacklist(
        address[] memory accounts,
        bool state
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            blackList[accounts[i]] = state;
        }
    }

    function rescueETH(uint256 weiAmount) external onlyOwner {
        payable(devWallet).transfer(weiAmount);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external {
        IERC20Upgradeable(tokenAdd).transfer(devWallet, amount);
    }

    receive() external payable {}
}