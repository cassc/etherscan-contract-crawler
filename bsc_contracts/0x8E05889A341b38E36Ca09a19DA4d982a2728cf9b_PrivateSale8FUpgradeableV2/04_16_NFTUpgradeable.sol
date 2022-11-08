// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./PrivateSaleUpgradeable.sol";

contract PrivateSaleNft8FContractV1 is Initializable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    CountersUpgradeable.Counter private _uriIds;

    address public PSContract;

    string defaultNftUri;
    string metadataBaseUrl;

    modifier onlyContract {
        require(msg.sender == PSContract);
        _;
    }

    mapping (address => uint256[]) burnedTokenOwners;
    mapping (uint256 => address) ownersOfBurned;

     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        require (!PrivateSale8FUpgradeableV2(PSContract).isOpened(tokenId), "Your token is not transferable now! It is opened");
        PrivateSale8FUpgradeableV2(PSContract).transferDecrease(tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function initialize(string memory _metadataBaseUrl) initializer public {
        __ERC721_init("8F Vesting", "8F");
        __Ownable_init();
        metadataBaseUrl = _metadataBaseUrl;
    }

    function burnTokenAfterOpen(uint256 tokenId) public {
        require(ownerOf(tokenId) == tx.origin, "Only owner can burn");
        _burn(tokenId);
        burnedTokenOwners[tx.origin].push(tokenId);
        ownersOfBurned[tokenId] = tx.origin;
    }

    function fullOwnerOf(uint256 tokenId) external view returns (address owner1) {
        try this.ownerOf(tokenId) returns (address a) {
            return a;
        } catch (bytes memory) {
            require(ownersOfBurned[tokenId] != address(0), "Owner of non-existent token");
            return ownersOfBurned[tokenId];
        }
    }

    function currentTokenId() public view returns (uint256){
        return _tokenIds.current();
    }

    function setPSContract(address psContract) public onlyOwner {
        PSContract = psContract;
    }

    function setDefaultNftUri(string memory uri) public onlyOwner {
        defaultNftUri = uri;
    }

    function createToken(address owner) private returns (uint256) {
        require(owner != address(0), "Mint to the zero address");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(owner, newItemId);

        return newItemId;
    }

    function checkUri (string memory uri) private view returns (string memory) {
        bytes memory tempEmptyStringTest = bytes(uri);
        if (tempEmptyStringTest.length == 0) {
            return defaultNftUri;
        } else {
            return uri;
        }
    }

    function getMyTokens () public view returns (uint256[] memory){
        uint256[] memory _tokensOfOwner = new uint256[](balanceOf(tx.origin) + burnedTokenOwners[tx.origin].length);
        uint256 userTokenId = 0;
        for (uint256 i = 1; i <= _tokenIds.current(); i++) {
            if (this.fullOwnerOf(i) == tx.origin) {
                _tokensOfOwner[userTokenId] = i;
                userTokenId++;
            }
        }

        return _tokensOfOwner;
    }

    function _baseURI() internal view override returns (string memory) {
        return string(abi.encodePacked(metadataBaseUrl, "/"));
    }

    function privateSaleMint (address to, bool defaultImage) public onlyContract returns (uint256) {
        uint256 tokenId;
        tokenId = createToken(to);
        uint256 imageId = 0;
        if (!defaultImage) 
         {
             _uriIds.increment();
             imageId = _uriIds.current();
         }
        _setTokenURI(tokenId, Strings.toString(imageId));

        return tokenId;
    }

    function calculateTokens() public view returns (uint256 closed, uint256 opened) {
        for (uint256 i = 1; i <= _tokenIds.current(); i++) {
            if (_exists(i)) {
                closed++;
            } else {
                opened++;
            }
        }
    }
}