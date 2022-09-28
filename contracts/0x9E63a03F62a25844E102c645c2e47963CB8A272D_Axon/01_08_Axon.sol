// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV3Factory.sol";

contract Axon is ERC20, ERC20Burnable, Ownable {
    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////////////

    uint256 private constant S_VESTING_PERCENT_FEE = 100 * 1 ether;  // Initial fee (100%)
    uint256 private constant S_BASE_PERCENT_FEE = 3 * 1 ether; // Permanent minimum fee (3%)
    uint256 private constant S_TIME_VESTING_PERIOD = 730 days; // 2 years (seconds)
    uint256 private immutable s_dateVestingStart;
    
    address private immutable s_salesContract; // Sales contract address
    address private immutable s_companyAddress; // Company address
    address private immutable s_liquidityAddress; // Liquidity address
    address private s_addressStake; // Stake contract address
    address private immutable s_poolAddress; // Pool adddress Uniswap
    
    IUniswapV3Factory private constant S_FACTORY_UNISWAP = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address private immutable S_WETH;

    // [0] == true => No fees for the from address // [1] == true => No fees for the to address
    mapping(address => bool[2]) private whiteListFees; 

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    constructor(
        string memory _name, 
        string memory _token,
        address p_salesContract,
        address p_companyaddress,
        address p_liquidityaddress,
        address p_addressStake,
        address p_S_WETH       
    ) ERC20(_name, _token) {
        s_salesContract = p_salesContract;
        s_companyAddress = p_companyaddress;
        s_liquidityAddress = p_liquidityaddress;
        s_addressStake = p_addressStake;
        
        // Total Supply => 1000M (100%)
        _mint(s_salesContract, 500 * 1000000 * 1 ether); // 500M (50%)
        _mint(s_companyAddress, 300 * 1000000 * 1 ether); // 300M (30%)
        _mint(s_liquidityAddress, 200 * 1000000 * 1 ether); // 200M (20%)

        whiteListFees[s_salesContract] = [true, true];
        whiteListFees[s_companyAddress] = [true, true];
        whiteListFees[s_liquidityAddress] = [true, true];
        whiteListFees[s_addressStake] = [true, true];

        S_WETH = p_S_WETH; 

        require(S_FACTORY_UNISWAP.getPool(address(this), S_WETH, 3000) == address(0), 'Error: Pool exists'); 
        s_poolAddress = S_FACTORY_UNISWAP.createPool(address(this), S_WETH, 3000);
        whiteListFees[s_poolAddress] = [true, false];

        s_dateVestingStart = block.timestamp;   
    } 

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    //////////////////////////////////////////////////////////////////////////////////////////////////   

    // => View functions

    function salesContract() public view returns(address) {
        return s_salesContract;
    }

    function addressStake() public view returns(address) {
        return s_addressStake;
    }

    function companyAddress() public view returns(address) {
        return s_companyAddress;
    }

    function percentFee() public view returns(uint256) {
        return _currentPercentFee();
    }

    function _amountFee(uint256 p_amountToTransfer) public view returns(uint256) {
        return _amountFee(p_amountToTransfer, _currentPercentFee());
    }

    function poolAddress() public view returns(address) {
        return s_poolAddress;
    }

    // => Set functions
    
    function transfer(address p_to, uint256 p_amount) public virtual override returns(bool) {
        if (!whiteListFees[msg.sender][0] && !whiteListFees[p_to][1]) { _executeFees(msg.sender, p_amount); }
        
        return super.transfer(p_to, p_amount);
    }

    function transferFrom(address p_from, address p_to, uint256 p_amount) public virtual override returns (bool) {
        if (!whiteListFees[p_from][0] && !whiteListFees[p_to][1]) { _executeFees(p_from,  p_amount); }    
        
        return super.transferFrom(p_from, p_to, p_amount);
    }

    function setAddressStake(address p_newAddressStake) public onlyOwner returns(bool) {
        delete whiteListFees[s_addressStake];
        
        s_addressStake = p_newAddressStake;
        whiteListFees[p_newAddressStake] = [true, true];
        
        return true;
    }

    function setWhitelist(address p_address, bool p_flagFrom, bool p_flagTo) public onlyOwner returns(bool) {
        whiteListFees[p_address] = [p_flagFrom, p_flagTo];
        
        return true;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions
    //////////////////////////////////////////////////////////////////////////////////////////////////

    // Percent Fee
    function _currentPercentFee() internal view returns(uint256) {
        uint256 finalTime = s_dateVestingStart + S_TIME_VESTING_PERIOD;

        if (block.timestamp >= finalTime) { return S_BASE_PERCENT_FEE / 0.01 ether; }

        uint256 diffTimeSeconds = block.timestamp - s_dateVestingStart;
        uint256 discountPercentSecond = (S_VESTING_PERCENT_FEE - S_BASE_PERCENT_FEE) / (S_TIME_VESTING_PERIOD) ;
        uint256 percentFee18Decimals = S_VESTING_PERCENT_FEE - (discountPercentSecond * diffTimeSeconds);

        return percentFee18Decimals / 0.01 ether; // 2 decimals
    }

    // Amount Fee
    function _amountFee(uint256 p_amountToTransfer, uint256 p__currentPercentFee) internal pure returns(uint256) {
        return  (p_amountToTransfer * p__currentPercentFee) / 10000;
    }

    function _executeFees(address p_from, uint256 p_amount) internal {
        uint256 total_amountFee = _amountFee(p_amount, _currentPercentFee());
        
        if (total_amountFee * 30 >= 100){
            _burn(p_from, (total_amountFee * 30) / 100);

            if (p_from != msg.sender) {  _spendAllowance(p_from, msg.sender, (total_amountFee * 30) / 100); }
        } else {
            _burn(p_from, 1);

            if (p_from != msg.sender) { _spendAllowance(p_from, msg.sender, 1); }
        }

        if (total_amountFee * 70 >= 100){
            _transfer(p_from, s_addressStake, (total_amountFee * 70) / 100);  

            if (p_from != msg.sender) { _spendAllowance(p_from, msg.sender, (total_amountFee * 70) / 100); }    
        } else {
            _transfer(p_from, s_addressStake, 1);

            if (p_from != msg.sender) { _spendAllowance(p_from, msg.sender, 1); }
        }
    }
}