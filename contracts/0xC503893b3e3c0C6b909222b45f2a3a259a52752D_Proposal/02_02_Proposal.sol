// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Ownable.sol";

interface IRelayerRegistry {
    function getRelayerBalance(address relayer) external view returns (uint256);

    function nullifyBalance(address relayer) external;
}

interface IStakingRewards {
    function withdrawTorn(uint256 amount) external;
}

contract Proposal is Ownable {
    function getNullifiedTotal(address[4] memory relayers) public view returns (uint256) {
        uint256 nullifiedTotal;

        address _registryAddress = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;

        for (uint8 x = 0; x < relayers.length; x++) {
            nullifiedTotal += IRelayerRegistry(_registryAddress).getRelayerBalance(relayers[x]);
        }

        return nullifiedTotal;
    }

    function executeProposal() external {
        address[4] memory VIOLATING_RELAYERS = [
            0xcBD78860218160F4b463612f30806807Fe6E804C, // thornadope.eth
            0x94596B6A626392F5D972D6CC4D929a42c2f0008c, // 0xgm777.eth
            0x065f2A0eF62878e8951af3c387E4ddC944f1B8F4, // 0xtorn365.eth
            0x18F516dD6D5F46b2875Fd822B994081274be2a8b // abc321.eth
        ];

        uint256 NULLIFIED_TOTAL_AMOUNT = getNullifiedTotal(VIOLATING_RELAYERS);

        address _registryAddress = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;
        address _stakingAddress = 0x2FC93484614a34f26F7970CBB94615bA109BB4bf;

        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[0]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[1]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[2]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[3]);

        IStakingRewards(_stakingAddress).withdrawTorn(NULLIFIED_TOTAL_AMOUNT);
    }

    function emergencyStop() public onlyOwner {
        selfdestruct(payable(0));
    }
}