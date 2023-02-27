// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IMinterChild.sol";
import "./interface/IChildStorage.sol";

contract MultiWalletCallerOnlyOwnerV2 is Ownable {
    IChildStorage private immutable _ChildStorage;

    constructor(address childStorage_) {
        _ChildStorage = IChildStorage(childStorage_);
    }
    receive() external payable {}

    function run(
        uint256 _startId,
        address _callContract,
        bytes calldata _callData,
        uint256 _value,
        address _nft,
        uint256 _id,
        uint256 _margin
    ) external onlyOwner {
        uint256 totalSupply = IERC20(_nft).totalSupply();
        require(totalSupply < _id && totalSupply + _margin > _id, "id over..");
        uint256 loop = _id - totalSupply;
        for (uint256 i = _startId; i <= _startId + loop; ) {
            IMinterChild(
                payable(_ChildStorage.child(msg.sender, i))
            ).run_Ozzfvp4CEc(_callContract, _callData, _value);
            unchecked {
                i++;
            }
        }
    }
}