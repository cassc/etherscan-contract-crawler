// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./IERC721AntiScamControl.sol";
import "../ERC721AntiScam.sol";

abstract contract ERC721AntiScamControl is
    IERC721AntiScamControl,
    ERC721AntiScam
{
    mapping(address => bool) _operators;

    /*///////////////////////////////////////////////////////////////
                        OVERRIDES ERC721Lockable
    //////////////////////////////////////////////////////////////*/
    
    modifier onlyLocker() {
        checkLockerRole(msg.sender);
        _;
    }

    /**
     * @dev トークンレベルのロックステータスを変更する
     */
    function setTokenLock(uint256[] calldata tokenIds, LockStatus lockStatus)
        external
        virtual
        override
        onlyLocker
    {
        _setTokenLock(tokenIds, lockStatus);
    }

    /**
     * @dev トークン所有者のウォレットアドレスのロックステータスを変更する
     */
    function setWalletLock(address to, LockStatus lockStatus)
        external
        virtual
        override
        onlyLocker
    {
        _setWalletLock(to, lockStatus);
    }

    /**
     * @dev コントラクトのロックステータスを変更する
     */
    function setContractLock(LockStatus lockStatus)
        external
        virtual
        override
        onlyLocker
    {
        _setContractLock(lockStatus);
    }

    function isLocker(address operator) public view returns (bool) {
        return _operators[operator];
    }

    function _grantLockerRole(address candidate) internal {
        require(
            !_operators[candidate],
            "account is already has an operator role"
        );
        _operators[candidate] = true;
    }

    function _revokeLockerRole(address candidate) internal {
        checkLockerRole(candidate);
        delete _operators[candidate];
    }

    function checkLockerRole(address operator) public view {
        require(_operators[operator], "account is not an locker");
    }
}