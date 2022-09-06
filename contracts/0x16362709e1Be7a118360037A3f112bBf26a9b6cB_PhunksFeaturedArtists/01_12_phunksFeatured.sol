// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PhunksFeaturedArtists is ERC1155, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private mintSeriesId;

    mapping(uint256 => string) artTokenUriLocation;
    mapping(address => mapping(uint256 => bool)) addressToTokenClaimTracker;
    address public phunksContractAddress;
    IERC721 public phunkContract;

    function getPhunkBalance(address _wallet) public view returns (uint256 result) {
           return IERC721(phunksContractAddress).balanceOf(_wallet);
       }

    constructor() ERC1155("") {
    }

    function set_phunks_address(address _phunks_contract_address) public onlyOwner {
        phunksContractAddress = _phunks_contract_address;
    }

    function update_token_uri(uint256 _tokenId, string memory _uri) public onlyOwner {
        artTokenUriLocation[_tokenId] = _uri;
    }

    function add_new_token(string memory _uri) public onlyOwner {
        mintSeriesId.increment();
        artTokenUriLocation[mintSeriesId.current()] = _uri;
    }

    function mint(uint256 _id)
        public
    {
        require(!addressToTokenClaimTracker[msg.sender][_id], "Being greedy");
        require(_id <= mintSeriesId.current(), "Doesnt exist");
        require(getPhunkBalance(msg.sender) > 0, "Be a phunk plz");

        bytes memory data;
        addressToTokenClaimTracker[msg.sender][_id] = true;

        _mint(msg.sender, _id, 1, data);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId > 0, "Invalid Token ID");
        require(tokenId <= mintSeriesId.current(), "Invalid Token ID");
        return artTokenUriLocation[tokenId];
    }

}