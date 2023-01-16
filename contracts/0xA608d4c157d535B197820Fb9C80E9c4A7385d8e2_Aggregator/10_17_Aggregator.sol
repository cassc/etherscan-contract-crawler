// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./bases/TokenHolder.sol";
import "./bases/Constants.sol";
import "./bases/TransferHelper.sol";
import "./markets/MarketRegistry.sol";
import "./interfaces/IWETH.sol";

contract Aggregator is Ownable, Pausable, TokenHolder, TransferHelper {
    IWETH public immutable WETH; //immutable不占用slot
    MarketRegistry public marketRegistry;
    address public protocolFeeRecipient;
    uint256 private reentrancyStatus = 1;

    // Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
    modifier nonReentrant() {
        require(reentrancyStatus == 1, "ReentrancyGuard: reentrant call");
        reentrancyStatus = 2;
        _;
        reentrancyStatus = 1;
    }

    event TradeResult(uint256 index, bool status);
    event RewardsClaimed(address token, uint256 amount);

    constructor(
        address _marketRegistry,
        address _weth,
        address _protocolFeeRecipient
    ) {
        marketRegistry = MarketRegistry(_marketRegistry);
        WETH = IWETH(_weth);
        protocolFeeRecipient = _protocolFeeRecipient;
        // TODO : 授权opensea\looksrare\x2y2 可以扣除本合约中的weth。其余token的授权可以调用下方的 setOneTimeApproval()
        WETH.approve(SEAPORT, 2**256 - 1); // "type(uint256).max" or  "2**256 - 1"
        WETH.approve(LOOKSRARE, 2**256 - 1);
        WETH.approve(X2Y2, 2**256 - 1);
    }

    // receive ETH
    receive() external payable {}

    // 用 主网币+erc20 去代购NFT。首先需要将用户的erc20 转到本合约中（因为用户只对本合约进行过授权）
    /// @notice Execute purchase with the given token and inputs
    /// @param erc20Details payment token
    /// @param tradeDetails the inputs to call
    /// @param amountToWETH eth -> weth amount
    /// @param amountToETH  weth -> eth amount(weth should be contained in the "erc20Details")
    /// @param protocolFeeAmount protocol fee amount
    function batchBuy(
        ERC20Detail[] calldata erc20Details,
        TradeDetail[] calldata tradeDetails,
        uint256 amountToWETH,
        uint256 amountToETH, //两者只有一个大于0
        uint256 protocolFeeAmount
    ) external payable nonReentrant whenNotPaused {
        // 1.transfer ERC20 tokens from the sender to this contract
        if (erc20Details.length > 0) {
            _transferERC20s(erc20Details, msg.sender, address(this));
        }
        // 2.Convert eth and weth if needed
        if (amountToWETH > 0 && amountToETH > 0) {
            revert("batchBuy: invalid amountToWETH or amountToETH");
        }
        if (amountToWETH > 0) {
            WETH.deposit{value: amountToWETH}();
        } else if (amountToETH > 0) {
            // in _transferERC20s(), sender has deposited in weth
            WETH.withdraw(amountToETH);
        }

        // 3.  charge protocolFee
        if (protocolFeeAmount > 0) {
            _transferETH(protocolFeeRecipient, protocolFeeAmount);
        }

        //4.execute trades
        _trade(tradeDetails);

        // 5. return dust tokens (if any)
        _returnDust(erc20Details);
    }

    // market Proxy-> xxxMarket contract
    function _trade(
        TradeDetail[] calldata _tradeDetails //marketId- value- tradeData
    ) internal {
        TradeDetail calldata detail;
        bool status;
        // bytes memory result;
        for (uint256 i = 0; i < _tradeDetails.length; i++) {
            detail = _tradeDetails[i];
            // get market details
            (address _proxy, bool _isLib, bool _isActive) = marketRegistry
                .markets(detail.marketId);
            // market should be active
            require(_isActive, "_trade: InActive Market");

            (status, ) = _isLib
                ? _proxy.delegatecall(detail.tradeData) //注：_proxy合约中不能定义变量，否则delegatecall的时候读取slot时会出错！！
                : _proxy.call{value: detail.value}(detail.tradeData); // 以seaport为例、call的返回值可能非常长，因此此处不再取返回值
            //call调用时，这里的proxy不要设置成ERC20、ERC721等“本合约会被授权的合约”，例如proxy是USDC合约，而很多用户又将USDC授权给本合约，那么黑客就可以构造“detail数据=transfer普通用户的USDC”，盗取那些用户授权给本合约的USDC。

            emit TradeResult(i, status); //不同的_proxy情况下，result的数据格式是不确定的，因此无法进行decode
        }
    }

    // function bytesToUint(bytes memory b) public pure returns (uint256) {
    //     //该方法中的参数b可以是任意长度。相比之下， abi.decode(result, (uint256)) 中result必须是标准的32字节才能解码出结果
    //     uint256 number;
    //     for (uint256 i = 0; i < b.length; i++) {
    //         number = number + uint8(b[i]) * (2**(8 * (b.length - (i + 1))));
    //     }
    //     return number;
    // }

    // Return the remaining tokens(eth、erc20s、weth) to the user
    function _returnDust(ERC20Detail[] calldata _tokens) internal {
        // 1.return remaining ETH (if any)
        uint256 selfBalance = address(this).balance;
        if (selfBalance > 0) {
            _transferETH(msg.sender, selfBalance);
        }
        // 2.return remaining erc20 tokens (if any)
        address tokenAddr;
        uint256 tokenBalance;
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenAddr = _tokens[i].tokenAddr;
            tokenBalance = IERC20(tokenAddr).balanceOf(address(this));
            if (tokenBalance > 0) {
                IERC20(tokenAddr).transfer(msg.sender, tokenBalance);
            }
        }
        // 3.spectial treatement:weth
        if (WETH.balanceOf(address(this)) > 0) {
            WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
        }
    }

    //////////////// 参数设置等管理员权限的方法   //////////
    // 将本合约拥有的token授权给各个market，用于支付代购费用
    function setOneTimeApproval(
        IERC20 token,
        address operator,
        uint256 amount
    ) external onlyOwner {
        token.approve(operator, amount);
    }

    //本合约负责帮用户代购，因此可能会有代币奖励
    /// @notice Performs a call to claim token rewards and transfer to owner. e.g. LOOKS、X2Y2
    /// @param rewardsDistributor The address of rewards distributor
    /// @param claimData The inputs to call rewardsDistributor
    /// @param rewardsToken The address of reward token
    /// @dev In looksrare,earn crypto just by staking, trading and listing. For looksrare, the parameters: (LOOKSRARE_REWARDS_DISTRIBUTOR,0x...,LOOKSRARE_TOKEN)
    /// @dev X2Y2 shares 100% of its profit to X2Y2 token holders. For X2Y2, the parameters: (X2Y2_REWARDS_DISTRIBUTOR,对应入参...,X2Y2_TOKEN)
    function collectMarketRewards(
        address rewardsDistributor,
        bytes calldata claimData,
        address rewardsToken
    ) external onlyOwner {
        (bool success, ) = rewardsDistributor.call(claimData);
        require(success, "collectLooksRareRewards: Claim Failed");

        uint256 tokenBalance = IERC20(rewardsToken).balanceOf(address(this));
        if (tokenBalance > 0) {
            IERC20(rewardsToken).transfer(msg.sender, tokenBalance);
            emit RewardsClaimed(rewardsToken, tokenBalance);
        }
    }

    function setMarketRegistry(MarketRegistry _marketRegistry)
        external
        onlyOwner
    {
        marketRegistry = _marketRegistry;
    }

    function setProtocolFeeRecipient(address _protocolFeeRecipient)
        external
        onlyOwner
    {
        protocolFeeRecipient = _protocolFeeRecipient;
    }

    /////////////////////////////////////
    ////////////////////////////////////////

    // withdraw tokens
    function rescueETH(address recipient) external onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }

    function rescueERC20(address token, address recipient) external onlyOwner {
        IERC20(token).transfer(
            recipient,
            IERC20(token).balanceOf(address(this))
        );
    }

    function rescueERC721(
        address collection,
        uint256 tokenId,
        address recipient
    ) external onlyOwner {
        IERC721(collection).safeTransferFrom(address(this), recipient, tokenId);
    }

    function rescueERC1155(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address recipient
    ) external onlyOwner {
        IERC1155(collection).safeTransferFrom(
            address(this),
            recipient,
            tokenId,
            amount,
            ""
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}