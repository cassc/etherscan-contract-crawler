// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ScorchingDucks is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxSupply = 10000;

    string public _provenanceHash;
    string public _baseURL;

    // Scorching variables
    IERC721 private ogd;
    event ScorchMultiple(address _from, uint256[] _tokenIds);
    bool private scorchIsActive = false;
    mapping(uint256 => uint256) public scorchDuckToOGDuck;

    // Minting
    bool private mintIsActive = false;



    constructor() ERC721("ScorchingDucks", "SCD") {
        // TODO Add as parameter
        ogd = IERC721(0x0F4B28D46CAB209bC5fa987A92A26a5680538e45);
    }

    function flipScorchingState() public onlyOwner {
        scorchIsActive = !scorchIsActive;
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function scorchNDucks(uint256[] memory tokenIds) public {
        require(scorchIsActive, "Scorching is not active");
        require(ogd.isApprovedForAll(msg.sender, address(this)), "Contract is not approved to transfer your OG Ducks.");
        require(tokenIds.length <= 10, "Can't scorch more than 10 Ducks at once.");

        for (uint i = 0; i < tokenIds.length; i++) {
            require(ogd.ownerOf(tokenIds[i]) == msg.sender, "You must own the requested token");

            // Burn OG Ducks
            ogd.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, tokenIds[i]);
            // Mint Duck
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
            scorchDuckToOGDuck[_tokenIds.current()] = tokenIds[i];
        }
        emit ScorchMultiple(msg.sender, tokenIds);
    }

    function mint(uint256 count) external payable {
        require(mintIsActive, "Mint is not active");
        require(_tokenIds.current() < _maxSupply, "Can not mint more than max supply");
        require(count > 0 && count <= 10, "You can mint between 1 and 10 at once");
        require(msg.value >= count * 0.03 ether, "Insufficient payment");
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }

        bool success = false;
        (success,) = owner().call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        _provenanceHash = provenanceHash;
    }

    function setBaseURL(string memory baseURI) public onlyOwner {
        _baseURL = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}