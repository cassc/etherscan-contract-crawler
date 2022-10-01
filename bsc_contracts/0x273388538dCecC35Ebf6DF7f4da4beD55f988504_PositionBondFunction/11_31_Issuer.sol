pragma solidity ^0.8.9;

abstract contract Issuer {
    address private _issuer;
    event IssuerChanged(address oldIssuer, address newIssuer);

    modifier onlyIssuer() {
        require(msg.sender == _issuer, "only issuer");
        _;
    }

    modifier notIssuer(address recipient) {
        require(recipient != _issuer, "not issuer");
        _;
    }

    constructor() {
        _issuer = msg.sender;
    }

    function issuer() public view virtual returns (address) {
        return _issuer;
    }

    function setIssuer(address issuer_) internal {
        _issuer = issuer_;
    }

}