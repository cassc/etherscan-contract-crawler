// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import './library/Initializable.sol';


contract Vault is Initializable {
    using SafeERC20 for IERC20;
    address private _exchange;
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ExchangeAddressChanged(address indexed previousExchange , address indexed newExchange);

    modifier onlyExchange() {
        require(_exchange==msg.sender, "ExchangeVault: Not Exchange");
        _;
    }

    modifier onlyOwner() {
        require(_owner ==msg.sender,"ExchangeVault: only owner");
        _;
    }

    function initialize(address exchange_,address owner_)external initializer {
        _exchange = exchange_;
        _owner = owner_;
    }
  
    function balanceOf(IERC20 _token ) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function owner() external view returns (address ) {
        return _owner;
    }

    function exchange() external view returns (address ) {
         return _exchange;
    }

    function safeTokenTransfer(IERC20 _token, address _to, uint256 _amount) external  onlyExchange {
        uint256 tokenBal = IERC20(_token).balanceOf(address(this));
        require(tokenBal >= _amount, "TokenVault: insufficient balance");
        IERC20(_token).transfer(_to, _amount);
    }

    function changeExchangeAddress(address _newexchange) external onlyOwner {
        emit ExchangeAddressChanged(_exchange,_newexchange);
        _exchange = _newexchange;
       
    }

    function transferOwnership(address _newOwner) external onlyOwner {
      emit OwnershipTransferred( _owner,  _newOwner);
      _owner = _newOwner;
    }

}