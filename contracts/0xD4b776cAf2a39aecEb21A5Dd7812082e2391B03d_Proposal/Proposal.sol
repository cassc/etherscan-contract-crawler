/**
 *Submitted for verification at Etherscan.io on 2023-04-17
*/

pragma solidity 0.8.1;

interface IRelayerRegistry {

	function getRelayerBalance(address relayer) external returns (uint256);

	function isRelayer(address relayer) external returns (bool);

	function setMinStakeAmount(uint256 minAmount) external;

	function nullifyBalance(address relayer) external;

}

interface IStakingRewards {

	function withdrawTorn(uint256 amount) external;

}

contract Proposal {

    function getNullifiedTotal(address[13] memory relayers) public returns (uint256) {        
        uint256 nullifiedTotal;

        address _registryAddress = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;

        for (uint8 x = 0; x < relayers.length; x++) {
            nullifiedTotal += IRelayerRegistry(_registryAddress).getRelayerBalance(relayers[x]);
        }

        return nullifiedTotal;
    }

    function executeProposal() external { 
        address[13] memory VIOLATING_RELAYERS = [
            0x30F96AEF199B399B722F8819c9b0723016CEAe6C,     // moon-relayer.eth 
            0xEFa22d23de9f293B11e0c4aC865d7b440647587a,     // tornado-relayer.eth 
            0x996ad81FD83eD7A87FD3D03694115dff19db0B3b,     // secure-tornado.eth 
            0x7853E027F37830790685622cdd8685fF0c8255A2,     // tornado-secure.eth 
            0x36DD7b862746fdD3eDd3577c8411f1B76FDC2Af5,     // tornado-crypto-bot-exchange.eth
            0x18F516dD6D5F46b2875Fd822B994081274be2a8b,     // torn69.eth
            0x853281B7676DFB66B87e2f26c9cB9D10Ce883F37,     // available-reliable-relayer.eth
            0xaaaaD0b504B4CD22348C4Db1071736646Aa314C6,     // tornrelayers.eth
            0x0000208a6cC0299dA631C08fE8c2EDe435Ea83B8,     // 0xtornadocash.eth
            0xf0D9b969925116074eF43e7887Bcf035Ff1e7B19,     // lowfee-relayer.eth
            0x12D92FeD171F16B3a05ACB1542B40648E7CEd384,     // torn-relayers.eth
            0x87BeDf6AD81A2907633Ab68D02c44f0415bc68C1,     // tornrelayer.eth
            0x14812AE927e2BA5aA0c0f3C0eA016b3039574242      // pls-im-poor.eth
        ];

        uint256 NEW_MINIMUM_STAKE_AMOUNT = 2000 ether; 
        uint256 NULLIFIED_TOTAL_AMOUNT = getNullifiedTotal(VIOLATING_RELAYERS);

        address _registryAddress = 0x58E8dCC13BE9780fC42E8723D8EaD4CF46943dF2;
        address _stakingAddress = 0x2FC93484614a34f26F7970CBB94615bA109BB4bf;

        IRelayerRegistry(_registryAddress).setMinStakeAmount(NEW_MINIMUM_STAKE_AMOUNT);

        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[0]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[1]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[2]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[3]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[4]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[5]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[6]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[7]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[8]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[9]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[10]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[11]);
        IRelayerRegistry(_registryAddress).nullifyBalance(VIOLATING_RELAYERS[12]);

        IStakingRewards(_stakingAddress).withdrawTorn(NULLIFIED_TOTAL_AMOUNT);
  }

}