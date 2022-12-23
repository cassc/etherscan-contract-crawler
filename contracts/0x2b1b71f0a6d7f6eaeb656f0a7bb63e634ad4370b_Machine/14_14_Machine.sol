pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Machine is ERC721, ERC721URIStorage{
    uint256 private _nextId = 1;

    struct UserDetails{
        uint256 timestamp;
        string name;
        uint8[] choices;
    }

    mapping (uint256 => UserDetails) private user_details;


    constructor() public ERC721("Sax Machine", "SAXMCH") {
        

    }

    function mint(string calldata name, uint8[] calldata choices, string memory uri) public {
        user_details[_nextId] = UserDetails({
            timestamp: block.timestamp,
            name: name,
            choices: choices
        });

        _safeMint(msg.sender, _nextId);
        _setTokenURI(_nextId, uri);

        _nextId++;
    }

    function getUserDetails(uint256 tokenId) public view returns (UserDetails memory) {
        return user_details[tokenId];
    }


    // The following functions are overrides required by Solidity.


    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


}