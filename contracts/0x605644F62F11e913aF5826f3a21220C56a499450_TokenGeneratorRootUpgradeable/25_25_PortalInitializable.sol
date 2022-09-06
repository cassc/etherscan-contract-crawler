pragma solidity 0.6.6;

contract PortalInitializable {
    bool inited;

    modifier portalInitializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}