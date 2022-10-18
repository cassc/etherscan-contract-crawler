//SPDX-License-Identifier: MIT
/*
     ^\                                               /^
    @@@@@                                           @@@@@
   @@@@@@&                                        &@@@@@@
   @@  @@@@@@                                   @@@@@@  @
   #@   [email protected]@@@@@@@     /@@@@@@@@@@@@@@@\     @@@@@@@@@.  @
    @#  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&  #@
     @&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@
     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@  GUTTERZ 2  @@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@ BY THE KARMELEONS @@@@@@@@@@@@@@@@
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


/// @title Gutterz Species 2 minting contract
/// @author Jack (@DblJackDiamond) on Twitter
/// @dev All functions have been tested and work correctly
contract Gutterz2 is ERC721, Ownable, ReentrancyGuard  {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // Keeps track of Gutterz Species 2 minted so far
    Counters.Counter private supply;

    // Mapping of which Karmeleons have claimed a free mint
    mapping(uint => bool) public CLAIMED;

    // Switch for turning public mint on and off
    bool public REQUIRE_GUTTERZ = true;
    // Price if going through public mint
    uint256 public PUBLIC_COST = 0.07 ether;


    bool public paused = true;
    bool public revealed = false;
    string public NOT_REVEALED_URI = "ipfs://QmbDNbq63c9mMNsq2tbZXkvB3nZwKZGzN8KK8dgyoWi4Ls/hidden.json";


    string public uriPrefix = "";
    string public uriSuffix = ".json";

    string public _name = "Gutterz 2";
    string public _symbol = "GTRZ2";
    uint256 public MAX_SUPPLY = 1000;


    IERC721Enumerable public KARMELEONS_CONTRACT = IERC721Enumerable(0xD396706543979149f7510839E9EB0B0608E8bc23);
    IERC721 public GUTTERZ_CONTRACT = IERC721(0xB71b0a17E21a0D1BF4f07858bCd6B18A985467e5);


    constructor() ERC721(_name, _symbol) {}

    modifier mintCompliance(uint256 _amount) {
        require(supply.current() + _amount <= MAX_SUPPLY, "Max supply exceeded");
        require(_amount > 0, "Invalid mint amount");
        _;
    }

    /// @param _address Address of account to check for a Gutterz Species 1
    /// @return bool True if the address owns a Gutter animal with that ID
    function hasGutterz(address _address) public view returns (bool) {
        if(GUTTERZ_CONTRACT.balanceOf(_address) > 0 ){
            return true;
        }
        return false;
    }

    /// @return uint The amount of Gutterz Species 2 minted
    function totalSupply() public view returns (uint) {
        return supply.current();
    }

    function checkWalletEligibility(address _wallet) public view returns (bool, uint) {
            if(hasGutterz(_wallet) || !REQUIRE_GUTTERZ){
                return (true, unusedKarmeleons(_wallet).length);
            } else {
                return (false, 0);
            }
    }

    ////////////////////////// 3 Mint types - free, public, and owner //////////////////////////

    /// @notice Checks to make sure msg.sender is eligible to mint the desired amount of Gutterz
    /// @param _amount How many Gutterz to mint
    function holdersMint(uint _amount) public mintCompliance(_amount) nonReentrant {
        require(hasGutterz(msg.sender), "You need to own a Gutterz Species 1 to mint a Gutterz Species 2 for free");
        uint[] memory freeMintsRemaining = unusedKarmeleons(msg.sender);
        require(freeMintsRemaining.length >= _amount, "You don't own enough unused Karmeleons");
        require(!paused, "The contract is paused");
        for(uint i=0; i < _amount; i++) {
            CLAIMED[freeMintsRemaining[i]] = true;
            supply.increment();
            _mint(msg.sender, supply.current());
        }
    }

    /// @notice Public mint for those that do not qualify for a free mint
    /// @param _amount How many Gutterz to mint
    function publicMint(uint _amount) public payable mintCompliance(_amount) nonReentrant {
        require(msg.value >= PUBLIC_COST * _amount, "Insufficient payment sent to mint");
        require(!paused, "The contract is paused");
        for(uint i=0; i < _amount; i++) {
            supply.increment();
            _mint(msg.sender, supply.current());
        }
    }

    /// @notice Allows the owner (Karmelo) to mint without restrictions
    function ownerMint(uint _amount, address _to) public onlyOwner mintCompliance(_amount) {
        for(uint i=0; i < _amount; i++) {
            supply.increment();
            _mint(_to, supply.current());
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////

    /// @return address[] A list of all owner addresses from 1 to totalSupply()
    function getAllOwners() public view onlyOwner returns (address[] memory){
        address[] memory gutterzOwners = new address[](totalSupply());
        for(uint i=1; i <= totalSupply(); i++){
            gutterzOwners[i -1] = ownerOf(i);
        }
        return gutterzOwners;
    }


    /// @notice Retrieves the Karmeleons in owners account then returns karmeleons not been used for a free claim.
    /// @param _owner Address of account to check for Karmeleons
    /// @return uint[] Array of Eligible karmeleons by ID.
    function unusedKarmeleons(address _owner) internal view returns (uint[] memory) {
        uint ownedKarmeleonCount = KARMELEONS_CONTRACT.balanceOf(_owner);
        uint validKarmeleonCount = 0;
        for(uint i=0; i < ownedKarmeleonCount; i++){
            if(!CLAIMED[KARMELEONS_CONTRACT.tokenOfOwnerByIndex(_owner, i)]){
                //Karmeleon is valid for mint
                validKarmeleonCount++;
            }
        }
        uint[] memory validKarmeleons = new uint[](validKarmeleonCount);
        for(uint i=0; i < ownedKarmeleonCount; i++){
            uint karmeleonID = KARMELEONS_CONTRACT.tokenOfOwnerByIndex(_owner, i);
            if(!CLAIMED[karmeleonID]){
                validKarmeleons[validKarmeleonCount - 1] = karmeleonID;
                validKarmeleonCount--;
            }
        }
        return validKarmeleons;
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

    function setCost(uint256 _newCost) public onlyOwner {
        PUBLIC_COST = _newCost;
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


    /// @notice Allows owner to change whether a gutterz 1 is required for mint or not
    /// @param _state true = Gutterz Required
    function setRequireGutterz(bool _state) public onlyOwner {
       REQUIRE_GUTTERZ = _state;
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