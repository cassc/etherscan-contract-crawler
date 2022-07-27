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
// ᴅᴇᴘʟᴏʏᴇʀ
//
//
//               built by: cryptoforcharity.io
//                  author: buzzybee.eth
//               SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DonationSplitter.sol";
contract Deployer is Ownable {
  address public immutable implementation;
  address[] private _tokens;

  constructor(address wethAddress) {
    implementation = address(new DonationSplitter());

    _tokens = [wethAddress];
  }

  function genesis(address[] calldata donationAddresses, uint[] calldata donationBasisPoints, address ownerAddress) external returns (address) {
    address payable clone = payable(Clones.clone(implementation));
    DonationSplitter d = DonationSplitter(clone);
    d.initialize(donationAddresses, donationBasisPoints, ownerAddress, _tokens, owner());
    return clone;
  }

  function setTokens(address[] calldata tokens) public onlyOwner {
    _tokens = tokens;
  }
}