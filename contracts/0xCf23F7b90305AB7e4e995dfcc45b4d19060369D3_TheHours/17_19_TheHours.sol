// SPDX-License-Identifier: GPL-3.0
/// @title TheHours2.sol
/// @author Lawrence X Rogers
/// @dev this contract handles the NFT implementation (ERC721) and metadata formatting

pragma solidity ^0.8.19;

import "contracts/TheHoursArt.sol";
import "contracts/interfaces/ITheHours.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract TheHours is ITheHours, ERC721, Ownable {
    using Strings for uint256;
    using Mint for bytes32;

    // the rarity of each action type, out of 0xFF for each action
    bytes11 immutable public actionRarity;
    bytes11 immutable public actionRarityForAllowlist;
    
    // action availability, where each index corresponds to the action type
    bool[MINT_TYPES_COUNT] public isActionAvailable;
    bool[MINT_TYPES_COUNT] public isActionAvailableForAllowlist;
    
    // if a finishing touch is available, this is the type. NONE means not available.
    uint256 public finishingTouchType = MINT_TYPE_NONE;

    // the k value for the finishing touch rarity function
    uint256 public immutable finishingTouchK;

    // whether the collection has finished. no more minting after this.
    bool public finished = false;

    // address of the approved minter.
    address public approvedMinter;

    // the number of minted tokens and the id of the next token to be minted
    uint256 public tokenCounter;

    // all of the information about each mint. used to generate the SVG
    bytes32[] mintDetails;

    // the address of the Jackson2Art contract
    address immutable artAddress;


    /**
     * @notice create TheHours ERC721 contract
     * @param _actionRarity must have at least one byte as 0xFF to ensure one action is always available
     */
    constructor(
        address _artAddress, 
        bytes11 _actionRarity, 
        bytes11 _actionRarityForAllowList,
        uint256 _finishingTouchK
    ) ERC721("TheHours", "HOUR") {
        artAddress = _artAddress;
        actionRarity = _actionRarity;
        actionRarityForAllowlist = _actionRarityForAllowList;
        finishingTouchK = _finishingTouchK;
        approvedMinter = address(0);
        setActionAvailability();
    }

    /**
     * @notice set the approved minter
     * @notice this can only be set once
     */
    function setApprovedMinter(address _approvedMinter) public onlyOwner {
        require(approvedMinter == address(0), "TheHours: Approved minter already set");
        approvedMinter = _approvedMinter;
    }

    /**
     * @notice mint a new token to the given address, storing the mintDetails.
     * @notice updates the action availability.
     * @notice depends on approvedMinter being the AuctionHouse for validateBid to be called, so mintDetails respects action availability
     */
    function mint(bytes32 _mintDetails, address _to) public {
        require(finished == false, "TheHours: Minting is over");
        require(msg.sender == approvedMinter, "TheHours: Not approved minter");
        mintDetails.push(_mintDetails);

        _mint(_to, tokenCounter);
        unchecked {
            tokenCounter++;
        }
        
        setActionAvailability();
        
        if (_mintDetails.isFinishingTouch()) {
            finished = true;
        }
    }

    /**
     * @notice updates the availability of actions, including finishingTouch
     * @dev uses block.difficulty and block.number for creating a random seed
     * @dev the availability of each action is calculated independently by using different parts of the seed
     */
    function setActionAvailability() internal {
        bytes32 random = keccak256(abi.encodePacked(block.difficulty, block.number));
        
        for (uint256 i = 0; i < MINT_TYPES_COUNT; i++) {
            isActionAvailable[i] = random[i] <= actionRarity[i];
            isActionAvailableForAllowlist[i] = random[i] <= actionRarityForAllowlist[i];
        }

        finishingTouchType = (uint(random) % 10000 <= getFinishingTouchRarity10000()) ? 
            uint(random) % MINT_TYPES_COUNT : MINT_TYPE_NONE;
    }

    /**
     * @notice used by the AuctionHouse to make sure a given bid is valid
     * @param _mintDetails the details of the bid
     * @param _isInAllowlist whether the bidder is attempting to use the allowlist
     */
    function validateBid(bytes32 _mintDetails, bool _isInAllowlist) public view returns (bool) {
        require(_mintDetails.mintType() < MINT_TYPES_COUNT, "TheHours: Invalid mint type");

        if (_mintDetails.isFinishingTouch()) {
            require(finishingTouchType == _mintDetails.mintType(), "TheHours: Finishing touch not available for type");
            return true;
        }
        
        if (_isInAllowlist) {
            return isActionAvailableForAllowlist[_mintDetails.mintType()];
        }
        return isActionAvailable[_mintDetails.mintType()];
    }

    function getAllMintDetails() public view returns (bytes32[] memory) {
        return mintDetails;
    }

    /**
     * @notice returns the probability of a finishing touch being available, as a number out of 10000 (lowest probability is 0.01%)
     */
    function getFinishingTouchRarity10000() public view returns (uint) {
        if (tokenCounter <= 96) {
            return 0;
        }
        else {
            return (tokenCounter - 96) * (tokenCounter - 96) / finishingTouchK;
        }
    }

    function getActionAvailability() public view returns (bool[MINT_TYPES_COUNT] memory) {
        return isActionAvailable;
    }

    function getAllowlistActionAvailability() public view returns (bool[MINT_TYPES_COUNT] memory) {
        return isActionAvailableForAllowlist;
    }

    function _attributeNames() internal pure returns (string[MINT_TYPES_COUNT] memory) {
        return [
            "Rectangle",
            "Circle",
            "Rotate",
            "Quad",
            "Shear",
            "Background Color",
            "Window Rectangle",
            "Window Circle",
            "Tile",
            "Scale",
            "Italicize"
        ];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory theURI)
    {
        require(_exists(tokenId), "TheHours: Token doesn't exist");
        
        bytes memory imageURI = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(ITheHoursArt(artAddress).generateSVG(mintDetails, tokenId))
        );

        bytes memory actionTypeAttribute = abi.encodePacked(_attributeNames()[mintDetails[tokenId].mintType()]);
        if (mintDetails[tokenId].isFinishingTouch()) {
            actionTypeAttribute = abi.encodePacked("Finishing Touch -- ", actionTypeAttribute);
        }
        
        theURI = formatTokenURI(imageURI, tokenId, actionTypeAttribute);
    }

    function formatTokenURI(bytes memory imageURI, uint tokenId, bytes memory actionTypeAttribute)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{',
                            '"name" : "Hour#', tokenId.toString(), '", ',
                            '"description" : "An experimint in collaborative art the evolves through hourly auctions.", ',
                            '"image" : "', imageURI, '", ',
                            '"attributes": [{"trait_type":"Action Type", "value": "', actionTypeAttribute, '"}]',
                            "}"
                        )
                    )
                )
            );
    }
}