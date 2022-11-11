pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./theproxy.sol";
import "../registry/IRegistryController.sol";
import "../registry/IRegistryConsumer.sol";
import "./CommunityRegistry.sol";
import "./community_list.sol";



contract mainnetChainImplementer is AccessControlEnumerable {

    address constant reg = 0x1e8150050A7a4715aad42b905C08df76883f396F;

    bytes32 public constant COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");

    event MainnetCommunityRegistryCreated(uint32 community_id,address community_proxy);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function createCommunity(
        uint32 community_id,
        address community_admin,
        string memory community_name
    ) external {
        address master_reg = RegistryConsumer(reg).getRegistryAddress("MASTER_REGISTRY");
        
        require(master_reg == msg.sender,"mainChainImplementer: Unauthorised access");
        theproxy community_proxy = new theproxy("GOLDEN_COMMUNITY_REGISTRY"); // all golden contracts should start with `GOLDEN_`
        CommunityRegistry cr = CommunityRegistry(address(community_proxy));
        cr.init(community_id,community_admin,community_name);

        address cl = RegistryConsumer(reg).getRegistryAddress("COMMUNITY_LIST"); // one list so from galaxis registry
        
        community_list(cl).addCommunity(community_id, community_name,address(community_proxy)); // now the community list holds the registry address

       emit MainnetCommunityRegistryCreated(community_id,address(community_proxy));
    }

 
}