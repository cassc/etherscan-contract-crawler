pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract Mishka2 is Context, ERC20, Ownable {
    using SafeMath for uint256;

    // ##### Constant Value ######

    uint256 private constant TOTAL_SUPPLY = 1000000000 * 10**18;
    address private constant MISHKA1 =
        0x976091738973b520A514ea206AcDD008A09649De;

    // ##### Tokenomic Private Value ####
    uint256 private m_ClaimRate = 1100; // unit 1 / 10**6 ;
    bool private m_ClaimEnabled = true;
    address private m_ClaimWallet;

    uint256 private m_SellFeePercent = 10; // 10% Sell Fee.
    uint256 private m_BuyFeePercent = 0; // 0% Buy Fee.
    uint256 private m_BuyBonusPercent = 0; // 0% Buy Bonus.
    address payable private m_FeeWallet; // FeeWalletAddress.
    bool private m_IsSwap = false;
    mapping(address => bool) private m_IgnoreFeeList;
    mapping(address => bool) private m_DevWalletList;

    mapping(address => bool) private m_WhiteList;
    mapping(address => bool) private m_BlackList;
    bool private m_PublicTradingOpened = false;

    uint256 private m_TxLimit = 5000000 * 10**18; // 0.5% of total supply
    uint256 private m_MaxWalletSize = 1000000000 * 10**18; // 100% of total supply

    uint256 private m_NumOfTokensForDisperse = 5000 * 10**18; // Exchange to Eth Limit - 5 Mil

    address private m_UniswapV2Pair;
    IUniswapV2Router02 private m_UniswapV2Router;
    bool private m_SwapEnabled = false;

    ///////////////////////////////////////

    receive() external payable {}

    modifier lockTheSwap() {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }

    modifier transferable(
        address _sender,
        address _recipient,
        uint256 _amount
    ) {
        if (!m_WhiteList[_sender] && !m_WhiteList[_recipient]) {
            require(m_PublicTradingOpened, "Not enabled transfer.");
        }

        require(!m_BlackList[_sender], "You are in block list.");
        require(!m_BlackList[_recipient], "You are in block list.");

        if (
            (_sender == m_UniswapV2Pair &&
                !m_DevWalletList[_recipient] &&
                _recipient != address(m_UniswapV2Router)) ||
            (_recipient == m_UniswapV2Pair &&
                !m_DevWalletList[_sender] &&
                _sender != address(m_UniswapV2Router))
        ) require(_amount <= m_TxLimit, "Amount is bigg too.");
        _;
        if (
            !m_DevWalletList[_recipient] &&
            _recipient != m_UniswapV2Pair &&
            _recipient != address(m_UniswapV2Router)
        )
            require(
                ERC20.balanceOf(_recipient) <= m_MaxWalletSize,
                "The balance is big too"
            );
    }

    constructor() ERC20("Mishka Token", "MSK") {
        m_WhiteList[owner()] = true;
        m_WhiteList[address(this)] = true;
        m_DevWalletList[address(this)] = true;
        m_DevWalletList[owner()] = true;
        m_IgnoreFeeList[address(this)] = true;
        m_ClaimWallet = address(this);
        _mint(address(this), TOTAL_SUPPLY);
    }

    // ##### Transfer Feature #####

    function setPublicTradingOpened(bool _enabled) external onlyOwner {
        m_PublicTradingOpened = _enabled;
    }

    function isPublicTradingOpened() external view returns (bool) {
        return m_PublicTradingOpened;
    }

    function setWhiteList(address _address) public onlyOwner {
        m_WhiteList[_address] = true;
    }

    function setWhiteListMultiple(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            setWhiteList(_addresses[i]);
        }
    }

    function removeWhiteList(address _address) external onlyOwner {
        m_WhiteList[_address] = false;
    }

    function isWhiteListed(address _address) external view returns (bool) {
        return m_WhiteList[_address];
    }

    function setBlackList(address _address) public onlyOwner {
        m_BlackList[_address] = true;
    }

    function setBlackListMultiple(address[] memory _addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            setBlackList(_addresses[i]);
        }
    }

    function removeBlackList(address _address) external onlyOwner {
        m_BlackList[_address] = false;
    }

    function isBlackListed(address _address) external view returns (bool) {
        return m_BlackList[_address];
    }

    function setDevWallet(address _address) external onlyOwner {
        m_DevWalletList[_address] = true;
    }

    function removeDevWallet(address _address) external onlyOwner {
        m_DevWalletList[_address] = false;
    }

    function isDevWallet(address _address) external view returns (bool) {
        return m_DevWalletList[_address];
    }

    function setTxLimitToken(uint256 _txLimit) external onlyOwner {
        m_TxLimit = _txLimit.mul(10**18);
    }

    function getTxLimitToken() external view returns (uint256) {
        return m_TxLimit.div(10**18);
    }

    function setMaxWalletSizeToken(uint256 _maxWalletSize) external onlyOwner {
        m_MaxWalletSize = _maxWalletSize.mul(10**18);
    }

    function getMaxWalletSizeToken() external view returns (uint256) {
        return m_MaxWalletSize.div(10**18);
    }

    function transfer(address _recipient, uint256 _amount)
        public
        override
        transferable(_msgSender(), _recipient, _amount)
        returns (bool)
    {
        uint256 realAmount = _feeProcess(_msgSender(), _recipient, _amount);
        _transfer(_msgSender(), _recipient, realAmount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        public
        override
        transferable(_sender, _recipient, _amount)
        returns (bool)
    {
        uint256 realAmount = _feeProcess(_sender, _recipient, _amount);
        _transfer(_sender, _recipient, realAmount);

        _approve(
            _sender,
            _msgSender(),
            allowance(_sender, _msgSender()).sub(
                _amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    // ###### Claim Feature ######

    function setClaimRate(uint256 _rate) external onlyOwner {
        m_ClaimRate = _rate;
    }

    function getClaimRate() external view returns (uint256) {
        return m_ClaimRate;
    }

    function setClaimEnabled(bool _enabled) external onlyOwner {
        m_ClaimEnabled = _enabled;
    }

    function getClaimEnabled() external view returns (bool) {
        return m_ClaimEnabled;
    }

    function setClaimWallet(address _claimWallet) external onlyOwner {
        m_ClaimWallet = _claimWallet;
        m_IgnoreFeeList[_claimWallet] = true;
        m_WhiteList[_claimWallet] = true;
    }

    function getClaimWallet() external view returns (address) {
        return m_ClaimWallet;
    }

    function claimV2() external {
        require(m_ClaimEnabled, "Claim is not enabled");
        IERC20 mishkaV1 = IERC20(MISHKA1);
        uint256 v1Amount = mishkaV1.balanceOf(_msgSender());

        if (v1Amount == 0) return;

        uint256 claimAmount = v1Amount.mul(m_ClaimRate.mul(10**3));
        require(
            claimAmount <= ERC20.balanceOf(m_ClaimWallet),
            "Claim Wallet balance is not enough"
        );

        mishkaV1.transferFrom(_msgSender(), address(this), v1Amount);
        _transfer(m_ClaimWallet, _msgSender(), claimAmount);
    }

    // ###### Liquidity Feature ######

    function addLiquidity() external onlyOwner {
        require(!m_SwapEnabled, "Liquidity pool already created");

        uint256 ethAmount = address(this).balance;
        uint256 v2Amount = balanceOf(address(this));

        require(ethAmount > 0, "Ethereum balance is empty");

        require(v2Amount > 0, "Mishka balance is empty");

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        m_UniswapV2Router = _uniswapV2Router;

        m_WhiteList[address(m_UniswapV2Router)] = true;

        _approve(address(this), address(m_UniswapV2Router), v2Amount);

        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // m_WhiteList[m_UniswapV2Pair] = true;

        m_UniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            v2Amount,
            0,
            0,
            owner(),
            block.timestamp
        );
        m_SwapEnabled = true;
        IERC20(m_UniswapV2Pair).approve(
            address(m_UniswapV2Router),
            type(uint256).max
        );
    }

    // ##### Fee Feature ######

    function setSellFeePercent(uint256 _sellFeePercent) external onlyOwner {
        m_SellFeePercent = _sellFeePercent;
    }

    function getSellFeePercent() external view returns (uint256) {
        return m_SellFeePercent;
    }

    function setBuyFeePercent(uint256 _buyFeePercent) external onlyOwner {
        m_BuyFeePercent = _buyFeePercent;
    }

    function getBuyFeePercent() external view returns (uint256) {
        return m_BuyFeePercent;
    }

    function setBuyBonusPercent(uint256 _buyBonusPercent) external onlyOwner {
        m_BuyBonusPercent = _buyBonusPercent;
    }

    function getBuyBonusPercent() external view returns (uint256) {
        return m_BuyBonusPercent;
    }

    function setFeeWallet(address payable _feeWallet) external onlyOwner {
        m_FeeWallet = _feeWallet;
    }

    function getFeeWallet() external view returns (address payable) {
        return m_FeeWallet;
    }

    function setIgnoreFeeAddress(address _address) external onlyOwner {
        m_IgnoreFeeList[_address] = true;
    }

    function removeIgnoreFeeAddress(address _address) external onlyOwner {
        m_IgnoreFeeList[_address] = false;
    }

    function isIgnoreFeeAddress(address _address) external view returns (bool) {
        return m_IgnoreFeeList[_address];
    }

    function setNumOfTokensForDisperse(uint256 _numOfTokensForDisperse)
        external
        onlyOwner
    {
        m_NumOfTokensForDisperse = _numOfTokensForDisperse.mul(10**18);
    }

    function getNumOfTokensForDisperse() external view returns (uint256) {
        return m_NumOfTokensForDisperse.div(10**18);
    }

    function _isBuy(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return
            _sender == m_UniswapV2Pair &&
            _recipient != address(m_UniswapV2Router) &&
            !m_IgnoreFeeList[_recipient];
    }

    function _isSale(address _sender, address _recipient)
        private
        view
        returns (bool)
    {
        return
            _recipient == m_UniswapV2Pair &&
            _sender != address(m_UniswapV2Router) &&
            !m_IgnoreFeeList[_sender];
    }

    function _swapTokensForETH(uint256 _amount) private lockTheSwap {
        address[] memory _path = new address[](2);
        _path[0] = address(this);
        _path[1] = m_UniswapV2Router.WETH();
        _approve(address(this), address(m_UniswapV2Router), _amount);
        m_UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            _path,
            address(this),
            block.timestamp
        );
    }

    function _readyToSwap() private view returns (bool) {
        return !m_IsSwap && m_SwapEnabled;
    }

    function _payToll() private {
        uint256 _tokenBalance = balanceOf(address(this));

        bool overMinTokenBalanceForDisperseEth = _tokenBalance >=
            m_NumOfTokensForDisperse;
        if (_readyToSwap() && overMinTokenBalanceForDisperseEth) {
            _swapTokensForETH(_tokenBalance);
            if (m_FeeWallet != address(0) && m_FeeWallet != address(this))
                m_FeeWallet.transfer(address(this).balance);
        }
    }

    function _feeProcess(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private returns (uint256) {
        uint256 fee = 0;
        uint256 bonus = 0;
        bool isSale = _isSale(_sender, _recipient);
        bool isBuy = _isBuy(_sender, _recipient);
        if (isSale) fee = m_SellFeePercent;
        else if (isBuy) {
            fee = m_BuyFeePercent;
            bonus = m_BuyBonusPercent;
        }

        uint256 feeAmount = _amount.mul(fee).div(100);
        uint256 bonusAmount = _amount.mul(bonus).div(100);

        if (feeAmount != 0) _transfer(_sender, address(this), feeAmount);
        if (bonusAmount != 0) _transfer(m_ClaimWallet, _recipient, bonusAmount);

        if (isSale) _payToll();
        return _amount.sub(feeAmount);
    }

    // ##### Other Functions ######

    function withdrawV1() external onlyOwner {
        IERC20 mishkaV1 = IERC20(MISHKA1);
        mishkaV1.transfer(owner(), mishkaV1.balanceOf(address(this)));
    }

    function withdraw(uint256 _amount) external onlyOwner {
        _transfer(address(this), owner(), _amount.mul(10**18));
    }

    function transferOwnership(address _newOwner) public override onlyOwner {
        m_WhiteList[owner()] = false;
        m_IgnoreFeeList[owner()] = false;
        m_DevWalletList[owner()] = false;
        Ownable.transferOwnership(_newOwner);
        m_WhiteList[_newOwner] = true;
        m_DevWalletList[_newOwner] = true;
        m_IgnoreFeeList[_newOwner] = true;
    }
}