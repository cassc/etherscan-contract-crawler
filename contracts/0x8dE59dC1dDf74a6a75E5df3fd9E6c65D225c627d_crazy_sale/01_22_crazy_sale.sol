pragma solidity ^0.8.4;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/community_interface.sol";


import "../recovery/recovery.sol";


import "../configuration/configuration.sol";

import "../token/token_interface.sol";

import "hardhat/console.sol";


contract crazy_sale is Ownable, recovery , ReentrancyGuard {
    using SafeMath for uint256;
    using Strings  for uint256;

    uint256[]                   public prices = [5e16,4e16,3e16,2e16,1e16,0];
    uint16[]                    public quants = [8,8,8,8,8,1];

    token_interface             public _token;

    uint256                     public _saleStart;
    uint256                     public _presaleStart;

    mapping(address => mapping(uint16=>uint16))  public saleClaimed;
    mapping(address => mapping(uint16=>uint16))  public presaleClaimed;

    uint16 constant            public _maxSupply = 7000;
    uint16                     public _next = 146;
    uint16                     public _clientMint = 200;
    uint16                     public _clientMinted;
    


    address                     _presigner;

    address payable[]           public   _wallets;
    uint16[]                    public   _shares;
    

    event Allowed(address,bool);

     modifier onlyAllowed() {
        require(_token.permitted(msg.sender) || (msg.sender == owner()),"Unauthorised");
        _;
    }

    constructor( token_interface _token_ ,address _signer, address payable[] memory wallets, uint16[] memory shares) {
        require(wallets.length == shares.length,"wallets and shares lengths not equal");
        _token = _token_;
        _presigner = _signer;
       
        uint total = 0;
        for (uint pos = 0; pos < shares.length; pos++) {
            total += shares[pos];
        }
        require (total == 1000, "shares must total 1000");
        _wallets = wallets;
        _shares = shares;
    }

    receive() external payable {
        _split(msg.value);
    }

    function _split(uint256 amount) internal {
        bool sent;
        uint256 _total;
        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = amount * _shares[j] / 1000;
            if (j == _wallets.length-1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            ( sent, ) = _wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
        }
    }

    function SalePrice() public view returns (uint256 price, uint16 tier, uint16 quantity) {
        uint256 nowx = block.timestamp;
        require(nowx > _saleStart,"Sale not started");
        uint256 hoursSinceStart = (nowx - _saleStart) / (2 hours);
        require(hoursSinceStart < prices.length,"Sale over");
        tier = uint16(hoursSinceStart);
        return(prices[hoursSinceStart],tier, quants[hoursSinceStart]);
    }

    function PresalePrice() public view returns (uint256 price, uint16 tier, uint16 quantity) {
        uint256 nowx = block.timestamp;
        require(nowx > _presaleStart,"Presale not started");
        uint256 hoursSinceStart = (nowx - _presaleStart) / (2 hours);
        require(hoursSinceStart < prices.length,"Presale over");
        tier = uint16(hoursSinceStart);
        return(prices[hoursSinceStart],tier, quants[hoursSinceStart]);
    }


    // make sure this respects ec_limit and client_limit
    function mint(uint16 numberOfCards) external payable {
        uint16 maxQuantity;
        uint16 tier;
        uint256 price;
        (price,tier,maxQuantity) = SalePrice();
        uint16 sc = saleClaimed[msg.sender][tier] += numberOfCards;
        require(sc <= maxQuantity,"Number exceeds max sale per address in this tier");
        _mintPayable(numberOfCards, msg.sender, price); 
    }

 
    function mintAdvanced(uint16 numberOfCards, address destination) external onlyAllowed {
        require((_clientMinted += numberOfCards) <= _clientMint ,"All minted or no allowance");
        _mintCards(numberOfCards,destination);
    }


    function mintPresale(uint16 numberOfCards,  bytes memory signature) external payable {
        uint16 maxQuantity;
        uint16  tier;
        uint256 price;
        require(verify(msg.sender,signature) ,"Invalid Presale Secret");
         (price,tier,maxQuantity) = PresalePrice();
        uint16 sc = presaleClaimed[msg.sender][tier] += numberOfCards;
        require(sc <= maxQuantity,"Number exceeds max sale per address in this tier");
        _mintPayable(numberOfCards, msg.sender, price); 
    }

    function _mintPayable(uint16 numberOfCards, address recipient, uint256 price) internal {
        uint256 amountToPay = uint256(numberOfCards) * price;
        require(msg.value >= amountToPay,"price not met");
        _mintCards(numberOfCards,recipient);
        _split(msg.value);
    }

    function _mintCards(uint16 numberOfCards, address recipient) internal {
        require((_next += numberOfCards) < _maxSupply,"This exceeds maximum number of user mintable cards");
        _token.mintCards(numberOfCards,recipient);
    }


    function setSaleDate(uint256 start) external onlyOwner {
        _saleStart = start;
    }

    function setPresaleDate(uint256 start) external onlyOwner {
        _presaleStart = start;
    }

    function setPresigner(address _ps) external onlyOwner {
        _presigner = _ps;
    }

    function verify(
        address signer,
        bytes memory signature
    ) internal  view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        bytes32 hash = keccak256(abi.encode(signer));
        require (signature.length == 65,"Invalid signature length");
        bytes32 sigR;
        bytes32 sigS;
        uint8   sigV;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            sigR := mload(add(signature, 0x20))
            sigS := mload(add(signature, 0x40))
            sigV := byte(0, mload(add(signature, 0x60)))
        }
        
        bytes32 data =  keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(
                data,
                sigV,
                sigR,
                sigS
            );
            
        return
            _presigner == recovered;
    }

 

}