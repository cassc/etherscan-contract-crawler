// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ILostMiner {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID
    ) external;
}

contract Disperse is Ownable {
    address _lostMinerContract;

    function setLostMinerContract(address lostMinerContract) public onlyOwner {
        _lostMinerContract = lostMinerContract;
    }

    function disperse(uint256[] calldata tokenIDs, uint256 seed)
        public
        onlyOwner
    {
        ILostMiner lostMiner = ILostMiner(_lostMinerContract);

        for (uint64 i = 0; i < tokenIDs.length; i++) {
            address dest = address(
                uint160(
                    bytes20(
                        keccak256(abi.encodePacked(seed, block.timestamp, i))
                    )
                )
            );

            lostMiner.safeTransferFrom(_lostMinerContract, dest, tokenIDs[i]);
        }
    }
}