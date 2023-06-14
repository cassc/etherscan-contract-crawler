// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "solmate/src/utils/CREATE3.sol";

contract AddressToken is ERC721("1inch Address NFT", "1ANFT") {
    error RemintForbidden();
    error AccessDenied();
    error CallReverted(bytes);

    mapping(uint256 tokenId => bytes32 salt) public salts;

    function addressForTokenId(uint256 tokenId) external pure returns(address) {
        return address(uint160(tokenId));
    }

    function tokenURI(uint256 tokenId) public pure override returns(string memory) {
        bytes memory addr = bytes(Strings.toHexString(tokenId, 20));
        _checksumAddress(addr);
        return string.concat("data:application/json;base64,", Base64.encode(
            bytes.concat('{\n',
                '\t"name": "Deploy to ', addr, '",\n',
                '\t"description": "Enables holder to deploy arbitrary smart contract to ', addr, '",\n',
                '\t"external_url": "https://etherscan.io/address/', addr, '",\n',
                '\t"image": "ipfs://QmZW3TTdtK87ktxmh6PG5UumbtoWXU8rVBApo65oknekmc",\n',
                '\t"animation_url": "ipfs://QmZKp3K7oyDFPkVUXUgDKqZ6RcLZY7QW267JvXRTLW1qaG"\n'
            '}')
        ));
    }

    function _checksumAddress(bytes memory hexAddress) private pure {
        bytes32 hash;
        assembly {
            hash := keccak256(add(hexAddress, 0x22), sub(mload(hexAddress), 2))
        }
        for (uint256 i = 2; i < 42; i++) {
            uint256 hashByte = uint8(hash[(i - 2) >> 1]);
            if (((i & 1 == 0) ? (hashByte >> 4) : (hashByte & 0x0f)) > 7 && hexAddress[i] > '9') {
                hexAddress[i] = bytes1(uint8(hexAddress[i]) - 0x20);
            }
        }
    }

    function addressAndSaltForMagic(bytes16 magic) public view returns(address account, bytes32 salt) {
        salt = bytes32(uint256(type(uint128).max & uint160(msg.sender))) | bytes32(magic);
        account = CREATE3.getDeployed(salt);
    }

    function mint(bytes16 magic) external returns(uint256 tokenId) {
        (address account, bytes32 salt) = addressAndSaltForMagic(magic);
        tokenId = uint160(account);
        if (salts[tokenId] != 0) revert RemintForbidden();
        salts[tokenId] = salt;
        _mint(msg.sender, tokenId);
    }

    function deploy(uint256 tokenId, bytes calldata creationCode) public payable returns(address deployed) {
        if (msg.sender != ownerOf(tokenId)) revert AccessDenied();
        _burn(tokenId);
        deployed = CREATE3.deploy(salts[tokenId], creationCode, msg.value);
    }

    function deployAndCall(uint256 tokenId, bytes calldata creationCode, bytes calldata cd) external payable returns(address deployed) {
        deployed = deploy(tokenId, creationCode);
        (bool success, bytes memory reason) = deployed.call(cd);
        if (!success) revert CallReverted(reason);
    }
}