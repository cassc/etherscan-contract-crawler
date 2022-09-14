// SPDX-License-Identifier: MIT
//                       ...`
//                   :sdmdhhdNy.
//                .sNh/.   `ydyM+
//              .sNy.     /m+  sM-
//         .+ymmhyN:    `hh.   .My                        .:-                                           .-.
//       +dmsydy+.-mo  /m+     `MMmo`                     oMM                  -hh`                     yMy
//     .mm:    `/shdMhhh.      -Mo-hN:    .+sso-  +o:  ++ oMM  :oss+.  oo/ss   :yMMo  /sys/      /sys/  yMy `/ss+-
//     mm`         `:NMmhyo/.  yM.  hM`   +Mm  Mh NMo  mM oMM +Mm   Mh MMNso   :hMMs -NMy+sMN- -NMy+sMN yMy NM
//     Nm           .Mom+`-/oydMo   yM.  NMdyyyMM NMo  mM oMM MMyssdMN MM/     :MM` yMd   dMh yMd   dMh oyz smNyo:
//     :Nh.         +N `dy`  .Nh  `sM+   dMh      My .NMs MM- dMh      MM:     :MM-  oMN. .NM  oMN. .NM yMy    dMy
//      `sNh+.      ds   sm--Nh./yNy-    `yNNmMmo /NMNNNM oMN :dMmmMh: MM- /Nd `yNM  omMNMmo   omMNMmo  sNs ymmmNd:
//         +MNmhso//M+---:yMMMNmy/`
//          mm`.:/ossyyyyNMm/-`
//          -Nh.      .omm/
//           .sNdssshmds-
//              .:::-`

pragma solidity ^0.8.7;

contract EulerToolsStorage {

  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes32 value;
  }

  struct BridgeTicket {
    uint256 chainIdDestination;
    uint256 chainIdOrigin;
    bytes32 transactionOrigin;
    uint256 logIndexOrigin;
    address tokenOrigin;
    address tokenDestination;
    uint256 amount;
    address account;
  }

  uint256 public _maxSupply;
  address public _oldToken;
  mapping(bytes32 => bool) public ticketsUsed;
  mapping(uint256 => address) public allowedTokens;
  mapping(address => uint256) public migratedTokens;

  event Migration(address indexed account, uint256 amount);
  event Bridge(address indexed account, uint256 indexed amount, uint256 chainIdOrigin, uint256 chainIdDestination, address tokenDestination);
  event ClaimBridge(address indexed account, uint256 indexed amount,
    uint256 chainIdOrigin, uint256 chainIdDestination, bytes32 transactionOrigin, uint256 logIndexOrigin, address tokenOrigin);
  event AddAllowedToken(uint256 indexed chainId, address indexed token);

  /**
  * @dev This empty reserved space is put in place to allow future versions to add new
  * variables without shifting down storage in the inheritance chain.
  * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  */
  uint256[45] private __gap;
}
