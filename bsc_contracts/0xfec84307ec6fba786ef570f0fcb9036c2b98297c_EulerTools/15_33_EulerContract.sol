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

import "./28_33_PausableUpgradeable.sol";
import "./26_33_IManagerTax.sol";
import "./25_33_IGlobalStorage.sol";
import "./20_33_IDexAgregator.sol";
import "./29_33_ProxyableUpgradeable.sol";

abstract contract EulerContract is ProxyableUpgradeable, PausableUpgradeable {

  bytes32 public constant TREASURY = keccak256("TREASURY");
  bytes32 public constant WETH = keccak256("WETH");
  bytes32 public constant MANAGER_TAX = keccak256("MANAGER_TAX");
  bytes32 public constant DEX_AGREGATOR = keccak256("DEX_AGREGATOR");

  address public _this;
  IGlobalStorage public globalStorageData;

  receive() external payable {}

  function __EulerContract_init(address _globalStorageData) internal onlyInitializing {
    require(_globalStorageData != address(0), 'ZERO_ADDRESS_STORAGE');
    globalStorageData = IGlobalStorage(_globalStorageData);
    _this = address(this);
  }

  modifier requireTax(bytes4 method, uint256 amount) {
    (uint256 _tax, bool _buyback) = IManagerTax(_address(MANAGER_TAX)).tax(address(this), method, msg.sender);
    require(msg.value == _tax + amount, 'WRONG_ETH');
    if(_tax > 0) {
      address dex = _address(DEX_AGREGATOR);
      if(dex != address(0) && _buyback) {
        payable(dex).transfer(_tax);
        IDexAgregator(_address(DEX_AGREGATOR)).buyback(_tax);
      } else {
        payable(_address(TREASURY)).transfer(_tax);
      }
    }
    _;
  }

  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function _address(bytes32 key) internal view returns(address) {
    return IGlobalStorage(globalStorageData).get(key);
  }

  /**
  * @dev This empty reserved space is put in place to allow future versions to add new
  * variables without shifting down storage in the inheritance chain.
  * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  */
  uint256[48] private __gap;
}
