/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT

/**
@title iSpy Token
@author [email protected]
@contents ERC-20 standard with modifications made to introduce new token standard

@Foreward 
Bobs work in the space is nothing short of exceptional, so when he decided to take the 
plunge into this with $INEDIBLE we couldn't help but throw our hat into the ring with some flavor. 
Some issues we set out to solve:

1. MEV is an issue in Crypto today. Blocking them is an option however that cuts valuable volume. 
Charging a nominal tax that can be used for few purposes works a little more win-win.
Picture a situation where a sandwich trader pays a fee for protocol development or that can be 
utilized to redistribute to the holders. 

2. Long term tokenomic sustainability. Majority of the ERC-20 standards today are fixed supply. 
There is little innovation taking place in exploring the depths of the ERC-20 standard. 
Project Teams and Holders therefore are subject to tokens that are unable to sustain themselves. 
Some charge a tax for development and marketing however that is visibly a short term effort. 
Buybacks and Burns do little other than provide temporary relief as the rise in price is likely
going to be sold into eventually by other holders. Burning by itself is rudimentary if sent to 
the dead wallet because it does nothing to impact the marketcap or total supply. 

3. Holders are disincentivized to remain invested. The above factors in addition to new concepts
launching on a daily basis make it difficult for the holder to remain invested for more than few days 
or even few hours let alone weeks. There is little happening from a protocol perspective to keep
holders engaged and or interested other than the hope of monetary gain. 

With these in mind, we developed iSpy. 

An ERC-20 token with hyper-deflationary characteristics that burns 0.5% on each transaction. 
This burn gets wiped off the total supply providing a cushion and floor riser effect for the Token MC.
An additional 0.5% is charged on each transaction, bringing the total to 1% Tax. This 0.5% is sent
directly to a Rewards contract where holders can claim their share proportionate to their holdings. 

Thereby causing increased hyper-deflation by not restricting MEVs as long as their simulation returns a profit,
further hyper-deflation on any other transaction inclusive of buys, sells, transfers, reward claims, etc.
Holders are incentivized to remain engaged as they continually claim rewards.
Price padding for holders is achieved via the total supply reduction on the burns, and rewards claimed from the fees.

What about the Project Teams? Uniswap V2 does not allow for claiming fees on locked tokens. V3 by itself is restrictive
and does not support rebase-fee tokens. Therefore the need for a custom liquidity locker where the Project Team can
retrieve 1% of the fees every 24 hours as an incentive to continue project development. 

Thereby achieving the perfect trifecta straight from the MasterChef kitchen!

@suggestions
We request Project Teams to feel free to use these contracts, improvize on this and help improve the space because hyper-deflation is 
the fastest and quickest way to survive. Incentivizing your holders is easier when you give them a method to 
grow their holdings passively to tide over falling charts. We bet a majority of the underwater meme token holders 
would have benefited from similar tokenomics to help sustain their projects and ideas for longer. 
A bit more flair in your contracts will save you from a world of FUD.

We also request holders and influencers to spread the word on the strategy employed here so that many more can 
benefit from some of these initiatives. If we want this space to evolve beyond a laugh then we have to improve 
on the tech and bring out the best of available standards. 

@about
iSPY is an experimental project. The Team has reserved no allocation and will add 99% of the tokens to LP.
1% of the Tokens will be moved to the Rewards Contract for holders to immediately begin earning at the start. 
Claims are set to once every 60 minutes.

The custom liquidity locker will contain the LP tokens locked for a period of 6 months. 
1% fees are redeemable by us every 24 hours. 

As such this is a demonstration of what can be done in this space without promise of any monetary gains. 
Please trade the token with the same risks associated with any other token on chain within your appetite.

If some widespread adoption is visible, we will see if a partnership with Inedible is possible on setting up 
something along the lines of an Anti-MEV DEX that auto-locks liquidity etc protecting the users in the way we 
have done for iSPY. Another option would be to enable automated solidity contract reviews and audits etc. 

@Caveat
Etherchef.org is not responsible for the trading dynamics of this token nor is in charge of its development.
This remains a method to educate and spread awareness in addition to allowing for transformation. 

@footnotes hyper-deflation with reduced supply and claimable tax redirected to holders

@Contact If you have an exciting idea in DeFi and want to chat, reach [email protected] 

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+++++++++++++++++++++++++++++++++++*****##############################++++++++++++++++++++
++++++++++++++++++++++++++++++**#####################################+++++++++++++++++++++
++++++++++++++++++++++++++**####*****+++++++++++++++####++++++++++###+++++++++++++++++++++
+++++++++++++++++++++++**###**+++++++++++++++++++++*####+++++++++*##++++++++++++++++++++++
+++++++++++++++++++++*###*+++++++++++++++++++++++++####+++++++++++++++++++++++++++++++++++
+++++++++++++++++++*###*++++++++++++++++++++++++++####*+++++++++++++++++++++++++++++++++++
+++++++++++++++++*###*+++++++++++++++++++++++++++*####++++++++++++++++++++++++++++++++++++
++++++++++++++++*###*+++++++++++++++++++++++++++*####*########*+++++++++++++++++++++++++++
+++++++++++++++####*++++++++++++++++++++++++++*####*+++#######*+++++++++++++++++++++++++++
++++++++++++++*####+++++++++++++++++++++++++*####*++++++#*****++++++++++++++++++++++++++++
++++++++++++++####++++++++++**************####**++++++++*#*+++++++++++++++++++++++++++++++
++++++++++++++####+++++++++*##############*+++++++++++++*##*++++++++++++++++++++++++++++++
++++++++++++++####++++++++*********#########**++++++++++*###++++++++++++++++++++++++++++++
++++++++++++++####*++++++++++++++++++++**#######*+++++++###*++++++++++++++**++++++++++++++
==============*####+=====================++**######*+++###*==============+*##=============
===============*###*+========================++*#########+===============*##*=============
================+*##*+===========================+*#######*+===========+###+==============
==================+*##**+======================+*###**#######**+++++**##*+================
=====================+*###***+++++++++++++***###**+====++*###########*+===================
=========================++*****######*****+++==============+***##*+======================
==========================================================================================
==========================================================================================


*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    }

pragma solidity ^0.8.0;

contract iSPY is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    address private _feeRecipient;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_, uint256 totalSupply_, address feeRecipient_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
         _feeRecipient = feeRecipient_;
        _balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_); // Optional
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
    if (account == address(0)) {
        return 0;
    }
    return _balances[account];
    }

    function setFeeRecipient(address feeRecipient) public onlyOwner {
    require(feeRecipient != address(0), "Fee recipient cannot be the zero address");
    _feeRecipient = feeRecipient;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    address sender = _msgSender();
    require(sender != address(0), "ERC20: transfer from the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

    uint256 fee = amount / 100; // calculate 1% fee
    uint256 burnAmount = fee / 2; // calculate burn amount (half of fee)
    uint256 transferAmount = amount - fee; // calculate transfer amount (original amount minus fee)
    
    if (_feeRecipient != address(0)) {
        uint256 feeRecipientAmount = fee - burnAmount; // calculate the feeRecipient amount (other half of the fee)
        
        _balances[sender] -= amount; // subtract amount from sender's balance
        _balances[recipient] += transferAmount; // add transfer amount to recipient
        _balances[_feeRecipient] += feeRecipientAmount; // add the feeRecipient amount to feeRecipient's balance
        _balances[address(0)] += burnAmount; // add burn amount to the 0 address
        
        emit Transfer(sender, recipient, transferAmount); // emit transfer event to recipient
        emit Transfer(sender, _feeRecipient, feeRecipientAmount); // emit transfer event for feeRecipient amount
        emit Transfer(sender, address(0), burnAmount); // emit transfer event to burn address
        
        if (burnAmount > 0) {
            _totalSupply -= burnAmount; // update total supply by burning tokens
        }
    } else {
        // if feeRecipient address is not set/invalid, burn the fee instead
        _balances[sender] -= amount; // subtract amount from sender's balance
        _balances[recipient] += transferAmount; // add transfer amount to recipient
        _balances[address(0)] += fee; // add burn amount to the 0 address
        
        emit Transfer(sender, recipient, transferAmount); // emit transfer event to recipient
        emit Transfer(sender, address(0), fee); // emit transfer event to burn address
        
        _totalSupply -= fee; // update total supply by burning tokens
    }
    
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(amount <= _allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance");

    _allowances[sender][_msgSender()] -= amount;

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

    uint256 fee = amount / 100;
    uint256 burnAmount = fee / 2;
    uint256 transferAmount = amount - fee;

    if (_feeRecipient != address(0)) {
        uint256 feeRecipientAmount = fee - burnAmount;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[_feeRecipient] += feeRecipientAmount;
        _balances[address(0)] += burnAmount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, _feeRecipient, feeRecipientAmount);
        emit Transfer(sender, address(0), burnAmount);

        if (burnAmount > 0) {
            _totalSupply -= burnAmount;
        }
    } else {
        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[address(0)] += fee;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(0), fee);

        _totalSupply -= fee;
    }

    return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
        
    _beforeTokenTransfer(from, to, amount);
        
    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
    }
        
    uint256 fee = amount / 100; // calculate 1% fee
    uint256 burnAmount = fee / 2; // calculate burn amount (half of fee)
    uint256 transferAmount = amount - fee; // calculate transfer amount (original amount minus fee)
    
    if (_feeRecipient != address(0)) {
        uint256 feeRecipientAmount = fee - burnAmount; // calculate the feeRecipient amount (other half of the fee)
        _balances[_feeRecipient] += feeRecipientAmount; // add the feeRecipient amount to feeRecipient's balance
        emit Transfer(from, _feeRecipient, feeRecipientAmount); // emit transfer event for feeRecipient amount
        if (burnAmount > 0) {
            _totalSupply -= burnAmount; // update total supply by burning tokens
            _balances[address(0)] += burnAmount; // add burn amount to the 0 address
            emit Transfer(from, address(0), burnAmount); // emit burn event
        }
    } else {
        // if feeRecipient address is not set/invalid, burn the fee instead
        _totalSupply -= fee; // update total supply by burning tokens
        _balances[address(0)] += fee; // add burn amount to the 0 address
        emit Transfer(from, address(0), fee); // emit burn event
    }
        
    _balances[to] += transferAmount; // add transfer amount to recipient
    emit Transfer(from, to, transferAmount); // emit transfer event
        
    _afterTokenTransfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}