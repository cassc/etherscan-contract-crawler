// contracts/LaboratoriesStaking.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

struct StakeDetails {
    uint256 duration;
    address owner;
    uint256 timestamp;
}

contract LaboratoriesStaking is IERC721Receiver, Ownable {
    IERC721A private laboratories;
    IERC721A private vials;
    address private pool;
    uint256 private quantity = 250; // 250 vials initially
    uint256 private duration = 30 * 24 * 60 * 60; // 30 days
    mapping(uint256 => StakeDetails) stakes;
    mapping(address => uint256[]) wallets;
    bool private stakeActive = false;
    bool private claimActive = false;

    constructor(
        IERC721A _laboratoriesAddress,
        IERC721A _vialsAddress,
        address _pool
    ) {
        laboratories = _laboratoriesAddress;
        vials = _vialsAddress;
        pool = _pool;
    }

    function withdrawLabs(uint256[] calldata _labsId) external onlyOwner {
        for (uint256 i = 0; i < _labsId.length; i++) {
            laboratories.safeTransferFrom(
                address(this),
                msg.sender,
                _labsId[i]
            );
        }
    }

    function stake(uint256 _laboratoryId) external {
        require(stakeActive, "Staking not active.");
        require(quantity > 0, "Vials pool exhausted.");

        // transfer lab to the contract
        laboratories.safeTransferFrom(msg.sender, address(this), _laboratoryId);

        // update staking information
        stakes[_laboratoryId] = StakeDetails(
            duration,
            msg.sender,
            block.timestamp
        );
        wallets[msg.sender].push(_laboratoryId);
        quantity -= 1;
    }

    function claim(uint256 _laboratoryId, uint256 _vialId) external {
        require(claimActive, "Claiming not active.");
        StakeDetails memory details = stakes[_laboratoryId];
        require(
            block.timestamp > details.timestamp + details.duration,
            "Required staking time is not over yet."
        );

        // transfer lab back to the owner
        laboratories.safeTransferFrom(
            address(this),
            details.owner,
            _laboratoryId
        );

        // transfer vial as a reward
        vials.safeTransferFrom(pool, details.owner, _vialId);

        // update staking information
        delete stakes[_laboratoryId];
        uint256[] storage wallet = wallets[msg.sender];
        uint256 index = indexOf(wallet, _laboratoryId);
        remove(wallet, index);
    }

    function getQuantity() external view returns (uint256) {
        return quantity;
    }

    function setQuantity(uint256 _quantity) external onlyOwner {
        quantity = _quantity;
    }

    function addQuantity(uint256 _quantity) external onlyOwner {
        quantity += _quantity;
    }

    function getStakeActive() external view returns (bool) {
        return stakeActive;
    }

    function setStakeActive(bool _stakeActive) external onlyOwner {
        stakeActive = _stakeActive;
    }

    function getClaimActive() external view returns (bool) {
        return claimActive;
    }

    function setClaimActive(bool _claimActive) external onlyOwner {
        claimActive = _claimActive;
    }

    function getDuration() external view returns (uint256) {
        return duration;
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function getStakedLaboratories(address _address)
        external
        view
        returns (uint256[] memory)
    {
        return wallets[_address];
    }

    function getStakeDetails(uint256 _laboratoryId)
        external
        view
        returns (StakeDetails memory)
    {
        return stakes[_laboratoryId];
    }

    function getPoolAddress() external view returns (address) {
        return pool;
    }

    function indexOf(uint256[] memory array, uint256 element)
        private
        pure
        returns (uint256)
    {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == element) return i;
        }
        revert("not found");
    }

    function remove(uint256[] storage array, uint index) private {
        array[index] = array[array.length - 1];
        array.pop();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}