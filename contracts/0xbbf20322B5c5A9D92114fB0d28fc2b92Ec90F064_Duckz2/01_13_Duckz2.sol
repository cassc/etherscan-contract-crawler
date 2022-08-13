// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Duckz2 is ERC721A, Ownable {
    using SafeMath for uint256;
    
    //Sale States
    bool public isPresaleActive = false;
    bool public isBreadmintActive = false;
    bool public isPublicSaleActive = false;
    mapping (address => uint256) public voucherId;
    mapping (address => uint256) public duckMints;
    mapping (address => uint256) public allowListMints;
    
    //Privates
    string private _baseURIextended;  
    address private signer = 0x9A936666bA976722dDB109ba4EAB82dE2A253BF2;
    address private payoutWallet1 = 0x7f504FdbdD987fd1E0390DCEa0f3c9D6A4b8c7e3;
    address private payoutWallet2 = 0xEEe92B57337818A6D4718a8A3Ec092D3776e7d42;
    address private payoutWallet3 = 0x5c1F8EBA81507c2A0D83e6DE84cb083f2Fac98A7;
    address private payoutWallet4 = 0x857b371e3318b9fbfe13C04001FA4563Ff931cD2;
    address private payoutWallet5 = 0xa02291Bd4ccA0B604c85FF63FA0357E7d840Dd74;
    address private payoutWallet6 = 0xa2C219Eb7e10439a21E7F38E77DA661eb18295AF;
    address private payoutWallet7 = 0x87BB217C7B61f1b37037fc2612589E0B2BD83324;
    address private payoutWallet8 = 0x4F4c9D8F3424c56eC71835868aF042B2a5429c34;
    address private advisorWallet1 = 0xD0322cd77b6223F777b254E7f18FA55D74756B52;
    address private advisorWallet2 = 0x29e01eC68521FA1c3bd685aA4aDa59FAe1e7C048;

    //Constants
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant RESERVE_COUNT = 100;
    uint256 public constant PRICE_PER_TOKEN = 0.025 ether;
    uint256 public constant SALE_PRICE = 0.0125 ether;
    
    constructor() ERC721A("HypnoDuckzGen2", "DUCKZ2") {
    }

    //Mint flow
    function startPresale() external onlyOwner {
        isPresaleActive = true;
        isBreadmintActive = true;
    }

    function startPublicSale() external onlyOwner {
        isPresaleActive = false;
        isPublicSaleActive = true;
    }

    function endMint() external onlyOwner {
        isPublicSaleActive = false;
        isBreadmintActive = false;
    }

    //Presale
    function setIsPresaleActive(bool _isPresaleActive) external onlyOwner {
        isPresaleActive = _isPresaleActive;
    }

    function setIsBreadmintActive(bool _isBreadmintActive) external onlyOwner {
        isBreadmintActive = _isBreadmintActive;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) private pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    //Bread minting
    function mintBread(uint256 _voucherId, address _address, uint256 _amount, bytes calldata _voucher) external {
        uint256 ts = totalSupply();
        require(isBreadmintActive, "Breadmint is not active");
        require(voucherId[_address] == _voucherId, "Bad voucherId");
        require(ts + _amount < MAX_SUPPLY + 1, "Purchase would exceed max tokens");
        require(msg.sender == _address, "Not your voucher");

        bytes32 hash = keccak256(
            abi.encodePacked(_voucherId, _address, _amount, "bread")
        );
        require(_verifySignature(signer, hash, _voucher), "Invalid voucher");

        voucherId[_address]++;
        _safeMint(_address, _amount);
    }

    //Duck sale minting
    function mintSale(uint256 _amount, uint256 _max, address _address, bytes calldata _voucher) external payable {
        uint256 ts = totalSupply();
        require(isPresaleActive, "Presale is not active");
        require(duckMints[_address] + _amount < _max + 1, "Over mint limit");
        require(ts + _amount < MAX_SUPPLY + 1, "Purchase would exceed max tokens");
        require(msg.value + 1 > SALE_PRICE * _amount, "Ether value sent is not correct");
        require(msg.sender == _address, "Not your voucher");

        bytes32 hash = keccak256(
            abi.encodePacked(_max, _address, "salemint")
        );
        require(_verifySignature(signer, hash, _voucher), "Invalid voucher");

        duckMints[_address] += _amount;
        _safeMint(msg.sender, _amount + (_amount / 3));
    }

    //Allowlist minting
    function mintAllowList(uint256 _amount, address _address, bytes calldata _voucher) external payable {
        uint256 ts = totalSupply();
        require(isPresaleActive, "Presale is not active");
        require(allowListMints[_address] + _amount < 4, "Over mint limit");
        require(ts + _amount < MAX_SUPPLY + 1, "Purchase would exceed max tokens");
        require(msg.value + 1 > PRICE_PER_TOKEN * _amount , "Ether value sent is not correct");
        require(msg.sender == _address, "Not your voucher");

        bytes32 hash = keccak256(
            abi.encodePacked(_address, "allowlist")
        );
        require(_verifySignature(signer, hash, _voucher), "Invalid voucher");

        allowListMints[_address] += _amount;
        if (_amount == 3) {
            _safeMint(_address, 4);
        }
        else {
            _safeMint(_address, _amount);
        }
    }
    //
    
    //Public Minting
    function setPublicSaleState(bool _isPublicSaleActive) external onlyOwner {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function mintNFT(uint256 _amount, address _address) external payable {
        uint256 ts = totalSupply();
        require(tx.origin == msg.sender, "No contracts");
        require(isPublicSaleActive, "Public sale is not active");
        require(_amount < 4, "Over mint limit");
        require(ts + _amount < MAX_SUPPLY + 1, "Purchase would exceed max tokens");
        require(msg.value + 1 > PRICE_PER_TOKEN * _amount , "Ether value sent is not correct");
        require(msg.sender == _address, "Bad address");

        if (_amount == 3 && ts + 4 < MAX_SUPPLY + 1) {
            _safeMint(_address, 4);
        }
        else {
            _safeMint(_address, _amount);
        }
    }
    //

    //Overrides
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 555;
    }
    //

    function reserve() external onlyOwner {
        require(totalSupply() == 0, "Tokens already reserved");
        _safeMint(msg.sender, RESERVE_COUNT);
    }
    
    //Withdraw balance
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        //Gross
        payable(advisorWallet1).transfer(balance*25/1000);
        payable(advisorWallet2).transfer(balance*25/1000);
        uint256 newBalance = address(this).balance;
        //Gross
        payable(payoutWallet2).transfer(balance*105/1000);
        payable(payoutWallet3).transfer(balance*8/100);
        payable(payoutWallet4).transfer(balance*5/100);
        //Net
        payable(payoutWallet5).transfer(newBalance*5/100);
        payable(payoutWallet6).transfer(newBalance*5/100);
        payable(payoutWallet7).transfer(newBalance*15/1000);
        payable(payoutWallet8).transfer(newBalance*1/100);
        balance = address(this).balance;
        payable(payoutWallet1).transfer(balance);
    }
    //
}