// SPDX-License-Identifier: MIT
// Archetype Auctionable NFT
//
//        d8888                 888               888
//       d88888                 888               888
//      d88P888                 888               888
//     d88P 888 888d888 .d8888b 88888b.   .d88b.  888888 888  888 88888b.   .d88b.
//    d88P  888 888P"  d88P"    888 "88b d8P  Y8b 888    888  888 888 "88b d8P  Y8b
//   d88P   888 888    888      888  888 88888888 888    888  888 888  888 88888888
//  d8888888888 888    Y88b.    888  888 Y8b.     Y88b.  Y88b 888 888 d88P Y8b.
// d88P     888 888     "Y8888P 888  888  "Y8888   "Y888  "Y88888 88888P"   "Y8888
//                                                            888 888
//                                                       Y8b d88P 888
//                                                        "Y88P"  888

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "solady/src/utils/LibString.sol";
import "../interfaces/IExternallyMintable.sol";


/* -------------- *\
|* Contract Utils *|
\* -------------- */
error ForbiddenMint();
error NonExistentTokenId();
error OptionLocked();
error WrongConfiguration();
error OwnershipError();

struct Config {
    string baseUri;
    // optional alternative address for owner withdrawals.
    address ownerAltPayout; 
    // optional platform address, will receive half of platform fee if set.
    address altPlatformPayout; 
    uint24 maxSupply;
    uint16 platformFee; //BPS
}

struct Options {
    bool mintLocked; 
    bool mintersManipulationLocked;
    bool maxSupplyLocked;
    bool baseUriLocked;
    bool ownerAltPayoutLocked;
}

address constant PLATFORM = 0x86B82972282Dd22348374bC63fd21620F7ED847B;
uint16 constant MAXBPS = 5000; // max fee or discount is 50%


contract PixeladyFigmata is ERC721Enumerable, Ownable, IExternallyMintable {

    Config public config;
    Options public options;
    mapping (address => bool) private _isMinter;
    

	constructor( 
        string memory name,
        string memory symbol,
        Config memory _config
    ) ERC721(name, symbol) { 
        if(
            (bytes(_config.baseUri).length == 0) || 
            (_config.maxSupply < 1) ||
            (_config.platformFee > MAXBPS && _config.platformFee < 500)
        ) revert WrongConfiguration();
        
        config = _config;
    }

    function withdraw() external {
        uint256 platformFee = address(this).balance * config.platformFee / 10000;

        // Platform withdrawal
        if (config.altPlatformPayout != address(0)) {
            payable(PLATFORM).transfer(platformFee / 2);
            payable(config.altPlatformPayout).transfer(platformFee / 2);
        } else payable(PLATFORM).transfer(platformFee);
        
        // Collection owner withdrawal
        if (config.ownerAltPayout != address(0))
            payable(config.ownerAltPayout).transfer(address(this).balance);
        else payable(owner()).transfer(address(this).balance);
    }

    function getPlatform() external pure returns (address) {
        return PLATFORM;
    }


    /* ---------------------------------- *\
    |* IExternallyMintable implementation *|
    \* ---------------------------------- */
    function mint(uint24 tokenId, address to) external {
        if (!_isMinter[msg.sender] || tokenId > config.maxSupply || options.mintLocked) 
            revert ForbiddenMint();
        _mint(to, tokenId);
    }

    function addMinter(address minter) external onlyOwner {
        if (options.mintersManipulationLocked) revert OptionLocked();
        _isMinter[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        if (options.mintersManipulationLocked) revert OptionLocked();
        _isMinter[minter] = false;
    }

    function isMinter(address minter) external view returns (bool) {
        return _isMinter[minter];
    }

    function exists(uint24 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function maxSupply() external view returns (uint24) {
        return config.maxSupply;
    }

    receive() external payable {}


    /* ------------------------------ *\
    |* IERC721Metadata implementation *|
    \* ------------------------------ */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentTokenId();

        return bytes(config.baseUri).length != 0
            ? string(abi.encodePacked(config.baseUri, LibString.toString(tokenId)))
            : "";
    }


    /* ----------------------------------- *\
    |* General contract state manipulation *|
    \* ----------------------------------- */
    function setMaxSupply(uint24 newMaxSupply) external onlyOwner {
        if (options.maxSupplyLocked) revert OptionLocked();
        if (newMaxSupply < totalSupply()) revert WrongConfiguration();
        config.maxSupply = newMaxSupply;
    }

    function setBaseUri(string memory newBaseUri) external onlyOwner {
        if (options.baseUriLocked) revert OptionLocked();
        config.baseUri = newBaseUri;
    }

    function setAltPayoutAddess(address newPayoutAddress) external onlyOwner {
        if (options.ownerAltPayoutLocked) revert OptionLocked();
        config.ownerAltPayout = newPayoutAddress;
    }

    function setSuperAffiliatePayout(address altPlatformPayout) external {
        if (msg.sender != PLATFORM) revert OwnershipError();
        config.altPlatformPayout = altPlatformPayout;
    }


    /* ---------------- *\
    |* Contract locking *|
    \* ---------------- */
    function lockMintForever() external onlyOwner {
        options.mintLocked = true;
    }

    function lockMintersManipulationForever() external onlyOwner {
        options.mintersManipulationLocked = true;
    }

    function lockMaxSupplyForever() external onlyOwner {
        options.maxSupplyLocked = true;
    }

    function lockBaseUriForever() external onlyOwner {
        options.baseUriLocked = true;
    }

    function lockOwnerAltPayoutForever() external onlyOwner {
        options.ownerAltPayoutLocked = true;
    }

}