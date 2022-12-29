// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISoulGenesis.sol";

/// @title Soul Genesis sale ✨
/// @author Bitquence <@_bitquence>
/// @dev Delegate ownership to this contract before using
contract SoulGenesisSale is Ownable {
    ISoulGenesis constant SOUL_GENESIS = ISoulGenesis(0x733e534A2B8330DF4Ac10a4F248BbaA81A887492);

    uint256 public WHITELIST_SUPPLY = 1197;
    uint256 public TOKEN_PRICE = 0.05 ether;
    uint256 public MAX_MINT = 1;
    using ECDSA for bytes32;
    address public adminAddress = 0xae87B3506C1F48259705BA64DcB662Ed047575Bb;

    SaleState public saleState;

    enum SaleState {
        Closed,
        Restricted,
        Open
    }

    mapping(address => uint256) public whitelistMints;
    mapping(address => uint256) public amountMinted;

    modifier onlyExternallyOwnedAccount {
        require(msg.sender == tx.origin);
        _;
    }

    function verifiedAddress(bytes memory signature) public view returns(bool){
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(sender);
        address signer = ECDSA.recover(message, signature);
        return signer==adminAddress;
    }

    function purchasePrivate(
        uint256 amount,
        bytes memory signature
    ) public payable onlyExternallyOwnedAccount {
        uint256 currentSupply = SOUL_GENESIS.totalSupply();

        require(verifiedAddress(signature), "Sign not verified");
        require(saleState == SaleState.Restricted, "SG: sale closed");
        require(currentSupply + amount <= WHITELIST_SUPPLY, "SG: mint exceeds max supply");
        require(whitelistMints[msg.sender] + amount <= MAX_MINT, "SG: mint limit exceeded");
        require(msg.value >= TOKEN_PRICE * amount, "SG: insufficient funds sent");

        whitelistMints[msg.sender] += amount;

        SOUL_GENESIS.teamMint(msg.sender, amount);
    }

 

    function purchase(uint256 amount) public payable onlyExternallyOwnedAccount{
       require(saleState == SaleState.Open, "SG: sale closed");
        require(amountMinted[msg.sender] + amount <= MAX_MINT, "SG: mint limit exceeded");
        require(msg.value >= TOKEN_PRICE * amount, "SG: insufficient funds sent");

        amountMinted[msg.sender] += amount;

        SOUL_GENESIS.teamMint(msg.sender, amount);
    }

    function teamMint(address to, uint256 amount) external onlyOwner {
        SOUL_GENESIS.teamMint(to, amount);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        SOUL_GENESIS.setBaseURI(newBaseURI);
    }


    function reclaimOwnership(address newOwner) external onlyOwner {
        SOUL_GENESIS.transferOwnership(newOwner);
    }

    function totSupply() public view returns (uint256){
        return SOUL_GENESIS.totalSupply();
    }

    function setCost(uint256 _newCost) public onlyOwner {
        TOKEN_PRICE = _newCost;
    }

    function setWalletList(uint256 _list) public onlyOwner {
        WHITELIST_SUPPLY = _list;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        MAX_MINT = _newmaxMintAmount;
    }

    function setAdminAddress(address _address) public onlyOwner {
        adminAddress = _address;
    }

    function setSaleState(SaleState newState) external onlyOwner {
        saleState = newState;
    }

    address a1 = 0x66a7E85fC3bbacF0A9D0f81B9F5Bd080BE599D82; 
    address a2 = 0x91C744fa5D176e8c8c2243a952b75De90A5186bc; 
    address a3 = 0xE0D80FC054BC859b74546477344b152941902CB6; 
    address a4 = 0xae87B3506C1F48259705BA64DcB662Ed047575Bb; 
    
      function withdraw() public payable onlyOwner {

       uint256 _sender1 = address(this).balance * 23/100;
       uint256 _sender2 = address(this).balance * 24/100;
       uint256 _sender3 = address(this).balance * 23/100;
       uint256 _sender4 = address(this).balance * 30/100;

        require(payable(a1).send(_sender1));
        require(payable(a2).send(_sender2));
        require(payable(a3).send(_sender3));
        require(payable(a4).send(_sender4));
  }
}