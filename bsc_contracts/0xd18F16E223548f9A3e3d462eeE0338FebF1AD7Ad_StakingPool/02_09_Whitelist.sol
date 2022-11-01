pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {

    mapping(address => bool) public whitelist;
    //Gas optimization
    // address[] public whitelistedAddresses;
    bool public hasWhitelisting = false;

    event AddedToWhitelist(address account);
    event RemovedFromWhitelist(address account);

    modifier onlyWhitelisted() {
        if(hasWhitelisting){
            require(isWhitelisted(msg.sender));
        }
        _;
    }
    
    constructor (bool _hasWhitelisting) public{
        hasWhitelisting = _hasWhitelisting;
    }

    function add(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            // require(whitelist[_addresses[i]] != true);
            whitelist[_addresses[i]] = true;
            // whitelistedAddresses.push(_addresses[i]);
            emit AddedToWhitelist(_addresses[i]);
        }
    }

    function remove(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            address uAddress = _addresses[i];
            if(whitelist[uAddress]){
                whitelist[uAddress] = false;
                emit RemovedFromWhitelist(uAddress);
            }
        }
    }

    // function getWhitelistedAddresses() public view returns(address[] memory) {
    //     return whitelistedAddresses;
    // } 

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}