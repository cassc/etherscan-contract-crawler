//SPDX-License-Identifier: MIT
/*
                             /@\
                            @@@@@
                           #/   \#
                          @@     @@
                        #@@@     @@@#
                       @@@**     **@@@
                    /@@@@@         @@@@@\
             @@@@@@@@@@     KARMZ     @@@@@@@@@@
          /##@@@****#@@###         ###@@#****@@@#\
         @@@@          @@@@@     @@@@@          @@@@
        @@@              #@@     @@#              @@@
        @@%##############&@@     @@###############@@@
        @@@    @@@@      #@@     @@#     @@@@     @@@
        @@@              #@@     @@#              @@@
        @@@##          ##/         \##          ##@@@
        @@@  @@@@@@@@@@   @@     @@   @@@@@@@@@@  @@@
        @@@                                       @@@
        @@@            ###############            @@@
        @@@    @@@@@@@@@@/         \@@@@@@@@@@    @@@
        @@@  @@@@@                         @@@@@  @@@
        @@@##**                               **##@@@
          #@@@@@@@                         @@@@@@@#
               \@@@@@@@               @@@@@@@/
                 '**@@@###        ###@@@**'
                        \KARMELEONS/

*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


/// @title Karmeleons Karmz free mint contract
/// @author Jack Hancock (@DblJackDiamond) | Guidance from @AYYYliens_nft
/// @dev All function calls are currently implemented without side effects
contract Karmz is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    address public KARMELEONS_ADDRESS;
    string public NOT_REVEALED_URI;

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public MAX_SUPPLY = 3333;
    uint256 MINT_SUPPLY;

    mapping(uint => bool) public CLAIMED;

    bool public paused = true;
    bool public revealed = false;


    constructor(string memory _name, string memory _symbol, address _karmeleonsAddress, string memory _notRevealedURI) ERC721(_name, _symbol) {
        KARMELEONS_ADDRESS = _karmeleonsAddress;
        NOT_REVEALED_URI = _notRevealedURI;
    }

    modifier mintCompliance(uint256 _numberOfTokens) {
        require(supply.current() + _numberOfTokens <= MAX_SUPPLY, "Max supply exceeded!");
        require(_numberOfTokens > 0, "Invalid mint amount!");
        _;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        NOT_REVEALED_URI = _notRevealedURI;
    }


    /// @return uint The amount of Karmz minted
    function totalSupply() public view returns (uint) {
        return supply.current();
    }

    /// @return address[] A list of all owner addresses from 1 to totalSupply()
    function getAllOwners() public view onlyOwner returns (address[] memory){
        address[] memory karmzOwners = new address[](totalSupply());
        for(uint i=1; i <= totalSupply(); i++){
            karmzOwners[i -1] = ownerOf(i);
        }
        return karmzOwners;
    }


    /// @param _owner Address of account to check for Karmeleons
    /// @return uint The amount of Karmeleons the address has
    /// @return uint The amount of karmeleons eligible for free mint
    function karmeleonCount(address _owner) public view returns (uint, uint) {
        uint ownedKarmeleonCount = IERC721Enumerable(KARMELEONS_ADDRESS).balanceOf(msg.sender);
        uint validKarmeleonCount = 0;
        for(uint i=0; i < ownedKarmeleonCount; i++){
            if(!CLAIMED[IERC721Enumerable(KARMELEONS_ADDRESS).tokenOfOwnerByIndex(_owner, i)]){
                //Karmeleon is valid for mint
                validKarmeleonCount++;
            }
        }
        return (ownedKarmeleonCount, validKarmeleonCount);
    }


    /// @notice Retrieves the Karmeleons in owners account then returns karmeleons not been used for a free claim.
    /// @param _owner Address of account to check for Karmeleons
    /// @return uint[] Array of Eligible karmeleons by ID.
    function remainingMints(address _owner) internal view returns (uint[] memory) {
        uint ownedKarmeleonCount;
        uint validKarmeleonCount;
        (ownedKarmeleonCount, validKarmeleonCount) = karmeleonCount(_owner);
        uint[] memory validKarmeleons = new uint[](validKarmeleonCount);
        for(uint i=0; i < ownedKarmeleonCount; i++){
            uint karmeleonID = IERC721Enumerable(KARMELEONS_ADDRESS).tokenOfOwnerByIndex(_owner, i);
            if(!CLAIMED[karmeleonID]){
                validKarmeleons[validKarmeleonCount - 1] = karmeleonID;
                validKarmeleonCount--;
            }
        }
        return validKarmeleons;
    }

    /// @notice Checks to make sure msg.sender has enough eligible karmeleons then mints the amount specified.
    /// @param _numberOfTokens Address of account to check for Karmeleons
    function mint(uint _numberOfTokens) public payable mintCompliance(_numberOfTokens) {
        require(!paused, "The contract is paused!");
        uint[] memory mintsRemaining = remainingMints(msg.sender);
        require(mintsRemaining.length >= _numberOfTokens, "You don't own enough non-claimed Karmeleons!");
        for(uint i=0; i < _numberOfTokens; i++) {
            CLAIMED[mintsRemaining[i]] = true;
            supply.increment();
            _mint(msg.sender, supply.current());
        }
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