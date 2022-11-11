pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../registry/IRegistryConsumer.sol";
interface IChainImplementer {
    function createCommunity(
        uint32 community_id,
        address community_admin,
        string memory community_name
    ) external;
}

    struct MasterListEntry {
        uint32  community_id;
        uint32  chain_id;
        address initial_owner;
        string  community_name;
    }


contract MasterRegistry is AccessControlEnumerable {

    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");


    RegistryConsumer reg;

    mapping (uint32 => MasterListEntry)   public communityListByID;
    mapping (uint256 => uint32)           public communitiesAsAdded;
    uint256                               public nextCommunity;

    mapping (address => mapping(uint256 => uint32)) userCommunityLists; // entry zero is the count
    
    mapping (uint32 => IChainImplementer) public chainImplementers;

    event ChainImplementerChanged(uint32 ChainID, address Implementer);

    

    constructor( ) {
        reg = RegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN,msg.sender);
        
    }

    function setChainImplementer(uint32 chain_id, IChainImplementer _imp) external onlyRole(CONTRACT_ADMIN) {
        chainImplementers[chain_id] = _imp;
        emit ChainImplementerChanged(chain_id,address(_imp));
    }

   

    function createCommunity(
        uint32  chain_id,
        uint32  community_id,
        address community_admin,
        string memory community_name
    ) external {
        require(launchKey().ownerOf(uint256(community_id)) == msg.sender,"You do not own the specified launch key");
        //require(launchKey().isApprovedForAll(msg.sender,address(this)),"Token Approvals not granted");
        launchKey().transferFrom(msg.sender,address(this),community_id);
        require(community_admin != address(0),"Admin must be specified");
        require(address(chainImplementers[chain_id]) != address(0),"This chain is not implemented yet");
        uint256 position = nextCommunity++;
        communityListByID[community_id] = MasterListEntry(
            community_id,
            chain_id,
            community_admin,
            community_name
        );
        communitiesAsAdded[position] = community_id;
        chainImplementers[chain_id].createCommunity(community_id,community_admin,community_name);
        
        uint256 count = uint256(userCommunityLists[community_admin][0] += 1);
        userCommunityLists[community_admin][count] = community_id;
    }

    function launchKey() public view returns (IERC721) {
        return IERC721(reg.getRegistryAddress("LAUNCHKEY"));
    }

    function userCommunities(address user) external view returns (MasterListEntry[] memory) {
        uint256 count = uint256(userCommunityLists[user][0]);
        MasterListEntry[] memory mla = new MasterListEntry[](count);
        for (uint pos = 0; pos < count; pos++) {
            mla[pos] = communityListByID[userCommunityLists[user][pos+1] ];
        }
        return mla;
    }

}