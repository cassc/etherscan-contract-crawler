pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./theproxy.sol";
import "../registry/IRegistryController.sol";
import "../registry/IRegistryConsumer.sol";
import "./CommunityRegistry.sol";
import "./community_list.sol";





abstract contract L2ChainImplementerBase is AccessControlEnumerable {

    address constant reg = 0x1e8150050A7a4715aad42b905C08df76883f396F;

    bytes32 public constant COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");

    event MainnetCommunityRegistryCreated(uint32 community_id,address community_proxy);
    event MainnetCommunityAlreadyExists(uint32 community_id);

    function createCommunity(
        uint32 community_id,
        address community_admin,
        string memory community_name
    ) external virtual;

    // @dev the implemented `createCommunity` must call createMainnetCommunity to ensure
    //      that the community also gets created on L1 to allow hybrid communities
    //
    //      ensure that the L2implementer contract has been allowed access by the community list
    //      with role CONTRACT_ADMIN or the addCommunity call will fail
    function createMainnetCommunity(
        uint32 community_id,
        address community_admin,
        string memory community_name
    ) internal {
        address master_reg = RegistryConsumer(reg).getRegistryAddress("MASTER_REGISTRY");
        
        require(master_reg == msg.sender,"L2ChainImplementer: Unauthorised access");

        // check that the community entry is not already there...
        address cl = RegistryConsumer(reg).getRegistryAddress("COMMUNITY_LIST"); // one list so from galaxis registry
        (,address community_registry,uint32 id) = community_list(cl).communities(community_id);
        if ((id == community_id) && (community_registry == address(0))) { // second to ensure that Eth Classic can be handled
            // community already deployed on mainnet
            emit MainnetCommunityAlreadyExists(community_id);
            return;
        }

        theproxy community_proxy = new theproxy("GOLDEN_COMMUNITY_REGISTRY"); // all golden contracts should start with `GOLDEN_`
        CommunityRegistry cr = CommunityRegistry(address(community_proxy));
        cr.init(community_id,community_admin,community_name);
        
        community_list(cl).addCommunity(community_id, community_name,address(community_proxy)); // now the community list holds the registry address

       emit MainnetCommunityRegistryCreated(community_id,address(community_proxy));
    }


}