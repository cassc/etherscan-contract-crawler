// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";


library TrainerLib {
    using Address for address;

    bytes4 private constant _selectorLastTraining = 0xabf1caca;
    bytes4 private constant _selectorTrain = 0x55fc4cf8;
    uint256 private constant _fee = 0.0005 ether;

    function train(address trainer_, uint256 id_) internal {
        trainer_.functionCallWithValue(abi.encodeWithSelector(_selectorTrain, id_), _fee);
    }

    function lastTraining(address trainer_, uint256 id_) internal view returns (uint256) {
        bytes memory ret = trainer_.functionStaticCall(abi.encodeWithSelector(_selectorLastTraining, id_));
        return abi.decode(ret, (uint256));
    }

    function canTrain(address trainer_, uint256 id_) internal view returns (bool) {
        return (block.timestamp - lastTraining(trainer_, id_)) > 8 * 3600;
    }
}