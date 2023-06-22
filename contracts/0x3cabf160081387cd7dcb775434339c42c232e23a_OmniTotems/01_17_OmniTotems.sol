// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//  ____  __  __ _   _ _____ _______ ____ _______ ______ __  __  _____
//  / __ \|  \/  | \ | |_   _|__   __/ __ \__   __|  ____|  \/  |/ ____|
//  | |  | | \  / |  \| | | |    | | | |  | | | |  | |__  | \  / | (___
//  | |  | | |\/| | . ` | | |    | | | |  | | | |  |  __| | |\/| |\___ \
//  | |__| | |  | | |\  |_| |_   | | | |__| | | |  | |____| |  | |____) |
//  \____/|_|  |_|_| \_|_____|  |_|  \____/  |_|  |______|_|  |_|_____/
contract OmniTotems is ERC721Enumerable, Ownable {

    // Omnimorphs contract
    IERC721Enumerable private _omnimorphsContract;

    // OmniFusion contract
    IERC1155 private _omniFusionContract;

    // base uri for token metadata
    string public baseURI;

    // whether minting is active
    bool public mintIsActive = false;

    // lock minting forever
    bool public mintLocked = false;

    // max number of totems that can be minted in 1 tx
    uint constant public MAX_MINT = 50;

    constructor(string memory _initialBaseURI, address _omnimorphsContractAddress) ERC721('OmniTotems', 'OMNITO') {
        _omnimorphsContract = IERC721Enumerable(_omnimorphsContractAddress);
        baseURI = _initialBaseURI;
    }

    // PUBLIC

    // mints totems for Omnimorphs held in batch
    function mintBatch(uint[] calldata ids) external {
        require(mintIsActive, "Minting is not currently active");
        require(ids.length > 0, "Cannot mint 0 totems");

        uint balance = _omnimorphsContract.balanceOf(msg.sender);

        require(ids.length <= MAX_MINT && ids.length <= balance, "Trying to mint too many totems");

        for (uint i = 0; i < ids.length; i++) {
            uint id = ids[i];

            // only mints the totems that don't yet exist and are owned by sender
            if (_omnimorphsContract.ownerOf(id) == msg.sender && !_exists(id)) {
                _safeMint(msg.sender, id);
            }
        }
    }

    // mints totems for Soul Shards held in batch
    function mintForSoulShards(uint[] calldata ids) external {
        require(mintIsActive, "Minting is not currently active");
        require(ids.length > 0, "Cannot mint 0 totems");
        require(ids.length <= MAX_MINT, "Trying to mint too many totems");

        for (uint i = 0; i < ids.length; i++) {
            uint id = ids[i];

            require(id > 0, "Cannot mint a totem with id 0");

            // only mints the tokens that don't yet exist and are owned by sender
            if (_omniFusionContract.balanceOf(msg.sender, id) == 1 && !_exists(id)) {
                _safeMint(msg.sender, id);
            }
        }
    }

    // OWNER

    // sets the fusion contract
    function setOmniFusionContract(address _address) external onlyOwner {
        _omniFusionContract = IERC1155(_address);
    }

    // set base uri when moving metadata
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    // set whether minting is active
    function setMintIsActive(bool value) external onlyOwner {
        require(!mintLocked, "Cannot reset, as minting is locked forever");

        mintIsActive = value;
    }

    // lock minting in an inactive state forever
    function lockMinting() external onlyOwner {
        require(!mintIsActive, "Can only lock when minting is inactive");

        mintLocked = true;
    }

    // INTERNALS

    // used internally by tokenURI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}