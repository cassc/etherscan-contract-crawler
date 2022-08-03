// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BonesRewards.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BonesClaim is Ownable {

    BonesRewards public immutable rewardsToken;
    IERC721 public immutable nftCollection;

    struct Vault {
        ERC721AQueryable nft;
        string name;
        uint allocation;
        uint specialAllocation;
        uint[] specialTokens;
    }

    mapping(address => Vault) public vault;
    mapping(address => mapping(uint => bool)) public claimedTokens;

    constructor(
        IERC721 _nftCollection, 
        BonesRewards _rewardsToken
        ) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
    }

    function initialClaim(ERC721AQueryable _nft, uint[] calldata _tokenIDs) external { 
        Vault memory vaultInfo = vault[address(_nft)];
        require(_tokenIDs.length > 0, "Token array cannot be empty");
        uint amount;
        uint specialDiff = vaultInfo.specialAllocation - vaultInfo.allocation;
        for (uint i = 0; i < _tokenIDs.length; i++) {
            uint tokenId = _tokenIDs[i];
            require(ERC721AQueryable(_nft).ownerOf(tokenId) == _msgSender(), "You do not own this token");
            require(!claimedTokens[address(_nft)][tokenId], "This tokens rewards have already been claimed");
            if (vaultInfo.specialTokens.length > 0) {
                for (uint j = 0; j < vaultInfo.specialTokens.length; j++) {
                    if (tokenId == vaultInfo.specialTokens[j]) {
                        // amount += vaultInfo.specialAllocation;
                        amount += specialDiff;
                    }
                }
            }
            amount += vaultInfo.allocation;
            claimedTokens[address(_nft)][tokenId] = true;
        }

        if (amount > 0) {
            rewardsToken.mint(_msgSender(), amount * (10 ** 18));
        }
    }

    function ownerTokens(ERC721AQueryable _nft, address _user) public view returns (uint[] memory) {
        address NFT = address(_nft);
        return ERC721AQueryable(NFT).tokensOfOwner(_user);
    }

    function createVault(ERC721AQueryable _nft, string memory _name, uint _allocation, uint _specialAllocation, uint[] calldata _specialTokens) public onlyOwner {
        Vault memory newVault = Vault(
            _nft,
            _name,
            _allocation,
            _specialAllocation,
            _specialTokens
        );

        vault[address(_nft)] = newVault;
    }
}