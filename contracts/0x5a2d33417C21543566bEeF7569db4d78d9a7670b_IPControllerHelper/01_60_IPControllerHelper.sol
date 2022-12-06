// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IPRegistrarController.sol";

contract IPControllerHelper is Ownable {
    IPRegistrarController public controller;
    BaseRegistrar public immutable baseRegistrar;
    PublicResolver public immutable resolver;
    ENS public immutable registry;
    
    string public constant tldString = 'ip';
    bytes32 public constant tldLabel = keccak256(abi.encodePacked(tldString));
    bytes32 public constant rootNode = bytes32(0);
    bytes32 public immutable tldNode = keccak256(abi.encodePacked(rootNode, tldLabel));
    
    modifier onlyBaseRegistrar() virtual {
        require(msg.sender == address(baseRegistrar), "Only base registrar");
        _;
    }
    
    constructor(
        BaseRegistrar _base,
        IPRegistrarController _controller,
        PublicResolver _resolver
    ) {
        baseRegistrar = _base;
        controller = _controller;
        resolver = _resolver;
        registry = baseRegistrar.ens();
    }

    function setController(IPRegistrarController _controller) public onlyOwner {
        controller = _controller;
    }
    
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external onlyBaseRegistrar {}
    
    function afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external onlyBaseRegistrar {
        if (from == address(0)) return;
        
        bytes32 labelHash = bytes32(tokenId);
        bytes32 nodeHash = keccak256(abi.encodePacked(tldNode, labelHash));
        
        if (to == address(0)) {
            registry.setSubnodeOwner(tldNode, labelHash, address(this));
            resolver.clearRecords(nodeHash);
            return;
        }
        
        registry.setSubnodeOwner(tldNode, labelHash, address(this));
        
        resolver.clearRecords(nodeHash);
        resolver.setAddr(nodeHash, to);
        
        registry.setSubnodeRecord(tldNode, labelHash, to, address(resolver), 0);
    }
    
    function settleAuctions(
        string[] calldata names,
        address[] calldata owners
    ) public {
        require(names.length == owners.length, "Length mismatch");
        
        bytes[] memory empty = new bytes[](0);
        
        for (uint i; i < names.length; ++i) {
            uint tokenId = uint(keccak256(bytes(names[i])));
            
            if (baseRegistrar.exists(tokenId)) continue;
            
            controller.settleAuction(
                names[i],
                owners[i],
                365 days,
                address(0),
                empty,
                false
            );
        }
    }
    
    function settleAuctionsOfOneUser(
        string[] calldata names,
        address owner
    ) public {
        bytes[] memory empty = new bytes[](0);
        
        for (uint i; i < names.length; ++i) {
            uint tokenId = uint(keccak256(bytes(names[i])));
            
            if (baseRegistrar.exists(tokenId)) continue;
            
            controller.settleAuction(
                names[i],
                owner,
                365 days,
                address(0),
                empty,
                false
            );
        }
    }
    
    function getAuctionFromTokenId(uint tokenId) public view returns (IPRegistrarController.AuctionInfo memory) {
         (, string memory name,,) = controller.auctions(tokenId);
         return controller.getAuction(name);
    }
}