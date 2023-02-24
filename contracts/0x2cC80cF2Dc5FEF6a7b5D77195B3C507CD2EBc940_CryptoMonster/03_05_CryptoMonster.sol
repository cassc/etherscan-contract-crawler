pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoMonster is ERC721A, Ownable {
    constructor() ERC721A("Crypto Monster", "Crypto Monster") {
        baseURI = 'https://nftstorage.link/ipfs/bafybeih5caaow7jtud3p4rxmbpewtbaixcj4nmj7sjfppsgy53eh3cdlpm/';
    }

    string public baseURI;
    uint256 maxSupply = 200;
    address[] public allowlist;

    function airdrop() external onlyOwner {
        require(totalSupply() <= maxSupply, "mint over");
        for (uint256 i; i < allowlist.length; i++) {
            _mint(allowlist[i], 8);
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