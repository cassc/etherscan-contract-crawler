//
//                       ▄██████████▄▄
//                   ╓██████████████████▄
//                  ███████████████████▀
//                ╓█████████▀╙  └╙▀██▀
//               ╒███████▀
//               ███████▌
//               ███████            ╗╬▒▒▒▒╬▒▒▒╖
//               ███████▌          ╚▒▒▒▒▒▒▒▒▒▒▒
//                ████████          ╚▒▒▒▒▒▒▒▒╬
//                 ██████████▄▄▄▄▓█   ╙╠▒▒▒╩
//                 ▀████████████████   ╙╜
//                   ╙████████████████
//                       └▀███████▀▀└
//                  ᴛʜᴇ ᴄʀʏᴘᴛᴏ ғᴏʀ ᴄʜᴀʀɪᴛʏ 
// █▀▀ █▀█ █▀█ █▀▄   ▄▀█ █   █   █▀█ █▀▀ ▄▀█ ▀█▀ █▀█ █▀█
// █▄█ █▄█ █▄█ █▄▀   █▀█ █▄▄ █▄▄ █▄█ █▄▄ █▀█  █  █▄█ █▀▄
//
//
//               built by: cryptoforcharity.io
//                  author: buzzybee.eth
//               SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

error TransferFailed();

contract DonationSplitter is Initializable, OwnableUpgradeable {
  Charity[] private _charities;
  address private _owner;
  address private _weth;
  address[] private _tokens;
  uint _ownerCut;

  struct Charity {
    address account;
    uint basis;
  }

  error InvalidInputs();
  function initialize(
    address[] calldata charities,
    uint[]    calldata basisPoints,
    address            owner,
    address[] calldata tokens,
    address            controller
  ) initializer public {
    if (charities.length != basisPoints.length) revert InvalidInputs();

    _ownerCut = 10000;

    for (uint i = 0; i < charities.length; i++) {
      _charities.push(Charity(charities[i], basisPoints[i]));
      _ownerCut -= basisPoints[i];
    }

    _owner = owner;
    _weth = tokens[0];
    _tokens = tokens;

    __Ownable_init();
    transferOwnership(controller);
  }

  receive () external payable {
    uint bal = address(this).balance;
    for (uint i = 0; i < _charities.length; i++) {
      (bool success,) = _charities[i].account.call{value: bal * _charities[i].basis / 10000}("");
      if (success == false) revert TransferFailed();
    }

    (bool ownerSuccess,) = _owner.call{value: address(this).balance}("");
    if (ownerSuccess == false) revert TransferFailed();
  }


  function withdrawWETH() external {
    _withdrawERC20(_weth);
  }

  function withdrawTokens() external {
    for(uint i=0; i<_tokens.length; i++) {
      _withdrawERC20(_tokens[i]);
    }
  }

  function updateTokens(address[] calldata tokens) external onlyOwner {
    _tokens = tokens;
    _weth = _tokens[0];
  }

  function getTokens() external view returns (address[] memory) {
    return _tokens;
  }

  function _withdrawERC20(address id) private {
    uint bal = IERC20(id).balanceOf(address(this));

    for (uint i = 0; i < _charities.length; i++) {
      _transferERC20(
        id,
        _charities[i].account,
        bal * _charities[i].basis / 10000
      );
    }

    _transferERC20(id, _owner, IERC20(id).balanceOf(address(this)));
  }

  function _transferERC20(address id, address dest, uint value) private {
    if (value == 0) {
      value = IERC20(id).balanceOf(address(this));
    }

    if (value == 0) {
      return;
    }

    IERC20(id).transfer(dest, value);
  }
}