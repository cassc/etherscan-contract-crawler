// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./LlamaLandOrigin.sol";

abstract contract LlamaLandClaimer is Context, Ownable {
    uint public MAX_CLAIM;

    uint public MAXIMUM;
    uint public price;
    uint public claimedAmount;
    uint public unlockedAmount;

    LlamaLandOrigin origin;
    constructor(address _origin, uint _maximum, uint _price, uint _maxClaim) {
        origin = LlamaLandOrigin(_origin);
        address admin = origin.admin();
        transferOwnership(admin);
        MAXIMUM = _maximum;
        price = _price;
        MAX_CLAIM = _maxClaim;
    }

    function setPrice(uint _price) onlyOwner external {
        price = _price;
    }

    function unlock(uint amount) onlyOwner external {
        require(amount <= MAXIMUM, "Exceeded the maximum");
        require(amount > claimedAmount, "The amount should be more than the claimed amount");
        unlockedAmount = amount;
    }

    function _checkClaim(uint amount) internal {
        require(claimedAmount < MAXIMUM, "FINISH");
        require(amount > 0, "At least 1");
        require(amount <= MAX_CLAIM, "Exceeded the legal amount");

        uint expectedAmount = claimedAmount + amount;
        require(expectedAmount <= unlockedAmount, "Exceeded the unlocked amount");

        uint total = price * amount;
        require(msg.value >= total, "Token is not enough");
    }

    function _pay() internal {
        address owner = origin.owner();
        (bool success,) = payable(owner).call{value : msg.value}("");
        require(success, "Payable is failed");
    }

    function _effectClaim(uint amount) internal {
        claimedAmount = claimedAmount + amount;
    }

    function _interactClaim(uint amount) internal {
        uint i;
        for (i = 0; i < amount; i++) {
            origin.claim(_msgSender());
        }
    }
}