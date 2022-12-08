pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../registry/IRegistryConsumer.sol";


interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract polygonChainImplementer is AccessControlEnumerable {

    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");

        address reg = 0x1e8150050A7a4715aad42b905C08df76883f396F;



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
        fxChildTunnel = _fxChildTunnel;
    }

    function createCommunity(
        uint32 community_id,
        address community_admin,
        string memory community_name
    ) external {
        address master_reg = RegistryConsumer(reg).getRegistryAddress("MASTER_REGISTRY");
        
        require(master_reg == msg.sender,"Unauthorised access");

        bytes memory message = abi.encodePacked(community_id,community_admin,community_name);
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }

}