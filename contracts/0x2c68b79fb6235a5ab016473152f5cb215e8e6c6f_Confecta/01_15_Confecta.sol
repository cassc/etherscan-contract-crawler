// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

///////////////////////////////////////////////////////
//   ___  _____  _  _  ____  ____  ___  ____   __    //
//  / __)(  _  )( \( )( ___)( ___)/ __)(_  _) /__\   //
// ( (__  )(_)(  )  (  )__)  )__)( (__   )(  /(__)\  //
//  \___)(_____)(_)\_)(__)  (____)\___) (__)(__)(__) //
//                                                   //
///////////////////////////////////////////////////////
// by Nick Kuder

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract Confecta is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ERC721Burnable
{
    uint256 private _tokenIdCounter;

    string private baseUri;
    uint256 public mintPrice; // in Wei
    uint256 public availSupply; // public supply
    // mapping address to number of works it can mint
    mapping(address => uint8) public whitelist; // Rings Genesis specific optimization: uint8 has max of 255. no one address can hold more than 255 pieces because the RG supply is 65

    event Mint(address indexed _purchaser, uint256 _tokenId, uint256 _price);

    modifier supplyAvailable() {
        require(availSupply > 0, "Reached max public token supply");
        _;
    }

    constructor(
        uint256 _mintPrice,
        uint256 _availSupply,
        string memory _baseUri
    ) ERC721("Confecta", "CFKTA") {
        mintPrice = _mintPrice;
        availSupply = _availSupply;
        baseUri = _baseUri;

        pause();
    }

    function setAvailSupply(uint256 _availSupply) public onlyOwner {
        availSupply = _availSupply;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    // add a single entry to whitelist. can also be used to remove if _mints set to 0.
    function setWhitelistEntry(address _whitelister, uint8 _mints)
        public
        onlyOwner
    {
        whitelist[_whitelister] = _mints;
    }

    // attempt to set many entries in whitelist. refer to setWhitelistEntry for more info.
    function setWhiteList(address[] memory _whitelisters, uint8[] memory _mints)
        public
        onlyOwner
    {
        require(
            _whitelisters.length == _mints.length,
            "Length of Whitelistees Does Not Match Length of Quantity of Mints Per Whitelistee"
        );
        for (uint256 i = 0; i < _whitelisters.length; i++) {
            whitelist[_whitelisters[i]] = _mints[i];
        }
    }

    // mint one of whitelisters token
    function whitelistMint() public {
        bool onWhitelist = whitelist[msg.sender] > 0;
        require(onWhitelist, "Minter is not on Whitelist");

        // run side-effect first
        // decrease
        whitelist[msg.sender] -= 1;
        mint(msg.sender, 0);
    }

    // mint all of whitelisters tokens with one call
    function whitelistMintAll() public {
        uint8 mintsAvail = whitelist[msg.sender];
        require(mintsAvail > 0, "Minter is not on Whitelist");

        // run side-effect first
        // decrease
        for (uint8 i = 0; i < mintsAvail; i++) {
            whitelist[msg.sender] -= 1;
            mint(msg.sender, 0);
        }
    }

    // purchase token with mintPrice if not on whitelist
    function purchase() public payable supplyAvailable {
        // check can mint
        bool notOnWhitelist = whitelist[msg.sender] <= 0; // either not on whitelist or ran out of mints
        if (notOnWhitelist) {
            // make sure Eth was sent
            require(
                msg.value == mintPrice,
                "Eth Value Not Equal to Mint Price"
            );
        } else {
            revert("Purchaser is on Whitelist; Call `whitelistMint` instead");
        }

        // passed check, able to mint
        availSupply -= 1;
        mint(msg.sender, msg.value);
    }

    function mint(address _to, uint256 _mintPrice) internal {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(_to, tokenId);
        emit Mint(msg.sender, tokenId, _mintPrice);
    }

    // withdraw all ether from this contract to owner
    function withdraw() public onlyOwner {
        // get the amount of ether stored in this contract
        uint256 amount = address(this).balance;

        // send all ether to owner
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseUri = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function ownerMint() public onlyOwner {
        mint(owner(), 0);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        // pausable doesnt apply to owner in this case
        if (msg.sender != owner() && paused()) {
            revert("Pausable: paused");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // OPENZEPPELIN GENERATED CODE: start
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    // OPENZEPPELIN GENERATED CODE: end
}