// contracts/Dogs0.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./Incubator.sol";

struct BirthCertificate {
    string name;
    uint256 birthday;
    uint256 vialId;
}

contract Dogs0 is ERC721AQueryable, Incubator, Ownable {
    address private vialsAddress;

    string private tokenUri;

    mapping(uint256 => BirthCertificate) private birthCertificates;

    constructor(
        string memory _tokenUri,
        address _vialsAddress
    ) ERC721A("The Digital Pets Company", "DOG0") {
        tokenUri = _tokenUri;
        vialsAddress = _vialsAddress;
    }

    function incubate(uint256 _vialId, address _to) external override {
        require(msg.sender == vialsAddress, "Unauthorized.");

        // mint
        _safeMint(_to, 1);

        // create birth certificate
        uint256 dogId = _totalMinted();
        birthCertificates[dogId] = BirthCertificate(
            Strings.toString(dogId),
            block.timestamp,
            _vialId
        );
    }

    function getBirthCertificate(
        uint256 _dogId
    ) external view returns (BirthCertificate memory) {
        return birthCertificates[_dogId];
    }

    function getVialId(uint256 _dogId) external view returns (uint256) {
        return birthCertificates[_dogId].vialId;
    }

    function getBirthday(uint256 _dogId) external view returns (uint256) {
        return birthCertificates[_dogId].birthday;
    }

    function setName(uint256 _dogId, string calldata _name) external {
        require(
            ownerOf(_dogId) == msg.sender,
            "Only owner can change the name."
        );
        birthCertificates[_dogId].name = _name;
    }

    function getName(uint256 _dogId) external view returns (string memory) {
        return birthCertificates[_dogId].name;
    }

    function setTokenUri(string calldata _tokenUri) external onlyOwner {
        tokenUri = _tokenUri;
    }

    function getTokenUri() external view returns (string memory) {
        return tokenUri;
    }

    function setVialsAddress(address _vialsAddress) external onlyOwner {
        vialsAddress = _vialsAddress;
    }

    function getVialsAddress() external view returns (address) {
        return vialsAddress;
    }

    /** OVERRIDES */
    function _baseURI() internal view virtual override returns (string memory) {
        return tokenUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}