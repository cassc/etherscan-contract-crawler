// SPDX-License-Identifier: MIT

/**
 * ███╗   ███╗ ██████╗  ██████╗ ███╗   ██╗    ██╗      █████╗ ██████╗ ███████╗
 * ████╗ ████║██╔═══██╗██╔═══██╗████╗  ██║    ██║     ██╔══██╗██╔══██╗██╔════╝
 * ██╔████╔██║██║   ██║██║   ██║██╔██╗ ██║    ██║     ███████║██████╔╝███████╗
 * ██║╚██╔╝██║██║   ██║██║   ██║██║╚██╗██║    ██║     ██╔══██║██╔══██╗╚════██║
 * ██║ ╚═╝ ██║╚██████╔╝╚██████╔╝██║ ╚████║    ███████╗██║  ██║██████╔╝███████║
 * ╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
 */

pragma solidity 0.8.17;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonLabs is ERC20, Ownable {
    /*|| === STATE VARIABLES === ||*/
    uint public launchDate;
    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable uniswapV2Router;
    IERC721 public immutable nftContract;
    bool private inSwapAndLiquify;
    bool public launched;
    BuyTax public buyTax;
    SellTax public sellTax;

    address payable public treasuryWallet;
    address payable public teamWallet;
    address payable public liqWallet;

    uint public nftBalance;
    uint public nftPayout = 0.001 ether;
    uint8 maxNftDistribution = 10;
    uint16 public nftIndex = 1;

    string private constant NAME = "Moon Labs";
    string private constant SYMBOL = "MLAB";
    uint8 private constant DECIMALS = 9;
    uint private constant SUPPLY = 100000000;

    uint public swapThreshold = 200000 * 10 ** DECIMALS;
    bool public taxSwap = true;

    /*|| === STRUCTS === ||*/
    struct BuyTax {
        uint8 liquidityTax;
        uint8 treasuryTax;
        uint8 teamTax;
        uint8 burnTax;
        uint8 nftTax;
        uint8 totalTax;
    }

    struct SellTax {
        uint8 liquidityTax;
        uint8 treasuryTax;
        uint8 teamTax;
        uint8 burnTax;
        uint8 nftTax;
        uint8 totalTax;
    }

    /*|| === MAPPINGS === ||*/
    mapping(address => bool) public excludedFromFee;

    /*|| === CONSTRUCTOR === ||*/
    constructor(
        address payable _treasuryWallet,
        address payable _teamWallet,
        address payable _liqWallet,
        address nftAddress
    ) ERC20(NAME, SYMBOL) {
        _mint(msg.sender, (SUPPLY * 10 ** DECIMALS)); /// Mint and send all tokens to deployer
        treasuryWallet = _treasuryWallet;
        teamWallet = _teamWallet;
        liqWallet = _liqWallet;

        nftContract = IERC721(nftAddress);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH()); /// Create uniswap pair

        uniswapV2Router = _uniswapV2Router;

        excludedFromFee[address(uniswapV2Router)] = true;
        excludedFromFee[msg.sender] = true;
        excludedFromFee[treasuryWallet] = true;
        excludedFromFee[teamWallet] = true;
        excludedFromFee[liqWallet] = true;

        buyTax = BuyTax(10, 10, 10, 10, 20, 60);
        sellTax = SellTax(10, 10, 10, 10, 20, 60);
    }

    /*|| === EVENT EMITTERS === ||*/
    event DistributeNftPayout(address[] to, uint16[] index, uint payout);

    /*|| === MODIFIERS === ||*/
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /*|| === RECIEVE FUNCTION === ||*/
    receive() external payable {}

    /*|| === EXTERNAL FUNCTIONS === ||*/

    /**
     * @notice Enables initial trading and logs time of activation. Once trading is started it cannot be stopped.
     */
    function launch() external onlyOwner {
        require(!launched, "MLAB: token already launched");
        launched = true;
        launchDate = block.timestamp;
    }

    function setNftPayout(uint _nftPayout) external onlyOwner {
        nftPayout = _nftPayout;
    }

    function setMaxNftDistribution(
        uint8 _maxNftDistribution
    ) external onlyOwner {
        require(_maxNftDistribution <= 20, "MLAB: max distribution");
        maxNftDistribution = _maxNftDistribution;
    }

    function setTreasuryWallet(
        address payable _treasuryWallet
    ) external onlyOwner {
        require(
            _treasuryWallet != address(0),
            "MLAB: address cannot be 0 address"
        );
        treasuryWallet = _treasuryWallet;
    }

    function setTeamWallet(address payable _teamWallet) external onlyOwner {
        require(_teamWallet != address(0), "MLAB: address cannot be 0 address");
        teamWallet = _teamWallet;
    }

    function setLiqWallet(address payable _liqWallet) external onlyOwner {
        require(_liqWallet != address(0), "MLAB: address cannot be 0 address");
        liqWallet = _liqWallet;
    }

    function addToWhitelist(address _address) external onlyOwner {
        require(_address != address(0), "MLAB: address cannot be 0 address");
        excludedFromFee[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        require(_address != address(0), "MLAB: address cannot be 0 address");
        excludedFromFee[_address] = false;
    }

    function setTaxSwap(bool _taxSwap) external onlyOwner {
        taxSwap = _taxSwap;
    }

    function setBuyTax(
        uint8 liquidityTax,
        uint8 treasuryTax,
        uint8 teamTax,
        uint8 burnTax
    ) external onlyOwner {
        uint8 totalTax = liquidityTax + treasuryTax + teamTax + burnTax + 2;
        require(totalTax <= 10, "MLAB: sell tax must not be greater than 10");
        buyTax = BuyTax(
            liquidityTax * 10,
            treasuryTax * 10,
            teamTax * 10,
            burnTax * 10,
            2 * 10,
            totalTax * 10
        );
    }

    function setSellTax(
        uint8 liquidityTax,
        uint8 treasuryTax,
        uint8 teamTax,
        uint8 burnTax
    ) external onlyOwner {
        uint8 totalTax = liquidityTax + treasuryTax + teamTax + burnTax + 2;
        require(totalTax <= 10, "MLAB: buy tax must not be greater than 10");
        sellTax = SellTax(
            liquidityTax * 10,
            treasuryTax * 10,
            teamTax * 10,
            burnTax * 10,
            2 * 10,
            totalTax * 10
        );
    }

    function setTokensToSellForTax(uint _swapThreshold) external onlyOwner {
        require(
            _swapThreshold <= 500000 * 10 ** DECIMALS,
            "MLAB: max swap amount"
        );
        swapThreshold = _swapThreshold;
    }

    function claimETH() external onlyOwner {
        require(
            nftBalance < address(this).balance,
            "MLAB: insignificant eth balance"
        );
        (bool sent, ) = payable(msg.sender).call{
            value: address(this).balance - nftBalance
        }("");
    }

    /*|| === INTERNAL FUNCTIONS === ||*/
    function _transfer(
        address from,
        address to,
        uint amount
    ) internal override {
        require(from != address(0), "MLAB: transfer from the zero address");
        require(to != address(0), "MLAB: transfer to the zero address");
        require(
            balanceOf(from) >= amount,
            "MLAB: transfer amount exceeds balance"
        );

        /// If buy or sell
        if (
            (from == uniswapV2Pair || to == uniswapV2Pair) && !inSwapAndLiquify
        ) {
            /// On sell and if tax swap enabled
            if (to == uniswapV2Pair && taxSwap) {
                /// If the contract balance reaches sell threshold
                if (balanceOf(address(this)) >= swapThreshold) {
                    /// Perform tax swap
                    _swapAndDistribute();
                }
            }

            uint16[] memory indexArray = new uint16[](maxNftDistribution);
            address[] memory addressArray = new address[](maxNftDistribution);

            bool rewardsSent = false;

            for (uint i = 0; i < maxNftDistribution; i++) {
                /// Check if nft threshold is met
                if (nftBalance > nftPayout) {
                    if (nftIndex < 500) {
                        nftIndex++;
                    } else {
                        nftIndex = 1;
                    }
                    address nftOwner = nftContract.ownerOf(nftIndex);
                    /// Check if not contract address
                    if (!(nftOwner.code.length > 0)) {
                        /// Send eth to index holder
                        (bool sent, ) = payable(nftOwner).call{
                            value: nftPayout
                        }("");
                        /// Check if eth sent
                        if (sent) {
                            if (!rewardsSent) rewardsSent = true;
                            /// Subtract amount sent from pool of nft rewards
                            nftBalance -= nftPayout;
                            /// Push nft index to array
                            indexArray[i] = nftIndex;
                            /// Push nft payout address to array
                            addressArray[i] = nftOwner;
                        }
                    }
                } else {
                    /// Break from loop
                    break;
                }
            }

            /// Emit event if nft payout
            if (rewardsSent)
                emit DistributeNftPayout(addressArray, indexArray, nftPayout);

            uint transferAmount = amount;
            if (!(excludedFromFee[from] || excludedFromFee[to])) {
                require(launched, "MLAB: token not launched");
                uint fees = 0;

                /// On sell
                if (to == uniswapV2Pair) {
                    fees = sellTax.totalTax;

                    /// On buy
                } else if (from == uniswapV2Pair) {
                    fees = buyTax.totalTax;
                }
                uint tokenFees = (amount * fees) / 1000;
                transferAmount -= tokenFees;
                super._transfer(from, address(this), tokenFees);
            }
            super._transfer(from, to, transferAmount);
        } else {
            super._transfer(from, to, amount);
        }
    }

    /*|| === PRIVATE FUNCTIONS === ||*/

    function _swapTokens(uint tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapAndDistribute() private lockTheSwap {
        uint8 totalTokenTax = buyTax.totalTax + sellTax.totalTax;
        uint8 burnTax = buyTax.burnTax + sellTax.burnTax;
        uint8 liquidityTax = buyTax.liquidityTax + sellTax.liquidityTax;

        uint burnTokenCut = 0;

        /// If burns are enabled
        if (buyTax.burnTax != 0 || sellTax.burnTax != 0) {
            burnTokenCut = (swapThreshold * burnTax) / totalTokenTax;
            /// Send tokens to dead address
            super._transfer(address(this), address(0xdead), burnTokenCut);
        }

        /// Tokens to add to liquidity
        uint addToLiquidityHalf = ((swapThreshold * liquidityTax) /
            totalTokenTax) / 2;

        _swapTokens(swapThreshold - addToLiquidityHalf - burnTokenCut);

        uint ethBalance = address(this).balance - nftBalance;

        uint totalSellFee = (totalTokenTax - (liquidityTax / 2) - burnTax);

        /// Distribute to team and treasury
        if (buyTax.treasuryTax + sellTax.treasuryTax > 0) {
            (treasuryWallet).call{
                value: (ethBalance *
                    (buyTax.treasuryTax + sellTax.treasuryTax)) / totalSellFee
            }("");
        }

        if (buyTax.teamTax + sellTax.teamTax > 0) {
            (teamWallet).call{
                value: (ethBalance * (buyTax.teamTax + sellTax.teamTax)) /
                    totalSellFee
            }("");
        }

        /// Add ETH to nft balance
        nftBalance +=
            (ethBalance * (buyTax.nftTax + sellTax.nftTax)) /
            totalSellFee;

        /// Add tokens to liquidity
        if (addToLiquidityHalf > 0) {
            _addLiquidity(
                (addToLiquidityHalf),
                ((ethBalance * liquidityTax) / totalSellFee) / 2
            );
        }
    }

    function _addLiquidity(
        uint tokenAmount,
        uint ethAmount
    ) private lockTheSwap {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liqWallet,
            block.timestamp
        );
    }
}