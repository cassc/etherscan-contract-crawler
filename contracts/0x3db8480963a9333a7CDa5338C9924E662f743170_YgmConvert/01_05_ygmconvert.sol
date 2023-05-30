// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IYGME {
    function swap(address to, address _recommender, uint mintNum) external;

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IYGM {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract YgmConvert is Pausable, Ownable, ReentrancyGuard {
    event Convert(address account, uint256[] tokokenIds, uint256 amount);

    IYGM public immutable ygm;
    IYGME public immutable ygme;
    address public immutable receiver;

    uint256 public maxOnce = 3;
    uint256 public rate = 10;

    constructor(address _ygm, address _ygme, address _receiver) {
        ygm = IYGM(_ygm);
        ygme = IYGME(_ygme);
        receiver = _receiver;
    }

    function setPause() external onlyOwner {
        if (!paused()) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setRateAndMaxOnce(
        uint256 _rate,
        uint256 _maxOnce
    ) external onlyOwner {
        if(rate != _rate){
            rate = _rate;
        }
        if(maxOnce != _maxOnce){
            maxOnce = _maxOnce;
        }
    }

    function convert(
        uint256[] calldata tokenIds,
        address _recommender
    ) external whenNotPaused nonReentrant returns (bool) {
        address account = _msgSender();

        require(_recommender != address(0), "recommender can not be zero");
        require(_recommender != account, "recommender can not be self");
        require(ygme.balanceOf(_recommender) > 0, "invalid recommender");

        uint256 len = tokenIds.length;

        require(len > 0 && len <= maxOnce, "Invalid tokenIds");

        for (uint i = 0; i < len; ++i) {
            uint256 tokenId = tokenIds[i];

            require(ygm.ownerOf(tokenId) == account, "Invalid account");

            ygm.safeTransferFrom(account, receiver, tokenId);
        }

        uint256 amount = len * rate;

        ygme.swap(account, _recommender, amount);

        emit Convert(account, tokenIds, amount);

        return true;
    }
}