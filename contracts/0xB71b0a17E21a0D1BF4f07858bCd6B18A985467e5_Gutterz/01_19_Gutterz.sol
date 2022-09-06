//SPDX-License-Identifier: MIT
/*
     ^\                                               /^
    @@@@@                                           @@@@@
   @@@@@@&                                        &@@@@@@
   @@  @@@@@@                                   @@@@@@  @
   #@   [email protected]@@@@@@@     /@@@@@@@@@@@@@@@\     @@@@@@@@@.  @
    @#  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  #@
     @&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@
     @@@@@@@@@@@@@@@@@@@@@ GUTTERZ @@@@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@@ BY KARMELO @@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@ CREATOR OF THE KARMELEONS @@@@@@@@@@@
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
     @@@     @@@@@@@      /@@@@@@\      @@@@@@@     @@@
      @@@@     @@@/     @@@@@@@@@@@@     \@@@     @@@@
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@
       @@@@@@@@@@@@@@@@@@@@\    /@@@@@@@@@@@@@@@@@@@@
          @@@@@@@@@@@@@@@@@@@||@@@@@@@@@@@@@@@@@@@
             @@@@@@@@@@@@@@@@/\@@@@@@@@@@@@@@@@
               @@@@@/-------/@@\-------\@@@@@
                \@@/@@@@@@@@@@@@@@@@@@@@\@@/
                     \@@@@@@@@@@@@@@@@/
*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/// @title Gutterz free mint contract $GTRZ
/// @author Jack (@DblJackDiamond) | Karmelo (@KeepItKarmelo) | © 2022 Karmic Labs, all rights reserved
/// @dev All function calls are currently implemented without side effects
contract Gutterz is ERC721, Ownable, ReentrancyGuard  {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    bool public paused = true;
    bool public revealed = false;
    string public NOT_REVEALED_URI = "ipfs://QmWLGZQ2nbNqZXu3cxdUbP9JtdA78w24pqDRrhNQSf6G4J/hidden.json";

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    string public _name = "Gutterz";
    string public _symbol = "GTRZ";
    uint256 public MAX_SUPPLY = 3000;

    IERC1155 public CATS_ADDRESS = IERC1155(0xEdB61f74B0d09B2558F1eeb79B247c1F363Ae452);
    IERC1155 public RATS_ADDRESS = IERC1155(0xD7B397eDad16ca8111CA4A3B832d0a5E3ae2438C);
    IERC721Enumerable public PIGEONS_ADDRESS = IERC721Enumerable(0x950b9476a4de757BB134483029AC4Ec17E739e3A);
    IERC721Enumerable public DOGS_ADDRESS = IERC721Enumerable(0x6E9DA81ce622fB65ABf6a8d8040e460fF2543Add);


    constructor() ERC721(_name, _symbol) {}

    modifier mintCompliance(uint256 _amount) {
        require(supply.current() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
        require(_amount > 0, "Invalid mint amount!");
        _;
    }

    /// @param _address Address of account to check for a Gutter species
    /// @param _id The ID of a Gutter species that the user says they own
    /// @return bool True if the address owns a Gutter species with that ID
    function hasGutterID(address _address, uint _id) public view returns (bool) {
        if(CATS_ADDRESS.balanceOf(_address, _id) > 0 ){
            return true;
        }
        if(RATS_ADDRESS.balanceOf(_address, _id) > 0 ){
            return true;
        }
        if(PIGEONS_ADDRESS.balanceOf(_address) > 0 ){
            return true;
        }
        if(DOGS_ADDRESS.balanceOf(_address) > 0 ){
            return true;
        }
        return false;
    }

    /// @return uint The amount of Gutterz minted
    function totalSupply() public view returns (uint) {
        return supply.current();
    }

    /// @notice Checks to make sure msg.sender is eligible to mint the desired amount of Gutterz
    /// @param _amount How many Gutterz to mint
    function mint(uint _amount, uint _id) public mintCompliance(_amount) nonReentrant {
        require(hasGutterID(msg.sender, _id), "You must own an OG Gutter Species to mint a Gutterz!");
        require(3 - balanceOf(msg.sender) - _amount >= 0, "You can only claim 3 Gutterz per wallet.");
        require(!paused, "The contract is paused!");
        for(uint i=0; i < _amount; i++) {
            supply.increment();
            _mint(msg.sender, supply.current());
        }
    }

    /// @notice Allows the owner to mint more than the wallet limit
    function ownerMint(uint _amount, address _to) public onlyOwner mintCompliance(_amount) {
        for(uint i=0; i < _amount; i++) {
            supply.increment();
            _mint(_to, supply.current());
        }
    }

    /// @return address[] A list of all owner addresses from 1 to totalSupply()
    function getAllOwners() public view onlyOwner returns (address[] memory){
        address[] memory gutterzOwners = new address[](totalSupply());
        for(uint i=1; i <= totalSupply(); i++){
            gutterzOwners[i -1] = ownerOf(i);
        }
        return gutterzOwners;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(!revealed) {
            return NOT_REVEALED_URI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    /// @notice Allows owner to start and stop minting process
    /// @param _state true = paused, false = not paused
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}