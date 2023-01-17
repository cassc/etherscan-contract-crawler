// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./token/BasedOFT.sol";

contract SershBaseToken is BasedOFT {
    mapping(bytes => uint) public hashAmounts;
    mapping(bytes => address) public hashRecipients;

    event CompleteMigration(address _recipient, uint _amount, bytes _requestHash);

    constructor(address _layerZeroEndpoint, uint _initialSupply) BasedOFT("SerenityShield", "SERSH", _layerZeroEndpoint) {
        _mint(_msgSender(), _initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function completeMigration(address _recipient, uint _amount, bytes memory _requestHash) external onlyOwner {
        // If same hash, then skip
        require(hashAmounts[_requestHash] == 0, "Already processed");

        _mint(_recipient, _amount);        
        hashAmounts[_requestHash] = _amount;
        hashRecipients[_requestHash] = _recipient;

        emit CompleteMigration(_recipient, _amount, _requestHash);
    }
}