// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import './Delegated.sol';

interface IERC20Withdraw{
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721Withdraw{
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IMasterCats{
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable;
}

interface IClaimed{
  function claimed( address ) external returns( uint );
}

contract MasterCatsMint is Delegated{
  struct MintConfig{
    uint64 ethPrice;
    uint16 freeMints;
    uint16 maxOrder;

    bool isMintActive;
    bool isFreeMintActive;
  }

  MintConfig public CONFIG = MintConfig(
    0.019 ether, //ethPrice
        1,
       10,
    false,
    false
  );

  IClaimed public CLAIMS = IClaimed(0x784b2Bf7e10FFdbE5647BAC4FF71144D0Be044c1);
  IMasterCats public PRINCIPAL = IMasterCats(0xF03c4e6b6187AcA96B18162CBb4468FC6E339120);
  string public name = "Master Cats Mint";
  string public symbol = "MCM";

  mapping(address => uint16) public claimed;

  constructor()
    Delegated(){
  }

  function mint( uint16 quantity ) external payable{
    MintConfig memory cfg = CONFIG;
    require( cfg.isMintActive, "sale is not active" );
    require( cfg.maxOrder >= quantity, "order too big" );

    ( uint16 paid, uint16 free, uint16 claims ) = calculateQuantities(msg.sender, quantity);
    require(msg.value >= paid * cfg.ethPrice, "insufficient funds" );

    if( free > 0 || claims > 0 ){
      claimed[ msg.sender ] = claims + free;
    }

    PRINCIPAL.mintTo{ value: msg.value }( _asArray( quantity ), _asArray( msg.sender ));
  }

  function setConfig( MintConfig calldata newConfig ) external onlyDelegates{
    CONFIG = newConfig;
  }

  function setPrincipal( IMasterCats newAddress ) external onlyDelegates{
    PRINCIPAL = newAddress;
  }

  //withdraw
  function withdraw() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "no funds available");
    Address.sendValue(payable(owner()), totalBalance);
  }

  function withdraw(address token) external onlyDelegates{
    IERC20Withdraw erc20 = IERC20Withdraw(token);
    erc20.transfer(owner(), erc20.balanceOf(address(this)) );
  }

  function withdraw(address token, uint256[] calldata tokenId) external onlyDelegates{
    for( uint256 i = 0; i < tokenId.length; ++i ){
      IERC721Withdraw(token).transferFrom(address(this), owner(), tokenId[i] );
    }
  }

  function calculateQuantities( address account, uint16 quantity ) public returns( uint16, uint16, uint16 ){
    MintConfig memory cfg = CONFIG;

    //free mint is not active
    if( !cfg.isFreeMintActive )
      return (quantity, 0, 0);


    uint16 claims = claimed[ msg.sender ];
    if( claims == 0 && address(CLAIMS) != address(0)){
      claims = uint16(CLAIMS.claimed( account ));
    }

    //no free mints remaining
    if( claims >= cfg.freeMints )
      return (quantity, 0, claims);


    uint16 free = cfg.freeMints - claims;
    if( quantity > free ){
      //use remaining free
      uint16 paid = quantity - free;
      return (paid, free, claims);
    }
    else{
      //total quantity is free
      return (0, quantity, claims);
    }
  }

  function calculateTotal( address account, uint16 quantity ) external returns( uint256 ){
    ( uint16 paid, uint16 free, uint16 claims ) = calculateQuantities(account, quantity);
    return paid * CONFIG.ethPrice;
  }


  function _asArray(address element) private pure returns (address[] memory array) {
    array = new address[](1);
    array[0] = element;
  }

  function _asArray(uint16 element) private pure returns (uint16[] memory array) {
    array = new uint16[](1);
    array[0] = element;
  }
}