//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "./NameEncoder.sol";

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface ENS {
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function recordExists(bytes32 node) external view returns (bool);
}

interface Resolver {
    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external;

    function setAddr(bytes32 node, address addr) external;
    function addr(bytes32 node) external view returns (address);
}

abstract contract ReverseResolver {
    mapping (bytes32 => string) public name;    
}

contract LuftRegistrar {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (bytes memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return buffer;
    }

    Resolver constant ensResolver = Resolver(0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41);
    ENS constant ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    IERC721 constant basisNFT = IERC721(0x356E1363897033759181727e4BFf12396c51A7E0);
    ReverseResolver constant revreg = ReverseResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047);

    bytes32 immutable rootNode = NameEncoder.dnsEncodeName("theluftballons.eth");
    
    string constant avatarURL = "eip155:1/erc721:0x356E1363897033759181727e4BFf12396c51A7E0/";

    function register(uint256 balloon) public {
        require(msg.sender == basisNFT.ownerOf(balloon), "NOT OWNER");
        bytes32 subnode = keccak256(abi.encodePacked(toString(balloon)));
        bytes32 node = NameEncoder.dnsEncodeName(string(abi.encodePacked(toString(balloon),".theluftballons.eth")));
        bool existed = ens.recordExists(node);
        
        if(!existed){
            ens.setSubnodeRecord(rootNode, subnode, address(this), address(ensResolver), 0);
            ensResolver.setText(node,"avatar",string(abi.encodePacked(avatarURL,toString(balloon))));
        }

        ensResolver.setAddr(node, msg.sender);
    }

    function reverseNode(address addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes32(0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2), sha3HexAddress(addr)));
    }

    function isRegistered(uint256[] memory balloons) public view returns (uint256[] memory registered) {
        registered = new uint256[](balloons.length);

        for(uint i = 0; i < balloons.length; i++) {
            string memory dns = string(abi.encodePacked(toString(balloons[i]),".theluftballons.eth"));
            bytes32 node = NameEncoder.dnsEncodeName(dns);

            if(ensResolver.addr(node) == msg.sender) {
                string memory reverseDNS = revreg.name(reverseNode(msg.sender));
                if(NameEncoder.dnsEncodeName(reverseDNS) == node)
                    registered[i] = 2;
                else
                    registered[i] = 1;
            }
        }
    }

    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        addr;
        ret; // Stop warning us about unused variables
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000

            for { let i := 40 } gt(i, 0) { } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }
}