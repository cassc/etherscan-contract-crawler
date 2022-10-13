// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "hardhat/console.sol";
import "stl-contracts/royalty/DerivedERC2981Royalty.sol";

interface Minter {
    function getMinter(uint tokenId) external view returns (address);
}

contract RoyaltyReceiver is OwnableUpgradeable, UUPSUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    using ECDSA for bytes32;

    address suitUp;
    
    // struct Pay {
    //     uint256 id;
    //     uint256 timestamp;
    // }

    struct ERC20Payment {
        bytes32 TX;
        uint amount;
        address erc20;
        uint tokenId;

    }

    struct ETHPayment {
        bytes32 TX;
        uint amount;
        uint tokenId;
    }

    struct ERC20toPay {
        address erc20;
        uint beneficiaryAmount;
        uint userAmount;
    }

    struct ETHtoPay {
        uint amount;
        uint beneficiaryAmount;
        uint userAmount;
    }

    // TX or some unique bytes32 -> amount
    mapping(bytes32 => uint256) private _ETHPaid;

    mapping(bytes32 => ETHtoPay) private _ETHpayments;
    // list of paid and unpaid royaties
    mapping(bytes32 => ERC20toPay) private _erc20payments;

    address private _tokenDetector;
    
    address public beneficiary;
    
    uint256 public beneficiaryPercentage;
   
    event RoyaltyPaid(bytes32 indexed tx, address indexed receiver, uint256 sum);
    event RoyaltyPaidERC20(bytes32 indexed tx, address indexed erc20, address indexed receiver, uint256 sum);

    event TokenDetectorSet(
        address indexed previousAddress, 
        address indexed newAddress
        );

    event ReceiversDataSet(
        address indexed addr, 
        uint256 percent
    );

    function initialize(address tokenDetector_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        _tokenDetector = tokenDetector_;
    }

    // use for tests
    function setSuitUp(address _suitUp) external onlyOwner {
        suitUp = _suitUp;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function getContractAddress() internal view returns (address) {
        return suitUp;
    }

    function getERC20txData(bytes32 _tx) view external returns (ERC20toPay memory) {
        require(_erc20payments[_tx].erc20 != address(0), "TX not exists");
        return _erc20payments[_tx];
    }

    function getETHtxData(bytes32 _tx) view external returns (ETHtoPay memory) {
        require(_ETHpayments[_tx].amount != 0, "TX not exists");
        return _ETHpayments[_tx];
    }

    // internal function. dont waste gas and dont save current user amount . just save rest of users amounts
    function saveTxDataAndGetRequestorAmount(ERC20Payment memory txData) internal returns (uint currentUserSum) {

        (uint256 beneficiaryPart, uint256 UserPart) = getRoyaltyValues(txData.amount);

        // if TX already exists then return amount to withdraw and clear saved amount for current user in the _erc20payments list
        ERC20toPay memory savedTxData = _erc20payments[txData.TX];
        
        if ( savedTxData.erc20 != address(0) ) {

            require(savedTxData.erc20 == txData.erc20, "Wrong ERC20 for TX");

            if (_msgSender() == beneficiary && beneficiaryPart == savedTxData.beneficiaryAmount ) {
                currentUserSum = savedTxData.beneficiaryAmount;
                _erc20payments[txData.TX].beneficiaryAmount = 0;
            } else {
                currentUserSum = savedTxData.userAmount;
                _erc20payments[txData.TX].userAmount = 0;
            }
            return currentUserSum;
        }

        // if its a new TX then save TX data except of the msg.sender amount, because we will pay it immediately
        if (_msgSender() == beneficiary) {
            currentUserSum = beneficiaryPart;
            beneficiaryPart = 0;
        } else {
            currentUserSum = UserPart;
            UserPart = 0;
        }

        _erc20payments[txData.TX] = ERC20toPay(txData.erc20, beneficiaryPart, UserPart);

    }


    function saveTxDataAndGetRequestorAmountETH(ETHPayment memory txData) internal returns (uint currentUserSum) {

        (uint256 beneficiaryPart, uint256 UserPart) = getRoyaltyValues(txData.amount);

        // if TX already exists then return amount to withdraw and clear saved amount for current user in the _ETHpayments list
        ETHtoPay memory savedTxData = _ETHpayments[txData.TX];
        if ( savedTxData.amount > 0 ) {

            require(savedTxData.amount == txData.amount, "Wrong Amount for TX");

            if (_msgSender() == beneficiary && beneficiaryPart == savedTxData.beneficiaryAmount ) {
                currentUserSum = savedTxData.beneficiaryAmount;
                _ETHpayments[txData.TX].beneficiaryAmount = 0;
            } else {
                currentUserSum = savedTxData.userAmount;
                _ETHpayments[txData.TX].userAmount = 0;
            }
            return currentUserSum;
        }

        // if its a new TX then save TX data except of the msg.sender amount, because we will pay it immediately
        if (_msgSender() == beneficiary) {
            currentUserSum = beneficiaryPart;
            beneficiaryPart = 0;
        } else {
            currentUserSum = UserPart;
            UserPart = 0;
        }

        _ETHpayments[txData.TX] = ETHtoPay(txData.amount, beneficiaryPart, UserPart);

    }

    // validate signature and parse input data
    function convertValidateERC20Input(bytes calldata payload, bytes memory signature) internal view returns (
        // address receiver, 
        ERC20Payment[] memory _erc20paymetsData) {
        validateSignature(payload, signature);
        _erc20paymetsData = abi.decode(payload, (ERC20Payment[]));
        
    }

    // validate signature and parse input data
    function convertValidateETHInput(bytes calldata payload, bytes memory signature) internal view returns (ETHPayment[] memory _ETHpaymetsData) {

        validateSignature(payload, signature);
        _ETHpaymetsData = abi.decode(payload, (ETHPayment[]));

    }


    // it should be project owner / NFT minter
    function validateMinter(uint tokenId) view internal {

        if (_msgSender() != beneficiary) {

            Minter erc721minter = Minter(getContractAddress());
    
            address minter = erc721minter.getMinter(tokenId);

            require(_msgSender() == minter, "Requestor not allowed");

        }
        
    }

    /**
    withdraw multiple ERC20 payments with single TX. payload should signed by SERVICE 
    and user/nifty/stl can run transaction. It will send funds to the requestor and save 
    other parties data to the storage.

    In the input should be full royalty values. to save GAS send data, sorted by ERC20 contract 
    TXes will be saved to avoid double spending
     */
    function withdrawERC20(bytes calldata payload, bytes memory signature) public {

        // (address receiver, ERC20Payment[] memory _erc20paymetsData) = convertValidateERC20Input( payload, signature);
        (ERC20Payment[] memory _erc20paymetsData) = convertValidateERC20Input( payload, signature);

        uint _collectedAmount;
        uint currentAmount;

        uint256 length = _erc20paymetsData.length;
        for (uint i = 0; i < length; i++ ){
            // if next erc20 payment related to the same ERC20 contract then collect amounts, related to the current requestor 

            currentAmount = saveTxDataAndGetRequestorAmount(_erc20paymetsData[i]);
            require(currentAmount > 0, "TX already paid");
            _collectedAmount += currentAmount;

            validateMinter(_erc20paymetsData[i].tokenId);

            emit RoyaltyPaidERC20(_erc20paymetsData[i].TX, _erc20paymetsData[i].erc20,  _msgSender(),  currentAmount);

            if ((_erc20paymetsData.length == i + 1) || (_erc20paymetsData[i].erc20 != _erc20paymetsData[i + 1].erc20)) {
                
                payERC20(_erc20paymetsData[i], _collectedAmount);
                _collectedAmount = 0;
            }
        }
     
    }

    function withdrawETH(bytes calldata payload, bytes memory signature) public {
        (ETHPayment[] memory _ETHpaymetsData) = convertValidateETHInput( payload, signature);

        uint _collectedAmount;
        uint currentAmount;

        for (uint i = 0; i < _ETHpaymetsData.length; i++ ){
            // if next erc20 payment related to the same ERC20 contract then collect amounts, related to the current requestor 

            currentAmount = saveTxDataAndGetRequestorAmountETH(_ETHpaymetsData[i]);
            require(currentAmount > 0, "TX already paid");
            _collectedAmount += currentAmount;

            validateMinter(_ETHpaymetsData[i].tokenId);

            emit RoyaltyPaid(_ETHpaymetsData[i].TX, _msgSender(),  currentAmount);

        }

        _pay(_collectedAmount, _msgSender());     
    }

    /*
    Its just a combine of ERC20 withdraw and ETH withdraw
    */
    function combinedWithdrawUserRoyalty(bytes calldata erc20payload, bytes memory erc20signature, bytes calldata payload, bytes memory signature) external {
        withdrawERC20(erc20payload, erc20signature);
        withdrawETH(payload, signature);
    }

    function payERC20(ERC20Payment memory txData, uint amount) internal {
        
        IERC20Upgradeable erc20c = IERC20Upgradeable(txData.erc20);

        // validation disabled to save 3k gas

        // get this contract balabce to avoid overflow
        // uint balance = erc20c.balanceOf(address(this));
        // throw error if it requests more that in the contract balance
        // require(balance >= amount, "Dont have enough funds");
        require(amount > 0, "Nothing to pay here");

        erc20c.safeTransfer(_msgSender(), amount);

    }

    function getRoyaltyValues(uint amount) internal view returns (uint _beneficiary, uint _user) {
        _beneficiary = amount * beneficiaryPercentage / 10000;
        _user = amount - _beneficiary;
    }

    receive() external payable {
    }

    function _pay(uint256 amount, address receiver) internal {
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function validateSignature(bytes calldata payload, bytes memory signature) internal view {
        address signerAddress = keccak256(payload).toEthSignedMessageHash().recover(signature);
               
        require(signerAddress == _tokenDetector, "Payload must be signed");
    }

    function setTokenDetector(address addr) external onlyOwner {
        _setTokenDetector(addr);
    }

    function _setTokenDetector(address addr) internal {
        emit TokenDetectorSet(_tokenDetector, addr);
        _tokenDetector = addr;

    }

    function setReceiversData(address _beneficiaryAddr, uint256 _beneficiaryPercent) external onlyOwner {

        require(_beneficiaryPercent < 10000, "Too big commission.");
        beneficiary = _beneficiaryAddr;
    
        beneficiaryPercentage = _beneficiaryPercent;

        emit ReceiversDataSet(_beneficiaryAddr, _beneficiaryPercent);

    }

}