// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBEP20.sol";
import "./SafeBEP20.sol";

contract TechFinancePayment is Ownable, Pausable, ReentrancyGuard {
    using SafeBEP20 for IBEP20;
    uint256 public MIN_DEPOSIT = 10 ether;

    address private receiver;
    mapping(string => address) public supportCurrencies;


    event Deposit(address indexed sender, uint256 amount, string currency, string orderId, uint time);
    event UpdateReceiver(address indexed receiver, address oldReceiver, address owner);
    event UpdateSupportCurrencies(string indexed currency, address indexed token, address owner);
    event UpdateMinDeposit(uint256 indexed minDeposit, uint256 oldMinDeposit, address owner);


    function deposit(uint256 _amount, string memory _currency, string memory _orderId) external payable whenNotPaused nonReentrant {
        require(_amount >= MIN_DEPOSIT, "TechFinancePayment: Minimum amount required");
        require(supportCurrencies[_currency] != address(0), "TechFinancePayment: Currency not supported");
        require(bytes(_orderId).length > 0, "TechFinancePayment: OrderId is required");

        if (keccak256(abi.encodePacked(_currency)) == keccak256(abi.encodePacked("BNB"))) {
            require(msg.value == _amount, "TechFinancePayment: Amount is not correct");
        }

        address tokenAddress = supportCurrencies[_currency];
        IBEP20 token = IBEP20(tokenAddress);
        
        require(token.balanceOf(msg.sender) >= _amount, "TechFinancePayment: Insufficient balance");

        if (receiver != address(0)) {
            token.safeTransferFrom(msg.sender, receiver, _amount);
        } else {
            token.safeTransferFrom(msg.sender, address(this), _amount);
        }
        emit Deposit(msg.sender, _amount, _currency, _orderId, block.timestamp);
    }


    function addCurrency(string memory _currency, address _address) external onlyOwner {
        if (supportCurrencies[_currency] != address(0)) {
            revert("TechFinancePayment: Currency already exists");
        }
        
        supportCurrencies[_currency] = _address;
        emit UpdateSupportCurrencies(_currency, _address, msg.sender);
    }

    function removeCurrency(string memory _currency) external onlyOwner {
        delete supportCurrencies[_currency];
        emit UpdateSupportCurrencies(_currency, address(0), msg.sender);
    }
   

    function updateReceiver(address _receiver) external onlyOwner {
        emit UpdateReceiver(_receiver, receiver, msg.sender);
        receiver = _receiver;
    }

    function updateMinDeposit(uint256 _minDeposit) external onlyOwner {
        emit UpdateMinDeposit(_minDeposit, MIN_DEPOSIT, msg.sender);
        MIN_DEPOSIT = _minDeposit;
    }

    receive() external payable {
        //solhint-disable-previous-line no-empty-blocks
    }

    function recoverLostToken() external onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    function recoverLostBEP20Token(address _token, uint256 amount) external onlyOwner {
        require(_token != address(this), "Cannot recover BEP20 token");
        IBEP20(_token).transfer(msg.sender, amount);
    }
}