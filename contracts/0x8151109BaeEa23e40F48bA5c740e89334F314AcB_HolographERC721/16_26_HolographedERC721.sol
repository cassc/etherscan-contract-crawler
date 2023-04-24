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

/// @title Holograph ERC-721 Non-Fungible Token Standard
/// @dev See https://holograph.network/standard/ERC-721
///  Note: the ERC-165 identifier for this interface is 0xFFFFFFFF.
interface HolographedERC721 {
  // event id = 1
  function bridgeIn(
    uint32 _chainId,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 2
  function bridgeOut(
    uint32 _chainId,
    address _from,
    address _to,
    uint256 _tokenId
  ) external returns (bytes memory _data);

  // event id = 3
  function afterApprove(address _owner, address _to, uint256 _tokenId) external returns (bool success);

  // event id = 4
  function beforeApprove(address _owner, address _to, uint256 _tokenId) external returns (bool success);

  // event id = 5
  function afterApprovalAll(address _sender, address _to, bool _approved) external returns (bool success);

  // event id = 6
  function beforeApprovalAll(address _sender, address _to, bool _approved) external returns (bool success);

  // event id = 7
  function afterBurn(address _owner, uint256 _tokenId) external returns (bool success);

  // event id = 8
  function beforeBurn(address _owner, uint256 _tokenId) external returns (bool success);

  // event id = 9
  function afterMint(address _owner, uint256 _tokenId) external returns (bool success);

  // event id = 10
  function beforeMint(address _owner, uint256 _tokenId) external returns (bool success);

  // event id = 11
  function afterSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 12
  function beforeSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 13
  function afterTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 14
  function beforeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 15
  function afterOnERC721Received(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 16
  function beforeOnERC721Received(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external returns (bool success);

  // event id = 17
  function onIsApprovedForAll(address _wallet, address _operator) external view returns (bool approved);

  // event id = 18
  function contractURI() external view returns (string memory contractJSON);
}