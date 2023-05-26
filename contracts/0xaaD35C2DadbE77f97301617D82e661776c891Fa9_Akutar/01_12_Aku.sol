//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
Akutar.sol

Written by: mousedev.eth
Contributions by: manifold.xyz
Public Repository: https://github.com/mouse-dev-1/Akutar

15,000 NFTs in 4 sections

(6) ID 1-6 partner reserved NFTs

(529) ID 7-535 Mega OG Akutars, randomly assigned to 529 Mega OG Mint Pass holders (addresses known)

(2527) ID 536-3,062 OG Akutars, randomly assigned to 2,527 OG Mint Pass holders (addresses known)

(11938) ID 3,063-15,000 Akutars, randomly assigned to 6,443 Mint Pass holders + 5495 public bids (addresses known)

*/

contract Akutar is Ownable, ERC721, ERC721Burnable {
    //Contract URI
    string public CONTRACT_URI;

    //Base URI
    string public BASE_URI;

    //Shift Quantity;
    uint256 public shiftQuantity;

    //Block to base randomness off of
    uint256 blockToUse;

    uint256 _totalSupply;

    //Provenance hash
    string public PROVENANCE_HASH;

    //Struct to define a grouping of airdrops
    struct Grouping {
        uint256 startingIndex;
        uint256 endingIndex;
        uint256 minted;
    }

    //Mapping of groupingId to grouping struct.
    mapping(uint256 => Grouping) public airdropGroupings;

    // EIP2981
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    constructor() ERC721("Akutars", "AKU") {
        //Partner
        airdropGroupings[0] = Grouping(1, 7, 0);

        //Mega OG
        airdropGroupings[1] = Grouping(7, 536, 0);

        //OG
        airdropGroupings[2] = Grouping(536, 3063, 0);

        //Normal
        airdropGroupings[3] = Grouping(3063, 15001, 0);
    }



    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }

    function airdrop(uint256 airdropGrouping, address[] memory addresses)
        public
        onlyOwner
    {
        require(shiftQuantity > 0, "Not yet shifted!");

        Grouping memory thisGrouping = airdropGroupings[airdropGrouping];

        //Total tokens in this grouping.
        uint256 maxQuantityWithinThisGrouping = (thisGrouping.endingIndex -
            thisGrouping.startingIndex);

        //How much to shift within these constraints.
        uint256 shiftQuantityWithinThisGrouping = shiftQuantity %
            maxQuantityWithinThisGrouping;

        //Index to currently start on.
        uint256 startingIndexWithinThisGrouping = thisGrouping.startingIndex +
            thisGrouping.minted +
            shiftQuantityWithinThisGrouping;

        require(
            thisGrouping.minted + addresses.length <=
                maxQuantityWithinThisGrouping,
            "Would overflow grouping"
        );

        //Cast to thisId
        uint256 currentId = startingIndexWithinThisGrouping;

        for (uint256 i = 0; i < addresses.length; i++) {
            //If we are over the endingIndex because of the shuffle, adjust to current position minus max quantity;
            if (currentId >= thisGrouping.endingIndex)
                currentId = currentId - maxQuantityWithinThisGrouping;

            //Mint thisId
            _mint(addresses[i], currentId);

            //Increment ID by one.
            currentId++;
        }

        _totalSupply += addresses.length;
        airdropGroupings[airdropGrouping].minted += addresses.length;
    }

    function commit(string memory _provenanceHash) external onlyOwner {
        //Require shift hasn't happened
        require(blockToUse == 0, "Already committed!");

        //Set the block to use as 5 blocks from now
        blockToUse = block.number + 5;

        //Set the provenance hash
        PROVENANCE_HASH = _provenanceHash;
    }


    function reveal() external onlyOwner {
        //Require they have committed
        require(blockToUse != 0, "You have yet to commit");

        //Require shift hasn't happened
        require(shiftQuantity == 0, "Already shifted!");

        //Require it is at or beyond blockToUse
        require(
            block.number >= blockToUse,
            "Not enough time has passed to reveal"
        );

        //set shift quantity
        shiftQuantity = uint256(blockhash(blockToUse));
    }


    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");

        return
            string(
                abi.encodePacked(BASE_URI, Strings.toString(_tokenId), ".json")
            );
    }
    
    /**
     * ROYALTY FUNCTIONS
     */
    function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

}