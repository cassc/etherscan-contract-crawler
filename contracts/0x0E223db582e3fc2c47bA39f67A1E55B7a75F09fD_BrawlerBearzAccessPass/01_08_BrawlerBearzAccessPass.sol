// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**
 * @title BrawlerBearzAccessPass
 * @author @ScottMitchell18
 * @dev Access pass airdrop + public mint
 *
 * WARNING: Owner based Burn mechanic
 * Baked in off-chain oriented burn mechanic for "paperhands" of the airdropped passes
 *
 */
contract BrawlerBearzAccessPass is ERC721AQueryable, Ownable {
    using Strings for uint256;

    // @dev Base uri for the nft
    string private baseURI =
        "ipfs://bafybeihwwazh5gqlndzsm6zgoxakpcfx3yu4toud5th446xrjnioc2bmde/";

    // @dev Treasury
    address public treasury =
        payable(0x593b94c059f37f1AF542c25A0F4B22Cd2695Fb68);

    /*
     * @notice Mint Price
     * @dev Public mint price
     */
    uint256 public constant price = 0.01 ether;

    /*
     * @notice Mint Live ~ July 23rd, 5PM EST
     * @dev Public mint go live date
     */
    uint256 public liveAt = 1658610000;

    /*
     * @notice Total Supply
     * @dev The total supply of the collection (1-indexed)
     */
    uint256 public maxSupply = 445;

    // @dev An address mapping for max mint per wallet
    mapping(address => bool) public addressToMinted;

    constructor() ERC721A("Brawler Bearz Access Pass", "BBPASS") {}

    /**
     * @notice Mints a token
     * @dev Checks for price, whether sender can mint, mints, and toggles address mint flag
     */
    function mint() external payable {
        require(msg.value == price, "1");
        require(canMint(_msgSender()), "2");
        addressToMinted[_msgSender()] = true;
        _mint(_msgSender(), 1);
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    // @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp > liveAt;
    }

    /**
     * @dev Check if wallet has minted
     * @param _address mint address lookup
     */
    function hasMinted(address _address) public view returns (bool) {
        return addressToMinted[_address];
    }

    /**
     * @dev Check if wallet can mint
     * @param _address mint address lookup
     */
    function canMint(address _address) public view returns (bool) {
        return
            block.timestamp > liveAt &&
            totalSupply() + 1 < maxSupply &&
            !addressToMinted[_address];
    }

    // @dev Returns the starting token ID.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Yes, this is controversial
     * @dev Ability to burn specific tokenIds
     * @param _burnTokenIds Burn token ids
     *
     * Reasoning:
     * Pass is free (We are paying gas) and we want to set an adequate pre-mint floor for future NFT mint
     * This will ONLY be for the access passes
     */
    function paperhands(uint256[] calldata _burnTokenIds) external onlyOwner {
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            _burn(_burnTokenIds[i], false); // No owner or approval check
        }
    }

    /**
     * @dev Airdrop process
     * @param _addresses An array of user addresses to airdrop
     */
    function airdrop(address[] calldata _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1);
        }
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the go live timestamp
     * @param _liveAt A base uri
     */
    function setLiveAt(uint256 _liveAt) external onlyOwner {
        liveAt = _liveAt;
    }

    /**
     * @notice Sets the collection max supply
     * @param _maxSupply The max supply of the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    // @notice Withdraws funds from contract
    function withdraw() public onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "999");
    }
}