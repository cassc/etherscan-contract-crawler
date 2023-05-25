// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OwnershipClaimable is Ownable {
    address private _nominatedOwner;
    error NotSupported(string reason);

    /// @dev Overriding renounceOwnership() to prevent the ability to renounce ownership
    ///      of this contract. Callable only by the contract owner but throws when called.
    function renounceOwnership() 
        public 
        override
        onlyOwner 
    {   
        revert NotSupported("Ownership cannot be renounced");
    }

    /// @dev Overriding transferOwnership() to mandate that contract ownership is transferred 
    ///      via the two step process: nominateNewOwner then claimOwnershipNomination. Callable 
    ///      only by the contract owner but throws when called.
    function transferOwnership(address newOwner)
        public 
        override
        onlyOwner 
    {   
        revert NotSupported("Use nominateNewOwner and claimOwnershipNomination instead");
    }

    /// @notice Nominate a new owner for this contract who can then claim ownership,
    /// @dev Callable only by the contract owner.
    /// @param newOwner the address of the new owner.
    function nominateNewOwner(address newOwner) 
        public 
        virtual 
        onlyOwner 
    {
        _nominatedOwner = newOwner;
    }

    /// @notice Claim the nomination to take ownership of this contract. It is required
    ///         that the caller must have been nominated for this to succeed. Emits a
    ///         {OwnershipTransferred} event.
    /// @dev Callable only by the contract owner.
    function claimOwnershipNomination() 
        public
        virtual 
    {
        require(
            msg.sender == _nominatedOwner,
            "Caller is not the nominated owner"
        );
        _transferOwnership(_nominatedOwner);
        delete _nominatedOwner;
    }

    /// @notice Get the owner that has been nominated.
    /// @return address The address of the nominated owner.
    function nominatedOwner() 
        public 
        view 
        virtual returns (address) 
    {
        return _nominatedOwner;
    }
}