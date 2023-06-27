// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./Governable.sol";
 
contract RevenueShare is Governable {
    receive() external payable {}

    using SafeMath for uint256;

    mapping (address => bool) public _isHandler;

    address[] public _accountList;
    uint256[] public _nftBalanceList;
    mapping (address => bool) public _accountMap;

    uint256 public _sendId;

   IERC721 private _nftContract;

    event RevenueShare(
        uint256 sendId,
        uint256 balance
    );

    event RevenueSend(
        uint256 sendId,
        address indexed account,
        uint256 balance
    );

    modifier onlyHandler() {
        require(_isHandler[msg.sender], "RevenueShare: forbidden");
        _;
    }

    constructor() {
        _isHandler[msg.sender] = true;
        _nftContract = IERC721(0xf3Bb55d379E8c505749B9afD2c23b993a7D72CB7);
        _sendId = 0;
    }

    function  getAccountLength() public view returns (uint256) {
        return _accountList.length;
    }

    function  getAccountInfo(uint256 i) public view returns (address, uint256) {
        return (_accountList[i], _nftBalanceList[i]);
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        _isHandler[_handler] = _isActive;
    }

    function setTokenAddress(address nftContractAddress) external onlyGov {
        _nftContract = IERC721(nftContractAddress);
    }

    function addAccount(address[] memory _accounts, uint256[] memory _nftBalances) public onlyHandler {

        require(_accounts.length == _nftBalances.length, "account and balance mismatch");

        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 bal = _nftBalances[i];

            if (_accountMap[account] != true) {
                _accountMap[account] = true;
                _accountList.push(account);
                _nftBalanceList.push(bal);
            }
        }
    }

    function clearAccount() public onlyHandler {
        
        for (uint256 i = 0; i < _accountList.length; i++) {
            address account = _accountList[i];
            _accountMap[account] = false;
        }

        _accountList = new address[](0);
        _nftBalanceList = new uint256[](0);
    }

    function withdraw() external onlyGov {
        address payable ownerAddress = payable(msg.sender);
        ownerAddress.transfer(address(this).balance);
    }

    function sendRevenue(uint256 total) public onlyHandler {

        require(total <= address(this).balance, "Balance is not enough");

        uint256 nftTotal = 999;
        uint256 sum = 0;

        _sendId++;

        for (uint256 i = 0; i < _accountList.length; i++) {
            address account = _accountList[i];
            
            uint256 nftBalance = _nftContract.balanceOf(account);

            //uint256 nftBalance = _nftBalanceList[i];

            uint256 amount = total * nftBalance / nftTotal;
            sum += amount;

            address payable toAddress = payable(account);
            toAddress.transfer(amount);

            emit RevenueSend(_sendId, account, amount);
        }

        emit RevenueShare(_sendId, sum);
    }

    function sendRevenue_(uint256 total) public onlyHandler {

        require(total <= address(this).balance, "Balance is not enough");

        uint256 nftTotal = 999;
        uint256 sum = 0;

        _sendId++;

        for (uint256 i = 0; i < _accountList.length; i++) {
            address account = _accountList[i];
            
            // uint256 nftBalance = _nftContract.balanceOf(account);

            uint256 nftBalance = _nftBalanceList[i];

            uint256 amount = total * nftBalance / nftTotal;
            sum += amount;

            address payable toAddress = payable(account);
            toAddress.transfer(amount);

            emit RevenueSend(_sendId, account, amount);
        }

        emit RevenueShare(_sendId, sum);
    }
}