// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error Relayer__InvalidCall();

interface IWhoIsWho {
    function mint(address, uint256) external payable;
}

contract Relayer {
    uint256 public mintPrice = 0.02 ether;
    uint256 public presaleStartDate = 1684854000;
    uint256 public presaleEndDate = 1685131200;
    address public owner;
    address public immutable whoIsWhoContract;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Relayer__InvalidCall();
        }
        _;
    }

    constructor(address _whoIsWhoContract) {
        whoIsWhoContract = _whoIsWhoContract;
        owner = msg.sender;
    }

    function mintRelay(uint256 _mintAmount) external payable {
        if (
            _mintAmount == 0 ||
            _mintAmount * mintPrice > msg.value ||
            block.timestamp < presaleStartDate ||
            block.timestamp > presaleEndDate
        ) {
            revert Relayer__InvalidCall();
        }

        IWhoIsWho(whoIsWhoContract).mint{value: msg.value}(address(msg.sender), _mintAmount);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setPresaleStartDate(uint256 _presaleStartDate) external onlyOwner {
        presaleStartDate = _presaleStartDate;
    }

    function setPresaleEndDate(uint256 _presaleEndDate) external onlyOwner {
        presaleEndDate = _presaleEndDate;
    }
}