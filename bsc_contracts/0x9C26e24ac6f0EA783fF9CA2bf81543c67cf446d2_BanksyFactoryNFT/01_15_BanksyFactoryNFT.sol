/*
     ,-""""-.
   ,'      _ `.
  /       )_)  \
 :              :
 \              /
  \            /
   `.        ,'
     `.    ,'
       `.,'
        /\`.   ,-._
            `-'         Banksy.farm

 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./libs/ERC721Presets.sol";

contract BanksyFactoryNFT is ERC721Presets {
    using SafeMath for uint256;
    using Strings for string;


    struct ArtWork {
        uint256 power;
        uint256 experience;
        uint256 generation;
        uint256 mergeCount;
    }

    ArtWork[] public artWorks;
    
    uint256 modulus = 100;
    // operator role
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    // minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    event RequestNewRandomArtWork(address indexed userAddress, uint256 nftID);
    event SetGeneration(address indexed userAddress, uint256 nftID, uint256 newValue);
    event SetPower(address indexed userAddress, uint256 nftID, uint256 newValue);
    event SetExperience(address indexed userAddress, uint256 nftID, uint256 newValue);
    event SetMergeCount(address indexed userAddress, uint256 nftID, uint256 newValue);
    event SetAllAttributes(address indexed userAddress, uint256 nftID, uint256[] newValue);
    event SetModulus(uint256 newValue);
    event SetTokenURI(uint256 nftID, string nftURI);


    constructor() ERC721("Banksy Factory NFT", "BanksyFactoryNFT")
    {   
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function requestNewRandomArtWork(
        uint256 _generation,
        address _userAddress
    ) external onlyRole(MINTER_ROLE) {

        uint256 newId = artWorks.length;
        uint256 power = randomNumber(_userAddress, newId);

        artWorks.push(
            ArtWork(
                power,
                0,
                _generation,
                0
            )
        );

        _safeMint(_userAddress, newId);

        emit RequestNewRandomArtWork(_userAddress, newId);
    }

    function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        return tokenURI(_tokenId);
    }


    function getNumberOfArtWorks() external view returns (uint256) {
        return artWorks.length; 
    }


    function setExperience(uint256 _tokenId, uint256 _newExperience) onlyRole(OPERATOR_ROLE) external {
        artWorks[_tokenId].experience = _newExperience;

        emit SetExperience(_msgSender(), _tokenId, _newExperience);
    }

    function setPower(uint256 _tokenId, uint256 _power) onlyRole(OPERATOR_ROLE) external {
        artWorks[_tokenId].power = _power;
        
        emit SetPower(_msgSender(), _tokenId, _power);
    }

    function setGeneration(uint256 _tokenId, uint256 _generation) onlyRole(OPERATOR_ROLE) external {
        artWorks[_tokenId].generation = _generation;

        emit SetGeneration(_msgSender(), _tokenId, _generation);
    }

    function setMergeCount(uint256 _tokenId, uint256 _newCount) onlyRole(OPERATOR_ROLE) external {
        artWorks[_tokenId].mergeCount = _newCount;

        emit SetMergeCount(_msgSender(), _tokenId, _newCount);
    }

    function setAllAttributes(uint256 _tokenId, uint256[] memory _values) onlyRole(OPERATOR_ROLE) external {
        artWorks[_tokenId].power = _values[0];
        artWorks[_tokenId].experience = _values[1];
        artWorks[_tokenId].generation = _values[2];
        artWorks[_tokenId].mergeCount = _values[3];

        emit SetAllAttributes(_msgSender(), _tokenId, _values);
    }

    function setModulus(uint256 _modulus) onlyRole(OPERATOR_ROLE) external {
        modulus = _modulus;

        emit SetModulus(_modulus);
    }


    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyRole(OPERATOR_ROLE) {
        require(_exists(tokenId));
        _setTokenURI(tokenId, _tokenURI);

        emit SetTokenURI(tokenId, _tokenURI);
    }

    function getArtWorkOverView(uint256 tokenId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            artWorks[tokenId].power,
            artWorks[tokenId].experience,
            artWorks[tokenId].generation
        );
    }
 
    function randomNumber(address _userAddress, uint256 _randNonce) internal view returns(uint256) {
        uint256 _randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp,
                                                _userAddress,
                                                _randNonce))) % modulus;
        if(_randomNumber < 10)
            _randomNumber = _randomNumber + 10;

        return _randomNumber;
    }

}