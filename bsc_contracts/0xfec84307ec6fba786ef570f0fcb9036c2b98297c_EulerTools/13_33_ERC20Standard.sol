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

import "./draft-ERC20PermitUpgradeable.sol";
import "./EulerContract.sol";

contract ERC20Standard is ERC20PermitUpgradeable, EulerContract {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  function __ERC20Standard_init(string memory name, string memory symbol, address globalStorage) internal onlyInitializing {
    require(bytes(name).length > 0, 'NAME_REQUIRED');
    require(bytes(symbol).length > 0, 'SYMBOL_REQUIRED');

    __ERC20_init(name, symbol);
    __ERC20Permit_init(name);
    __EulerContract_init(globalStorage);
  }

  function supportsInterface(bytes4 interfaceId) public view override virtual returns (bool) {
    return interfaceId == type(IERC20Upgradeable).interfaceId ||
      interfaceId == type(IERC20PermitUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
  uint256[50] private __gap;
}
