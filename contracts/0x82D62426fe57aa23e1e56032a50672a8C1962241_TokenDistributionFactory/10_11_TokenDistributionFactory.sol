// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Airdrop.sol";
import "./Vesting.sol";

contract TokenDistributionFactory is Ownable {
    event AirdropCreated(
        address addr,
        bytes32 root,
        uint256 start,
        uint256 end
    );

    event VestingCreated(
        address addr,
        address beneficiary,
        uint256 start,
        uint256 duration,
        uint256 numVestings
    );

    Vesting[] public vestings;
    Airdrop[] public airdrops;
    address public immutable token;

    /**
     * @dev create a new airdrop.
     * @param root merkle root
     * @param start unix timestamp of start time
     * @param end unix timestamp of end time
     * NOTE: need to move token to this contract
     */
    function createAirdrop(
        bytes32 root,
        uint256 start,
        uint256 end
    ) public onlyOwner {
        Airdrop airdrop = new Airdrop(
            owner(),
            address(token),
            root,
            start,
            end
        );
        airdrops.push(airdrop);
        emit AirdropCreated(address(airdrop), root, start, end);
    }

    /**
     * @dev create a new vesting.
     * @param beneficiary who can got the vested token.
     * @param start unix timestamp of start time
     * @param duration seconds of every vesting.
     * @param numVestings the number of vestings.
     */
    function createVesting(
        address beneficiary,
        uint256 start,
        uint256 duration,
        uint256 numVestings
    ) public onlyOwner {
        Vesting vesting = new Vesting(
            owner(),
            address(token),
            beneficiary,
            start,
            duration,
            numVestings
        );
        vestings.push(vesting);
        emit VestingCreated(
            address(vesting),
            beneficiary,
            start,
            duration,
            numVestings
        );
    }

    constructor(address owner, address _token) {
        transferOwnership(owner);
        token = _token;
    }
}