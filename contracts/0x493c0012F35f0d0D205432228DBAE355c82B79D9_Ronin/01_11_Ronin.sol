// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Ronin is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    mapping(address => bool) private _isExcludedFromRyou;

    uint256 public launchBlock;

    uint256 public constant MAX_SUPPLY = 1000 * 10**6 * 10**18;
    uint256 public constant OHAKA_SHARE = MAX_SUPPLY / 2;
    uint256 public constant LIQUIDITY_SHARE = (MAX_SUPPLY / 1000) * 225;
    uint256 public maxWallet = MAX_SUPPLY / 100; // 1% (10000000)
    uint256 public maxTransfer = MAX_SUPPLY / 200; // 0.5% (5000000)
    uint256 public maxRestrictionBlocks = 7200;

    uint256 public ohakaRyou = 100;
    uint256 public ohakaRyouDenominator = 10000;
    uint256 public ohakaRyouDivider = 3;
    uint256 public ohakaRyouAmount = 0;

    address public marketing = 0x0000000000000000000000000000000000004321;
    address public staking = 0x0000000000000000000000000000000000005432;
    address public dev = 0x0000000000000000000000000000000000006543;

    bool public launched = false;
    bool private inDistribution = false;
    bool private inLaunch = false;

    event SetMarketingWallet(address addr, address sender);
    event SetStakingWallet(address addr, address sender);
    event SetDevWallet(address addr, address sender);
    event ExtendMaxRestrictionBlocks(uint256 blocks, address sender);
    event IncludeInRyou(address addr);
    event ExcludeFromRyou(address addr);
    event MarketingSync();
    event StakingSync();
    event DevSync();

    constructor(
        string memory name_,
        string memory symbol_,
        address router_
    ) ERC20(name_, symbol_) {
        // mint tokens and store on contract
        _mint(address(this), MAX_SUPPLY);

        // get uniswap router to create a pair
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router_);

        // create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // exclude owner and this contract from any ryou
        _isExcludedFromRyou[owner()] = true;
        _isExcludedFromRyou[address(this)] = true;
        _isExcludedFromRyou[marketing] = true;
        _isExcludedFromRyou[staking] = true;
        _isExcludedFromRyou[dev] = true;
    }

    receive() external payable {}

    fallback() external payable {}

    function launch(address[] memory drops, uint256[] memory amounts)
        external
        payable
    {
        require(!launched, "Token already launched");

        // balances
        uint256 _balance = address(this).balance;

        inLaunch = true;
        airdropBatch(drops, amounts);

        addLiquidity(LIQUIDITY_SHARE, _balance);

        // if leftovers move to marketing
        uint256 _balanceOf = balanceOf(address(this));
        if (_balanceOf > OHAKA_SHARE) {
            _balanceOf = _balanceOf.sub(OHAKA_SHARE);
            _transfer(address(this), marketing, _balanceOf);
        }

        launchBlock = block.number;

        launched = true;
        inLaunch = false;
    }

    function airdropBatch(address[] memory drops, uint256[] memory amounts)
        public
        onlyOwner
    {
        require(!launched, "Token already launched");
        if (
            drops.length > 0 &&
            amounts.length > 0 &&
            drops.length == amounts.length
        ) {
            for (uint256 i = 0; i < drops.length; i++) {
                airdrop(drops[i], amounts[i]);
            }
        }
    }

    function airdrop(address drop, uint256 amount) public onlyOwner {
        require(!launched, "Token already launched");
        require(drop != address(0), "Token already launched");
        require(
            balanceOf(address(this)) - amount >= LIQUIDITY_SHARE + OHAKA_SHARE,
            "Token limit for airdrop reached"
        );
        _transfer(address(this), drop, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (inLaunch) return;

        if (_msgSender() != owner()) {
            require(launched, "not launched yet");
        }

        // --- restrictions ---
        if (hasRestrictions()) {
            // max amount
            require(amount <= maxTransfer, "max transfer amount reached");

            // max wallet
            if (
                to != owner() &&
                to != address(0) &&
                to != address(this) &&
                to != address(uniswapV2Router) &&
                to != address(uniswapV2Router.factory()) &&
                to != address(uniswapV2Pair) &&
                from != owner()
            ) {
                uint256 walletAmount = balanceOf(to);
                require(
                    walletAmount + amount <= maxWallet,
                    "max wallet size reached"
                );
            }
        }

        // --- ryou distribution ---
        uint256 ryouSupply = balanceOf(address(this));
        // if there is any supply left on the contract, we can distribute ryou
        if (ryouSupply > 0 && !inDistribution) {
            inDistribution = true;
            // collect ryou from buy and sells
            if (to == uniswapV2Pair || from == uniswapV2Pair) {
                ohakaRyouAmount = ohakaRyouAmount.add(
                    amount.mul(ohakaRyou).div(ohakaRyouDenominator)
                );
            }

            // if collected ohakaRyouAmount reaches more than available ryou supply
            if (ohakaRyouAmount > ryouSupply) {
                ohakaRyouAmount = ryouSupply;
            }

            if (
                ohakaRyouAmount > 0 &&
                !_isExcludedFromRyou[from] &&
                !_isExcludedFromRyou[to] &&
                from != uniswapV2Pair // NOT on buys
            ) {
                uint256 ryouAmount = ohakaRyouAmount;
                ohakaRyouAmount = 0;

                // collect all eth on token contract
                swapTokensForEth(ryouAmount, address(this));

                uint256 distAmount = address(this).balance;
                uint256 ryouLeftovers = distAmount.mod(ohakaRyouDivider);
                uint256 ryouPartial = distAmount.sub(ryouLeftovers).div(
                    ohakaRyouDivider
                );

                if (staking.isContract()) {
                    (bool successTransfer, ) = staking.call{
                        value: ryouPartial,
                        gas: 100000
                    }(abi.encodeWithSignature(""));

                    if (successTransfer) {
                        (bool successSync, bytes memory data) = staking.call(
                            abi.encodeWithSignature("sync()")
                        );
                        if (
                            successSync &&
                            (data.length == 0 || abi.decode(data, (bool)))
                        ) {
                            emit StakingSync();
                        }
                    }
                } else payable(address(staking)).transfer(ryouPartial);

                if (marketing.isContract()) {
                    (bool successTransfer, ) = marketing.call{
                        value: ryouPartial,
                        gas: 100000
                    }(abi.encodeWithSignature(""));
                    if (successTransfer) {
                        (bool successSync, bytes memory data) = marketing.call(
                            abi.encodeWithSignature("sync()")
                        );
                        if (
                            successSync &&
                            (data.length == 0 || abi.decode(data, (bool)))
                        ) {
                            emit MarketingSync();
                        }
                    }
                } else payable(address(marketing)).transfer(ryouPartial);

                if (dev.isContract()) {
                    (bool successTransfer, ) = dev.call{
                        value: ryouPartial,
                        gas: 100000
                    }(abi.encodeWithSignature(""));

                    if (successTransfer) {
                        (bool successSync, bytes memory data) = dev.call(
                            abi.encodeWithSignature("sync()")
                        );
                        if (
                            successSync &&
                            (data.length == 0 || abi.decode(data, (bool)))
                        ) {
                            emit DevSync();
                        }
                    }
                } else
                    payable(address(dev)).transfer(
                        ryouPartial.add(ryouLeftovers)
                    );
            }
            inDistribution = false;
        }
    }

    function swapTokensForEth(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function addLiquidity(uint256 _amount, uint256 _eth) private {
        _approve(address(this), address(uniswapV2Router), _amount);
        uniswapV2Router.addLiquidityETH{value: _eth}(
            address(this),
            _amount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function setDev(address addr) external onlyOwner {
        require(addr != address(0) && addr != dev, "wrong address");
        includeInRyou(dev);
        dev = addr;
        excludeFromRyou(dev);
        emit SetDevWallet(addr, _msgSender());
    }

    function setStaking(address addr) external onlyOwner {
        require(addr != address(0) && addr != staking, "wrong address");
        includeInRyou(staking);
        staking = addr;
        excludeFromRyou(staking);
        emit SetStakingWallet(addr, _msgSender());
    }

    function setMarketing(address addr) external onlyOwner {
        require(addr != address(0) && addr != marketing, "wrong address");
        includeInRyou(marketing);
        marketing = addr;
        excludeFromRyou(marketing);
        emit SetMarketingWallet(addr, _msgSender());
    }

    function extendMaxRestrictionBlocks(uint256 blocks) external onlyOwner {
        require(blocks > 0, "more blocks");
        require(
            launchBlock + maxRestrictionBlocks > block.number,
            "no more extension possible"
        );
        maxRestrictionBlocks += blocks;
        emit ExtendMaxRestrictionBlocks(blocks, _msgSender());
    }

    function excludeFromRyou(address addr) public onlyOwner {
        _isExcludedFromRyou[addr] = true;
        emit ExcludeFromRyou(addr);
    }

    function includeInRyou(address addr) public onlyOwner {
        _isExcludedFromRyou[addr] = false;
        emit IncludeInRyou(addr);
    }

    function isExcludedFromRyou(address addr) public view returns (bool) {
        return _isExcludedFromRyou[addr];
    }

    function hasRestrictions() public view returns (bool) {
        return launchBlock + maxRestrictionBlocks > block.number;
    }
}