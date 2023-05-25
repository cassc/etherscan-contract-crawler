// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Admins.sol";

abstract contract ERC721Mint is ERC721, Admins, ReentrancyGuard {

    /**
    @notice Max supply available for this contract
    */
    uint32 public MAX_SUPPLY;

    /**
    @notice Amount of token reserved for team project/giveaway/other
    */
    uint32 public RESERVE;

    /**
    @notice Tracker for the total minted
    */
    uint32 public mintTracked;

    /**
    @notice Tracker for the total burned
    */
    uint32 public burnedTracker;

    /**
    @notice The number of the First token Id
    */
    uint8 public START_AT = 1;

    /**
    @notice The base URI for metadata for all tokens
    */
    string public baseTokenURI;


    /**
    @dev Verify if the contract is soldout
    */
    modifier notSoldOut(uint256 _count) {
        require(mintTracked + uint32(_count) <= MAX_SUPPLY, "Sold out!");
        _;
    }


    /**
    @notice Set the max supply of the contract
    @dev only internal, can't be change after contract deployment
    */
    function setMaxSupply(uint32 _maxSupply) internal {
        MAX_SUPPLY = _maxSupply;
    }

    /**
    @notice Set the amount of reserve tokens
    @dev only internal, can't be change after contract deployment
    */
    function setReserve(uint32 _reserve) internal {
        RESERVE = _reserve;
    }

    /**
    @notice Set the number of the first token
    @dev only internal, can't be change after contract deployment
    */
    function setStartAt(uint8 _start) internal {
        START_AT = _start;
    }

    /**
    @notice Set the base URI for metadata of all tokens
    */
    function setBaseUri(string memory baseURI) public onlyOwnerOrAdmins {
        baseTokenURI = baseURI;
    }

    /**
    @notice Get all tokenIds for a wallet
    @dev This method can revert if the mintedTracked is > 30000.
        it is not recommended to call this method from another contract.
    */
    function walletOfOwner(address _owner) public view virtual returns (uint32[] memory) {
        uint256 count = balanceOf(_owner);
        uint256 key = 0;
        uint32[] memory tokensIds = new uint32[](count);

        for (uint32 tokenId = START_AT; tokenId < mintTracked + START_AT; tokenId++) {
            if (_owners[tokenId] != _owner) continue;
            if (key == count) break;

            tokensIds[key] = tokenId;
            key++;
        }
        return tokensIds;
    }

    /**
    @notice Get the base URI for metadata of all tokens
    */
    function getBaseTokenURI() internal view returns(string memory){
        return baseTokenURI;
    }

    /**
    @notice Replace ERC721Enumerable.totalSupply()
    @return The total token available.
    */
    function totalSupply() public view returns (uint32) {
        return mintTracked - burnedTracker;
    }

    /**
    @notice Mint the next token
    @return the tokenId minted
    */
    function _mintToken(address wallet) internal returns(uint256){
        uint256 tokenId = uint256(mintTracked + START_AT);
        mintTracked += 1;
        _safeMint(wallet, tokenId);
        return tokenId;
    }

    /**
    @notice Mint the next tokens
    */
    function _mintTokens(address wallet, uint32 _count) internal{
        for (uint32 i = 0; i < _count; i++) {
            _mintToken(wallet);
        }
    }

    /**
    @notice Mint the tokens reserved for the team project
    @dev the tokens are minted to the owner of the contract
    */
    function reserve(uint32 _count) public virtual onlyOwnerOrAdmins {
        require(mintTracked + _count <= RESERVE, "Exceeded RESERVE_NFT");
        require(mintTracked + _count <= MAX_SUPPLY, "Sold out!");
        _mintTokens(_msgSender(), _count);
    }

    /**
    @notice Burn the token if is approve or owner
    */
    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not owner nor approved");
        burnedTracker += 1;
        _burn(_tokenId);
    }
}