// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MesToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public ammPairs;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100 * 10**9 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    uint256 public _buyTaxFee = 4;
    uint256 public _buyAdvestisementFee = 3;

    uint256 public _sellTaxFee = 4;
    uint256 public _sellAdvestisementFee = 3;

    uint256 private _taxFee = _buyTaxFee;
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _burnFee = 3;
    uint256 private _previousBurn = _burnFee;
    address public advertisementWallet =
        0x000000000000000000000000000000000000dEaD;

    uint256 public _advestisementFee = _buyAdvestisementFee;
    uint256 private _previousAdvestisementFee = _advestisementFee;

    address public DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) antiBuySoonWhitelist;
    bool antiBuySoon = true;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256(
            "Transfer(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)"
        );

    bytes32 public immutable DOMAIN_SEPARATOR;

    address airdropContract;

    constructor(
        address _router,
        string memory __name,
        string memory __symboy
    ) {
        _rOwned[_msgSender()] = _rTotal;
        _name = __name;
        _symbol = __symboy;
        IUniswapV2Router01 _uniswapV2Router = IUniswapV2Router01(_router);
        // Create a uniswap pair for this new token
        address WETH = _uniswapV2Router.WETH();
        address factory = _uniswapV2Router.factory();
        address _uniswapV2Pair = IUniswapV2Factory(factory).createPair(
            address(this),
            WETH
        );

        ammPairs[_uniswapV2Pair] = true;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        excludeFromReward(DEAD_ADDRESS);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        antiBuySoonWhitelist[address(this)] = true;
        antiBuySoonWhitelist[_uniswapV2Pair] = true;
        antiBuySoonWhitelist[WETH] = true;
        antiBuySoonWhitelist[factory] = true;
        antiBuySoonWhitelist[_router] = true;
        antiBuySoonWhitelist[_msgSender()] = true;
        _approve(address(this), address(_uniswapV2Router), MAX);
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    //to recieve ETH from uniswapV2Router when swapping
    receive() external payable {}

    function turnOffAntiBuySoon() public onlyOwner {
        antiBuySoon = false;
    }

    function setAntiBuySoon(address[] memory wallets, bool status)
        public
        onlyOwner
    {
        for (uint256 index = 0; index < wallets.length; index++)
            antiBuySoonWhitelist[wallets[index]] = status;
    }

    function updateRouter(address _router) public onlyOwner {
        IUniswapV2Router01 _uniswapV2Router = IUniswapV2Router01(_router);
        address WETH = _uniswapV2Router.WETH();
        address factory = _uniswapV2Router.factory();
        address _uniswapV2Pair = IUniswapV2Factory(factory).getPair(
            address(this),
            WETH
        );
        if (_uniswapV2Pair == address(0)) {
            _uniswapV2Pair = IUniswapV2Factory(factory).createPair(
                address(this),
                WETH
            );
        }
        ammPairs[_uniswapV2Pair] = true;
    }

    modifier preventBuySoon(
        address from,
        address to,
        string memory errorMsg
    ) {
        require(
            !antiBuySoon ||
                from == owner() ||
                from == airdropContract ||
                (antiBuySoonWhitelist[from] && antiBuySoonWhitelist[to]),
            errorMsg
        );
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function changeAdvestisementWallets(address wallet) public onlyOwner {
        advertisementWallet = wallet;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
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
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 allowed = _allowances[sender][_msgSender()];
        if (allowed != type(uint256).max) {
            _approve(
                sender,
                _msgSender(),
                _allowances[sender][_msgSender()].sub(
                    amount,
                    "ERC20: transfer amount exceeds allowance"
                )
            );
        }

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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tAdvertisement,
            uint256 tBurn
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeAdvertisement(tAdvertisement);
        _reflectFee(rFee, tFee);
        _takeBurn(tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function setDeadAddress(address _DEAD_ADDRESS) public onlyOwner {
        DEAD_ADDRESS = _DEAD_ADDRESS;
    }

    function manageAmmPairs(address pair, bool isAdd) public onlyOwner {
        ammPairs[pair] = isAdd;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tAdvertisement,
            uint256 tBurn
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tAdvertisement,
            tBurn,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tAdvertisement,
            tBurn
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tAdvertisement = calculateAdvestisementFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);

        uint256 tTransferAmount = tAmount.sub(tFee).sub(tAdvertisement).sub(
            tBurn
        );

        return (tTransferAmount, tFee, tAdvertisement, tBurn);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tAdvertisement,
        uint256 tBurn,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rAdvertisement = tAdvertisement.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rAdvertisement).sub(
            rBurn
        );
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeAdvertisement(uint256 tAdvertisement) private {
        uint256 currentRate = _getRate();
        uint256 rAdvertisement = tAdvertisement.mul(currentRate);
        _rOwned[advertisementWallet] = _rOwned[advertisementWallet].add(
            rAdvertisement
        );
        if (_isExcluded[advertisementWallet])
            _tOwned[advertisementWallet] = _tOwned[advertisementWallet].add(
                tAdvertisement
            );
    }

    function _takeBurn(uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[DEAD_ADDRESS] = _rOwned[DEAD_ADDRESS].add(rBurn);
        if (_isExcluded[DEAD_ADDRESS])
            _tOwned[DEAD_ADDRESS] = _tOwned[DEAD_ADDRESS].add(tBurn);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateAdvestisementFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_advestisementFee).div(10**2);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(10**2);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _advestisementFee == 0 && _burnFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousAdvestisementFee = _advestisementFee;
        _previousBurn = _burnFee;
        _taxFee = 0;
        _advestisementFee = 0;
        _burnFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _advestisementFee = _previousAdvestisementFee;
        _burnFee = _previousBurn;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
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

    function setAirdropContract(address _airdropContract) public onlyOwner {
        airdropContract = _airdropContract;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
        private
        preventBuySoon(from, to, "ERC20: Not allow from address buy soon")
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, advertisement fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {
            removeAllFee();
        } else {
            bool isBuy = ammPairs[sender];
            bool isSell = ammPairs[recipient];
            if (isBuy) {
                _taxFee = _buyTaxFee;
                _advestisementFee = _buyAdvestisementFee;
            } else if (isSell) {
                _taxFee = _sellTaxFee;
                _advestisementFee = _sellAdvestisementFee;
            }
            takeFee = isBuy || isSell;

            if (!takeFee) {
                removeAllFee();
            }
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tAdvertisement,
            uint256 tBurn
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeAdvertisement(tAdvertisement);
        _reflectFee(rFee, tFee);
        _takeBurn(tBurn);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tAdvertisement,
            uint256 tBurn
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeAdvertisement(tAdvertisement);
        _takeBurn(tBurn);

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tAdvertisement,
            uint256 tBurn
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeAdvertisement(tAdvertisement);
        _reflectFee(rFee, tFee);
        _takeBurn(tBurn);

        emit Transfer(sender, recipient, tTransferAmount);
    }
}