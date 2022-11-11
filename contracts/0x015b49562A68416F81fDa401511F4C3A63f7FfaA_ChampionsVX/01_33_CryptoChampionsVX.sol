// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Champions.sol";
import "./Staking.sol";

contract ChampionsVX is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    string public _baseTokenURI;
    Champions champions;
    Staking staking;

    function initialize(
        address _champions,
        address _staking,
        string memory baseURI
    ) public initializer {
        __Ownable_init();
        __ERC721_init("Crypto Champions VX", "CVX");
        champions = Champions(_champions);
        staking = Staking(_staking);
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mint(address recipient, uint256 tokenId) public {
        require(
            champions.ownerOf(tokenId) == recipient ||
                staking.ownerOf(tokenId) == recipient,
            "Not owner of specified champion"
        );
        require(!_exists(tokenId), "Token already minted");
        _mint(recipient, tokenId);
    }

    function bulkMint(uint256[] calldata tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mint(msg.sender, tokenIds[i]);
        }
    }

    function bulkMintFor(address recipient, uint256[] calldata tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            mint(recipient, tokenIds[i]);
        }
    }

    function heldTokens(address owner)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokens = new uint256[](champions.balanceOf(owner));
        for (uint256 i = 0; i < champions.balanceOf(owner); i++) {
            uint256 tokenId = champions.tokenOfOwnerByIndex(owner, i);
            if (!_exists(tokenId)) {
                tokens[i] = tokenId;
            }
        }
        return tokens;
    }

    function stakedTokens(address owner)
        internal
        view
        returns (uint256[] memory)
    {
        (uint256 stakedNftNum, , , ) = staking.stakingInfo(owner);

        uint256[] memory tokens = new uint256[](stakedNftNum);
        for (uint256 i = 0; i < stakedNftNum; i++) {
            uint256 tokenId = staking.tokenIdByIndex(i, owner);
            if (!_exists(tokenId)) {
                tokens[i] = tokenId;
            }
        }
        return tokens;
    }

    function mintableTokens(address owner)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        return (heldTokens(owner), stakedTokens(owner));
    }
}