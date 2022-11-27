// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./OperationWithSigner.sol";
import "./PancakeSwap.sol";

contract PTC is ERC20Burnable, OperationWithSigner {
    using ECDSA for bytes32;

    uint8 constant _DECIMALS = 9;
    uint256 constant _GWEI = 10**_DECIMALS;
    uint256 constant _TOTAL_SUPPLY = 3330000 * _GWEI;
    uint256 constant _LP_ALLOCATION = 30000 * _GWEI;
    uint256 constant _CARD_REWARD = 66666 * _GWEI;
    uint256 constant _STAKE_INCOME = 3233334 * _GWEI;
    //0.00001 gwei
    uint256 constant MIN_BALANCE = 10000;    
    uint256 constant CARD_INCOME = 1;
    uint256 constant FOUNDATION_INCOME = 1;
    uint256 constant STAKE_INCOME = 1;

    uint256 private _incomePool = 0;
    uint256 private _burnPercent = 8;
    uint256 private _cardRewardPool = _CARD_REWARD;
    uint256 private _stakeIncomePool =_STAKE_INCOME;

    IERC20 public USDT;

    uint256 private _totalBurned = 0;
    /*fee related */
    address private _foundationAddress;
    address public pancakePairAddress;
    address public pancakeRouterAddress;
    address public stakerAddress;
    bool private _feeEnabled;

    /*withdrawal related */
    mapping(string => bool) _usedIds;

    event IncomeAdded(address indexed from, uint256 amount);
    event CardRewardSent(address indexed recipient, uint256 amount);    
    event Withdrawal(
        address indexed wallet,
        string withdrawalId,
        uint256 amount
    );
    //tracking of total withdrawals per address so we can have 
    //a sanity check on total income to ensure that user cannot
    //withdraw more than their income.
    mapping(address=>uint256) private _stakeIncomeWithdrawals;
    mapping(address=>uint256) private _incomeWithdrawals;
    mapping(address=>uint256) private _cardRewardWithdrawals;

    constructor(address foundationAddress, address usdtAddress)
        ERC20("Perfect Curve", "PTC")
    {
        _foundationAddress = foundationAddress;
        USDT = IERC20(usdtAddress);
        _mint(_foundationAddress, _LP_ALLOCATION);
    }

    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }

    //fee functions
    function setFeeEnabled(bool value) external onlyOperators {
        _feeEnabled = value;
    }

    function isFeeEnabled() public view returns (bool) {
        return _feeEnabled;
    }

    function setPancakePairAddress(address pairAddress) external onlyOperators {
        pancakePairAddress = pairAddress;
    }

    function setPancakeRouterAddress(address routerAddress)
        external
        onlyOperators
    {
        pancakeRouterAddress = routerAddress;
    }

    function setStakerAddress(address newAddress) external onlyOperators {
        stakerAddress = newAddress;
    }

    function setBurnPercent(uint256 burnPercent) external onlyOperators {
        _burnPercent=burnPercent;
    }

    function getBurnPercent() external view returns (uint256)  {
        return _burnPercent;
    }

    function getFoundationAddress() public view returns (address) {
        return _foundationAddress;
    }

    function getIncomePool() public view returns (uint256) {
        return _incomePool;
    }

    function getStakeIncomePool() public view returns(uint256){
        return _stakeIncomePool;
    }

    function getCardRewardPool() external view returns (uint256) {
        return _cardRewardPool;
    }

    function safeMint(address to, uint256 amount) internal {
        require(
            totalSupply() + amount + _totalBurned <= _TOTAL_SUPPLY,
            "TOTAL_SUPPLY_EXCEEDED"
        );
        _mint(to, amount);
    }

    // function internalMint(address to, uint256 amount) external onlyOperators {
    //     safeMint(to, amount);
    // }


    function getCardRewardWithdrawal(address user) external view returns (uint256){
        return _cardRewardWithdrawals[user];
    }

    function getIncomeWithdrawal(address user) external view returns (uint256){
        return _incomeWithdrawals[user];
    }

    function getStakeIncomeWithdrawal(address user) external view returns (uint256){
        return _stakeIncomeWithdrawals[user];
    }
    
    function getTotalBurned() external view returns (uint256){
        return _totalBurned;
    }

    function hashTransaction(
        address sender,
        string memory withdrawalId,
        uint256 amount,
        uint256 maxWithdraw,
        uint256 timeoutBlock
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(sender, withdrawalId, amount, maxWithdraw, timeoutBlock)
                )
            )
        );
        return hash;
    }

    function withdrawIncome(
        bytes memory signature,
        string memory withdrawalId,
        uint256 amount,
        uint256 maxWithdraw,
        uint256 timeoutBlock
    ) external {        
        require( block.number<=timeoutBlock, "REQUEST_EXPIRED");
        require(amount <= _incomePool, "INCOME_EXCEEDED_BALANCE");
        require(_incomeWithdrawals[msg.sender]+amount<=maxWithdraw, "WITHDRAW_EXCEED_QUOTA");                
        require(bytes(withdrawalId)[0]=="I", "INVALID_WITHDRAWAL");
        require(_usedIds[withdrawalId] == false, "DUPLICATE_REQUEST");
        _usedIds[withdrawalId]=true;
        require(
            hashTransaction(msg.sender, withdrawalId, amount, maxWithdraw, timeoutBlock)
                .recover(signature) == getSignerAddress(),
            "INVALID_SIGNATURE"
        );
        _incomePool-=amount;
        _incomeWithdrawals[msg.sender]+=amount;
        super._transfer(address(this), msg.sender, amount);
        emit Withdrawal(msg.sender, withdrawalId, amount);
    }

    function withdrawCardRewards(
        bytes memory signature,
        string memory withdrawalId,
        uint256 amount,
        uint256 maxWithdraw,
        uint256 timeoutBlock
    ) external {
        require( block.number<=timeoutBlock, "REQUEST_EXPIRED");
        require(amount  <= _cardRewardPool, "REWARD_EXCEEDED_BALANCE");
        require(_usedIds[withdrawalId] == false, "DUPLICATE_REQUEST");        
        require(bytes(withdrawalId)[0]=="C", "INVALID_WITHDRAWAL");        
        require(_cardRewardWithdrawals[msg.sender]+amount<=maxWithdraw, "WITHDRAW_EXCEED_QUOTA");
        _usedIds[withdrawalId]=true;
        require(
            hashTransaction(msg.sender, withdrawalId, amount,maxWithdraw, timeoutBlock)
                .recover(signature) == getSignerAddress(),
            "INVALID_SIGNATURE"
        );        
        _cardRewardPool-=amount;
        _cardRewardWithdrawals[msg.sender]+=amount;                
        safeMint(msg.sender, amount);
        emit Withdrawal(msg.sender, withdrawalId, amount);
    }

    function withdrawStakeIncome(
        bytes memory signature,
        string memory withdrawalId,
        uint256 amount,
        uint256 maxWithdraw,
        uint256 timeoutBlock
    ) external {        
        require(block.number<=timeoutBlock, "REQUEST_EXPIRED");
        require(amount  <= _stakeIncomePool, "INCOME_EXCEEDED_BALANCE");
        require(_usedIds[withdrawalId] == false, "DUPLICATE_REQUEST");        
        require(bytes(withdrawalId)[0]=="S", "INVALID_WITHDRAWAL");
        require(_stakeIncomeWithdrawals[msg.sender]+amount<=maxWithdraw, "WITHDRAW_EXCEED_QUOTA");
        _usedIds[withdrawalId]=true;
        require(
            hashTransaction(msg.sender, withdrawalId, amount, maxWithdraw,timeoutBlock)
                .recover(signature) == getSignerAddress(),
            "INVALID_SIGNATURE"
        );        
        _stakeIncomePool-=amount;
        _stakeIncomeWithdrawals[msg.sender]+=amount;
        safeMint(msg.sender, amount);
        emit Withdrawal(msg.sender, withdrawalId, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {        
        if (
            balanceOf(from) - amount <= 0 &&
            from != pancakePairAddress &&
            from != address(this) &&
            from != _foundationAddress &&
            from != stakerAddress
        ) {
            //disallow emptying wallet except from pancakePair or this contract
            amount = amount - MIN_BALANCE;
        }
        if (
            !_feeEnabled || from == pancakePairAddress || from == address(this) || from==stakerAddress
        ) {
            //without fee
            super._transfer(from, to, amount);
        } else {
            //with fee
            
            uint256 toBurn = (_burnPercent * amount) / 100;
            uint256 incomeDeduction = ((CARD_INCOME + STAKE_INCOME) * amount) /
                100;
            uint256 foundationIncome = (FOUNDATION_INCOME * amount) / 100;
            _burn(from, toBurn);
            super._transfer(from, address(this), incomeDeduction);
            super._transfer(from, _foundationAddress, foundationIncome);
            super._transfer(
                from,
                to,
                amount - toBurn - incomeDeduction - foundationIncome
            );            
            _incomePool += incomeDeduction;
            emit IncomeAdded(from, incomeDeduction);
        }
    }
    /* return the price of PTC in USDT*/
    function getPtcPrice(uint256 amount) external view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(
            pancakePairAddress
        ).getReserves();
        if (address(this)> address(USDT)) {
            (reserve0,reserve1)=(reserve1,reserve0);
        }
        return
            IPancakeRouter01(pancakeRouterAddress).quote(
                amount,
                reserve0,
                reserve1
            );
    }

    /* return the price of USDT in PTC*/
    function getUsdtPrice(uint256 amount) external view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(
            pancakePairAddress
        ).getReserves();
        if (address(this)> address(USDT)) {
            (reserve0,reserve1)=(reserve1,reserve0);
        }
        return
            IPancakeRouter01(pancakeRouterAddress).quote(
                amount,
                reserve1,
                reserve0
            );
    }

    function addLiquidity(uint256 usdtAmount, uint256 ptcAmount)
        external
        returns (
            uint256 usdt,
            uint256 ptc,
            uint256 liquidity
        )
    {
        require(balanceOf(msg.sender) >= ptcAmount, "INSUFFICIENT_BALANCE");
        USDT.transferFrom(msg.sender, address(this), usdtAmount);
        super._transfer(msg.sender, address(this), ptcAmount);
        USDT.approve(pancakeRouterAddress, usdtAmount);
        this.approve(pancakeRouterAddress, ptcAmount);
        (ptc, usdt, liquidity) = IPancakeRouter01(pancakeRouterAddress)
            .addLiquidity(
                address(this),
                address(USDT),
                ptcAmount,
                usdtAmount,
                0,
                0,
                msg.sender,
                block.timestamp
            );
        //return  excess and clear approval
        if (usdt < usdtAmount) {
            USDT.transfer(msg.sender, usdtAmount - usdt);
            USDT.approve(pancakeRouterAddress, 0);
        }
        if (ptc < ptcAmount) {
            super._transfer(address(this), msg.sender, ptcAmount - ptc);
            approve(pancakeRouterAddress, 0);
        }
        return (usdt, ptc, liquidity);
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account,amount);        
        _totalBurned+=amount;
    }
}