// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./token/v2/OFTV2.sol";

contract SershBaseToken is OFTV2 {
    uint256 public immutable maxSupply;
    address public vaultAddress;
    bool public paused;

    mapping(bytes => uint256) public migratedAmounts;
    mapping(bytes => address) public migratedRequests;

    event CompleteMigration(
        address _recipient,
        uint256 _amount,
        bytes _requestHash
    );

    constructor(address _layerZeroEndpoint, uint256 _maxSupply)
        OFTV2("SerenityShield", "SERSH", 9, _layerZeroEndpoint)
    {
        maxSupply = _maxSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function setPause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }

    function completeMigration(
        address _requester,
        uint256 _amount,
        bytes memory _requestHash
    ) external onlyOwner {
        require(!paused, "Migration: paused");

        require(migratedAmounts[_requestHash] == 0, "Already processed");

        require(vaultAddress != address(0), "Vault address not set");

        require(_amount > 0, "Mint amount not valid");
        require(_amount + totalSupply() <= maxSupply, "Mint allowance over");

        _mint(vaultAddress, _amount);

        migratedAmounts[_requestHash] = _amount;
        migratedRequests[_requestHash] = _requester;

        emit CompleteMigration(_requester, _amount, _requestHash);
    }
}