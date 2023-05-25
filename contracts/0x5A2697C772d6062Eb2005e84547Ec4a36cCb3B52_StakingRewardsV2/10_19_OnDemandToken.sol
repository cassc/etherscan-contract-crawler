//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./MintableToken.sol";

abstract contract OnDemandToken is MintableToken {
    bool constant public ON_DEMAND_TOKEN = true;

    mapping (address => bool) public minters;

    event SetupMinter(address minter, bool active);

    modifier onlyOwnerOrMinter() {
        address msgSender = _msgSender();
        require(owner() == msgSender || minters[msgSender], "access denied");

        _;
    }

    function setupMinter(address _minter, bool _active) external onlyOwner() {
        minters[_minter] = _active;
        emit SetupMinter(_minter, _active);
    }

    function setupMinters(address[] calldata _minters, bool[] calldata _actives) external onlyOwner() {
        for (uint256 i; i < _minters.length; i++) {
            minters[_minters[i]] = _actives[i];
            emit SetupMinter(_minters[i], _actives[i]);
        }
    }

    function mint(address _holder, uint256 _amount)
        external
        virtual
        override
        onlyOwnerOrMinter()
        assertMaxSupply(_amount)
    {
        require(_amount != 0, "zero amount");

        _mint(_holder, _amount);
    }
}