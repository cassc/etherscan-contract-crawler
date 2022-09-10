// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IAllowedAirdrops.sol";
import "../utils/Ownable.sol";

contract AllowedAirdrops is Ownable, IAllowedAirdrops {
    mapping(bytes => bool) private airdropPermits;

    event AirdropPermit(address indexed airdropContract, bytes4 indexed selector, bool isPermitted);

    constructor(
        address _admin,
        address[] memory _airdopContracts,
        bytes4[] memory _selectors
    ) Ownable(_admin) {
        require(_airdopContracts.length == _selectors.length, "function information arity mismatch");
        for (uint256 i = 0; i < _airdopContracts.length; i++) {
            _setAirdropPermit(_airdopContracts[i], _selectors[i], true);
        }
    }

    function setAirdropPermit(
        address _airdropContract,
        bytes4 _selector,
        bool _permit
    ) external onlyOwner {
        _setAirdropPermit(_airdropContract, _selector, _permit);
    }

    function setAirdropPermits(
        address[] memory _airdropContracts,
        bytes4[] memory _selectors,
        bool[] memory _permits
    ) external onlyOwner {
        require(
            _airdropContracts.length == _selectors.length,
            "setAirdropPermits function information arity mismatch"
        );
        require(_selectors.length == _permits.length, "setAirdropPermits function information arity mismatch");

        for (uint256 i = 0; i < _airdropContracts.length; i++) {
            _setAirdropPermit(_airdropContracts[i], _selectors[i], _permits[i]);
        }
    }

    function isAirdropPermitted(bytes memory _addressSel) external view override returns (bool) {
        return airdropPermits[_addressSel];
    }

    function _setAirdropPermit(
        address _airdropContract,
        bytes4 _selector,
        bool _permit
    ) internal {
        require(_airdropContract != address(0), "airdropContract is zero address");
        require(_selector != bytes4(0), "selector is empty");

        airdropPermits[abi.encode(_airdropContract, _selector)] = _permit;

        emit AirdropPermit(_airdropContract, _selector, _permit);
    }
}