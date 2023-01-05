// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferBNB(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }
}

interface IPancakeRouter {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function WETH() external view returns (address);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

interface IVesting {
    function vestPurchase(address user, uint amount) external;

    function vesters(address vester) external returns (bool);
}

interface IBEP20Permit {
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract SYNTASale is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct Trade {
        address initiator;
        address proposedAsset;
        uint initialProposedAmount;
        uint proposedAmount;
        address askedAsset;
        bool proposedAssetVest;
        uint askedRate;
        uint askedSoldAmount;
        uint minTradeProposedAmount;
        uint deadline;
        uint totalReceived;
        uint status; //0: Active, 1: success, 2: canceled, 3: withdrawn
        mapping(address => uint) purchases;
    }

    enum TradeState {
        Active,
        Succeeded,
        Canceled,
        Withdrawn,
        Overdue
    }

    IPancakeRouter public pancakeRouter;
    IWETH public WETH;
    IERC20Upgradeable public BusdContract;

    mapping(uint => uint) public supportRewardRates;
    address public supportAddress;
    address public saleAddress;

    uint public tradeCount;
    mapping(uint => Trade) public trades;
    mapping(address => uint[]) private _userTrades;

    event NewTrade(
        address proposedAsset,
        uint proposedAmount,
        address askedAsset,
        bool proposedAssetVest,
        uint askedRate,
        uint deadline,
        uint minTradeProposedAmount,
        uint tradeId
    );
    event SupportTrade(
        uint tradeId,
        address counterparty,
        uint amount,
        uint assetAmount,
        bool isExternal
    );
    event CancelTrade(uint tradeId);
    event WithdrawOverdueAsset(uint tradeId);

    event Rescue(address indexed to, uint amount);
    event RescueToken(address indexed token, address indexed to, uint amount);

    function initialize(
        address newPancakeRouter,
        address newBusdContract,
        address newSupport,
        address newSale,
        uint[] memory newSupportRewardRates
    ) public initializer {
        __Context_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        require(
            AddressUpgradeable.isContract(newPancakeRouter),
            "SYNTASale: Not a contract"
        );
        pancakeRouter = IPancakeRouter(newPancakeRouter);
        WETH = IWETH(pancakeRouter.WETH());
        BusdContract = IERC20Upgradeable(newBusdContract);

        _updateSaleAddressAndRewardRates(
            newSupport,
            newSale,
            newSupportRewardRates
        );
    }

    receive() external payable {
        assert(msg.sender == address(WETH)); // only accept BNB via fallback from the WETH contract
    }

    function _updateSaleAddressAndRewardRates(
        address newSupport,
        address newSale,
        uint[] memory newSupportRewardRates
    ) private {
        require(
            newSupport != address(0) && newSale != address(0),
            "SYNTASale: Zero address"
        );
        supportAddress = newSupport;
        saleAddress = newSale;

        require(
            newSupportRewardRates.length == 2,
            "SYNTASale: Only 2 rates supported"
        );
        for (uint i = 0; i < newSupportRewardRates.length; i++) {
            require(
                newSupportRewardRates[i] >= 0 &&
                    newSupportRewardRates[i] <= 100,
                "SYNTASale: Reward rate should be from 0 to 100"
            );
            supportRewardRates[i] = newSupportRewardRates[i];
        }
    }

    function createTrade(
        address proposedAsset,
        uint proposedAmount,
        address askedAsset,
        bool proposedAssetVest,
        uint askedRate,
        uint minTradeProposedAmount,
        uint deadline
    ) external onlyOwner returns (uint tradeId) {
        require(
            AddressUpgradeable.isContract(proposedAsset),
            "SYNTASale: Not contract"
        );
        require(
            askedAsset == address(BusdContract),
            "SYNTASale: Only BUSD allowed"
        );
        TransferHelper.safeTransferFrom(
            proposedAsset,
            msg.sender,
            address(this),
            proposedAmount
        );
        tradeId = _createTrade(
            proposedAsset,
            proposedAmount,
            askedAsset,
            proposedAssetVest,
            askedRate,
            minTradeProposedAmount,
            deadline
        );
    }

    function supportTrade(
        uint tradeId,
        address purchaseToken,
        uint purchaseTokenAmount,
        bool isExternal
    ) external payable nonReentrant whenNotPaused {
        require(
            tradeCount >= tradeId && tradeId > 0,
            "SYNTASale: invalid trade id"
        );
        Trade storage trade = trades[tradeId];
        require(
            trade.status == 0 && trade.deadline > block.timestamp,
            "SYNTASale: not active trade"
        );
        require(
            purchaseToken == address(WETH) || purchaseToken == trade.askedAsset,
            "Purchase token should be WETH or specified in trade"
        );

        uint256 finalTokenAmount = purchaseTokenAmount;
        if (purchaseToken == address(WETH)) {
            require(purchaseTokenAmount == msg.value, "Wrong ETH value in purchaseTokenAmount");
            finalTokenAmount = _swapWethToPurchaseToken(trade.askedAsset);
        } else {
            require(msg.value == 0, "ETH should be 0");
            TransferHelper.safeTransferFrom(
                trade.askedAsset,
                msg.sender,
                address(this),
                purchaseTokenAmount
            );
        }

        uint256 tokenAmount = getCurrentTokenAmount(
            tradeId,
            trade.askedAsset,
            finalTokenAmount
        );
        require(
            tokenAmount >= trade.minTradeProposedAmount,
            "SYNTASale: purchase amount lower then min amount"
        );
        require(
            purchaseTokenAmount > 0 &&
                trade.proposedAmount > 0 &&
                trade.proposedAmount >= tokenAmount,
            "SYNTASale: wrong amount"
        );

        (uint256 toSupport, uint256 toSale) = calculatePayments(
            finalTokenAmount,
            isExternal
        );
        if (toSupport > 0)
            TransferHelper.safeTransfer(
                trade.askedAsset,
                supportAddress,
                toSupport
            );

        if (toSale > 0)
            TransferHelper.safeTransfer(
                trade.askedAsset,
                saleAddress,
                toSale
            );

        _supportTrade(tradeId, finalTokenAmount, isExternal);
    }

    function _swapWethToPurchaseToken(
        address purchaseToken
    ) internal returns (uint256 amountPurchaseToken) {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = purchaseToken;
        uint[] memory amountsBNBBusd = IPancakeRouter(pancakeRouter)
            .swapExactETHForTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp + 100
        );
        amountPurchaseToken = amountsBNBBusd[1];
    }

    function cancelTrade(uint tradeId) external nonReentrant whenNotPaused {
        require(
            tradeCount >= tradeId && tradeId > 0,
            "SYNTASale: invalid trade id"
        );
        Trade storage trade = trades[tradeId];
        require(trade.initiator == msg.sender, "SYNTASale: not allowed");
        require(
            trade.status == 0 && trade.deadline > block.timestamp,
            "SYNTASale: not active trade"
        );
        trade.status = 2;

        if (trade.proposedAsset != address(WETH)) {
            TransferHelper.safeTransfer(
                trade.proposedAsset,
                msg.sender,
                trade.proposedAmount
            );
        } else {
            WETH.withdraw(trade.proposedAmount);
            TransferHelper.safeTransferBNB(msg.sender, trade.proposedAmount);
        }

        emit CancelTrade(tradeId);
    }

    function withdrawOverdueAsset(
        uint tradeId
    ) external nonReentrant whenNotPaused {
        require(
            tradeCount >= tradeId && tradeId > 0,
            "SYNTASale: invalid trade id"
        );
        Trade storage trade = trades[tradeId];
        require(trade.initiator == msg.sender, "SYNTASale: not allowed");
        require(
            trade.status == 0 && trade.deadline < block.timestamp,
            "SYNTASale: not available for withdrawal"
        );

        if (trade.proposedAsset != address(WETH)) {
            TransferHelper.safeTransfer(
                trade.proposedAsset,
                msg.sender,
                trade.proposedAmount
            );
        } else {
            WETH.withdraw(trade.proposedAmount);
            TransferHelper.safeTransferBNB(msg.sender, trade.proposedAmount);
        }

        trade.status = 3;

        emit WithdrawOverdueAsset(tradeId);
    }

    function state(uint tradeId) external view returns (TradeState) {
        require(
            tradeCount >= tradeId && tradeId > 0,
            "SYNTASale: invalid trade id"
        );
        Trade storage trade = trades[tradeId];
        if (trade.status == 1) {
            return TradeState.Succeeded;
        } else if (trade.status == 2 || trade.status == 3) {
            return TradeState(trade.status);
        } else if (trade.deadline < block.timestamp) {
            return TradeState.Overdue;
        } else {
            return TradeState.Active;
        }
    }

    function userTrades(address user) external view returns (uint[] memory) {
        return _userTrades[user];
    }

    function userPurchasesForTrade(
        address user,
        uint tradeId
    ) external view returns (uint) {
        return trades[tradeId].purchases[user];
    }

    function _createTrade(
        address proposedAsset,
        uint proposedAmount,
        address askedAsset,
        bool proposedAssetVest,
        uint askedRate,
        uint minTradeProposedAmount,
        uint deadline
    ) private returns (uint tradeId) {
        require(
            askedAsset != proposedAsset,
            "SYNTASale: asked asset can't be equal to proposed asset"
        );
        require(proposedAmount > 0, "SYNTASale: zero proposed amount");
        require(askedRate > 0, "SYNTASale: zero asked amount");
        require(
            proposedAmount > minTradeProposedAmount,
            "SYNTASale: proposed amount should be more then min trade amount"
        );
        require(deadline > block.timestamp, "SYNTASale: incorrect deadline");
        require(
            !proposedAssetVest ||
                (proposedAssetVest &&
                    IVesting(proposedAsset).vesters(address(this))),
            "SYNTASale: this contract not allowed to vest on proposed asset"
        );

        tradeId = ++tradeCount;
        Trade storage trade = trades[tradeId];
        trade.initiator = msg.sender;
        trade.proposedAsset = proposedAsset;
        trade.initialProposedAmount = proposedAmount;
        trade.proposedAmount = proposedAmount;
        trade.askedAsset = askedAsset;
        trade.proposedAssetVest = proposedAssetVest;
        trade.askedRate = askedRate;
        trade.deadline = deadline;
        trade.minTradeProposedAmount = minTradeProposedAmount;
        trade.totalReceived = 0;

        _userTrades[msg.sender].push(tradeId);

        emit NewTrade(
            proposedAsset,
            proposedAmount,
            askedAsset,
            proposedAssetVest,
            askedRate,
            deadline,
            minTradeProposedAmount,
            tradeId
        );
    }

    function getBusdAmountFromPancake(
        uint256 amountBNB
    ) public view returns (uint256 amountBusd) {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(BusdContract);
        uint[] memory amountsBNBBusd = IPancakeRouter(pancakeRouter)
            .getAmountsOut(amountBNB, path);
        amountBusd = amountsBNBBusd[1];
    }

    function getCurrentTokenAmount(
        uint256 tradeId,
        address purchaseToken,
        uint256 partialAmount
    ) public view returns (uint256) {
        if (purchaseToken == trades[tradeId].askedAsset) return partialAmount * 1 ether / trades[tradeId].askedRate;
        if (purchaseToken == address(WETH)) return getBusdAmountFromPancake(partialAmount) * 1 ether / trades[tradeId].askedRate;
        return 0;
    }

    function calculatePayments(
        uint256 amount,
        bool isExternal
    ) public view returns (uint256 toSupport, uint256 toSale) {
        toSupport = (amount * supportRewardRates[isExternal ? 0 : 1]) / 100;
        toSale = amount - toSupport;
    }

    function _supportTrade(
        uint tradeId,
        uint partialAmount,
        bool isExternal
    ) private {
        Trade storage trade = trades[tradeId];

        uint256 tokenAmount = getCurrentTokenAmount(
            tradeId,
            trade.askedAsset,
            partialAmount
        );
        if (trade.proposedAsset != address(WETH)) {
            if (trade.proposedAssetVest)
                IVesting(trade.proposedAsset).vestPurchase(
                    msg.sender,
                    tokenAmount
                );
            else
                TransferHelper.safeTransfer(
                    trade.proposedAsset,
                    msg.sender,
                    tokenAmount
                );
        } else {
            WETH.withdraw(tokenAmount);
            TransferHelper.safeTransferBNB(msg.sender, tokenAmount);
        }

        trade.totalReceived += partialAmount;
        trade.proposedAmount -= tokenAmount;
        trade.askedSoldAmount += tokenAmount;
        trade.purchases[msg.sender] += partialAmount;

        if (trade.proposedAmount == 0) {
            trade.status = 1;
        }

        emit SupportTrade(tradeId, msg.sender, partialAmount, tokenAmount, isExternal);
    }

    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "SYNTASale: Can't be zero address");
        require(amount > 0, "SYNTASale: Should be greater than 0");
        TransferHelper.safeTransferBNB(to, amount);
        emit Rescue(to, amount);
    }

    function rescue(
        address to,
        address token,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "SYNTASale: Can't be zero address");
        require(amount > 0, "SYNTASale: Should be greater than 0");
        TransferHelper.safeTransfer(token, to, amount);
        emit RescueToken(token, to, amount);
    }

    function updatePancakeRouterAndWETH(
        address newPancakeRouter
    ) external onlyOwner {
        require(
            AddressUpgradeable.isContract(newPancakeRouter),
            "SYNTASale: Not a contract"
        );
        pancakeRouter = IPancakeRouter(newPancakeRouter);
        WETH = IWETH(pancakeRouter.WETH());
    }

    /**
     * @notice Sets Contract as paused
     * @param isPaused  Pausable mode
     */
    function setPaused(bool isPaused) external onlyOwner {
        if (isPaused) _pause();
        else _unpause();
    }

    function updateSupportAddressAndRewardRates(
        address newSupport,
        address newSale,
        uint[] memory newSupportRewardRates
    ) public onlyOwner {
        _updateSaleAddressAndRewardRates(
            newSupport,
            newSale,
            newSupportRewardRates
        );
    }
}