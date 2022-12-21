// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import "../abstract/ERC20H.sol";

import "../interface/ERC20.sol";
import "../interface/HolographERC20Interface.sol";
import "../interface/HolographInterface.sol";
import "../interface/HolographerInterface.sol";

/**
 * @title Holograph token (aka hToken), used to wrap and bridge native tokens across blockchains.
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph's Bridgeable ERC20 Tokens.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract hToken is ERC20H {
  /**
   * @dev Sample fee for unwrapping.
   */
  uint16 private _feeBp; // 10000 == 100.00%

  /**
   * @dev List of supported Wrapped Tokens (equivalent), on current-chain.
   */
  mapping(address => bool) private _supportedWrappers;

  /**
   * @dev Event that is triggered when native token is converted into hToken.
   */
  event Deposit(address indexed from, uint256 amount);

  /**
   * @dev Event that is triggered when ERC20 token is converted into hToken.
   */
  event TokenDeposit(address indexed token, address indexed from, uint256 amount);

  /**
   * @dev Event that is triggered when hToken is converted into native token.
   */
  event Withdrawal(address indexed to, uint256 amount);

  /**
   * @dev Event that is triggered when hToken is converted into ERC20 token.
   */
  event TokenWithdrawal(address indexed token, address indexed to, uint256 amount);

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external override returns (bytes4) {
    (address contractOwner, uint16 fee) = abi.decode(initPayload, (address, uint16));
    _setOwner(contractOwner);
    _feeBp = fee;
    // run underlying initializer logic
    return _init(initPayload);
  }

  /**
   * @dev Send native token value, get back hToken equivalent.
   * @param recipient Address of where to send the hToken(s) to.
   */
  function holographNativeToken(address recipient) external payable onlyHolographer {
    require(
      (HolographerInterface(holographer()).getOriginChain() ==
        HolographInterface(HolographerInterface(holographer()).getHolograph()).getHolographChainId()),
      "hToken: not native token"
    );
    require(msg.value > 0, "hToken: no value received");
    address sender = msgSender();
    if (recipient == address(0)) {
      recipient = sender;
    }
    HolographERC20Interface(holographer()).sourceMint(recipient, msg.value);
    emit Deposit(sender, msg.value);
  }

  /**
   * @dev Send hToken, get back native token value equivalent.
   * @param recipient Address of where to send the native token(s) to.
   */
  function extractNativeToken(address payable recipient, uint256 amount) external onlyHolographer {
    address sender = msgSender();
    require(ERC20(address(this)).balanceOf(sender) >= amount, "hToken: not enough hToken(s)");
    require(
      (HolographerInterface(holographer()).getOriginChain() ==
        HolographInterface(HolographerInterface(holographer()).getHolograph()).getHolographChainId()),
      "hToken: not on native chain"
    );
    require(address(this).balance >= amount, "hToken: not enough native tokens");
    HolographERC20Interface(holographer()).sourceBurn(sender, amount);
    // HERE WE NEED TO ADD FEE MECHANISM TO EXTRACT xx.xxxx% FROM NATIVE TOKEN AMOUNT
    // THIS SHOULD GO SOMEWHERE TO REWARD CAPITAL PROVIDERS
    uint256 fee = (amount / 10000) * _feeBp;
    // for now we just leave fee in contract balance
    //
    // amount is updated to reflect fee subtraction
    amount = amount - fee;
    recipient.transfer(amount);
    emit Withdrawal(recipient, amount);
  }

  /**
   * @dev Send supported wrapped token, get back hToken equivalent.
   * @param recipient Address of where to send the hToken(s) to.
   */
  function holographWrappedToken(
    address token,
    address recipient,
    uint256 amount
  ) external onlyHolographer {
    require(_supportedWrappers[token], "hToken: unsupported token type");
    ERC20 erc20 = ERC20(token);
    address sender = msgSender();
    require(erc20.allowance(sender, address(this)) >= amount, "hToken: allowance too low");
    uint256 previousBalance = erc20.balanceOf(address(this));
    require(erc20.transferFrom(sender, address(this), amount), "hToken: ERC20 transfer failed");
    uint256 currentBalance = erc20.balanceOf(address(this));
    uint256 difference = currentBalance - previousBalance;
    require(difference >= 0, "hToken: no tokens transferred");
    if (difference < amount) {
      // adjust for fee-based mechanisms
      // this allows for discrepancies to not fail the entire operation
      amount = difference;
    }
    if (recipient == address(0)) {
      recipient = sender;
    }
    HolographERC20Interface(holographer()).sourceMint(recipient, amount);
    emit TokenDeposit(token, sender, amount);
  }

  /**
   * @dev Send hToken, get back native token value equivalent.
   * @param recipient Address of where to send the native token(s) to.
   */
  function extractWrappedToken(
    address token,
    address payable recipient,
    uint256 amount
  ) external onlyHolographer {
    require(_supportedWrappers[token], "hToken: unsupported token type");
    address sender = msgSender();
    require(ERC20(address(this)).balanceOf(sender) >= amount, "hToken: not enough hToken(s)");
    ERC20 erc20 = ERC20(token);
    uint256 previousBalance = erc20.balanceOf(address(this));
    require(previousBalance >= amount, "hToken: not enough ERC20 tokens");
    if (recipient == address(0)) {
      recipient = payable(sender);
    }
    // HERE WE NEED TO ADD FEE MECHANISM TO EXTRACT xx.xxxx% FROM NATIVE TOKEN AMOUNT
    // THIS SHOULD GO SOMEWHERE TO REWARD CAPITAL PROVIDERS
    uint256 fee = (amount / 10000) * _feeBp;
    uint256 adjustedAmount = amount - fee;
    // for now we just leave fee in contract balance
    erc20.transfer(recipient, adjustedAmount);
    uint256 currentBalance = erc20.balanceOf(address(this));
    uint256 difference = currentBalance - previousBalance;
    require(difference == adjustedAmount, "hToken: incorrect new balance");
    HolographERC20Interface(holographer()).sourceBurn(sender, amount);
    emit TokenWithdrawal(token, recipient, adjustedAmount);
  }

  function availableNativeTokens() external view onlyHolographer returns (uint256) {
    if (
      HolographerInterface(holographer()).getOriginChain() ==
      HolographInterface(HolographerInterface(holographer()).getHolograph()).getHolographChainId()
    ) {
      return address(this).balance;
    } else {
      return 0;
    }
  }

  function availableWrappedTokens(address token) external view onlyHolographer returns (uint256) {
    require(_supportedWrappers[token], "hToken: unsupported token type");
    return ERC20(token).balanceOf(address(this));
  }

  function updateSupportedWrapper(address token, bool supported) external onlyHolographer onlyOwner {
    _supportedWrappers[token] = supported;
  }

  /**
   * @dev Temporarily placed to bypass bytecode conflicts
   */
  function isHToken() external pure returns (bool) {
    return true;
  }
}