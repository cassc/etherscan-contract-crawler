// SPDX-License-Identifier: MIT
// @FritzNFT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Juiceboxes is ERC721A, Ownable {
    //Sale States
    uint256 public mintStart = 1662937200 - 1;
    mapping (address => uint256) public mintClaimed;
    mapping (address => uint256) public publicMints;
    
    //Privates
    string private _baseURIextended;
    address private signer = 0x9fdE17Ed72a828b6898e6C7020221D626f7b8dd3;
    address private payoutWallet = 0xEf8ACC51b6411af79FFdaD8182394F0d7792445b;
    
    //Constants
    uint256 public constant MAX_SUPPLY = 1112; //1111 + 1 gas
    uint256 public constant MAX_POINT_SUPPLY = 576; //555 + 20 reserve + 1 gas
    uint256 public constant PRICE_PER_TOKEN = 0.33 ether;
    uint256 public constant MAX_PER_TXN = 6; //5 + 1 gas
    
    constructor() ERC721A("JuiceboxStudios", "JBS") {
    }

    //Airdrop
    function airdrop(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        require(totalSupply() < MAX_POINT_SUPPLY, "Tokens already airdropped");
        require (_addresses.length == _amounts.length, "Bad Arrays");
        for (uint256 i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], _amounts[i]);
        }
    }

    //Point Minting
    function setMintStart(uint256 _mintStart) external onlyOwner {
        mintStart = _mintStart;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function mintWithPoint(uint256 _amount, address _address, uint256 _points, bool _topHolder, bytes calldata _voucher) external payable {
        uint256 mintsClaimed = mintClaimed[_address];
        require(block.timestamp > mintStart, "Point minting not started");
        require(block.timestamp < mintStart + 86401, "Sale minting is over");
        require(mintsClaimed + _amount < 4, "Over mint allowance");
        require(totalSupply() + _amount < MAX_POINT_SUPPLY, "Purchase would exceed max tokens");
        uint256 price = PRICE_PER_TOKEN * _amount;
        //First sale gets discount
        if (mintsClaimed == 0) {
            price -= (_points * .025 ether);
        }
        require(msg.value + 1 > price, "Ether value sent is not correct");
        require(msg.sender == _address, "Not your voucher");

        bytes32 hash = keccak256(
            abi.encodePacked(_address, _points, _topHolder, "points")
        );
        require(_verifySignature(signer, hash, _voucher), "Invalid voucher");

        if (block.timestamp < mintStart + 43201) {
            require(_topHolder, "Only top 555 holders may mint during the first 12 hours");
        }
        else {
            uint256 requiredPoints = 3 - (block.timestamp - (mintStart + 43200)) / 10800; // 4 - 1 gas
            require(_topHolder || _points > requiredPoints, "Not enough points to mint yet");
        }

        mintClaimed[_address] += _amount;
        _safeMint(_address, _amount);
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) private pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function pointsRequired() external view returns (uint256) {
        require(pointMintActive(), "Point minting not active");
        if (block.timestamp < mintStart + 43201) {
            return 13;
        }
        return 4 - (block.timestamp - (mintStart + 43200)) / 10800;
    }

    function pointMintActive() public view returns (bool) {
        return (block.timestamp > mintStart && block.timestamp < mintStart + 86401);
    }
    //
    
    //Public Minting
    function mintNFT(uint256 _amount, address _address) external payable {
        uint256 ts = totalSupply();
        require(tx.origin == msg.sender, "No contracts");
        require(block.timestamp > mintStart + 86400, "Public sale is not active");
        require(ts + _amount < MAX_SUPPLY, "Purchase would exceed max tokens");
        require(msg.value + 1 > PRICE_PER_TOKEN * _amount, "Ether value sent is not correct");
        require(_amount < MAX_PER_TXN, "Max 5 per txn");

        _safeMint(_address, _amount);
    }

    function publicMintActive() external view returns (bool) {
        return (block.timestamp > mintStart + 86400);
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
        return 1;
    }
    //

    function reserve() external onlyOwner {
        require(totalSupply() == 0, "Tokens already reserved");
        _safeMint(payoutWallet, 20);
    }
    
    //Withdraw balance
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(payoutWallet).transfer(balance);
    }
    //
}