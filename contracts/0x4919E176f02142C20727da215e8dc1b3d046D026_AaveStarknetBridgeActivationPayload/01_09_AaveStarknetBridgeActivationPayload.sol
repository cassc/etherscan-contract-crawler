// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.0;

import {AaveGovernanceV2} from "@bgd-labs/aave-address-book/src/AaveGovernanceV2.sol";
import {ITransparentProxyFactory} from "./interfaces/IProxyFactory.sol";
import {IBridge} from "./interfaces/IBridge.sol";
import {ICrosschainForwarderStarknet} from "./interfaces/ICrosschainForwarderStarknet.sol";

/**
 * @title AaveStarknetBridgeActivationPayload
 * @author Aave on Starknet
 * @notice Aave governance proposal payload, activating the Aave <> Starknet Aave v2 Ethereum Bridge
 */
contract AaveStarknetBridgeActivationPayload {
    address public constant STARKNET_MESSAGING_CORE =
        0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4;
    ICrosschainForwarderStarknet public constant CROSSCHAIN_FORWARDER_STARKNET =
        ICrosschainForwarderStarknet(
            0x8c598667A5a6A14F04172326e62CE143BF8edaAB
        );
    uint256 public constant L2_BRIDGE =
        0x0434ab0e4f2a743f871e4d57a16aef3df84c1a29b61565e016da91c1f824b021;
    address public constant INCENTIVES_CONTROLLER =
        0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    ITransparentProxyFactory public constant PROXY_FACTORY =
        ITransparentProxyFactory(0xC354ce29aa85e864e55277eF47Fc6a92532Dd6Ca);
    string public constant ID_L1_BRIDGE = "aave_v2_ethereum.starknet_bridge";

    IBridge public constant L1_BRIDGE_IMPLEMENTATION =
        IBridge(0x69F4057cC8A32bdE63c2d62724CE14Ed1aD4B93A);
    uint256 public constant L2_INIT_SPELL =
        0x00be3e7fe64939ef463bc80b76703b93c10a61944de34df5bb2dbc7b734e3159;

    function execute() external {
        (
            address[] memory l1Tokens,
            uint256[] memory l2Tokens,
            uint256[] memory ceilings
        ) = getTokensData();

        try
            /// @dev Using createDeterministic() because the spell on L2 side needs to know in advance the address
            /// of the proxy to be deployed
            PROXY_FACTORY.createDeterministic(
                address(L1_BRIDGE_IMPLEMENTATION),
                AaveGovernanceV2.SHORT_EXECUTOR,
                abi.encodeWithSelector(
                    L1_BRIDGE_IMPLEMENTATION.initialize.selector,
                    L2_BRIDGE,
                    STARKNET_MESSAGING_CORE,
                    INCENTIVES_CONTROLLER,
                    l1Tokens,
                    l2Tokens,
                    ceilings
                ),
                keccak256(abi.encode(ID_L1_BRIDGE))
            )
        {} catch (bytes memory) {
            // Do nothing. If reverted, it is because the contract is already deployed
            // and initialized with exactly the parameters we require
        }

        // Send message to activate the L2 side of the system, by nested delegatecall to the forwarder
        (bool success, ) = address(CROSSCHAIN_FORWARDER_STARKNET).delegatecall(
            abi.encodeWithSelector(
                CROSSCHAIN_FORWARDER_STARKNET.execute.selector,
                L2_INIT_SPELL
            )
        );

        require(success, "CROSSCHAIN_FORWARDER_STARKNET_execute()");
    }

    function predictProxyAddress() public view returns (address) {
        (
            address[] memory l1Tokens,
            uint256[] memory l2Tokens,
            uint256[] memory ceilings
        ) = getTokensData();

        return
            PROXY_FACTORY.predictCreateDeterministic(
                address(L1_BRIDGE_IMPLEMENTATION),
                AaveGovernanceV2.SHORT_EXECUTOR,
                abi.encodeWithSelector(
                    L1_BRIDGE_IMPLEMENTATION.initialize.selector,
                    L2_BRIDGE,
                    STARKNET_MESSAGING_CORE,
                    INCENTIVES_CONTROLLER,
                    l1Tokens,
                    l2Tokens,
                    ceilings
                ),
                keccak256(abi.encode(ID_L1_BRIDGE))
            );
    }

    function getTokensData()
        public
        pure
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        address[] memory l1Tokens = new address[](3);
        l1Tokens[0] = 0xBcca60bB61934080951369a648Fb03DF4F96263C; // aUSDC
        l1Tokens[1] = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811; // aUSDT
        l1Tokens[2] = 0x028171bCA77440897B824Ca71D1c56caC55b68A3; // aDAI

        uint256[] memory l2Tokens = new uint256[](3);
        l2Tokens[
            0
        ] = 0x014cdaa224881ea760b055a50b7b8e65447d9310f5c637294e08a0fc0d04c0ce; // static aUSDC
        l2Tokens[
            1
        ] = 0x02e905e3d2fcf4e5813fef9bfe528a304e8e5adc8cbdc247b3980d7a96a01b90; // static aUSDT
        l2Tokens[
            2
        ] = 0x04212f12efcfc9e847bd98e58daff7dc588c4896f6cd320b74023ad5606f02fd; // static aDAI

        uint256[] memory ceilings = new uint256[](3);
        ceilings[0] = 30_000_000000; // ceiling of aUSDC, 6 decimals
        ceilings[1] = 30_000_000000; // ceiling of aUSDT, 6 decimals
        ceilings[2] = 30_000 ether; // ceiling of aDAI, 18 decimals

        return (l1Tokens, l2Tokens, ceilings);
    }
}