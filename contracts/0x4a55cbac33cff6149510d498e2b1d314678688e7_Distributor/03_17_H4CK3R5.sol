// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract H4CK3R5 is ERC721Enumerable, ERC2981, Ownable {
    
    uint256 public constant MAX_ID = 1507;

    address private multiSig = 0xFb34Fc2a64BB863015145370554B5fbA5eFc5DC8;
    string public baseUri = 'https://bafybeicnoxjorayfx2e3udo7gbbi2ab6j6bdc3yi4vhbrbpkz7fzqiimdu.ipfs.nftstorage.link/';
    address public distributor;

    constructor() 
        ERC721(
            "H4CK3R5",
            "H4CK3R5"
        ){
            _setDefaultRoyalty(multiSig, uint96(690));
        }

    modifier onlyDistributor() {
        require(distributor == _msgSender(), "H4CK3R5: caller is not the distributor");
        _;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    // minting should be called from the distributor contract which assigns an ID and gives it to the caller
    function mintFromDistributor(address to, uint256 id) external onlyDistributor {
        require(id<=MAX_ID && id != 0, "H4CK3R5: invalid ID");
        _mint(to, id);
    }

    ////////////////////////////////// Owner only functions //////////////////////////////////

    function updateRoyalties(address newghoulsMultiSig, uint96 newNumerator) external onlyOwner {
        _setDefaultRoyalty(newghoulsMultiSig, newNumerator);
    }

    function setDistributor(address newDistributor) external onlyOwner {
        distributor = newDistributor;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseUri = newBaseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return  interfaceId == type(IERC721Enumerable).interfaceId ||
                interfaceId == type(IERC2981).interfaceId ||
                super.supportsInterface(interfaceId);
    }
}