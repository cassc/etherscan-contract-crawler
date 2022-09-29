// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CollaborationPricing is Ownable {
    struct Collaboration {
        uint price;
        bool paused;
        uint maxPerTx;
        uint maxPerWallet;
        bool valid;
    }
    
    mapping(address => Collaboration) internal collaborations;
    
    function getCollaboration(
        address _contractAddress
    )
    public
    view
    returns (
        uint price,
        bool paused,
        uint maxPerTx,
        uint maxPerWallet,
        bool valid
    ) {
        return (
        collaborations[_contractAddress].price,
        collaborations[_contractAddress].paused,
        collaborations[_contractAddress].maxPerTx,
        collaborations[_contractAddress].maxPerWallet,
        collaborations[_contractAddress].valid
        );
    }
    
    function setCollaboration(
        address _contractAddress,
        uint _price,
        bool _paused,
        uint _maxPerTx,
        uint _maxPerWallet,
        bool _valid
    )
    external
    onlyOwner
    {
        collaborations[_contractAddress] = Collaboration(
            _price,
            _paused,
            _maxPerTx,
            _maxPerWallet,
            _valid
        );
    }
}