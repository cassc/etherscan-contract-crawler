pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./utils/Minting.sol";
import "./utils/String.sol";

contract Card is ERC721, AccessControl {
    mapping(uint256 => uint16) cardProtos;
    mapping(uint256 => uint8) cardQualities;

    event CardMinted(
        address to,
        uint256 amount,
        uint256 tokenId,
        uint16  proto,
        uint8   quality
    );

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    constructor(string memory baseURI)
        ERC721("Gods Unchained", "GU")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        string memory uri = string(abi.encodePacked(
            baseURI,
            String.fromAddress(address(this)),
            "/"
        ));

        super._setBaseURI(uri);
    }

    function mintFor(
        address to,
        uint256 amount,
        bytes memory mintingBlob
    ) public onlyAdmin {
        (uint256 tokenId, uint16 proto, uint8 quality) = Minting.deserializeMintingBlob(mintingBlob);
        super._mint(to, tokenId);
        cardProtos[tokenId] = proto;
        cardQualities[tokenId] = quality;

        emit CardMinted(to, amount, tokenId, proto, quality);
    }

    function burn(uint256 tokenId) public onlyAdmin {
        super._burn(tokenId);
    }

    /**
     * @dev Retrieve the proto and quality for a particular card represented by it's token id
     *
     * @param tokenId the id of the card you'd like to retrieve details for
     * @return proto The proto of the specified card
     * @return quality The quality of the specified card
     */
    function getDetails(
        uint256 tokenId
    )
        public
        view
        returns (uint16 proto, uint8 quality)
    {
        return (cardProtos[tokenId], cardQualities[tokenId]);
    }

}