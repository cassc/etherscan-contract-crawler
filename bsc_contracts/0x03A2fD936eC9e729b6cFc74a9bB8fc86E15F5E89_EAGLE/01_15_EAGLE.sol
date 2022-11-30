// SPDX-License-Identifier: Apache-2.0



/*
        ███████╗ █████╗  ██████╗ ██╗     ███████╗
        ██╔════╝██╔══██╗██╔════╝ ██║     ██╔════╝
        █████╗  ███████║██║  ███╗██║     █████╗
        ██╔══╝  ██╔══██║██║   ██║██║     ██╔══╝
        ███████╗██║  ██║╚██████╔╝███████╗███████╗
        ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝
*/

pragma solidity ^0.8.10;

import "./Interface/IEAGLENFT.sol";
import "./Interface/utils/Strings.sol";
import "./Interface/access/Ownable.sol";
import "./Interface/token/ERC20/ERC20.sol";
import "./Interface/pancake/IPancakeRouter02.sol";
import "./Interface/pancake/IPancakeFactory.sol";
import "./Interface/pancake/IPancakePair.sol";
import "./Wrap.sol";

// @custom:security-contact EAGLE TEAM
contract EAGLE is ERC20, Ownable {
    using Strings for uint256;
    address public MarketingWallet;
    address public BonusAccount;

    // @EAGLENFTAddress NFT address
    // @usdt usdt address
    // @pancakeSwapV2Router pancakeSwap router address
    // @pancakeSwapV2Pair pancakeSwap pair address(EAGLE/USDT)(POOL ADDRESS)
    IEAGLENFT public EAGLENFTAddress;
    IERC20 public usdt;
    IPancakeRouter02 public pancakeSwapV2Router;
    IPancakePair public pancakeSwapV2Pair;
    uint256 private coolingTime = 30 days;

    // @whitelist Free service charge for white list
    mapping(address => bool) public whitelist;
    Wrap public wrap;
    uint256 private txFee;
    uint public lastFeeIndex;
    uint256 private redFee = 15 * 10 ** 18;
    uint private maxFeeNum = 20;
    // Tax payment switch or not
    bool public swapAndLiquifyEnabled;

    constructor(address _eagleNft) ERC20("EAGLE", "EGL") {
        address coinAddr = 0x3d0DD066c198DD8bA115530d80951aDc54df306a;
        _mint(coinAddr, 10000000 * 10**decimals());
        MarketingWallet = 0x395738913e871a512057EF77bF578f1672e4DDD0;
        EAGLENFTAddress = IEAGLENFT(_eagleNft);
        usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
        IPancakeRouter02 _pancakeSwapv2Route = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _pancakeV2Pair = IPancakeFactory(_pancakeSwapv2Route.factory()).createPair(address(this), address(usdt));
        pancakeSwapV2Router = _pancakeSwapv2Route;
        pancakeSwapV2Pair = IPancakePair(_pancakeV2Pair);
        wrap = new Wrap(address(usdt), address(this));
        whitelist[MarketingWallet] = true;
        whitelist[coinAddr] = true;
        whitelist[address(this)] = true;
        whitelist[_msgSender()] = true;
        usdt.approve(address(pancakeSwapV2Router), ~uint256(0));
        _approve(address(this), address(pancakeSwapV2Router), ~uint256(0));
        BonusAccount = coinAddr;
    }

    // @addWhitelist add whitelist Address and Free service charge for white list
    // onlyOwner add whitelist
    function addWhitelist(address _newEntry) external onlyOwner {
        whitelist[_newEntry] = true;
    }

    // @removeWhitelist remove whitelist Address and Free service charge for white list
    // onlyOwner remove whitelist
    function removeWhitelist(address _newEntry) external onlyOwner {
        require(whitelist[_newEntry], "Previous not in whitelist");
        whitelist[_newEntry] = false;
    }

    function usdtWithdraw() external onlyOwner {
        usdt.transfer(_msgSender(), usdt.balanceOf(address(this)));
    }

    // @updateSwapAndLiquifupdateSwapAndLiquifyEnabledyEnabled Control tax payment switch
    // Must wait until the end of the first liquidity addition Can be opened
    function updateSwapAndLiquifupdateSwapAndLiquifyEnabledyEnabled(bool status)
        external
        onlyOwner
    {
        swapAndLiquifyEnabled = status;
    }

    //  to receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    //  withdraw BNB
    function emergencyBNBWithdraw() public onlyOwner {
        (bool success, ) = address(owner()).call{value: address(this).balance}("");
        require(success, "Address: unable to send value, may have reverted");
    }

    // @addLiquidityUseUsdt add liquidity use usdt and EAGLE to EAGLE/USDT POOL in pancakeSwap
    // tokenA:EAGLE     tokenB:USDT
    // pancakeSwap: addLiquidity used token A and B，The liquidity provider is address(this)
    function addLiquidityUseUsdt(
        uint256 tokenAmount,
        uint256 usdtAmount,
        address to
    ) private {
        pancakeSwapV2Router.addLiquidity(
            address(this),
            address(usdt),
            tokenAmount,
            usdtAmount,
            0,
            0,
            to,
            block.timestamp
        );
    }

    // @swapTokensForUsdt swap EAGLE to USDT (pancakeSwap EAGLE/USDT POOL)
    // tokenA:EAGLE     tokenB:USDT
    // pancakeSwap: swap EAGLE to token USDT,The user is address(this)
    // only to is address(this)
    function swapTokensForUsdt(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdt);
        // make the swap
        pancakeSwapV2Router.swapExactTokensForTokens(
            tokenAmount,
            0, // accept any amount of token
            path,
            address(wrap),
            block.timestamp + 360
        );
        wrap.withdraw();
    }

    // @swapUsdtAndLiquify swap USDT to EAGLE and add liquidity to EAGLE/USDT POOL
    // tokenA:EAGLE     tokenB:USDT
    // pancakeSwap: swap a half EAGLE to USDT,and addLiquidity EAGLE and USDT to pancakePool
    function swapUsdtAndLiquify(uint256 tokenAmount) private {
        uint256 half = (tokenAmount * 8) / 100;
        uint256 otherHalf = tokenAmount - half;
        uint256 balance = usdt.balanceOf(address(this));
        swapTokensForUsdt(otherHalf);
        uint256 newBalance = usdt.balanceOf(address(this)) - balance;
        uint256 backflow = newBalance / 10;
        addLiquidityUseUsdt(half, backflow, address(this));
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        uint256 trsAmount = amount;
        // Ordinary users need to wait for the opening transaction button after adding liquidity
        if (
            swapAndLiquifyEnabled &&
            !whitelist[from] &&
            !(from == address(this) && to == address(pancakeSwapV2Pair))
        ) {
            // 2.8% is Service Charge
            uint256 feeAmount = (amount * 28) / 1000;
            if (feeAmount > 0) {
                super._transfer(from, address(this), feeAmount);
                if (to == address(pancakeSwapV2Pair)) {
                    dealWithTxFee(feeAmount + txFee);
                    txFee = 0;
                } else {
                    txFee = feeAmount;
                }
            }
            trsAmount = amount - feeAmount;
        }
        super._transfer(from, to, trsAmount);
    }

    // @usdtDistribute When the contract balance reaches 50 usdt, air drop usdt will be distributed
    function dealWithTxFee(uint256 tokenAmount) private {
        uint256 fee = (tokenAmount * 14) / 100;
        uint256 NFTRewrd = tokenAmount - fee;
        super._transfer(address(this), MarketingWallet, fee);
        swapUsdtAndLiquify(NFTRewrd);
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance >= redFee) {
            usdtDistribute(usdtBalance);
        }
    }

    // @usdtDistribute When the contract balance reaches 50 usdt, air drop usdt will be distributed
    // 2.8% is Service Charge
    // 0.4% (14%) => Marking Wallet; 0.4% (14%) swapUsdtAndLiquify（backflow to EAGLE/USDT POOL）
    // 0.5 (18%)% => tigerEagleard Holders ; 1.5% (54%) => PhoenixEagleCard Holders
    // When the contract balance reaches 50 usdt, air drop usdt will be distributed
    function usdtDistribute(uint256 usdtBalance) private  {
        (address[] memory holdAddress, uint256[] memory types) = EAGLENFTAddress.getNFTConfig();
        uint128 _tigerEaglecardNum = 0;
        uint128 _PhoenixEagleCardNum = 0;
        uint thisIndexCount = 0;
        uint256[] memory rewardIndex = new uint256[](maxFeeNum);
        while(thisIndexCount < maxFeeNum){
            if(lastFeeIndex == types.length) lastFeeIndex = 0;
            if (types[lastFeeIndex] == 0) {
                _tigerEaglecardNum+=1;
            } else if (types[lastFeeIndex] == 1) {
                _PhoenixEagleCardNum+=1;
            }
            rewardIndex[thisIndexCount++] = lastFeeIndex++;
        }
        uint256 tigerOwnerPart;
        if(_tigerEaglecardNum > 0){
            tigerOwnerPart = (usdtBalance * 25) / 100 / _tigerEaglecardNum;
        }
        uint256 phoenixOwnerPart;
        if(_PhoenixEagleCardNum > 0){
            phoenixOwnerPart = (usdtBalance * 75) / 100 / _PhoenixEagleCardNum;
        }
        for (uint256 i = 0; i < maxFeeNum; i++) {
            if (types[rewardIndex[i]] == 0) {
                usdt.transfer(holdAddress[rewardIndex[i]], tigerOwnerPart);
            } else if (types[rewardIndex[i]] == 1) {
                usdt.transfer(holdAddress[rewardIndex[i]], phoenixOwnerPart);
            }
        }
    }

    // @receiveNFTrewards Receive the award of this NFT
    function receiveNFTrewards(uint256 _tokenId) external {
        (,uint256 nftCreationTimeInterval,uint256 nowReceivingBatch) = getNftCon(_tokenId);
        require(
            _msgSender() == EAGLENFTAddress.ownerOf(_tokenId),
            "you not owner this NFT"
        );
        require(
            nftCreationTimeInterval > coolingTime,
            "this nft create time not lagger 30 days,please wait!!!"
        );
        uint256 coinReward;
        for (uint256 i = 1; i <= nowReceivingBatch; i++) {
            if (EAGLENFTAddress.getNFTDraw(_tokenId, i) == false) {
                coinReward += getNFTThisMonthReward(_tokenId, i);
                EAGLENFTAddress.setNFTConfigReceiveOnlyEAGLETOKEN(_tokenId, i);
            }
        }
        super._transfer(BonusAccount, _msgSender(), coinReward);
    }

    function getNftCon(uint256 _tokenId)public view returns(uint256,uint256,uint256){
        uint256 NFTCreateTime = EAGLENFTAddress.getNFTCreateTime(_tokenId);
        uint256 nftCreationTimeInterval = block.timestamp - NFTCreateTime;
        uint256 nowReceivingBatch = nftCreationTimeInterval / coolingTime;
        if (nowReceivingBatch > 12) {
            nowReceivingBatch = 12;
        }
        return (NFTCreateTime,nftCreationTimeInterval,nowReceivingBatch);
    }

    // @getReward Check how much the NFT can charge
    function getReward(uint256 _tokenId) public view returns (uint256) {
        (,,uint256 nowReceivingBatch) = getNftCon(_tokenId);
        uint256 coinReward;
        for (uint256 i = 1; i <= nowReceivingBatch; i++) {
            if (EAGLENFTAddress.getNFTDraw(_tokenId, i) == false) {
                coinReward += getNFTThisMonthReward(_tokenId, i);
            }
        }
        return coinReward;
    }

    // @getNFTThisMonthReward Query how much the NFT can collect in the first month
    function getNFTThisMonthReward(uint256 _tokenId, uint256 monthId)
        public
        view
        returns (uint256)
    {
        require(monthId > 0 && monthId <= 12, "monthId must be 1-12");
        uint256 coinRewardNow;
        if (EAGLENFTAddress.getNFTEAGLESerial(_tokenId) == 0) {
            if (monthId <= 6) {
                coinRewardNow = 200 * 10**decimals();
            } else {
                coinRewardNow = 100 * 10**decimals();
            }
        } else if (EAGLENFTAddress.getNFTEAGLESerial(_tokenId) == 1) {
            if (monthId <= 6) {
                coinRewardNow = 100 * 10**decimals();
            } else {
                coinRewardNow = 50 * 10**decimals();
            }
        }
        return coinRewardNow;
    }

    // @getNFTPoolDates Get the NFT pool data
    function getNFTPoolDates(uint256 _tokenId)
    external
    view
    returns (string memory)
    {
        string memory cardName = EAGLENFTAddress.tokenType(_tokenId);
        string memory name = string(
            abi.encodePacked(cardName, " EAGLE NFT#", _tokenId.toString())
        );
        (uint256 NFTCreateTime,,uint256 nowReceivingBatch) = getNftCon(_tokenId);
        uint256 drawMonth;
        uint256 availableQuantity = getReward(_tokenId);
        for (uint256 i = 1; i <= nowReceivingBatch; i++) {
            if (EAGLENFTAddress.getNFTDraw(_tokenId, i) == true) {
                drawMonth += 1;
            }
        }
        bool receiveOrNot = EAGLENFTAddress.getNFTDraw(
            _tokenId,
            nowReceivingBatch
        );
        string memory thisMonthReceiv = receiveOrNot ? "true" : "false";
        if (nowReceivingBatch == 12) {
            nowReceivingBatch = 11;
        }
        uint256 nextCollectCountDown = NFTCreateTime + (coolingTime * (nowReceivingBatch+1));

        string memory description = string(
            abi.encodePacked(
                '","DrawMonth":',
                drawMonth.toString(),
                ',"NotDrawMonth":',
                (12 - drawMonth).toString(),
                ',"availableQuantity":',
                availableQuantity.toString(),
                ',"ReceiveOrNot":"',
                thisMonthReceiv,
                '","NextCollectCountDown":',
                nextCollectCountDown.toString(),
                ""
            )
        );

        return
            string(
                abi.encodePacked(
                    '{"token_id":',
                    _tokenId.toString(),
                    ',"name":"',
                    name,
                    description,
                    '}'
                )
            );
    }
}