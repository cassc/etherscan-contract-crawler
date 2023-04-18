/**
 *Submitted for verification at Etherscan.io on 2023-04-17
*/

pragma solidity 0.8.1;

interface IERC20 { 
	
	function transfer(address to, uint256 amount) external returns (bool);

	function transferFrom(address from, address to, uint256 amount) external returns (bool);

	function balanceOf(address owner) external returns (uint256);

	function approve(address spender, uint256 amount) external;
	
}

interface IENSResolver { 

	function setContenthash(bytes32 node, bytes memory hash) external;

	function contenthash(bytes32 node) external returns (bytes memory);

}

interface IENSRegistry {

  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);

  function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;

}

contract Proposal {

    function executeProposal() external {  
        bytes32 ROOT_ENS_NODE = 0xe6ae31d630cc7a8279c0f1c7cbe6e7064814c47d1785fa2703d9ae511ee2be0c;
        bytes32 ENS_DOCS_LABEL_HASH = 0x6bf9054545420e9e9f4aa4f353a32c7d0d52c11dbcdda56c53be8375cafeebb1;
        bytes32 ENS_RELAYERS_NETWORK_LABEL_HASH = 0x25e5cde5b364d3ffc5a7c8fecda7cf863701488fc2dd91fb4c9e6c59e62bad4a;
        bytes32 ENS_RELAYERS_NETWORK_SUBNODE = 0x4e37047f2c961db41dfb7d38cf79ca745faf134a8392cfb834d3a93330b9108d;

        bytes memory ROOT_IPFS_HASH = hex"e301017012209958c2dae126b12afe086fa7397b4af704bbe4e7feda58813932078ecdaf71a3";
        bytes memory DOCS_IPFS_HASH = hex"e3010170122019d458d9e82c0e5637fb90f5a0701b273aee8f733691492f870c35517749769b";
        bytes memory RELAYERS_NETWORK_IPFS_HASH = hex"e30101701220fe412f995e15573c95e24858e0427816f13632c6aba8751538888d84747baf64";

        address _resolverAddress = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;
        address _registryAddress = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
        address _governanceAddress = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;
 
        IENSRegistry(_registryAddress).setSubnodeRecord(ROOT_ENS_NODE, ENS_DOCS_LABEL_HASH, _governanceAddress, _resolverAddress, 0);
        IENSRegistry(_registryAddress).setSubnodeOwner(ROOT_ENS_NODE, ENS_RELAYERS_NETWORK_LABEL_HASH, _governanceAddress);

        bytes32 ENS_DOCS_SUBNODE = IENSRegistry(_registryAddress).setSubnodeOwner(ROOT_ENS_NODE, ENS_DOCS_LABEL_HASH, _governanceAddress);

        IENSResolver(_resolverAddress).setContenthash(ROOT_ENS_NODE, ROOT_IPFS_HASH);
        IENSResolver(_resolverAddress).setContenthash(ENS_DOCS_SUBNODE, DOCS_IPFS_HASH);
        IENSResolver(_resolverAddress).setContenthash(ENS_RELAYERS_NETWORK_SUBNODE, RELAYERS_NETWORK_IPFS_HASH);
    }

}