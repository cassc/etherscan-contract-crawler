pragma solidity ^0.8.17;

import '../DealPoint.sol';

/// @dev ether transaction point
contract EtherPoint is DealPoint {
    uint256 public needCount;
    address public firstOwner;
    address public newOwner;
    uint256 public feeEth;

    receive() external payable {}

    constructor(
        address _router,
        uint256 _needCount,
        address _firstOwner,
        address _newOwner,
        address _feeAddress,
        uint256 _feeEth
    ) DealPoint(_router, _feeAddress) {
        router = _router;
        needCount = _needCount;
        firstOwner = _firstOwner;
        newOwner = _newOwner;
        feeEth = _feeEth;
    }

    function isComplete() external view override returns (bool) {
        return address(this).balance >= needCount;
    }

    function swap() external override {
        require(msg.sender == router);
        isSwapped = true;
    }

    function withdraw() external payable {
        if (isSwapped) {
            require(msg.value >= feeEth);
            payable(feeAddress).transfer(feeEth);
        }

        address owner = isSwapped ? newOwner : firstOwner;
        require(msg.sender == owner || msg.sender == router);
        payable(owner).transfer(address(this).balance);
    }
}