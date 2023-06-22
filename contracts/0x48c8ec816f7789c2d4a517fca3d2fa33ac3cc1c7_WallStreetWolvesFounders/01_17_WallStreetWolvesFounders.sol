// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/****************************************
 * @author: @hammm.eth                  *
 * @team:   GoldenX                     *
 ***************************************/

import "./Delegated.sol";
import "./PaymentSplitterMod.sol";
import "./AbstractERC1155Factory.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract WallStreetWolvesFounders is Delegated, AbstractERC1155Factory, PaymentSplitterMod {
    using ECDSA for bytes32;
    using Strings for uint;
    using Counters for Counters.Counter;
    Counters.Counter private counter;

    mapping(uint => Token) public tokens;

    address private signer;

    struct Token {
      uint maxSupply;
      uint price;
      string tokenURI;
      mapping (address => bool) addressMinted;
    }

    enum SaleState {
      paused,
      whale,
      presale,
      publicsale
    }

    SaleState public saleState = SaleState.paused;

    address[] private splitter = [0xed386149321FBd84f0c4e27a1701Ad05eCA32f8A, 0x2d2352a56827515FAf6088c4cDf59befb4d0A67a, 0x5B1DC9219786c7929B4684eF8301bdF4F1d67465];
    uint[] private splitterShares = [3, 70, 27];

    constructor(
      string memory _name, 
      string memory _symbol,
      string memory _tokenURI,
      address _signer
    ) ERC1155(_tokenURI) PaymentSplitterMod (splitter, splitterShares) {
      name_ = _name;
      symbol_ = _symbol;
      signer = _signer;
      addToken(1000, 0.5 ether, _tokenURI);
      
      _mint(0x5B1DC9219786c7929B4684eF8301bdF4F1d67465, 0, 47, "");
      _mint(0x29EEe1Fe81B2b8e81D709fAe36Ce0dE8666b68Bd, 0, 3, "");
    }

  //external payable
  fallback() external payable {}

  function addToken( uint _maxSupply, uint _price, string memory _tokenURI ) public onlyDelegates {
    Token storage t = tokens[counter.current()];
    t.maxSupply = _maxSupply;
    t.price = _price;
    t.tokenURI = _tokenURI;

    counter.increment();
  }  

  function editToken( uint _maxSupply, uint _price, string memory _tokenURI, uint _tokenID ) public onlyDelegates {
    require(exists(_tokenID), "EditToken: Token ID does not exist");
    Token storage t = tokens[_tokenID];
    t.maxSupply = _maxSupply;
    t.price = _price;
    t.tokenURI = _tokenURI;
  }

  function airdrop ( address _address, uint _tokenID, uint _quantity ) external onlyDelegates {
    require( exists(_tokenID), "Airdrop: token does not exist" );
    require( totalSupply(_tokenID) + _quantity <= tokens[_tokenID].maxSupply, "Airdrop: Token supply exceeded" );

    _mint(_address, _tokenID, _quantity, "");
  }

  function mint ( uint _tokenID, uint8 _quantity, bytes memory _signature ) public payable {
    require( saleState != SaleState.paused, "mint: sale is paused" );
    require( exists(_tokenID), "mint: token does not exist" );
    require( totalSupply(_tokenID) + _quantity <= tokens[_tokenID].maxSupply, "mint: Token supply exceeded" );
    require( msg.value >= tokens[_tokenID].price * _quantity, "mint: Incorrect ETH sent" );

    if (saleState == SaleState.whale) {
      require( _quantity >= 10 && _quantity <= 25, "mint: invalid whale quantity");

    } else if (saleState == SaleState.presale) {
      require( verify(_tokenID, _quantity, _signature), "mint: invalid presale address" );
      require( _quantity <= 5, "mint: invalid presale quantity" );
      require( tokens[_tokenID].addressMinted[msg.sender] != true, "mint: presale address already minted" );
      tokens[_tokenID].addressMinted[msg.sender] = true;

    } else if (saleState == SaleState.publicsale) { 
      require( _quantity <= 10, "mint: invalid public sale quantity" );
    }

    _mint(msg.sender, _tokenID, _quantity, "");
  }

  function exists ( uint _tokenID ) public view override returns ( bool ) {
    return _tokenID < counter.current();
  }

  function uri( uint _tokenID ) public view override returns ( string memory ) {
    require( exists(_tokenID), "URI: nonexistent token" );
    return tokens[_tokenID].tokenURI;
  }

  function setSaleState ( SaleState _newSaleState ) external onlyDelegates {
    require( saleState != _newSaleState);
    saleState = _newSaleState;
  }

   function verify( uint _tokenID, uint _quantity,  bytes memory _signature ) private view returns ( bool ) {
        address signerCheck = getAddressSigner( _tokenID.toString(), _quantity.toString(), _signature );

        if (signerCheck == signer) {
            return true;
        } 
        return false;
    }

    function getAddressSigner( string memory _tokenID, string memory _quantity, bytes memory _signature ) private view returns ( address ) {
        bytes32 hash = createHash( _tokenID, _quantity );
        return hash.toEthSignedMessageHash().recover( _signature );
    }

    function createHash( string memory _tokenID, string memory _quantity ) private view returns ( bytes32 ) {
        return keccak256( abi.encodePacked( address(this), msg.sender, _tokenID, _quantity ) );
    }
    
    function setSigner( address _signer ) public onlyOwner{
        signer = _signer;
    }   
}