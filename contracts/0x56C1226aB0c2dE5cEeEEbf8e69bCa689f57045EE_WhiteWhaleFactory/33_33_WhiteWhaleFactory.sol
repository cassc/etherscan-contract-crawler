// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/proxy/Clones.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "./WhiteWhale.sol";

contract WhiteWhaleFactory is Ownable {
    address public whiteWhale;
    string public baseURI;

    event GameDeployed(address game);

    constructor(address _whiteWhale, string memory _baseURI) {
        whiteWhale = _whiteWhale;
        baseURI = _baseURI;
    }

    function setWhiteWhale(address newWhiteWhale) public onlyOwner {
        whiteWhale = newWhiteWhale;
    }

    function setBaseURI(string calldata newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function deploy(string memory name, string memory symbol)
        external
        returns (address)
    {
        address clone = Clones.clone(whiteWhale);

        WhiteWhale(clone).initialize(name, symbol, baseURI, msg.sender);

        emit GameDeployed(clone);

        return clone;
    }
}