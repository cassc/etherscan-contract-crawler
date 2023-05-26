//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "../interfaces/uniswapV2/IUniswapV2Router02.sol";
import "../interfaces/uniswapV2/IUniswapV2Factory.sol";

abstract contract VestedToken is AccessControlEnumerable, ERC20 {
    using Address for address;

    address public pairingToken;
    address public launchPool;

    uint256 public tradingTime;
    uint256 public restrictionLiftTime;
    uint256 public restrictionAmount;
    uint256 public restrictionGas;
    uint256 public launchPrice;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public openSender;
    mapping(address => bool) public lastTx;
    mapping(address => uint256) public lockTime;
    mapping(address => uint256) public lockedAmount;

    uint256 public unlockMultiple;
    uint256 public maxLock;

    function __intitialize(
        uint256 _restrictionGas,
        uint256 _restrictionAmount,
        uint256 _unlockMultiple,
        uint256 _maxLock
    ) internal {
        restrictionAmount = _restrictionAmount; // in ether
        restrictionGas = _restrictionGas; // in ether
        unlockMultiple = _unlockMultiple; // in 10**0
        maxLock = _maxLock;
    }

    function configurePool(
        address uniswapV2Router02,
        address pairingToken_,
        address lp
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(uniswapV2Router02 != address(0), "router address is 0");
        require(pairingToken_ != address(0), "factory address is 0");
        require(lp != address(0), "lauch pool address is 0");
        pairingToken = pairingToken_;
        launchPool = lp;
        isWhitelisted[uniswapV2Router02] = true;
        isWhitelisted[launchPool] = true;
    }

    function setRestrictionAmount(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        restrictionAmount = amount;
    }

    function setRestrictionGas(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        restrictionGas = price;
    }

    function addSender(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        openSender[account] = true;
    }

    function setLaunchPrice(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        launchPrice = price;
    }

    function lockBot(address account, uint256 unlockBotTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockTime[account] = unlockBotTime;
    }

    modifier launchRestrict(
        address sender,
        address recipient,
        uint256 amount
    ) {
        if (launchPool != address(0)) {
            if (tradingTime == 0) {
                require(openSender[sender], "VTKN: transfers are disabled");
                if (recipient == launchPool) {
                    tradingTime = block.timestamp;
                    restrictionLiftTime = block.timestamp + (3 * 60);
                }
            } else if (tradingTime == block.timestamp) {
                revert("VTKN: no transactions allowed");
            } else if (tradingTime < block.timestamp && restrictionLiftTime > block.timestamp) {
                require(amount <= restrictionAmount, "VTKN: amount greater than max limit");
                require(tx.gasprice <= restrictionGas, "VTKN: gas price above limit");
                if (!isWhitelisted[sender] && !isWhitelisted[recipient]) {
                    require(
                        !lastTx[sender] && !lastTx[recipient] && !lastTx[tx.origin],
                        "VTKN: only one tx in restricted time"
                    );
                    lastTx[sender] = true;
                    lastTx[recipient] = true;
                    lastTx[tx.origin] = true;
                } else if (!isWhitelisted[recipient]) {
                    require(!lastTx[recipient] && !lastTx[tx.origin], "VTKN: only one tx in restricted time");
                    lastTx[recipient] = true;
                    lastTx[tx.origin] = true;
                } else if (!isWhitelisted[sender]) {
                    require(!lastTx[sender] && !lastTx[tx.origin], "VTKN: only one tx in restricted time");
                    lastTx[sender] = true;
                    lastTx[tx.origin] = true;
                }

                // If 100 ETH : 8000 Tokens were in pool, price before buy = 0.0125. If 110 ETH : 7200 Tokens
                // after the purchase, price after buy = 0.0153. The ETH will be in the pool by the time of this function
                // execution, but tokens won't decrease yet, so we get to understand the actual execution price here
                // 110 ETH : 8000 Tokens = 0.01375. This logic will be used to understand the multiple and execute vesting
                // accordingly.

                if (sender == launchPool) {
                    require(
                        (isWhitelisted[recipient] || isWhitelisted[msg.sender]),
                        "VTKN: only uniswap router allowed"
                    );

                    uint256 ethBal = IERC20(pairingToken).balanceOf(launchPool);
                    uint256 tokenBal = balanceOf(launchPool);
                    uint256 curPriceMultiple = (ethBal * 10**18 * 1000) / (tokenBal * launchPrice); // multiple of launchPrice represented in 1e3
                    if (curPriceMultiple < (unlockMultiple * 1000)) {
                        // not yet reached target
                        lockTime[recipient] =
                            block.timestamp +
                            maxLock -
                            (maxLock * curPriceMultiple) /
                            (unlockMultiple * 1000);
                        lockedAmount[recipient] = amount - (amount * curPriceMultiple) / (unlockMultiple * 1000);
                    }
                }
            } else {
                if (!isWhitelisted[sender] && lockTime[sender] >= block.timestamp) {
                    require((amount + lockedAmount[sender]) <= balanceOf(sender), "VTKN: locked balance");
                }
            }
        }
        _;
    }
}