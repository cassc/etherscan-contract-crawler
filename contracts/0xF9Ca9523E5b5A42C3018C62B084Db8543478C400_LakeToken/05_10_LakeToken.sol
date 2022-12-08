// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './access/Ownable2Step.sol';
import './access/BlacklistManager.sol';

error LakeToken_SenderIsBlacklisted();

/**
 * @title Lake Token Contract
 */
contract LakeToken is ERC20, Ownable2Step, BlacklistManager {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        _mint(_msgSender(), _initialSupply);
    }

    /**
     * @dev Overrides _beforeTokenTransfer function. Makes sure that sender is not blacklisted
     * @param _from sender address
     * @param _to receiver address
     * @param _amount uint256 amount of tokens
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        if (isBlacklisted(_from)) {
            revert LakeToken_SenderIsBlacklisted();
        }
        super._beforeTokenTransfer(_from, _to, _amount);
    }
}