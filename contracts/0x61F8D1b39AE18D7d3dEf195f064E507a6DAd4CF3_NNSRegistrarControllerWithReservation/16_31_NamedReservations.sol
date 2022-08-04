pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NamedReservations is Ownable {
    mapping(uint256=>bool) public reservedTokens;

    function reserveName(string memory name) public onlyOwner {
        uint256 tokenId = getToken(name);
        reservedTokens[tokenId] = true;
    }

    function unreserveName(string memory name) public onlyOwner {
        uint256 tokenId = getToken(name);
        reservedTokens[tokenId] = false;
    }

    function reserved(string memory name) view public returns (bool) {
        return reservedTokens[getToken(name)];
    }

    function getToken(string memory name) pure private returns(uint256) {
        bytes32 label = keccak256(bytes(name));
        return uint256(label);
    }
}