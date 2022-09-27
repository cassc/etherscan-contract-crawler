// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface mintContract {
    function mint(address, uint256) external;
    function numberMinted(address) external view returns(uint256);
}

error WrongValueSent();
error MintZeroItems();
error NotEnoughAvailable();

contract Reinforcements is Ownable {
    uint256 public constant PUBLIC_MINT_PRICE = 0.03 ether;

    mintContract private q00nicorns;
    mintContract private q00tants;
    mintContract private reinforcements;

    uint256 public numAvailable;

    constructor(address _q00nicorns, address _q00tants) {
        q00nicorns = mintContract(_q00nicorns);
        q00tants = mintContract(_q00tants);
    }

    function reinforce(uint256 amount) external payable {
        if (amount > numAvailable) revert NotEnoughAvailable();
        if (amount == 0) revert MintZeroItems();
        if (msg.value != PUBLIC_MINT_PRICE * amount) revert WrongValueSent();
        unchecked { --numAvailable; }

        reinforcements.mint(msg.sender, amount);
    }

    function setReinforcements(uint256 _numAvailable, bool _isQ00tants) external onlyOwner {
        numAvailable = _numAvailable;
        reinforcements = _isQ00tants ? q00tants : q00nicorns;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}