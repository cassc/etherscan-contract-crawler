// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Hibby is Context, IERC20, AccessControlEnumerable {
    using SafeMath for uint256;
    using Address for address;

    //address with the GAME_ROLE can burn the token
    bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");

    mapping(address => bool) public isBlackListed; //Boolean value for the blacklisted address
    address[] internal _blackList; //Storage for the blacklisted address
    mapping(address => uint256) internal _rOwned;
    mapping(address => uint256) internal _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcluded; // Boolean value for the Excluded account
    address[] private _excluded; //Storage for the excluded account

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 90 * 10**6 * 10**18; // total supply of the token
    uint256 internal _totalSupply = _tTotal;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal; // All the amount that are reflected

    // All the fees that are going to be deducted
    struct Fee {
        uint88 reflectionFee;
        uint88 teamWalletFee;
        uint88 developmentFee;
        uint88 marketingFee;
    }

    Fee public fees;

    struct FeeCollected {
        uint256 teamCollection;
        uint256 developmentCollection;
        uint256 marketingCollection;
    }

    FeeCollected public collected;

    // All the wallets address
    struct Wallet {
        address teamWallet;
        address developmentWallet;
        address marketingWallet;
    }

    Wallet public wallets;

    string private _name = "Hibby Token";
    string private _symbol = "HIBBY";
    uint8 private _decimals = 18;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public owner;
    address public pairToken;

    bool inSwap;
    bool public isSwapTaxesActive;

    event BlackListSet(address addr, bool value);
    event BulkBlackList(address[] addr, bool[] value);

    constructor(
        address _teamWallet,
        address _developmentWallet,
        address _marketingWallet,
        address _routerAddress,
        address _pariToken,
        address _owner
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        owner = _owner;
        _setupRole(GAME_ROLE, _owner);
        _totalSupply = _tTotal;

        _rOwned[_owner] = _rTotal;
        _tOwned[_owner] = _tTotal;

        _isExcluded[wallets.teamWallet] = true;
        _isExcluded[wallets.developmentWallet] = true;
        _isExcluded[wallets.marketingWallet] = true;
        _isExcluded[address(this)] = true;
        _isExcluded[owner] = true;

        _excluded.push(wallets.teamWallet);
        _excluded.push(wallets.developmentWallet);
        _excluded.push(wallets.marketingWallet);
        _excluded.push(address(this));
        _excluded.push(owner);

        fees.reflectionFee = 2; //Reflection fee 2%
        fees.teamWalletFee = 3; //Team wallet fees 3%
        fees.developmentFee = 1; //Development fees 1%
        fees.marketingFee = 4; //Marketing fees 4%

        wallets.teamWallet = _teamWallet; //Team Wallet
        wallets.developmentWallet = _developmentWallet; //Development Wallet
        wallets.marketingWallet = _marketingWallet; //Marketing wallet

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _routerAddress
        );

        pairToken = _pariToken;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), pairToken);

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), MAX);

        isSwapTaxesActive = true;

        emit Transfer(address(0), owner, _tTotal);
    }

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // Function to blacklist the singel address
    function blackList(address addr, bool value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        isBlackListed[addr] = value;
        _blackList.push(addr);
        emit BlackListSet(addr, value);
        return true;
    }

    // function to blacklist multiple address
    function bulkBlackList(address[] calldata addr, bool[] calldata value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        require(addr.length == value.length, "Array length mismatch");
        uint256 len = addr.length;

        for (uint256 i = 0; i < len; i++) {
            isBlackListed[addr[i]] = value[i];
            _blackList.push(addr[i]);
        }

        emit BulkBlackList(addr, value);
        return true;
    }

    // Get all the blacklisted address
    function getBlackList() public view returns (address[] memory) {
        return _blackList;
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
        return _totalSupply;
    }

    // Get the total Value that is deducted from the transfer
    function getTotalDeductionFee() external view returns (uint256) {
        return (fees.reflectionFee +
            fees.teamWalletFee +
            fees.developmentFee +
            fees.marketingFee);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function burn(uint256 amount) public onlyRole(GAME_ROLE) {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        onlyRole(GAME_ROLE)
    {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
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

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    // Function to reflect your token to other Users
    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , ) = _getValues(tAmount, false);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    //Check the value that you will get if you transfer tAmount of token
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        (, uint256 rTransferAmount, , , ) = _getValues(
            tAmount,
            deductTransferFee
        );
        return rTransferAmount;
    }

    // Check what will be the tValue for the rValue
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

    // Function to exclude the account
    function excludeAccount(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    // Function to add the excluded account
    function includeAccount(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_isExcluded[account], "Account is already included");
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

    function swapTaxes() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _swapTaxes();
    }

    function takeTaxesInToken() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 collectedTaxes = collected.teamCollection +
            collected.developmentCollection +
            collected.marketingCollection;
        _takeTaxesInToken(collectedTaxes);
    }

    function getTaxes()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            collected.teamCollection,
            collected.developmentCollection,
            collected.marketingCollection
        );
    }

    // Function to change the fees
    function setFees(
        uint8 _reflectionFee,
        uint8 _teamWalletFee,
        uint8 _developmentFee,
        uint8 _marketingFee
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        fees.reflectionFee = _reflectionFee;
        fees.teamWalletFee = _teamWalletFee;
        fees.developmentFee = _developmentFee;
        fees.marketingFee = _marketingFee;
    }

    // Function to change the wallet address
    function setWallets(
        address _teamWallet,
        address _developmentWallet,
        address _marketingWallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        wallets.teamWallet = _teamWallet;
        wallets.developmentWallet = _developmentWallet;
        wallets.marketingWallet = _marketingWallet;
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlackListed[recipient], "Recipient is blacklisted");
        require(!isBlackListed[sender], "Sender is blacklisted");

        uint256 collectedTaxes = collected.teamCollection +
            collected.developmentCollection +
            collected.marketingCollection;

        if (collectedTaxes > 0) {
            if (isSwapTaxesActive) {
                if (sender != uniswapV2Pair) {
                    if (!inSwap) {
                        _swapTaxes();
                    }
                }
            } else {
                _takeTaxesInToken(collectedTaxes);
            }
        }

        bool _takeFee = false;

        if (
            (sender == uniswapV2Pair || recipient == uniswapV2Pair) &&
            (sender != owner) &&
            (recipient != owner) &&
            (!inSwap)
        ) {
            collected.teamCollection += (amount * fees.teamWalletFee) / 100;
            collected.developmentCollection +=
                (amount * fees.developmentFee) /
                100;
            collected.marketingCollection += (amount * fees.marketingFee) / 100;
            _takeFee = true;
            uint256 tax = ((amount *
                (fees.teamWalletFee +
                    fees.developmentFee +
                    fees.marketingFee)) / 100);
            _takeTaxes(tax);
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, _takeFee);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, _takeFee);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount, _takeFee);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, _takeFee);
        } else {
            _transferStandard(sender, recipient, amount, _takeFee);
        }
    }

    function _takeTaxesInToken(uint256 collectedTaxes) internal {
        if (_isExcluded[wallets.teamWallet]) {
            _tOwned[wallets.teamWallet] += collected.teamCollection;
        }
        _rOwned[wallets.teamWallet] += collected.teamCollection * _getRate();

        if (_isExcluded[wallets.developmentWallet]) {
            _tOwned[wallets.developmentWallet] += collected
                .developmentCollection;
        }
        _rOwned[wallets.developmentWallet] +=
            collected.developmentCollection *
            _getRate();

        if (_isExcluded[wallets.marketingWallet]) {
            _tOwned[wallets.marketingWallet] += collected.marketingCollection;
        }
        _rOwned[wallets.marketingWallet] +=
            collected.marketingCollection *
            _getRate();

        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] -= collectedTaxes;
        }
        _rOwned[address(this)] -= collectedTaxes * _getRate();

        collected.teamCollection = 0;
        collected.developmentCollection = 0;
        collected.marketingCollection = 0;
    }

    function _swapTaxes() internal {
        swapTokensForToken(collected.teamCollection, wallets.teamWallet);

        swapTokensForToken(
            collected.developmentCollection,
            wallets.developmentWallet
        );

        swapTokensForToken(
            collected.marketingCollection,
            wallets.marketingWallet
        );

        collected.teamCollection = 0;
        collected.developmentCollection = 0;
        collected.marketingCollection = 0;
    }

    function _takeTaxes(uint256 _tax) private {
        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] += _tax;
        }
        _rOwned[address(this)] += _tax * _getRate();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        bool _takeFee
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount, _takeFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool _takeFee
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount, _takeFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool _takeFee
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount, _takeFee);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool _takeFee
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount, _takeFee);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // Function that reflect the amount
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        uint256 rRefectAmount = (rFee.mul(fees.reflectionFee)).div(10);
        uint256 tRefectAmount = (tFee.mul(fees.reflectionFee)).div(10);
        _rTotal = _rTotal.sub(rRefectAmount);
        _tFeeTotal = _tFeeTotal.add(tRefectAmount);
    }

    // Function to calculte the reflection mechaninsm
    function _getValues(uint256 tAmount, bool _takeFee)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(
            tAmount,
            _takeFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            currentRate
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount, bool _takeFee)
        private
        view
        returns (uint256, uint256)
    {
        if (_takeFee) {
            uint256 tFee = (
                tAmount.mul(
                    fees.reflectionFee +
                        fees.teamWalletFee +
                        fees.developmentFee +
                        fees.marketingFee
                )
            ).div(100);
            uint256 tTransferAmount = tAmount.sub(tFee);
            return (tTransferAmount, tFee);
        } else {
            uint256 tFee = 0;
            uint256 tTransferAmount = tAmount;
            return (tTransferAmount, tFee);
        }
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
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
        uint256 rTransferAmount = rAmount.sub(rFee);
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

    function _burn(address account, uint256 tAmount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        (uint256 rAmount, , uint256 rFee, , uint256 tFee) = _getValues(
            tAmount,
            false
        );
        uint256 accountBalance = balanceOf(account);
        require(
            accountBalance >= tAmount,
            "ERC20: burn amount exceeds balance"
        );

        if (_isExcluded[account]) {
            _tOwned[account] = _tOwned[account].sub(tAmount);
        }
        _rOwned[account] = _rOwned[account].sub(rAmount);
        _totalSupply = _totalSupply.sub(tAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(account, address(0), tAmount);
    }

    function _spendAllowance(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }

    function swapTokensForToken(uint256 tokenAmount, address _account)
        public
        lockTheSwap
    {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pairToken;

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _account,
            block.timestamp
        );
    }

    function updateRouter(address newAddress, address _pairToken)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), _pairToken);
        uniswapV2Pair = _uniswapV2Pair;
        pairToken = _pairToken;
    }

    // Function to change the owner
    function changeOwner(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        owner = _address;
    }

    function setIsSwapTaxesActive(bool value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isSwapTaxesActive = value;
    }
}