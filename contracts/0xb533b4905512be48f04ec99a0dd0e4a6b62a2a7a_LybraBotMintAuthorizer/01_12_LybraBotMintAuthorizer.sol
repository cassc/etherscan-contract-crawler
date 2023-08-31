// commit 4dbe918e57ed51724777082190d82cc344b9e8d0
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "BaseACL.sol";

contract LybraBotMintAuthorizer is BaseACL {
    bytes32 public constant NAME = "LybraMintAuthorizer";
    uint256 public constant VERSION = 1;

    constructor(address _owner, address _caller) BaseACL(_owner, _caller) {}

    address public constant Lybra = 0x97de57eC338AB5d51557DA3434828C5DbFaDA371;

    function mint(address onBehalfOf, uint256 amount) external view onlyContract(Lybra) {
        _checkRecipient(onBehalfOf);
    }

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](1);
        _contracts[0] = Lybra;
    }
}