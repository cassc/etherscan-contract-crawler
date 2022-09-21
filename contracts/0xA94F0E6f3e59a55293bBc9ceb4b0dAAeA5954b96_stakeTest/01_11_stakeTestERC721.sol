// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract stakeTest is ERC721, Ownable, IERC721Receiver {
    using Strings for uint256;

    struct TokenConfig {
        uint256 darkId;
        uint256 lightId;
        uint256 maxDark;
        uint256 maxLight;
    }
    TokenConfig public tokenConfig;

    struct MintDetails {
        IERC721 tokenv1;
        string baseURI;
        uint256 totalSupply;
    }
    MintDetails public mintDetails;

    mapping(address => bool) public adminAddresses;

        modifier onlyAdminOrOwner {
        bool isAdmin = false;
        if (adminAddresses[msg.sender] == true) {
            isAdmin = true;
        }
        if (msg.sender == owner()) {
            isAdmin = true;
        }
        require(isAdmin == true, "Not an admin");
        _;
    }
    
    constructor(IERC721 _tokenv1, string memory baseURI) ERC721("Staketest", "staketest") {
        mintDetails.tokenv1 = _tokenv1;
        mintDetails.baseURI = baseURI;
        tokenConfig.darkId = 50;
        tokenConfig.lightId = 0;
        tokenConfig.maxDark = 100;
        tokenConfig.maxLight = 50;
    }

    function dark(uint256 _tokenId) external {
        MintDetails storage _mintDetails = mintDetails;
        require(_mintDetails.tokenv1.balanceOf(msg.sender) > 0, "Not a holder");
        require(tokenConfig.darkId < tokenConfig.maxDark, "Max dark supply reached");

        uint256 tokenId = _tokenId;
        require(_mintDetails.tokenv1.ownerOf(tokenId) == msg.sender, "Not the owner of this token");
        _mintDetails.tokenv1.safeTransferFrom(msg.sender, address(this), tokenId, "");

        unchecked {
            tokenConfig.darkId++;
            mintDetails.totalSupply++;
        }   
        _safeMint(msg.sender, tokenConfig.darkId);
    }

    function light(uint256 _tokenId) external {
        MintDetails storage _mintDetails = mintDetails;
        require(_mintDetails.tokenv1.balanceOf(msg.sender) > 0, "Not a holder");
        require(tokenConfig.lightId < tokenConfig.maxLight, "Max light supply reached");

        uint256 tokenId = _tokenId;
        require(_mintDetails.tokenv1.ownerOf(tokenId) == msg.sender, "Not the owner of this token");
        _mintDetails.tokenv1.safeTransferFrom(msg.sender, address(this), tokenId, "");

        unchecked {
            tokenConfig.lightId++;
            mintDetails.totalSupply++;
        }
        _safeMint(msg.sender, tokenConfig.lightId);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return mintDetails.baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistant token"
    );

    string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
    }

    function setBaseURI(string memory _newBaseURI) external onlyAdminOrOwner { 
        mintDetails.baseURI = _newBaseURI;
    }

    function setTokenv1Address(IERC721 _tokenv1) external onlyAdminOrOwner {
        mintDetails.tokenv1 = _tokenv1;
    }

    function setAdminAddresses(address[] calldata _wallets) external onlyAdminOrOwner { 
        for (uint256 i = 0; i < _wallets.length; i++) {
            adminAddresses[_wallets[i]] = true;
        }
    }
    function removeAdminAddresses(address[] calldata _wallets) external onlyAdminOrOwner { 
        for (uint256 i = 0; i < _wallets.length; i++) {
            adminAddresses[_wallets[i]] = false;
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}