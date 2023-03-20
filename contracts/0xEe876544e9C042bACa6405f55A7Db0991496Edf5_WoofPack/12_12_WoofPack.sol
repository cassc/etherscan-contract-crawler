// SPDX-License-Identifier: NONE 

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WoofPack is Ownable, ERC721 {
    using Strings for uint256;

    uint256 constant MAX_SUPPLY = 5555;

    // URI pointing to NFT metadata
    string public uri;
    // list of addresses that can mint from contract, should only be Sale contract
    mapping(address => bool) public minters;

    // store the ids of the mints that increased rare chance with boom 
    mapping(uint256 => address) public rareBoosts;

    /****
    @param _uri URI pointing to metadata
    ****/
    constructor(string memory _uri) ERC721("WoofPack", "WOOF") {
        uri = _uri;
    }

    /****
    mints a token to the recipient and saves whether or not it should use the rare URI
    @param recipient the address to send the token to
    @param id the ID of the token to mint
    @param rareBoose whether or not the token is using the rare URI
    ****/
    function mint(address recipient, uint256 id, bool rareBoost) external onlyMinters {
        _mint(recipient, id);
        if(rareBoost)
            rareBoosts[id] = recipient;
    }

    function wasRareBoost(uint256 id) external view returns (bool tokenWasRareBoost) {
        return rareBoosts[id] != address(0);
    } 

    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(uri, tokenId.toString()));
    }

    /****
    allows the owner to update the general URI
    @param _uri the new URI
    ****/
    function setURI(string calldata _uri) external onlyOwner {
        uri = _uri;
    }

    /****
    allows the owner to add / remove a minter
    @param _minter the address of the minter to add / remove
    @param _value whether or not they should be able to mint
    ****/
    function setMinter(address _minter, bool _value) external onlyOwner {
        minters[_minter] = _value;
    }

    modifier onlyMinters {
        require(minters[msg.sender], "Only minters can take this action");
        _;
    }
}