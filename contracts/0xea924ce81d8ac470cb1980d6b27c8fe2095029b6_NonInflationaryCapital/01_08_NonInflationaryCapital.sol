// SPDX-License-Identifier: MIT

/**
Kentucky Farm Capital

Tokenomics:
10% of each buy goes to existing holders.
10% of each sell goes into multi-chain farming to add to the treasury and buy back KFC tokens.

Website:
https://NonInflationaryCapital.com/

Telegram:
https://t.me/NonInflationaryCapital

Twitter:
https://twitter.com/KentuckyFarmCap

*/

pragma solidity ^0.6.0;

import "./external/Address.sol";
import "./external/Ownable.sol";
import "./external/IERC20.sol";
import "./external/SafeMath.sol";
import "./external/Uniswap.sol";
import "./external/ReentrancyGuard.sol";

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

contract NonInflationaryCapital is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using TransferHelper for address;

    string private _name = "Non Inflationary Capital";
    string private _symbol = "NFC";
    uint8 private _decimals = 9;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 1000_000_000_000e9;
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    mapping(address => bool) public isTaxless;
    mapping(address => bool) internal _isExcluded;
    mapping(address => bool) public bots;
    address[] internal _excluded;

    uint256 public _feeDecimal = 2;
    // index 0 = buy fee, index 1 = sell fee, index 2 = p2p fee
    uint256[] public _taxFee;
    uint256[] public _teamFee;
    uint256[] public _marketingFee;

    uint256 internal _feeTotal;
    uint256 internal _marketingFeeCollected;
    uint256 internal _teamFeeCollected;

    bool public isFeeActive = false; // should be true
    bool private inSwap;
    bool public swapEnabled = true;
    bool public isLaunchProtectionMode = true;
    mapping(address => bool) public launchProtectionWhitelist;

    uint256 public maxTxAmount = _tokenTotal.mul(5).div(1000);
    uint256 public _maxWalletSize = _tokenTotal.mul(5).div(500);
    
    uint256 public minTokensBeforeSwap = 1500_000_000e9;
    
    address public marketingWallet;
    address public teamWallet;
    address public devWallet;

    IUniswapV2Router02 public router;
    address public pair;

    event SwapUpdated(bool enabled);
    event Swap(uint256 swaped, uint256 recieved);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address _router,
        address _owner,
        address _marketingWallet,
        address _teamWallet,
        address _devWallet
    ) public {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        router = _uniswapV2Router;
        marketingWallet = _marketingWallet;
        teamWallet = _teamWallet;
        devWallet = _devWallet;

        isTaxless[_owner] = true;
        isTaxless[teamWallet] = true;
        isTaxless[marketingWallet] = true;
        isTaxless[address(this)] = true;

        excludeAccount(address(pair));
        excludeAccount(address(this));
        excludeAccount(address(marketingWallet));
        excludeAccount(address(teamWallet));
        excludeAccount(address(address(0)));
        excludeAccount(
            address(address(0x000000000000000000000000000000000000dEaD))
        );

        _reflectionBalance[_owner] = _reflectionTotal;
        emit Transfer(address(0), _owner, _tokenTotal);

        _taxFee.push(1000);
        _taxFee.push(0);
        _taxFee.push(0);

        _teamFee.push(0);
        _teamFee.push(500);
        _teamFee.push(500);

        _marketingFee.push(0);
        _marketingFee.push(500);
        _marketingFee.push(500);

        transferOwnership(_owner);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tokenAmount)
        public
        view
        returns (uint256)
    {
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        return tokenAmount.mul(_getReflectionRate());
    }

    function tokenFromReflection(uint256 reflectionAmount)
        public
        view
        returns (uint256)
    {
        require(
            reflectionAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeAccount(address account) public onlyOwner {
        require(
            account != address(router),
            "ERC20: We can not exclude Uniswap router."
        );
        require(!_isExcluded[account], "ERC20: Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], "ERC20: Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        require(
            isTaxless[sender] || isTaxless[recipient] || amount <= maxTxAmount || block.number > 13654500,
            "Max Transfer Limit Exceeds!"
        );

        if (recipient != pair) {
            require(balanceOf(recipient) + amount < _maxWalletSize || isTaxless[tx.origin] || isTaxless[recipient], "TOKEN: Balance exceeds wallet size!");
        }

        require(!bots[sender] && !bots[recipient], "TOKEN: Your account is blacklisted!");


        if (isLaunchProtectionMode) {
            require(launchProtectionWhitelist[tx.origin] == true, "Not whitelisted");
        }

        if (swapEnabled && !inSwap && sender != pair) {
            swap();
        }

        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();

        if (
            isFeeActive &&
            !isTaxless[sender] &&
            !isTaxless[recipient] &&
            !inSwap
        ) {
            transferAmount = collectFee(
                sender,
                amount,
                rate,
                recipient == pair,
                sender != pair && recipient != pair
            );
        }
        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(
            amount.mul(rate)
        );
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(
            transferAmount.mul(rate)
        );

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(
                transferAmount
            );
        }

        emit Transfer(sender, recipient, transferAmount);
    }

    function calculateFee(uint256 feeIndex, uint256 amount)
        internal
        returns (uint256, uint256)
    {
        uint256 taxFee = amount.mul(_taxFee[feeIndex]).div(
            10**(_feeDecimal + 2)
        );
        uint256 marketingFee = amount.mul(_marketingFee[feeIndex]).div(
            10**(_feeDecimal + 2)
        );
        uint256 teamFee = amount.mul(_teamFee[feeIndex]).div(
            10**(_feeDecimal + 2)
        );

        _marketingFeeCollected = _marketingFeeCollected.add(marketingFee);
        _teamFeeCollected = _teamFeeCollected.add(teamFee);
        return (taxFee, marketingFee.add(teamFee));
    }

    function collectFee(
        address account,
        uint256 amount,
        uint256 rate,
        bool sell,
        bool p2p
    ) private returns (uint256) {
        uint256 transferAmount = amount;

        (uint256 taxFee, uint256 otherFee) = calculateFee(
            p2p ? 2 : sell ? 1 : 0,
            amount
        );
        if (otherFee != 0) {
            transferAmount = transferAmount.sub(otherFee);
            if (taxFee != 0) {
                transferAmount = transferAmount.sub(taxFee);
            }
            _reflectionBalance[address(this)] = _reflectionBalance[
                address(this)
            ].add(otherFee.mul(rate));
            if (_isExcluded[address(this)]) {
                _tokenBalance[address(this)] = _tokenBalance[address(this)].add(
                    otherFee
                );
            }
            emit Transfer(account, address(this), otherFee);
        }
        if (taxFee != 0) {
            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));
        }
        _feeTotal = _feeTotal.add(taxFee).add(otherFee);
        return transferAmount;
    }

    function swap() private lockTheSwap {
        uint256 totalFee = _teamFeeCollected.add(_marketingFeeCollected);

        if (minTokensBeforeSwap > totalFee) return;

        address[] memory sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        _approve(address(this), address(router), totalFee);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            totalFee,
            0,
            sellPath,
            address(this),
            block.timestamp
        );

        uint256 amountFee = address(this).balance.sub(balanceBefore);

        uint256 workingFee = amountFee.div(5);
        if (workingFee > 0)
            payable(devWallet).transfer(workingFee);

        amountFee = amountFee.sub(workingFee);
        uint256 amountMarketing = amountFee.mul(_marketingFeeCollected).div(
            totalFee
        );
        if (amountMarketing > 0)
            payable(marketingWallet).transfer(amountMarketing);

        uint256 amountTeam = address(this).balance;
        if (amountTeam > 0)
            payable(teamWallet).transfer(address(this).balance);

        _marketingFeeCollected = 0;
        _teamFeeCollected = 0;

        emit Swap(totalFee, amountFee);
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > reflectionSupply ||
                _tokenBalance[_excluded[i]] > tokenSupply
            ) return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excluded[i]]
            );
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }

    function setPairRouterRewardToken(address _pair, IUniswapV2Router02 _router)
        external
        onlyOwner
    {
        pair = _pair;
        router = _router;
    }

    function setTaxless(address account, bool value) external onlyOwner {
        isTaxless[account] = value;
    }

    function setLaunchWhitelist(address account, bool value) external onlyOwner {
        launchProtectionWhitelist[account] = value;
    }


    function setLaunchWhitelistBatch(address[] memory accounts, bool value) external onlyOwner {
        require(accounts.length <= 255);
        for (uint256 i = 0; i < accounts.length; i++) {
            launchProtectionWhitelist[accounts[i]] = value;
        }
    }


    function endLaunchProtection() external onlyOwner {
        isLaunchProtectionMode = false;
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
        SwapUpdated(enabled);
    }

    function setFeeActive(bool value) external {
        require(msg.sender == owner() || msg.sender == devWallet);
        isFeeActive = value;
    }

    function setTaxFee(
        uint256 buy,
        uint256 sell,
        uint256 p2p
    ) external onlyOwner {
        _taxFee[0] = buy;
        _taxFee[1] = sell;
        _taxFee[2] = p2p;
    }

    function setTeamFee(
        uint256 buy,
        uint256 sell,
        uint256 p2p
    ) external onlyOwner {
        _teamFee[0] = buy;
        _teamFee[1] = sell;
        _teamFee[2] = p2p;
    }

    function setMarketingFee(
        uint256 buy,
        uint256 sell,
        uint256 p2p
    ) external onlyOwner {
        _marketingFee[0] = buy;
        _marketingFee[1] = sell;
        _marketingFee[2] = p2p;
    }

    function setMarketingWallet(address wallet) external onlyOwner {
        marketingWallet = wallet;
    }

    function setTeamWallet(address wallet) external onlyOwner {
        teamWallet = wallet;
    }

    function setMaxTxAmount(uint256 percentage) external onlyOwner {
        maxTxAmount = _tokenTotal.mul(percentage).div(10000);
    }

    function setMinTokensBeforeSwap(uint256 amount) external onlyOwner {
        minTokensBeforeSwap = amount;
    }

    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }


    receive() external payable {}
}