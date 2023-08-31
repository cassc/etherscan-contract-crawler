import "@openzeppelin/contracts/access/Ownable.sol";
pragma solidity 0.8.9;

contract ProxyStorage is Ownable {
    address internal _implementation;
}

contract Proxy is ProxyStorage {
    event ProxyUpdated(address indexed _new, address indexed _old);
    event OwnerUpdate(address _prevOwner, address _newOwner);

    constructor(address _proxyTo) {
        updateImplementation(_proxyTo);
    }

    function updateImplementation(address _newImplementation) public onlyOwner {
        require(_newImplementation != address(0x0), "INVALID_PROXY_ADDRESS");
        require(
            isContract(_newImplementation),
            "DESTINATION_ADDRESS_IS_NOT_A_CONTRACT"
        );
        emit ProxyUpdated(_newImplementation, _implementation);
        _implementation = _newImplementation;
    }

    function implementation() external view returns (address) {
        return _implementation;
    }

    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly {
            size := extcodesize(_target)
        }
        return size > 0;
    }
}