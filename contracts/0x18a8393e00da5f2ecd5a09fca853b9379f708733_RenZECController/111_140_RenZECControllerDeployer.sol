pragma solidity >=0.6.0;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import { RenZECController } from "./RenZECController.sol";

contract RenZECControllerDeployer {
  event Deployed(address indexed controller);

  constructor() {
    emit Deployed(
      address(
        new TransparentUpgradeableProxy(
          address(new RenZECController()),
          address(0xFF727BDFa7608d7Fd12Cd2cDA1e7736ACbfCdB7B),
          abi.encodeWithSelector(
            RenZECController.initialize.selector,
            address(0x5E9B37149b7d7611bD0Eb070194dDA78EB11EfdC),
            address(0x5E9B37149b7d7611bD0Eb070194dDA78EB11EfdC)
          )
        )
      )
    );
    selfdestruct(msg.sender);
  }
}