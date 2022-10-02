// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

// Reference - https://github.com/Synthetixio/synthetix/blob/develop/contracts/Owned.sol

abstract contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    /**
     * @dev Nominate new owner of contract by current owner
     * Requirements:
     *
     * - `_owner` - Address of new owner nominated
     *
     * emits event OwnerNominated
     */
    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    /**
     * @dev Accept the nomination for new owner of contract
     * emits event OwnerChanged
     */
    function acceptOwnership() external {
        require(
            msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership"
        );
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(
            msg.sender == owner,
            "Only the contract owner may perform this action"
        );
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}