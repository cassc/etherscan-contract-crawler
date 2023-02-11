pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AsciiPunksRenderer is Ownable {
    using Strings for uint256;
    string public baseUri = "https://storage.googleapis.com/asciipunks/punk";
    string public suffix = ".png";
    string public baguetteUri = "https://storage.googleapis.com/asciipunks/baguette.png";

    bool public contractSealed;

    modifier unsealed() {
        require(!contractSealed, "contract is sealed");
        _;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(baseUri, tokenId.toString(), suffix));
    }
    function baguette() external view returns (string memory) {
        return baguetteUri;
    }

    function setBaseUri(string memory _newBaseUri) external onlyOwner unsealed {
        baseUri = _newBaseUri;
    }
    function setSuffix(string memory _newSuffix) external onlyOwner unsealed {
        suffix = _newSuffix;
    }
    function setBaguette(string memory _newBaguette) external onlyOwner unsealed {
        baguetteUri = _newBaguette;
    }
    function seal() external onlyOwner unsealed { 
        //can only be called once, locks the IFPS contract.
        contractSealed = !contractSealed;
    }
}