// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract OvisSubscription is Ownable {
   
     using ECDSA for bytes32;

    address public signerAddress;
    
    mapping(address => bool) public whitelistedCurrencies;

    mapping(uint256 => AcquisitionInfo) public subscriptions;

    mapping(uint256 => AcquisitionInfo) public hints;

    struct AcquisitionInfo{
        address buyer;
        uint256 acquisitionTimestamp;
        address currency;
        uint256 cost;
    }
    

    event SignerUpdated(address oldSignerAddress, address newSignerAddress);
    
    event SubscriptionSet(
        address indexed buyer,
        uint256 id,
        uint256 acquisitionTimestamp,
        address currency,
        uint256 cost
    );

    event HintSet(
        address indexed buyer,
        uint256 id,
        uint256 acquisitionTimestamp,
        address currency,
        uint256 cost
    );


    constructor(address _signerAddress){
        signerAddress = _signerAddress;
    }


    function updateSignerAddress(address _signerAddress) external onlyOwner {
        emit SignerUpdated(signerAddress, _signerAddress);
        signerAddress = _signerAddress;
    }

    function subscribe(uint256 id, address currency, uint256 price, bytes calldata signature) external payable {
        
        
        bytes32 _messageHash = keccak256(abi.encodePacked(msg.sender, id, currency, price));

        require(
            signerAddress == _messageHash.toEthSignedMessageHash().recover(signature),
            "Signer address mismatch."
        );

        if(currency == address(0)){
            require(msg.value == price,"amount mismatch");
        } else{
            IERC20(currency).transferFrom(msg.sender, address(this), price);
        }

        subscriptions[id] = AcquisitionInfo(msg.sender,block.timestamp,currency,price);

        emit SubscriptionSet(msg.sender, id, block.timestamp, currency, price);

    }

    function hint(uint256 id, address currency, uint256 price, bytes calldata signature) external payable {
        
        
        bytes32 _messageHash = keccak256(abi.encodePacked(msg.sender, id, currency, price));

        require(
            signerAddress == _messageHash.toEthSignedMessageHash().recover(signature),
            "Signer address mismatch."
        );

        if(currency == address(0)){
            require(msg.value == price,"amount mismatch");
        } else{
            IERC20(currency).transferFrom(msg.sender, address(this), price);
        }

        hints[id] = AcquisitionInfo(msg.sender,block.timestamp,currency,price);

        emit HintSet(msg.sender, id, block.timestamp, currency, price);

    }

    function setWhitelistedCurrency(address currency,bool toggle) external onlyOwner{
        whitelistedCurrencies[currency] = toggle;
    }

    function withdraw(address withdrawalAddress, uint256 amount) external onlyOwner{
        payable(withdrawalAddress).transfer(amount);
    }

    function withdrawERC20(address withdrawalAddress,address currency, uint256 amount) external onlyOwner{
        IERC20(currency).transfer(withdrawalAddress, amount);
    }

}