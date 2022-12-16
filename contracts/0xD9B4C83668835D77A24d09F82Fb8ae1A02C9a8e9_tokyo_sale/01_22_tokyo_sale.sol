pragma solidity ^0.8.4;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/community_interface.sol";


import "../recovery/recovery.sol";


import "../configuration/configuration.sol";

import "../token/token_interface.sol";

//import "hardhat/console.sol";


contract tokyo_sale is configuration, Ownable, recovery , ReentrancyGuard {
    using SafeMath for uint256;
    using Strings  for uint256;

    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    token_interface             _token;

    bool                        public _saleActive;
    bool                        public _presaleActive;

    uint256                     public _presaleSold;

    uint256                     _userMinted;

    uint256                     _ts1;
    uint256                     _ts2;

    address                     public  _communityAddress;

    mapping(uint256 => bool)    public   _claimed;


    IERC20                      immutable public  _ENS;


    mapping (address => uint256)        _presalePerWallet;
    mapping (address => uint256)        _salePerWallet;

    


    event RandomProcessed(uint stage,uint256 randUsed_,uint256 _start,uint256 _stop,uint256 _supply);
    event ENSPayment(uint256 quantity, uint256 value);
    event Allowed(address,bool);

     modifier onlyAllowed() {
        require(_token.permitted(msg.sender) || (msg.sender == owner()),"Unauthorised");
        _;
    }

    constructor( token_interface _token_ ,IERC20 _ens, address payable[] memory wallets, uint256[] memory shares) {
        require(wallets.length == shares.length,"wallets and shares lengths not equal");
        _token = _token_;
        _ENS = _ens;
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

    function _split20(uint256 amount) internal {
        uint256 _total;
        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = amount * _shares[j] / 1000;
            if (j == _wallets.length-1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            require(IERC20(_ENS).transferFrom(msg.sender,_wallets[j], _amount),"Failed to send ENS tokens");
        }
    }

    uint256  maMinted;
    function mintAdvanced(uint256 number, address destination) external onlyAllowed {
        require((maMinted += number) <= _clientMint ,"All minted or no allowance");
        _mintCards(number,destination);
    }

    function mintPresaleWithENS(uint256 numberOfCards,  bytes memory signature) external  {
        require(verify(msg.sender,signature) ,"Invalid Presale Secret");
        require(checkPresaleIsActive(),"presale not open");
        uint256 cost = _ensPresalePrice * numberOfCards;
        require (_ENS.balanceOf(msg.sender) >= cost,"You do not hold enough ENS");
        require((_presalePerWallet[msg.sender] += numberOfCards) <= _presalePerAddress,"Number exceeds max presale per address");
        require( (_presaleSold += numberOfCards)<= _maxPresaleSupply,"Too many discount tokens claimed");
        _mintENS(numberOfCards, cost);
    }

    function mintSaleWithENS(uint256 numberOfCards) external  {
        require(checkSaleIsActive(),"sale not open");
        uint256 cost = _ensSalePrice * numberOfCards;
        require (_ENS.balanceOf(msg.sender) >= cost,"You do not hold enough ENS");
        require((_salePerWallet[msg.sender] += numberOfCards) <= _salePerAddress,"Number exceeds max sale per address");
        _mintENS(numberOfCards, cost);
    }

    function _mintENS(uint256 numberOfCards, uint256 ensToTake) internal {
        require (_ENS.allowance(msg.sender,address(this)) >= ensToTake, "Approval not set");
        _split20(ensToTake);
        _mintCards(numberOfCards, msg.sender);
    }


    // make sure this respects ec_limit and client_limit
    function mint(uint256 numberOfCards) external payable {
        require(checkSaleIsActive(),"sale is not open");
        require((_salePerWallet[msg.sender] += numberOfCards) <= _salePerAddress,"Number exceeds max sale per address");
        _mintPayable(numberOfCards, msg.sender, _fullPrice); 
    }

    function mintPresale(uint256 numberOfCards,  bytes memory signature) external payable {
        require(verify(msg.sender,signature) ,"Invalid Presale Secret");
        require(checkPresaleIsActive(),"presale is not open");
        require((_presalePerWallet[msg.sender] += numberOfCards) <= _presalePerAddress,"Number exceeds max presale per address");
        require( (_presaleSold += numberOfCards)<= _maxPresaleSupply,"Too many discount tokens claimed");
        _mintPayable(numberOfCards, msg.sender, _discountPrice); 
    }

    function _mintPayable(uint256 numberOfCards, address recipient, uint256 price) internal {
        require(msg.value >= numberOfCards.mul(price),"price not met");
        _mintCards(numberOfCards,recipient);
        _split(msg.value);
    }

    function _mintCards(uint256 numberOfCards, address recipient) internal {
        require((_userMinted += numberOfCards) < _maxSupply,"This exceeds maximum number of user mintable cards");
        _token.mintCards(numberOfCards,recipient);
    }

    function setSaleStatus(bool active) external onlyOwner {
        _saleActive = active;
    }

    function setPresaleStatus(bool active) external onlyOwner {
        _presaleActive = active;
    }

    function setSaleDates(bool timedSale, uint256 start, uint256 end) external onlyOwner {
        _timedSale = timedSale;
        _saleStart = start;
        _saleEnd   = end;
    }
    function setPresaleDates(bool timedSale, uint256 start, uint256 end) external onlyOwner {
        _timedPresale = timedSale;
        _presaleStart = start;
        _presaleEnd   = end;
    }

    function checkSaleIsActive() public view returns (bool) {
        if (_saleActive) return true;
        if (_timedSale && (_saleStart <= block.timestamp) && (_saleEnd >= block.timestamp)) return true;
        return false;
    }

    function checkPresaleIsActive() public view returns (bool) {
        if (_presaleActive) return true;
        if (_timedPresale && (_presaleStart <= block.timestamp) && (_presaleEnd >= block.timestamp)) return true;
        return false;
    }

    function verify(
        address signer,
        bytes memory signature
    ) internal  pure returns (bool) {
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

    // function tellEverything(address addr) external view returns (theKitchenSink memory) {
    //     // if community module active - get the community.taken[msg.sender]

    //     token_interface.TKS memory tokenData = _token.tellEverything();

    //     uint256 community_claimed;
    //     if (_communityAddress != address(0)) {
    //         community_claimed = community_interface(_communityAddress).community_claimed(addr);
    //     }

    //     return theKitchenSink(
    //     _maxSupply,
    //     tokenData._mintPosition,
    //     _wallets,
    //     _shares,
    //     _fullPrice,
    //     _discountPrice,
    //     _timedPresale,
    //     _presaleStart,
    //     _presaleEnd,
    //     _timedSale,
    //     _saleStart,
    //     _saleEnd, 
    //     _ensSalePrice,
    //     _ensPresalePrice,
    //     tokenData._lockTillSaleEnd,

        
    //     _maxFreeEC,
    //     _totalFreeEC,
        
    //     _maxDiscount,
    //     _totalDiscount,

    //     _freePerAddress,
    //     _discountedPerAddress,
    //     _tokenPreRevealURI,
    //     _signer,

    //     checkPresaleIsActive(),
    //     checkSaleIsActive(),
    //     checkSaleIsActive() && _dustMintAvailable,

    //     _freeClaimedPerWallet[addr],
    //     _discountedClaimedPerWallet[addr],

    //     address(_ENS),

    //     _maxPerSaleMint,

    //     community_claimed,

    //     tokenData._randomReceived,
    //     tokenData._secondReceived,
    //     tokenData._randomCL,
    //     tokenData._randomCL2,
    //     tokenData._ts1,
    //     tokenData._ts2

    //     );
    // }

}