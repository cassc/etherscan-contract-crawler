// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Delegated.sol";

interface IERC20Withdraw{
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721Withdraw{
  function transferFrom(address from, address to, uint256 tokenId) external;
}

contract ERC20Delegated is Delegated, Pausable, ERC20 {
  using Address for address;

  constructor()
    Delegated()
    ERC20( "ERC20Delegated", "ERC20D" ) {}

  receive() external payable {}

  function name() public view virtual override returns (string memory) {
    return "Wall Street Wolves Coin";
  }

  function symbol() public view virtual override returns (string memory) {
    return "WSW";
  }

  //withdraw
  function withdraw() external onlyOwner {
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "no funds available");
    Address.sendValue(payable(owner()), totalBalance);
  }

  function withdraw(address token) external onlyDelegates whenNotPaused returns (bool){
    IERC20Withdraw erc20 = IERC20Withdraw(token);
    return erc20.transfer(owner(), erc20.balanceOf(address(this)) );
  }

  function withdraw(address token, uint256[] calldata tokenIds) external onlyDelegates whenNotPaused{
    for( uint256 i = 0; i < tokenIds.length; ++i ){
      IERC721Withdraw(token).transferFrom(address(this), owner(), tokenIds[i] );
    }
  }

  //delegated
  function burnFrom( uint quantity, address account ) external onlyDelegates{
    _burn( account, quantity );
  }

  function mintTo(address _to, uint _amount) external onlyDelegates {
    _mint(_to, _amount);
  }

  //overrides
  function transfer(address to, uint256 amount) public override whenNotPaused returns (bool){
    super.transfer(to, amount);
    return true;
  }

  function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool){
    super.transferFrom(from, to, amount);
    return true;
  }

  function pause() external onlyDelegates{
    _pause();
  }

  function unpause() external onlyDelegates{
    _unpause();
  }
}