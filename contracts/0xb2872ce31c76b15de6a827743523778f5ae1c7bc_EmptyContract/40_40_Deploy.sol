// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DSTest} from "ds-test/src/test.sol";
import {Hevm} from "solmate/src/test/utils/Hevm.sol";

import "forge-std/src/Script.sol";
import "forge-std/src/StdJson.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {AludelFactory} from "../contracts/AludelFactory.sol";
import {IAludel} from "../contracts/aludel/IAludel.sol";
import {Aludel} from "../contracts/aludel/Aludel.sol";
import {PowerSwitchFactory} from "../contracts/powerSwitch/PowerSwitchFactory.sol";

import {RewardPoolFactory} from "alchemist/contracts/aludel/RewardPoolFactory.sol";

contract EmptyContract {}

contract DeploymentScript is Script, DSTest {
    

    struct NetworkConfig {
        uint256 chainId;
        address aludelFactory;
        ProgramConfig[] programs;
        address vaultFactory;
    }

    // JSON Keys mapped to this struct must be in alphabetical order
    struct ProgramConfig {
        string name;
        address program;
        string stakingTokenUrl;
        address template;
    }

    using stdJson for string;

    function loadConfig() internal returns (string memory config) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/oldPrograms.json");
        
        config = vm.readFile(path);
    
        return config;
    }

    function loadNetworkConfig(string memory config) internal returns (NetworkConfig memory) {
        string memory key = string.concat(".", Strings.toString(block.chainid));
        bytes memory raw = stdJson.parseRaw(config, key);
        NetworkConfig memory networkConfig = abi.decode(
            raw,
            (NetworkConfig)
        );

        return networkConfig;
    }

    function loadNetworkConfig() internal returns (NetworkConfig memory) {
        return loadNetworkConfig(loadConfig());
    }

}

contract DeployFactory is Script {

    function run() external {
        
        address recipient = vm.envAddress("ALUDEL_FACTORY_RECIPIENT");
        uint16 bps = uint16(vm.envUint("ALUDEL_FACTORY_BPS"));

        // start broadcasting transactions
        vm.startBroadcast();

        // AludelFactory factory = new AludelFactory(recipient, bps);

        // deploy an empty contract to reserve an address
        // EmptyContract aludelV1 = new EmptyContract();
        // no need to initialize an empty contract

        AludelFactory factory = AludelFactory(0xFe32d8c1Dcc3E31D2286C4Ed467C16e213e2d9B7);
        EmptyContract aludelV1 = EmptyContract(0xc61d759F28a30E1775c6e9F0F3f96EAFC4F335d7);

        // add AludelV1 template
        factory.addTemplate(address(aludelV1), "AludelV1", true);

        // deploy an empty contract to reserve an address
        EmptyContract geyser = new EmptyContract();

        // idem aludelV1, no need to initialize

        // add GeyserV2 template
        factory.addTemplate(address(geyser), "GeyserV2", true);
        
        Aludel aludel = new Aludel();

        aludel.initializeLock();

        // add AludelV2 template
        factory.addTemplate(address(aludel), "AludelV2", false);


        factory.setFeeRecipient(0xb784F92002117F11acF9F3F79769Eb9369B25F50);

        vm.stopBroadcast();

    }

}

/// @dev this is equivalent to using forge create
contract DeployPowerSwitchFactory is Script, DSTest {
    function run() external {
        vm.startBroadcast();

        PowerSwitchFactory powerSwitchFactory = new PowerSwitchFactory();

        vm.stopBroadcast();
    }
}

contract DeployRewardPoolFactory is Script, DSTest {
    function run() external {
        vm.startBroadcast();

        RewardPoolFactory rewardPoolFactory = new RewardPoolFactory();

        vm.stopBroadcast();
    }
}

contract AddPrograms is DeploymentScript {

    using stdJson for string;

    function run() external {
        
        NetworkConfig memory config = loadNetworkConfig();
        
        AludelFactory factory = AludelFactory(config.aludelFactory);

        vm.startBroadcast();

        for (uint256 i = 0; i < config.programs.length; i++) {

            ProgramConfig memory program = config.programs[i];

            emit log_string(program.name);
            emit log_address(program.program);
            // AludelFactory.ProgramData memory p = factory.programs(program.program);
            // emit log_string(p.name);

            emit log_address(program.template);
            emit log_string(program.stakingTokenUrl);
            // try to add program[i] to the factory
            try factory.addProgram(
                program.program,
                program.template,
                program.name,
                program.stakingTokenUrl,
                uint64(block.timestamp)
            ) {
            } catch (bytes memory err) {
                emit log_bytes(err);
                // catch revert and continue iterating
                if (bytes4(err) == AludelFactory.AludelAlreadyRegistered.selector) {
                    emit log_string("Aludel already added");
                    continue;
                }
            }
        }


        vm.stopBroadcast();

    }

}