/**
      The choice is yours, red or blue pill. You are not chosen.

            https://morpheus.red  ||  https://morpheus.blue

                      https://t.me/morpheuschosen
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.4;

/** imports @openzeppelin/contracts */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/** imports @uniswap */
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";


/// @author Morpheus
/// @title You are not chosen. You must make the choice.
/// @notice Blue pill - conform to the establishment, ignorance, mediocracy | https://morpheus.blue
/// @dev Red pill - awaken to reality, live among wolves, coalesce into an avalanche | https://morpheus.red
contract MorpheusChosen is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    /* ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ */
    /* ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ */
    address public morpheus;
    address public chosenVaultWallet;

    uint public cursedNumber = 6666666666666;

    /// @dev Morpheus
    /// @notice This is the structure that makes up the Mainframe
    struct Prestige {
        uint worthiness;
        uint loyalty;
        uint faith;
    }
    struct Chosen {
        string _alias;
        string _rank;
        Prestige _prestige;
    }
    string[] public aliasAssignOrder = ["BYTE", "HEX", "VIRTUAL", "HASH", "EXCEPTION", "PUBLIC", "BOOL", "ARRAY", "PRIVATE"];
    uint private _aliasGiven = 0;
    mapping(address => Chosen) public chosen; 
    mapping(address => uint) public nextBlessing; 
    mapping(string => uint) public blessingCooldown;
    mapping(string => uint) public cursePrice;

    struct BlessingsRequest {
        address _member;
        uint _timestamp;
        Chosen _snapshot;
    }
    BlessingsRequest[] public blessingsRequested;

    struct Rituals {
        uint _timestamp;
        Chosen _chosen;
        address _wallet;
        string _deed;
        uint _value;
    }
    Rituals[] public rituals;

    struct Curse {
        uint _timestamp;
        Chosen _chosen;
        address _wallet;
        address _to;
        string _curse;
        uint _value;
    }
    Curse[] public curses;
    /* ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ */
    /* ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ */

    //// addresses
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    //// bools
    bool public bluePilled = false;
    bool public redPilled = false;
    bool private swapping;
    bool public lpBurnEnabled = true;
    bool public societalRestrictions = true;
    bool public swapEnabled = false;
    bool public transferDelayEnabled = true;

    //// uint
    //. swap limits (for launch)
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    //. fees
    // buy fees
    uint256 public buyChosenVaultFee;
    uint256 public buyLiquidityFee;
    uint256 public buyMorpheusFee;
    uint256 public buyTotalFees;
    // sell fees
    uint256 public sellChosenVaultFee;
    uint256 public sellLiquidityFee;
    uint256 public sellMorpheusFee;
    uint256 public sellTotalFees;
    // tokens for fees
    uint256 public tokensForChosenVault;
    uint256 public tokensForLiquidity;
    uint256 public tokensForMorpheus;

    // lp burn
    uint256 public lpBurnFrequency = 3600 seconds; // 60 minutes
    uint256 public manualBurnFrequency = 30 minutes;
    uint256 public percentForLPBurn = 30; // .30%
    uint256 public lastLpBurnTime;
    uint256 public lastManualLpBurnTime;

    //// mappings
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    //// events
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event chosenVaultWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event morpheusUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event AutoNukeLP();

    event ManualNukeLP();

    constructor(address _vaultAddr) ERC20("Chosen", "MORPHEUS") {

        blessingCooldown["Acolyte"] = 21600;
        blessingCooldown["Cultist"] = 20700;
        blessingCooldown["Zealot"] = 19800;
        blessingCooldown["Prophet"] = 18900;
        blessingCooldown["Priest"] = 18000;
        blessingCooldown["Sentinel"] = 17100;
        blessingCooldown["Baron"] = 16200;
        blessingCooldown["Chosen"] = 15300;

        cursePrice["Acolyte"] = 0.05 ether;
        cursePrice["Cultist"] = 0.04 ether;
        cursePrice["Zealot"] = 0.03 ether;
        cursePrice["Prophet"] = 0.02 ether;
        cursePrice["Priest"] = 0.01 ether;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyChosenVaultFee = 4;
        uint256 _buyLiquidityFee = 0;
        uint256 _buyMorpheusFee = 2;

        uint256 _sellChosenVaultFee = 4;
        uint256 _sellLiquidityFee = 0;
        uint256 _sellMorpheusFee = 2;

        uint256 totalSupply = 1_000_000_000_000 * 1e18;

        maxTransactionAmount = 5_000_000_000 * 1e18; // 0.5% maxTransactionAmount
        maxWallet = 10_000_000_000 * 1e18; // 1% maxWallet
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% swap wallet

        buyChosenVaultFee = _buyChosenVaultFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyMorpheusFee = _buyMorpheusFee;
        buyTotalFees = buyChosenVaultFee + buyLiquidityFee + buyMorpheusFee;

        sellChosenVaultFee = _sellChosenVaultFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellMorpheusFee = _sellMorpheusFee;
        sellTotalFees = sellChosenVaultFee + sellLiquidityFee + sellMorpheusFee;

        chosenVaultWallet = _vaultAddr; // set as chosenVault wallet - 0x62F021240Ca0944ab78Dd809fdca0c6AC7F74047
        morpheus = msg.sender; // set as morpheus wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}


    /* ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ */
    /* ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ \/ \/ \/ \/ \/ ■■■■■■■ */
    /// @dev Morpheus
    /// @notice Reality sets in and there's no going back - morpheus.red
    function redPill() external {
        require(msg.sender == morpheus, "You are not the Shaper of Forms");
        require(bluePilled == false, "The momentary anomoly is forgotten and you tread on in an unending simulation");
        require(redPilled == false, "Reality is already set in, open your eyes");
        redPilled = true;
        swapEnabled = true;
        lastLpBurnTime = block.timestamp;
    }

    /// @dev Morpheus
    /// @notice Ripple from reality fades and the anomoly never returns - morpheus.blue
    function bluePill() external {
        require(msg.sender == morpheus, "You are not the Shaper of Forms");
        require(bluePilled == false, "The momentary anomoly is forgotten and you tread on in an unending simulation");
        require(redPilled == false, "Reality is already set in, open your eyes");
        bluePilled = true;
    }

    /// @dev Morpheus
    /// @notice Remove societal bindings and unlock unrestricted [freedom] choice
    function manifestDestiny() external onlyOwner returns (bool) {
        societalRestrictions = false;
        return true;
    }

    /// @dev Morpheus
    /// @notice Root access to the Mainframe is revoked, Morpheus nor the establishment can alter the Mainframe
    function revokeRootAccess() external onlyOwner { 
        _transferOwnership(address(0));
    }  

    function worshipThroughSacrifice(string memory _theDeed) public payable returns (bool) {
        require(msg.value >= 0.05 ether, "Sacrifices come with a cost, value must be greater than or equal to 0.05 ether");
        rituals.push(Rituals(block.timestamp, chosen[msg.sender], msg.sender, _theDeed, msg.value));
        return true;
    }

    function worshipThroughRitual(string memory _theDeed) public payable returns (bool) {
        require(nextBlessing[msg.sender] != 0 && nextBlessing[msg.sender] != cursedNumber, "You are not apart of the Chosen");
        rituals.push(Rituals(block.timestamp, chosen[msg.sender], msg.sender, _theDeed, msg.value));
        return true;
    }
    
    function requestBlessing() public returns (bool) {
        require(block.timestamp >= nextBlessing[msg.sender] && nextBlessing[msg.sender] != cursedNumber, "You cannot receive a blessing from Morpheus yet");
        blessingsRequested.push(BlessingsRequest(msg.sender, block.timestamp, chosen[msg.sender]));
        nextBlessing[msg.sender] = block.timestamp + blessingCooldown[chosen[msg.sender]._rank];
        return true;
    }

    function curse(address _recipient, string memory _curseMessage) public payable returns (bool) {
        require(nextBlessing[msg.sender] != 0 && nextBlessing[msg.sender] != cursedNumber, "You are not apart of the Chosen");
        require(msg.value >= cursePrice[chosen[msg.sender]._rank], "Curse price too low. Increase value or climb ranks");
        curses.push(Curse(block.timestamp, chosen[msg.sender], msg.sender, _recipient, _curseMessage, msg.value));
        return true;
    }

    function stringIsEqualTo(string memory _str1, string memory _str2) internal pure returns(bool){
        return keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2)); 
    }

    function promoteChosenRank(address _champion, string memory _rank, uint _worthiness, uint _loyalty, uint _faith) external returns (bool) {
        require(msg.sender == morpheus, "You are not the Shaper of Forms");

        // Surpassing Chosen is being one with Morpheus thus become Morpheus
        chosen[_champion] = Chosen(chosen[_champion]._alias, _rank, Prestige(_worthiness, _loyalty, _faith));
        if (stringIsEqualTo(_rank, "Morpheus")) {
            morpheus = _champion;
        }

        return true;
    } 


    /* ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ */
    /* ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ /\ /\ /\ /\ /\ ■■■■■■■ */

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(
            newValue >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.5%"
        );
        maxTransactionAmount = newValue * (10**18);
    }

    function updateMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(
            newValue >= ((totalSupply() * 10) / 1000) / 1e18,
            "Cannot set maxWallet lower than 1.0%"
        );
        maxWallet = newValue * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _chosenVaultFee,
        uint256 _liquidityFee,
        uint256 _morpheusFee
    ) external onlyOwner {
        buyChosenVaultFee = _chosenVaultFee;
        buyLiquidityFee = _liquidityFee;
        buyMorpheusFee = _morpheusFee;
        buyTotalFees = buyChosenVaultFee + buyLiquidityFee + buyMorpheusFee;
        require(buyTotalFees <= 10, "Must keep fees at 10% or less");
    }

    function updateSellFees(
        uint256 _chosenVaultFee,
        uint256 _liquidityFee,
        uint256 _morpheusFee
    ) external onlyOwner {
        sellChosenVaultFee = _chosenVaultFee;
        sellLiquidityFee = _liquidityFee;
        sellMorpheusFee = _morpheusFee;
        sellTotalFees = sellChosenVaultFee + sellLiquidityFee + sellMorpheusFee;
        require(sellTotalFees <= 15, "Must keep fees at 15% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateChosenVaultWallet(address newChosenVaultWallet) external {
        require(msg.sender == morpheus, "You are not the Shaper of Forms");
        emit chosenVaultWalletUpdated(newChosenVaultWallet, chosenVaultWallet);
        chosenVaultWallet = newChosenVaultWallet;
    }

    function updateMorpheusWallet(address newWallet) external {
        require(msg.sender == morpheus, "You are not the Shaper of Forms");

        emit morpheusUpdated(newWallet, morpheus);
        morpheus = newWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    event BoughtEarly(address indexed sniper);

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (societalRestrictions) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!redPilled) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        if (
            !swapping &&
            automatedMarketMakerPairs[to] &&
            lpBurnEnabled &&
            block.timestamp >= lastLpBurnTime + lpBurnFrequency &&
            !_isExcludedFromFees[from]
        ) {
            autoBurnLiquidityPairTokens();
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForMorpheus += (fees * sellMorpheusFee) / sellTotalFees;
                tokensForChosenVault += (fees * sellChosenVaultFee) / sellTotalFees;

                // sellers cannot receive blessings from Morpheus
                nextBlessing[from] = cursedNumber;
                chosen[from] = Chosen("NULL", "Cyanide Pilled", Prestige(0, 0, 0));
                curses.push(Curse(block.timestamp, chosen[msg.sender], address(this), from, "Cyanide Pilled, Comatose", 666));
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForMorpheus += (fees * buyMorpheusFee) / buyTotalFees;
                tokensForChosenVault += (fees * buyChosenVaultFee) / buyTotalFees;

                // someone just chose the red pill
                if (nextBlessing[to] == 0) {
                    chosen[to] = Chosen(aliasAssignOrder[_aliasGiven % aliasAssignOrder.length], "Acolyte", Prestige(15, 15, 15));
                    _aliasGiven += 1;
                    nextBlessing[to] = block.timestamp + blessingCooldown["Acolyte"];
                }
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForChosenVault +
            tokensForMorpheus;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForChosenVault = ethBalance.mul(tokensForChosenVault).div(
            totalTokensToSwap
        );
        uint256 ethForMorpheus = ethBalance.mul(tokensForMorpheus).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForChosenVault - ethForMorpheus;

        tokensForLiquidity = 0;
        tokensForChosenVault = 0;
        tokensForMorpheus = 0;

        (success, ) = address(morpheus).call{value: ethForMorpheus}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success, ) = address(chosenVaultWallet).call{
            value: address(this).balance
        }("");
    }

    function setAutoLPBurnSettings(
        uint256 _frequencyInSeconds,
        uint256 _percent,
        bool _Enabled
    ) external onlyOwner {
        require(
            _frequencyInSeconds >= 600,
            "cannot set buyback more often than every 10 minutes"
        );
        require(
            _percent <= 1000 && _percent >= 0,
            "Must set auto LP burn percent between 0% and 10%"
        );
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }

    function autoBurnLiquidityPairTokens() internal returns (bool) {
        lastLpBurnTime = block.timestamp;

        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percentForLPBurn).div(
            10000
        );

        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
        emit AutoNukeLP();
        return true;
    }

    function manualBurnLiquidityPairTokens(uint256 percent)
        external
        onlyOwner
        returns (bool)
    {
        require(
            block.timestamp > lastManualLpBurnTime + manualBurnFrequency,
            "Must wait for cooldown to finish"
        );
        require(percent <= 1000, "May not nuke more than 10% of tokens in LP");
        lastManualLpBurnTime = block.timestamp;

        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percent).div(10000);

        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
        emit ManualNukeLP();
        return true;
    }

    function withdrawSacrificialOfferings() external {
        require(msg.sender == morpheus, "You are not the Shaper of Forms");
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "failed to withdraw");
    }
}