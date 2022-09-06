// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import './Delegated.sol';
import './Signed.sol';

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

contract MasterCatsProxy is Delegated, Signed{
  using Address for address;

  struct MintConfig{
    uint16 maxClaims;
    bool isActive;
  }

  IMasterCats public PRINCIPAL = IMasterCats(0xF03c4e6b6187AcA96B18162CBb4468FC6E339120);
  string public name = "Master Cats Proxy";
  string public symbol = "MCP";

  mapping(address => uint) public claimed;

  MintConfig public CONFIG = MintConfig(
    1,
    false
  );

  constructor()
    Delegated()
    Signed( 0x41C9E80FAa5E12Ac1d61549267fB497041f0EFb8 ){
  }

  //payable
  function freeMint( uint16 quantity, bytes calldata signature ) external payable{
    MintConfig memory cfg = CONFIG;

    require( cfg.isActive, "sale is not active" );
    require( claimed[ msg.sender ] + quantity <= cfg.maxClaims,  "don't be greedy" );
    require( _isAuthorizedSigner( "1", signature ), "not authorized for badge mints" );

    PRINCIPAL.mintTo{ value: msg.value }( _asArray( quantity ), _asArray( msg.sender ));
  }

  function setConfig( MintConfig calldata newConfig ) external onlyDelegates{
    CONFIG = newConfig;
  }

  function setPrincipal( IMasterCats newAddress ) external onlyDelegates{
    PRINCIPAL = newAddress;
  }

  function setSigner( address newSigner ) external onlyDelegates {
    _setSigner( newSigner );
  }

  function _asArray(address element) private pure returns (address[] memory array) {
    array = new address[](1);
    array[0] = element;
  }

  function _asArray(uint16 element) private pure returns (uint16[] memory array) {
    array = new uint16[](1);
    array[0] = element;
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
}