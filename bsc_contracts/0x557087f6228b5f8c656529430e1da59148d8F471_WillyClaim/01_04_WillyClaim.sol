// SPDX-License-Identifier: MIT

/**
...................../´¯¯/)
...................,/¯.../
.................../..../
.............../´¯/'..'/´¯¯`·¸
.........../'/.../..../....../¨¯\
..........('(....´...´... ¯~/'..')
...........\..............'...../
............\....\.........._.·´
.............\..............(
..............\..............\                                                                                                                                                                                                                                                               
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IWillyNFT {
    function airDrop(address _to, uint256 _amount) external;
    function reveal() external;
    function setCost(uint256 _newCost) external;
    function setTokenAmount(uint256 _newTokenAmount) external;
    function setNotRevealedURI(string memory _notRevealedURI) external;
    function setBaseURI(string memory _newBaseURI) external;
    function setBaseExtension(string memory _newBaseExtension) external;
    function pause(bool _state) external;
    function withdraw() external;
    function transferOwnership(address newOwner) external;
    function totalSupply() external view returns (uint256);
    function cost() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function paused() external view returns (bool);
    function tokenAmount() external view returns (uint256);
}

contract WillyClaim is Ownable, ReentrancyGuard {
    IWillyNFT public constant WILLYNFT =
        IWillyNFT(0x0e07337B091CE236e215810E01ec63e82EA3cc1D);

    mapping(address => uint256) public freeClaims;

    function freeClaim(address _to, uint256 _amount) public nonReentrant {
        isEligibleForClaim(_to, _amount);
        WILLYNFT.airDrop(_to, _amount);
    }

    function revertOwnership() external onlyOwner {
        WILLYNFT.transferOwnership(owner());
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Can not renounce ownership");
    }

    // free claim functions

    function addFreeClaim(address to, uint256 _amount) external onlyOwner {
        freeClaims[to] += _amount;
    }

    function addFreeClaimsMultiple(
        address[] memory to,
        uint256[] memory _amounts
    ) external onlyOwner {
        require(
            to.length == _amounts.length,
            "Different amount of addresses and spots"
        );

        for (uint256 i = 0; i < to.length; ++i) {
            freeClaims[to[i]] += _amounts[i];
        }
    }

    function isEligibleForClaim(address user, uint256 _amount) internal {
        require(freeClaims[user] >= _amount, "Exceeds free claims");
        freeClaims[user] -= _amount;
    }

    // forward interface

    function airDrop(address _to, uint256 _amount) external onlyOwner {
        WILLYNFT.airDrop(_to, _amount);
    }

    function reveal() external onlyOwner {
        WILLYNFT.reveal();
    }

    function setCost(uint256 _newCost) external onlyOwner {
        WILLYNFT.setCost(_newCost);
    }

    function setTokenAmount(uint256 _newTokenAmount) external onlyOwner {
        WILLYNFT.setTokenAmount(_newTokenAmount);
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        external
        onlyOwner
    {
        WILLYNFT.setNotRevealedURI(_notRevealedURI);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        WILLYNFT.setBaseURI(_newBaseURI);
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        WILLYNFT.setBaseExtension(_newBaseExtension);
    }

    function pause(bool _state) external onlyOwner {
        WILLYNFT.pause(_state);
    }

    // withdraw forward

    receive() external payable {
    }

    function withdraw() external onlyOwner {
        WILLYNFT.withdraw();

        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}