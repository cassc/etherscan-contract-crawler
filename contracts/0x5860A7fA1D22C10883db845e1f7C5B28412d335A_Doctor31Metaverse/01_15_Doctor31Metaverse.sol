//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Doctor31Metaverse is ERC721, ERC2981, Ownable{
    constructor() ERC721("Doctor31Metaverse","DOC31"){}

    uint256 public MINT_LIMIT = 10000;
    uint256 public minted = 1;
    mapping(address => bool) public admins;

    string public baseURI;
    string public uriSuffix;

    function mint(uint256 amount, address to) public{
        require(admins[msg.sender],"You are not a admin!");
        require(minted+amount<MINT_LIMIT+2,"Mint limit exceeded!");
        for(uint256 i=0;i<amount;i++){
            _mint(to, minted+i);
        }
        minted+=amount;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"NFT does not exist");

        if (bytes(baseURI).length == 0) {
            return Strings.toString(tokenId);
        }

        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), uriSuffix));
    }

    function setAdminAddress(address admin) public onlyOwner{
        admins[admin] = true;
    }

    function removeAdminAddress(address admin) public onlyOwner{
        admins[admin] = false;
    }

    function setBaseURI(string memory uri) public{
        baseURI = uri;
    }

    function setSuffix(string memory suffix) public{
        uriSuffix = suffix;
    }

    function setRoyalties(address to, uint96 feeNumerator) public onlyOwner{
        _setDefaultRoyalty(to,feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}