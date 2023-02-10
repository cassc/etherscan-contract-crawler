pragma solidity ^0.8.13;

import "./L2ChainImplementerBase.sol";


interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract polygonChainImplementer is AccessControlEnumerable, L2ChainImplementerBase {

    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");

    event FxChildTunnelUpdated(address _fxChildTunnel);
    event L2communityRegistryCreationRequest(uint32 community_id,address community_admin,string community_name);



    // state sender contract
    IFxStateSender              public fxRoot;

    address                     public fxChildTunnel;

    constructor(
        address _fxRoot
    ) {
        fxRoot = IFxStateSender(_fxRoot);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN,msg.sender);
    }

    function setFxChildTunnel(address _fxChildTunnel) external onlyRole(CONTRACT_ADMIN) {
        require(fxChildTunnel == address(0x0), "FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
        _updateFxChildTunnel(_fxChildTunnel);

    }

    function updateFxChildTunnel(address _fxChildTunnel) external onlyRole(CONTRACT_ADMIN) {
        _updateFxChildTunnel(_fxChildTunnel);
    }

    function _updateFxChildTunnel(address _fxChildTunnel) internal  {
        fxChildTunnel = _fxChildTunnel;
        emit FxChildTunnelUpdated(_fxChildTunnel);
    }


    function createCommunity(
        uint32 community_id,
        address community_admin,
        string memory community_name
    ) external override {
        address master_reg = RegistryConsumer(reg).getRegistryAddress("MASTER_REGISTRY");
        
        require(master_reg == msg.sender,"Unauthorised access");
        require(fxChildTunnel != address(0),"fxChildTunnel not set");

        bytes memory message = abi.encodePacked(community_id,community_admin,community_name);
        fxRoot.sendMessageToChild(fxChildTunnel, message);

        createMainnetCommunity(community_id,community_admin,community_name);

        emit L2communityRegistryCreationRequest(
            community_id,
            community_admin,
            community_name
        );
    }

}