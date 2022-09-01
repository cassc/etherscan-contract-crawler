// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "solmate/src/tokens/ERC721.sol";
import "solmate/src/auth/Owned.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import {SBC} from "./SBC.sol";
import {STAKEABLE} from "./STAKEABLE.sol";

contract Free2Own is ERC721, Owned {
    using Strings for uint256;

    uint256 public constant COST_TO_COMBINEABLE = 1000 ether;
    uint256 public constant MAX_TOKENS = 100;

    uint256 public currentTokenId;

    address public sbc;
    address public stakeable;

    mapping(address => bool) public addressHasMinted;

    mapping(uint256 => uint256) public tokenLevel;

    constructor() ERC721("Free2Own", "F2O") Owned(msg.sender) {}

    function setContracts(address _sbc, address _stakeable) external onlyOwner {
        sbc = _sbc;
        stakeable = _stakeable;
    }

    function mint() external {
        require(
            !addressHasMinted[msg.sender],
            "only 1 free2own per address, sorry pal"
        );
        require(currentTokenId < MAX_TOKENS, "no more available, sorry pal");

        ++currentTokenId;
        addressHasMinted[msg.sender] = true;
        _mint(msg.sender, currentTokenId);
        STAKEABLE(stakeable).stakeF2O(currentTokenId);
    }

    //
    // 🔥 BURNABLE
    //
    function burn(uint256 id) external {
        require(
            ownerOf(id) == msg.sender,
            "you don't own this free to own nft, sorry pal"
        );
        _burn(id);
    }

    //
    // 👨‍👩‍👧‍👦 COMBINEABLE
    //
    function combine(uint256 tokenIdToBurn, uint256 tokenIdToLevelUp) external {
        require(
            ownerOf(tokenIdToBurn) == msg.sender,
            "you don't own this free to own nft, sorry pal"
        );
        require(
            ownerOf(tokenIdToLevelUp) == msg.sender,
            "you don't own this free to own nft, sorry pal"
        );

        uint256 newLevel = tokenLevel[tokenIdToLevelUp] +
            tokenLevel[tokenIdToBurn] +
            1;

        SBC(sbc).burn(msg.sender, COST_TO_COMBINEABLE * newLevel);

        _burn(tokenIdToBurn);
        tokenLevel[tokenIdToLevelUp] = newLevel;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Free2Own #',
            tokenId.toString(),
            '",',
            '"description": "Battles on chain",',
            '"image": "',
            imageURI(tokenId),
            '",',
            '"attributes": [',
            '{"trait_type": "Level", "value": ',
            tokenLevel[tokenId].toString(),
            "}",
            "]",
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    string public imageBaseURI;
    string public imageURISuffix;
    bool public sameImage;

    function setImageBaseURI(
        string memory _imageBaseURI,
        string memory _imageURISuffix,
        bool _sameImage
    ) external onlyOwner {
        imageBaseURI = _imageBaseURI;
        imageURISuffix = _imageURISuffix;
        sameImage = _sameImage;
    }

    function imageURI(uint256 tokenId) public view returns (string memory) {
        if (sameImage) {
            return imageBaseURI;
        }

        return string.concat(imageBaseURI, tokenId.toString(), imageURISuffix);
    }
}