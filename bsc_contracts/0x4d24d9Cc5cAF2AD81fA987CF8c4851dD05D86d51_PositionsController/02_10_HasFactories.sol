pragma solidity ^0.8.17;
import '../ownable/Ownable.sol';

abstract contract HasFactories is Ownable {
    mapping(address => bool) factories; // factories

    modifier onlyFactory() {
        require(factories[msg.sender], 'only for factories');
        _;
    }

    function addFactory(address factory) public onlyOwner {
        factories[factory] = true;
    }

    function removeFactory(address factory) public onlyOwner {
        factories[factory] = false;
    }

    function setFactories(address[] calldata addresses, bool isFactory)
        public
        onlyOwner
    {
        uint256 len = addresses.length;
        for (uint256 i = 0; i < len; ++i) {
            factories[addresses[i]] = isFactory;
        }
    }
}