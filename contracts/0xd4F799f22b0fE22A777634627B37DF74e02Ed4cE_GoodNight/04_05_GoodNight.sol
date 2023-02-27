pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GoodNight is ERC721A, Ownable {
    constructor() ERC721A("Good Night", "GOOD NIGHT") {
        baseURI = 'ipfs://bafybeicvuuspqdvgox44dn6377dzfthf5rgpjvur2khqqtnfsw3tdnomtm/';
    }

    string public baseURI;
    uint256 maxSupply = 600;
    address[] public allowlist;

    function airdrop() external onlyOwner {
        require(totalSupply() <= maxSupply, "mint over");
        for (uint256 i; i < allowlist.length; i++) {
            _mint(allowlist[i], 24);
        }
    }

    function seedAllowlist(address[] memory addresses)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist.push(addresses[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }
}