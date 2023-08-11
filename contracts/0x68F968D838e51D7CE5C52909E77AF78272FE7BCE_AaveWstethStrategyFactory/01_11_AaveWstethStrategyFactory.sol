// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./AaveWstethStrategy.sol";

contract AaveWstethStrategyFactory is Ownable {
    address public immutable implementation;
    uint256 public fee;
    address public feeReceiver;

    event CreatedClone(address clone);

    constructor() {
        implementation = address(new AaveWstethStrategy());
        fee = 52;
        feeReceiver = msg.sender;
    }

    function createClone(uint256 seed) private returns (address payable) {
        address payable clone =
            payable(Clones.cloneDeterministic(implementation, bytes32(uint256(uint160(msg.sender) + seed))));
        AaveWstethStrategy(clone).initialize(msg.sender, address(this));
        emit CreatedClone(clone);
        return clone;
    }

    function getClone(address account, uint256 seed) public view returns (address payable) {
        return payable(Clones.predictDeterministicAddress(implementation, bytes32(uint256(uint160(account) + seed))));
    }

    function createCloneAndEnterPosition(uint256 iterations, uint256 slippageTolerance, uint256 seed)
        public
        payable
        returns (address payable)
    {
        address payable clone = createClone(seed);
        AaveWstethStrategy(clone).enterPosition{value: msg.value}(iterations, slippageTolerance);
        return clone;
    }

    receive() external payable {}

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }
}