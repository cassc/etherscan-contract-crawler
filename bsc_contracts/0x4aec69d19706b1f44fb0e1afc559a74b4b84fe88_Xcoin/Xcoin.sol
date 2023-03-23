/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Xcoin {
    /// @notice EIP-20 token name for this token
    string public constant name = "Xcoin";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "XCN";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// Max token supply
    uint max_token_Supply;

    /// @notice the price per token in busd for STO
    uint token_price = 100000000000000; // $0.0001

    /// @notice Max token minted through airdrop
    uint public maxAirdrop; // The total that can be airdroped.

    // the whitelist mapping for tracking airdrop receivers
    mapping(address => bool) public Whitelist;

    //Airdrop Amount
    uint AirdropAmount;

    /// @notice Max token minted through airdrop
    uint public maxSTO; // The total that can be sold in an STO.

    /// @notice Max token minted through airdrop
    uint public maxInvestors; // The total that can be sold in an STO.

    /// max business
    uint public maxBusiness; // the total to be used for funding the project

    /// @notice Max token minted through airdrop
    uint public maxPublic; // The total that can be sold in an STO.

    /// @notice Total number of tokens in circulation
    uint public totalSupply; 

    /// @notice Accumulated token minted through airdrop
    uint public airdropAccumulated;

    /// @notice Accumulated token sold through STO
    uint public STOAccumulated;

    /// @notice Accumulated token sold to investors
    uint public InvestorAccumulated;

    /// the time when the contract was deployed
    uint public startTime;

    /// the time the tokens can be claimed after 3 months
    uint public claimTime1;

    /// the time the tokens can be claimed after 6 months
    uint public claimTime2;

    /// the time the tokens can be claimed after 9 months
    uint public claimTime3;

    // A mapping of addresses to their claim amount
    mapping (address => uint) public claimAmount;

    /// @notice The admin address, ultimately this will be set to the governance contract address
    /// so the community can colletively decide some of the key parameters (e.g. maxStakeReward)
    /// through on-chain governance.
    address admin = 0xC458A76C689b4adD5E8273c75d7897A94eaf2BcE;

    /// @notice Address which may airdrop new tokens
    address public airdropper;

    // a mapping of investors, to check if an address is an investor.
    mapping (address => bool) public investors;

    // An array containing the early investors
    address[] investors_list;


    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public check_holder;

    /// @notice Official record of token balances for each account
    mapping (address => uint) internal balances;

    /// @notice An event that is emmited when token is claimed
    event tokenClaimed(address owner, uint amount);

    /// @notice An event thats emitted when tokens are airdropped
    event TokenAirdropped(address airdropper);

    /// @notice An event thats emitted when tokens are bought in an STO
    event Tokensold(address buyer, uint amount);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// Event for max token supply reached
    event Max_reached(bool reached);

    /// an array of all holders
    address[] holders;

    function holder() public view returns (address[] memory) {
        return holders;
    }

    constructor() {

        startTime = block.timestamp;

        claimTime1 = startTime + (3 * 892800); // 3 months after the token contract has deployed before the token can be spent (vesting of tokens).

        claimTime2 = startTime + (6 * 892800); // 3 months after the token contract has deployed before the token can be spent (vesting of tokens).

        claimTime3 = startTime + (9 * 892800); // 3 months after the token contract has deployed before the token can be spent (vesting of tokens).

        max_token_Supply = 1500000000000000000000000000;

        maxInvestors = (max_token_Supply / 100) * 20;

        maxBusiness = (max_token_Supply / 100) * 20;

        maxPublic = (max_token_Supply / 100) * 1;

        uint reserve_mint_amount = (max_token_Supply / 100) * 30;

        maxSTO = (maxPublic / 100) * 70;

        maxAirdrop = (maxPublic / 100) * 30;

        AirdropAmount = 100000000000000000000;

        uint MintAmount = reserve_mint_amount + maxBusiness + maxInvestors;

        mint(address(this), MintAmount);
        // token is minted to admin
        // admin can send to whoever
        mint(admin, 500000000000000000000000000);
    }

    function Admin() external view returns (address) {
        return admin;
    }

    function MaxBusiness() external view returns (uint) {
        return maxBusiness;
    }

    function addinvestor(address _holder) internal {
        if(investors[_holder] != true) {
            investors[_holder] = true;
            investors_list.push(_holder);
        }
    }

    function make_investor() external {
        investors[msg.sender] = true;
    }

    function mint(address dst, uint rawAmount) internal {
        require(dst != address(0), "Xcoin::mint: cannot transfer to the zero address");

        // mint the amount
        uint amount = rawAmount;
        totalSupply = totalSupply + amount;

        balances[dst] = balances[dst] + amount;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        balances[account] = accountBalance - amount;
        
        totalSupply -= amount;
    }

    function burn(address account, uint256 amount) external returns (bool) {
        _burn(account, amount);
        return true;
    }

    function buyToken_Investors(address investor) payable public {
        require(InvestorAccumulated <= maxInvestors, "Xcoin::STO: All tokens for STO have been sold");
        require(totalSupply < max_token_Supply, "Minting has stoped");

        uint _amount = msg.value / token_price;
        uint amount_ = (_amount * (10 ** 18)) / 4;

        claimAmount[investor] = amount_;
        totalSupply = totalSupply + amount_;

        // transfer the amount to the recipient
        mint(investor, amount_);
        addinvestor(investor);

        InvestorAccumulated = InvestorAccumulated + amount_;
        
        emit Tokensold(msg.sender, _amount);
    }

    function buyToken_Partners(address partner) payable public {
        require(InvestorAccumulated <= maxInvestors, "Xcoin::STO: All tokens for STO have been sold");
        require(totalSupply < max_token_Supply, "Minting has stoped");

        uint _amount = msg.value / token_price;
        uint amount_ = (_amount * (10 ** 18)) / 4;

        claimAmount[partner] = amount_;

        totalSupply = totalSupply + amount_;

        // transfer the amount to the recipient
        mint(partner, amount_);
        addinvestor(partner);

        InvestorAccumulated = InvestorAccumulated + amount_;
        
        emit Tokensold(msg.sender, _amount);
    }

    // function to claim tokens after 3 months
    function claimToken1() public {

        require(InvestorAccumulated <= maxInvestors, "Xcoin::STO: All tokens for STO have been sold");
        require(totalSupply < max_token_Supply, "Minting has stoped");
        require(block.timestamp > claimTime1, "You can not claim your tokens yet");

        uint amount = claimAmount[msg.sender];

        totalSupply = totalSupply + amount;

        // transfer the amount to the recipient
        mint(msg.sender, amount);

        InvestorAccumulated = InvestorAccumulated + amount;
        
        emit tokenClaimed(msg.sender, amount);
    }

    // function to claim tokens after 6 months
    function claimToken2() public {

        require(InvestorAccumulated <= maxInvestors, "Xcoin::STO: All tokens for STO have been sold");
        require(totalSupply < max_token_Supply, "Minting has stoped");
        require(block.timestamp > claimTime2, "You can not claim your tokens yet");

        uint amount = claimAmount[msg.sender];

        totalSupply = totalSupply + amount;

        // transfer the amount to the recipient
        mint(msg.sender, amount);

        InvestorAccumulated = InvestorAccumulated + amount;
        
        emit tokenClaimed(msg.sender, amount);
    }

    // function to claim tokens after 9 months
    function claimToken3() public {

        require(InvestorAccumulated <= maxInvestors, "Xcoin::STO: All tokens for STO have been sold");
        require(totalSupply < max_token_Supply, "Minting has stoped");
        require(block.timestamp > claimTime3, "You can not claim your tokens yet");

        uint amount = claimAmount[msg.sender];

        totalSupply = totalSupply + amount;

        // transfer the amount to the recipient
        mint(msg.sender, amount);

        InvestorAccumulated = InvestorAccumulated + amount;
        
        emit tokenClaimed(msg.sender, amount);
    }


    function token_investors() external view returns (address[] memory) {
        return investors_list;
    }

    // function to get into whitelist
    function RegisterWhitelist() public {
        require(Whitelist[msg.sender] != true);
        Whitelist[msg.sender] = true;
    }

    // Airdrop function
    function ClaimAirdrop() public {
        require(maxAirdrop < max_token_Supply);
        require(Whitelist[msg.sender] == true, "you are not in the whitelist to claim Airdrop");
        require(airdropAccumulated <= maxAirdrop, "Xcoin::airdrop: accumlated airdrop token exceeds the max");
            mint(msg.sender, AirdropAmount);

            uint amount = AirdropAmount;
            airdropAccumulated = airdropAccumulated + amount;
            Whitelist[msg.sender] = false;
            emit TokenAirdropped(msg.sender);
        }

    function allowance(address account, address spender) public view returns (uint) {
        return _allowances[account][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
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

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    function balanceInWholeCoin(address account) external view returns (uint) {
        return balances[account] / 1_000_000_000_000_000_000;
    }

    function transfer(address dst, uint amount) public returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) public returns (bool) {
        _spendAllowance(src, msg.sender, amount);
        _transferTokens(src, dst, amount);

        return true;
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

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "Xcoin::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Xcoin::_transferTokens: cannot transfer to the zero address");
        emit Transfer(src, dst, amount);
        if(check_holder[dst] == true) {
            balances[src] = balances[src] - amount;
            balances[dst] = balances[dst] + amount;
        }
        else {
            balances[src] = balances[src] - amount;
            balances[dst] = balances[dst] + amount;
            check_holder[dst] = true;
            holders.push(dst);
        }

    }

    function get_investor (address investor) external view returns (bool) {
        if (investors[investor] == true) {
            return true;
        }
        else return false;
    }

    function withdraw(uint amount) public onlyAdmin {

        payable(msg.sender).transfer(amount);
    }

    function withdraw_token (uint amount) public onlyAdmin {
        transfer(admin, amount);
    }

    modifier onlyAdmin { 
        require(msg.sender == admin, "Xcoin::onlyAdmin: only the admin can perform this action");
        _; 
    }

    modifier onlyAirdropper { 
        require(msg.sender == airdropper, "Xcoin::onlyAirdropper: only the airdropper can perform this action");
        _; 
    }

}