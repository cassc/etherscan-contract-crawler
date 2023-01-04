// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './interfaces/IERC20.sol';

import "hardhat/console.sol";

interface IRoyalties{
    function deposit(uint256 amount) external;
}

// The base pair of pools, either stable or volatile
contract NFTSalesSplitter  {

    uint256 constant public PRECISION = 1000;
    uint256 public converterFee = 667;
    uint256 public royaltiesFee = 333;
    

    address public wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    address public stakingConverter;
    address public royalties;

    address public owner;

    mapping(address => bool) public splitter;


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    
    modifier onlyAllowed() {
        require(msg.sender == owner || splitter[msg.sender]);
        _;
    }

    constructor() {
        owner = msg.sender;
    }


    function split() public onlyAllowed {
        
        uint256 balance = balanceOf();
        if(stakingConverter != address(0)){
            uint256 stakingAmount = balance * converterFee / PRECISION;
            IERC20(wbnb).transfer(stakingConverter, stakingAmount);
        }

        if(royalties != address(0)){
            uint256 royaltiesAmount = balance * royaltiesFee / PRECISION;
            IERC20(wbnb).approve(royalties, 0);
            IERC20(wbnb).approve(royalties, royaltiesAmount);
            IRoyalties(royalties).deposit(royaltiesAmount);
        }        

    }

    function balanceOf() public view returns(uint){
        return IERC20(wbnb).balanceOf(address(this));
    }

    function setConverter(address _converter) external onlyOwner {
        require(_converter != address(0));
        stakingConverter = _converter;
    }

    function setRoyalties(address _royal) external onlyOwner {
        require(_royal != address(0));
        royalties = _royal;
    }

    function setSplitter(address _splitter, bool _what) external onlyOwner {
        splitter[_splitter] = _what;
    }

    
    ///@notice in case token get stuck.
    function withdrawERC20(address _token) external onlyOwner {
        require(_token != address(0));
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, _balance);
    }


    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    function setFees(uint256 _amountToStaking, uint256 _amountToRoyalties ) external onlyOwner {
        converterFee = _amountToStaking;
        royaltiesFee = _amountToRoyalties;
    }


}