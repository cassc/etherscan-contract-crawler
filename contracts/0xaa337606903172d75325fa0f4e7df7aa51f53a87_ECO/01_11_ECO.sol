// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ECO is ERC20, Ownable {
    using SafeMath for uint256;

    // string private _name = "Green Planet ECO";
    // string private _symbol = "ECO";

    uint public constant INIT_TOTAL_SUPPLY = 5 * 1e8 * 1e18;
    uint public constant MAX_SUPPLY = type(uint).max;

    /* ------------- The shares of every side in percentage -------------- */
    /*
        Private Sale ---- 34%
        Public Sales ----- 23%
        Ecosystem Fund ----- 12%
        Community ----- 10%
        Founders & Team ----- 10%
        Listing & Exchange ----- 7%
        Partners ----- 2%
        Marketing ----- 2%
    */
    uint8 public constant SHARE_OF_ECOSYSTEM = 120;
    uint8 public constant SHARE_OF_COMMUNITY = 100;
    uint8 public constant SHARE_OF_LISTING = 70;
    uint8 public constant SHARE_OF_MARKETING = 20;
    uint8 public constant SHARE_OF_FOUNDERS = 100;
    uint8 public constant SHARE_OF_PARTNERS = 20;
    uint16 public constant SHARE_OF_PRIVATE_SALE = 340;
    uint8 public constant SHARE_OF_PUBLIC_SALE = 230;
    /* ------------------------------------------------------------------- */

    /* -------- Mintable amount of tokens per each sale stage ------------ */
    uint public mintableTokenAmountForFounders =
        (INIT_TOTAL_SUPPLY * SHARE_OF_FOUNDERS) / 1000;
    uint public mintableTokenAmountForPartners =
        (INIT_TOTAL_SUPPLY * SHARE_OF_PARTNERS) / 1000;
    uint public mintableTokenAmountForPrivate =
        (INIT_TOTAL_SUPPLY * SHARE_OF_PRIVATE_SALE) / 1000;
    uint public mintableTokenAmountForPublic =
        (INIT_TOTAL_SUPPLY * SHARE_OF_PUBLIC_SALE) / 1000;
    /* ------------------------------------------------------------------- */

    /* -------------- The token prices for each sale stage --------------- */
    /*
        Partner Sale: 1 ECO = 0.00002 ETH
        Private Sale: 1 ECO = 0.00003 ETH
        Public Sale: 1 ECO = 0.00004 ETH
    */
    uint public tokenPriceForPartners = 0.00002 ether;
    uint public tokenPriceForPrivate = 0.00003 ether;
    uint public tokenPriceForPublic = 0.00004 ether;
    /* ------------------------------------------------------------------- */

    /* ---------------------------- Uniswap ------------------------------ */
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    /* ------------------------------------------------------------------- */

    /* ---------------------------- Wallets ------------------------------ */
    //  Founders' wallets
    address public walletOfFounder1 =
        0xF9e347F9837A07c3b0778011Db4720E252B7b6a0;
    address public walletOfFounder2 =
        0x21E41D5efC9A5FC24D7212A0151Bb18983c79Dc4;
    address public walletOfFounder3 =
        0x56F877f0bF4f8502c29afa4474692F8219C98bef;

    //  Admin wallets
    address public walletOfEcosystem =
        0xe0FcFd2a0aFE8c9F3707Beb34291C518D2FC00Cf;
    address public walletOfCommunity =
        0xbe3a59FD4Cbed7D850f1F622F788Bf16c8CA4bDa;
    address public walletOfListing = 0x89B3Fe584e4Ea44115fFcA6DD41B6621DF8c37EC;
    address public walletOfMarketing =
        0x39FC2c432cA5098301a97817aF894d75685bc496;
    address public walletOfFund = 0x5A1653A66EcA3D1858823582f9da4f5340de43de;

    //  Burn wallet
    address private walletOfBurn = 0x000000000000000000000000000000000000dEaD;

    /* ------------------------------------------------------------------- */

    bool public tradingEnabled;
    uint256 private launchedAt;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTxLimit;
    mapping(address => bool) public automatedMarketMakerPairs;

    bytes32 public merkleRootOfPartners;

    bool public maxTransactionLimitEnabled = true;
    uint256 private maxTransactionRateBuy = 10; // 1%
    uint256 private maxTransactionRateSell = 10; // 1%

    uint256 public buyFee = 10; //  1%
    uint256 public sellFee = 10; //  1%

    bool public walletToWalletTransferWithoutFee = true;

    bool private swapping;
    uint256 public swappableTokenAmountAtOnce;

    event ExcludedFromMaxTransactionLimit(
        address indexed account,
        bool isExcluded
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event FeesUpdated(uint256 buyFee, uint256 sellFee);
    event SwapTokenAndSendEthToWallet(uint256 tokenAmount, uint256 ethAmount);
    event MaxTransactionLimitStateChanged(bool maxTransactionLimit);
    event WalletOfFundChanged(address marketingWallet);
    event MaxTransactionLimitRatesChanged(
        uint256 maxTransferRateBuy,
        uint256 maxTransferRateSell
    );

    constructor() ERC20("Green Planet ECO", "ECO") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), MAX_SUPPLY);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[walletOfEcosystem] = true;
        _isExcludedFromFees[walletOfCommunity] = true;
        _isExcludedFromFees[walletOfListing] = true;
        _isExcludedFromFees[walletOfMarketing] = true;
        _isExcludedFromFees[walletOfBurn] = true;

        /* ---------- Share the tokens to the admin wallets -------- */
        _mint(
            walletOfEcosystem,
            (INIT_TOTAL_SUPPLY * SHARE_OF_ECOSYSTEM) / 1000
        );
        _mint(
            walletOfCommunity,
            (INIT_TOTAL_SUPPLY * SHARE_OF_COMMUNITY) / 1000
        );
        _mint(walletOfListing, (INIT_TOTAL_SUPPLY * SHARE_OF_LISTING) / 1000);
        _mint(
            walletOfMarketing,
            (INIT_TOTAL_SUPPLY * SHARE_OF_MARKETING) / 1000
        );
        /* ---------------------------------------------------------- */

        /* ----------- Share the tokens to the founders ------------- */
        _mint(walletOfFounder1, 16666667 * 1e18);
        _mint(walletOfFounder2, 16666667 * 1e18);
        _mint(walletOfFounder3, 16666666 * 1e18);
        /* ---------------------------------------------------------- */

        _mint(
            owner(),
            mintableTokenAmountForPartners +
                mintableTokenAmountForPrivate +
                mintableTokenAmountForPublic
        );
    }

    function mint(address ownerWallet, uint amount) public onlyOwner {
        _mint(ownerWallet, amount * 1e18);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            tradingEnabled ||
                _isExcludedFromFees[from] ||
                _isExcludedFromFees[to],
            "Trading is not enabled yet"
        );

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (maxTransactionLimitEnabled) {
            if (
                _isExcludedFromMaxTxLimit[from] == false &&
                _isExcludedFromMaxTxLimit[to] == false
            ) {
                if (from == uniswapV2Pair) {
                    require(
                        amount <= maxTransferAmountBuy(),
                        "AntiWhale: Transfer amount exceeds the maxTransferAmount"
                    );
                } else {
                    require(
                        amount <= maxTransferAmountSell(),
                        "AntiWhale: Transfer amount exceeds the maxTransferAmount"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swappableTokenAmountAtOnce;

        if (canSwap && !swapping && automatedMarketMakerPairs[to]) {
            swapping = true;

            if (contractTokenBalance > swappableTokenAmountAtOnce * 10) {
                contractTokenBalance = swappableTokenAmountAtOnce * 10;
            }

            swapTokenAndSendEthToWallet(contractTokenBalance);

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (
            walletToWalletTransferWithoutFee &&
            from != uniswapV2Pair &&
            to != uniswapV2Pair
        ) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 _totalFees;
            if (from == uniswapV2Pair) {
                _totalFees = buyFee;
            } else {
                _totalFees = sellFee;
            }
            uint256 fees = (amount * _totalFees) / 1000;

            amount = amount - fees;

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }

    /**
        Check whether the account is contract or not.
     */
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /**
        Get max token amount that user can buy at once
     */
    function maxTransferAmountBuy() public view returns (uint) {
        return (totalSupply() * maxTransactionRateBuy) / 1000;
    }

    /**
        Get max token amount that user can sell at once
     */
    function maxTransferAmountSell() public view returns (uint) {
        return (totalSupply() * maxTransactionRateSell) / 1000;
    }

    /**
        Enable or disable the limit of max transfer amount for a specified account.
     */
    function setExcludeFromMaxTransactionLimit(
        address account,
        bool exclude
    ) external onlyOwner {
        require(
            _isExcludedFromMaxTxLimit[account] != exclude,
            "Account is already set to that state"
        );
        _isExcludedFromMaxTxLimit[account] = exclude;
        emit ExcludedFromMaxTransactionLimit(account, exclude);
    }

    /**
        Exclude or include the account in paying fee
     */
    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    /**
        Check whether the account is excluded from paying fee or not.
     */
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    /**
        Update the fees for buying and selling
     */
    function updateFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(
            _buyFee <= 20 && _sellFee <= 30,
            "Max buy fee is 20% and max sell fee is 30%"
        );
        buyFee = _buyFee;
        sellFee = _sellFee;
        emit FeesUpdated(buyFee, sellFee);
    }

    /**
        Swap token and send ethereum which are getting from swap to marketing wallet
     */
    function swapTokenAndSendEthToWallet(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        uint256 newBalance = address(this).balance - initialBalance;

        sendETH(payable(walletOfFund), newBalance);

        emit SwapTokenAndSendEthToWallet(tokenAmount, newBalance);
    }

    /**
        Send ethereum to one of the admin wallets
     */
    function sendETH(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
        Enable trading of token
     */
    function enableTrading() external onlyOwner {
        require(launchedAt == 0, "Trading already enabled");
        launchedAt = block.timestamp;
        tradingEnabled = true;
    }

    /**
        Set swappable token amount at once
     */
    function setSwappableTokenAmountAtOnce(
        uint256 newAmount
    ) external onlyOwner {
        require(
            newAmount > totalSupply() / 100000,
            "SwappableTokenAmountAtOnce must be greater than 0.001% of total supply"
        );
        swappableTokenAmountAtOnce = newAmount;
    }

    /**
        Enable or disable the limit of max token amount can be traded at once
     */
    function setEnableMaxTransactionLimit(bool enable) external onlyOwner {
        require(
            enable != maxTransactionLimitEnabled,
            "Max transaction limit is already that state"
        );
        maxTransactionLimitEnabled = enable;
        emit MaxTransactionLimitStateChanged(maxTransactionLimitEnabled);
    }

    /**
        Enable or disable paying fee in the transferring token between 2 wallets
     */
    function enableWalletToWalletTransferWithoutFee(
        bool enable
    ) external onlyOwner {
        require(
            walletToWalletTransferWithoutFee != enable,
            "Wallet to wallet transfer without fee is already set to that value"
        );
        walletToWalletTransferWithoutFee = enable;
    }

    /**
        Change the address of walletOfFund
     */
    function changeWalletOfFund(address _walletOfFund) external onlyOwner {
        require(
            walletOfFund != _walletOfFund,
            "Marketing wallet is already that address"
        );
        require(
            !isContract(_walletOfFund),
            "Marketing wallet cannot be a contract"
        );
        walletOfFund = _walletOfFund;
        emit WalletOfFundChanged(walletOfFund);
    }

    /**
        Check whether the account is excluded from limitation of max token amount in one transaction
     */
    function isExcludedFromMaxTransaction(
        address account
    ) public view returns (bool) {
        return _isExcludedFromMaxTxLimit[account];
    }

    /**
        Percentage denoimator is 1000
     */
    function setMaxTransactionRates(
        uint256 _maxTransactionRateBuy,
        uint256 _maxTransactionRateSell
    ) external onlyOwner {
        require(
            _maxTransactionRateSell >= 1 && _maxTransactionRateBuy >= 1,
            "Max Transaction limit cannot be lower than 0.1% of total supply"
        );
        maxTransactionRateBuy = _maxTransactionRateBuy;
        maxTransactionRateSell = _maxTransactionRateSell;
        emit MaxTransactionLimitRatesChanged(
            maxTransactionRateBuy,
            maxTransactionRateSell
        );
    }

    /**
        Set the root of merkle tree of Partners' wallet addresses
     */
    function setMerkleRootOfPartners(
        bytes32 _merkleRootOfPartners
    ) public onlyOwner {
        merkleRootOfPartners = _merkleRootOfPartners;
    }

    /**
        Sell the tokens to the partners
     */
    function mintForPartners(
        bytes32[] calldata merkleProof,
        uint amount
    ) public payable {
        require(
            mintableTokenAmountForPartners > 0,
            "The sale for partners was finished."
        );
        require(
            amount <= mintableTokenAmountForPartners,
            "Required amount is over of mintable amount."
        );
        require(
            msg.value >= tokenPriceForPartners * amount,
            "Not Enough Funds"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRootOfPartners, leaf),
            "You are not our partner."
        );

        _transfer(owner(), msg.sender, amount * 1e18);
        mintableTokenAmountForPartners -= amount * 1e18;
    }

    /**
        Private sale
     */
    function privateSale(uint amount) public payable {
        require(
            mintableTokenAmountForPrivate > 0,
            "The private sale was finished."
        );
        require(
            amount <= mintableTokenAmountForPrivate,
            "Required amount is over of mintable amount."
        );
        require(msg.value >= tokenPriceForPrivate * amount, "Not Enough Funds");

        _transfer(owner(), msg.sender, amount * 1e18);
        mintableTokenAmountForPrivate -= amount * 1e18;
    }

    /**
        Public sale
     */
    function publicSale(uint amount) public payable {
        require(
            mintableTokenAmountForPublic > 0,
            "The public sale was finished."
        );
        require(
            amount <= mintableTokenAmountForPublic,
            "Required amount is over of mintable amount."
        );
        require(msg.value >= tokenPriceForPublic * amount, "Not Enough Funds");

        _transfer(owner(), msg.sender, amount * 1e18);
        mintableTokenAmountForPublic -= amount * 1e18;
    }

    function withdraw(address ownerWallet) public onlyOwner {
        payable(ownerWallet).transfer(address(this).balance);
    }

    //  fallback to recieve ether in
    receive() external payable {}
}