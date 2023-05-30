// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract TokenMint is ERC20, ERC20Burnable {
    event updateClaimable(uint _claimable);

    address owner;

    constructor() ERC20("S0meToken", "S0ME") {
        owner = msg.sender;
    }

    struct Holder {
        uint _claimable;
    }

    mapping(address => Holder) Holders;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function updateOneClaimable(
        address _holderAddress,
        uint _claimable
    ) external onlyOwner {
        require(
            _claimable >= 0,
            "Increment value should be equal or greater than zero"
        );
        Holders[_holderAddress]._claimable = _claimable;
        emit updateClaimable(_claimable);
    }

    function updateMultipleClaimable(
        address[] calldata _holderAddresses,
        uint[] calldata _claimables
    ) external onlyOwner {
        require(
            _holderAddresses.length == _claimables.length,
            "There should be as many holder addresses as claimables"
        );
        for (uint i = 0; i < _holderAddresses.length; i++) {
            if (_claimables[i] < 0) {
                continue;
            }
            Holders[_holderAddresses[i]]._claimable = _claimables[i];
            emit updateClaimable(_claimables[i]);
        }
    }

    function incrementOneClaimable(
        address _holderAddress,
        uint _increment
    ) external onlyOwner {
        require(_increment > 0, "Increment value should be greater than zero");
        Holders[_holderAddress]._claimable += _increment;
        emit updateClaimable(_increment);
    }

    function incrementMultipleClaimable(
        address[] calldata _holderAddresses,
        uint[] calldata _increments
    ) external onlyOwner {
        require(
            _holderAddresses.length == _increments.length,
            "There should be as many holder addresses as claimables"
        );
        for (uint i = 0; i < _holderAddresses.length; i++) {
            if (_increments[i] < 0) {
                continue;
            }
            Holders[_holderAddresses[i]]._claimable += _increments[i];
            emit updateClaimable(_increments[i]);
        }
    }

    function getClaimableBalanceOf(
        address _holderAddress
    ) external view returns (uint) {
        return Holders[_holderAddress]._claimable;
    }

    function mint() public returns (uint) {
        uint claimable = Holders[msg.sender]._claimable;
        require(claimable > 0, "Claimable should be more than zero to claim.");

        _mint(msg.sender, claimable * 10 ** 18);
        Holders[msg.sender]._claimable = 0;

        return claimable;
    }
}
