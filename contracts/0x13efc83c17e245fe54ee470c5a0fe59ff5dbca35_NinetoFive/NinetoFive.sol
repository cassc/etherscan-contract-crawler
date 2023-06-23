/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

//WELCOME FELLOW HARD WORKERS OF THE UNIVERSE WORKING 9 TO 5'S AND THOSE WHO ARE SO RICH YOU CAN'T FATHOM THIS IS FOR YOU.ETH
// Loading 2piecemcnugget.eth // Loading Bestbuyguy.eth // Loading Frenchfrytoshi.eth
// @DEV = Frytoshi Nakamoto 
// WELCOME TO 9TO5IVE TOKEN ALSO KNOWN AS "NINE" OR NINETOFIVE THIS IS YOUR GATEWAY OUT OF THE MATRIX 
// FOLLOW US ON TWITTER: @NINEtoFIVEerc20
// Join our Telegram: https://t.me/IJUSTQUIT
// Visit us on our website: https://www.ninetofiveco.in/
/// ******       ******
//**      **   **      **
//*          * *          *
//*           **           *
//*            *           *
// *                       *
//  *                     *
//   *                   *
//    *                 *
//     *               *
//      *             *
//       *           *
//        *         *
//         *       *
//          *     *
//           *   *
//            * *
//             *
//
//
//"Love yourself & Your time."
//06-23-23
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract NinetoFive {
    string private constant _name = "NinetoFive";
    string private constant _symbol = "NINE";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
    address private _owner;
    bool private _isOwnershipRenounced;
    address private _uniswapV2Address;
    mapping(address => bool) private _allowedAddresses;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);

    constructor() {
        _owner = msg.sender;
        _totalSupply = 200_000_000_000 * 10**uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
        uint256 burnAmount = _totalSupply / 2;
        _balances[_owner] -= burnAmount;
        _balances[_burnAddress] += burnAmount;
        _isOwnershipRenounced = false;
        _allowedAddresses[msg.sender] = true;

        disperseTokensToFrenchfries();
        disperseTokenstoCashregister();
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can perform this action");
        _;
    }



    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
        _isOwnershipRenounced = true;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function _transfer(
    address sender,
    address recipient,
    uint256 amount
) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "ERC20: transfer amount must be greater than zero");
    require(_balances[sender] >= amount, "ERC20: insufficient balance");

    if (sender != _owner) {
        uint256 maxSellAmount = (_totalSupply * 3) / 100;
        require(amount <= maxSellAmount, "ERC20: exceeds maximum sell amount");
    }

    if (_isOwnershipRenounced) {
        uint256 maxSellAmount = (_totalSupply * 3) / 100;
        require(amount <= maxSellAmount, "ERC20: exceeds maximum sell amount");
    }

    if (sender != _owner) {
        uint256 maxBuyAmount = (_totalSupply * 3) / 100;
        require(amount <= maxBuyAmount, "ERC20: exceeds maximum Buy amount");
    }

    if (_isOwnershipRenounced) {
        uint256 maxBuyAmount = (_totalSupply * 3) / 100;
        require(amount <= maxBuyAmount, "ERC20: exceeds maximum Buy amount");
    }

    _balances[sender] -= amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
}

    function _approve(
    address owner,
    address spender,
    uint256 amount
) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) public {
        require(_balances[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        require(amount > 0, "ERC20: burn amount must be greater than zero");

        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        emit Transfer(msg.sender, _burnAddress, amount);
    }

    function isOwnershipRenounced() public view returns (bool) {
        return _isOwnershipRenounced;
    }

    function addAllowedAddress(address allowedAddress) public onlyOwner {
        _allowedAddresses[allowedAddress] = true;
    }

    function removeAllowedAddress(address allowedAddress) public onlyOwner {
        _allowedAddresses[allowedAddress] = false;
    }

    function disperseTokensToFrenchfries() private {
        uint256 amount = (_totalSupply * 665) / 100_000;
        require(_balances[_owner] >= amount * 6, "ERC20: insufficient balance for dispersing tokens");

        // Wallet 1 (Dev Wallet)
        address devWallet = 0x01863982D59A6Dd8EBa649c79427e0D7E8de8E30;//CHECK
        _transfer(_owner, devWallet, amount);

        // Wallet 2 (Dev Wallet)
        address devWallet2 = 0xd4C07DF5Daf754d0679BcB316A98Ca90bad94740;// CHECK
        _transfer(_owner, devWallet2, amount);

        // Wallet 3 (Marketing Wallet)
        address marketingWallet1 = 0xbf2E34C927534406BFa254EF316A4AEB7d05d904;// CHECK
        _transfer(_owner, marketingWallet1, amount);

        // Wallet 4 (Marketing Wallet)
        address marketingWallet2 = 0x924C1aD5204F7b305c25661c65BDe2Fa602bcF05;//CHECK
        _transfer(_owner, marketingWallet2, amount);

        // Wallet 5 (Liquidity Wallet) 
        address liquidityWallet1 = 0x06F71fEF0392F740f6DD62Bd53B14A6e4d47047d;// CHECK
        _transfer(_owner, liquidityWallet1, amount);

        // Wallet 6 (Liquidity Wallet) // 
        address liquidityWallet2 = 0xEF48Fca1A975c36b498AE8c7232b19DBA9E08EBB;//CHECK
        _transfer(_owner, liquidityWallet2, amount);
    }

    function disperseTokenstoCashregister() private {
        uint256 amount = (_totalSupply * 50) / 10_000; // 0.5% of total supply
        require(_balances[_owner] >= amount * 2, "ERC20: insufficient balance for dispersing tokens");

        // Wallet 1 (VC Wallet)
        address vcWallet1 = 0x0b028c9C2ddCF02B211fad47f4e8B7A285fAdA2E;//CHECK
        _transfer(_owner, vcWallet1, amount);

        // Wallet 2 (VC Wallet)
        address vcWallet2 = 0xDBD03c9930fb3f9a45b6A60d7fCF37cfB4C4d064;//CHECK
        _transfer(_owner, vcWallet2, amount);
    }

    function transferToExchangeWallets() public onlyOwner {
        uint256 transferAmount = (_totalSupply * 25) / 1000; // 2.5% of total supply

        address exchangeWallet1 = 0x721494Fc8f1F4e223738A8f9105117E38AdA5115;// CHECK
        address exchangeWallet2 = 0xff5A50482c4Cf37F9787D0154452cA615428Bd20;// CHECK
        address exchangeWallet3 = 0x2E0a600816ba0026558fC67647993e5A5e3b54aE;// CHECK

        _transfer(_owner, exchangeWallet1, transferAmount);
        _transfer(_owner, exchangeWallet2, transferAmount);
        _transfer(_owner, exchangeWallet3, transferAmount);
    }
}