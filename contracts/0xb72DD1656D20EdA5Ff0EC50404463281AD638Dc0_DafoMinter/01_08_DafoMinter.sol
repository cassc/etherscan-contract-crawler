// SPDX-License-Identifier: GPL-3.0

/// @title DafoMinter
import "@openzeppelin/contracts/access/Ownable.sol";
import {IDafoToken} from './interfaces/IDafoToken.sol';
import {IDafoCustomizer} from './interfaces/IDafoCustomizer.sol';

pragma solidity ^0.8.18;

contract DafoMinter is Ownable{

    // The DafoToken ERC721 token contract
    IDafoToken public dafoToken;
    // The DafoCustomizer contract
    IDafoCustomizer public dafoCustomizer;
    // minimum price to be paid for minting
    uint256 public reservePrice;
    bool public mintEnabled;
    address public crossmintAddress;
    address public dafoWithdrawalAddress;

    event AuctionReservePriceUpdated(uint256);

    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        reservePrice = _reservePrice;
        emit AuctionReservePriceUpdated(_reservePrice);
    }

    function initializeParams(address _dafoTokenAddress, address _dafoCustomizerAddress) external onlyOwner {
        dafoToken = IDafoToken(_dafoTokenAddress);
        dafoCustomizer = IDafoCustomizer(_dafoCustomizerAddress);
    }

    function flipMintStatus() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function mintDafoToken(IDafoCustomizer.CustomInput calldata _customInput, address _to) external payable {    
        require(msg.value > reservePrice,"Insuficient ether value");   
        dafoToken.mint(_customInput, _to); 
    }

    function crossmint(address _to, uint256 _tokenId, uint8 _role, uint8 _palette, bool _outline) external payable {      
       require(msg.sender == crossmintAddress);
       require(msg.value > reservePrice,"Insufficient ether value"); 
        IDafoCustomizer.CustomInput memory _customInput = IDafoCustomizer.CustomInput(_tokenId, _role, _palette, _outline);
        dafoToken.mint(_customInput, _to); 
    }

    function setCrossmintAddress(address _crossmintAddress) external onlyOwner {
        crossmintAddress = _crossmintAddress;
    }

    function setDafoWithdrawalAddress(address _dafoWithdrawalAddress) external onlyOwner {
        dafoWithdrawalAddress = _dafoWithdrawalAddress;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = dafoWithdrawalAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}