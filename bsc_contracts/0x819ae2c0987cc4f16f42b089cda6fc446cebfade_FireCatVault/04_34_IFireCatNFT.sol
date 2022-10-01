// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

/**
* @notice IFireCatNFT
*/
interface IFireCatNFT is IERC721 {

    /**
     * @notice Return total amount of supply, not include destoryed.
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() external view returns (uint256);

    /**
    * @notice Latest ID not yet minted.
    * @dev currentTokenId add 1.
    * @return tokenId
    */
    function freshTokenId() external view returns (uint256);

    /**
    * @notice check user whether has minted.
    * @dev fetch data from _hasMinted.
    * @param user user_address.
    * @return minted
    */
    function hasMinted(address user) external view returns (bool);

    /**
    * @notice the supply limit of NFT, set by owner.
    * @return supplyLimit
    */
    function supplyLimit() external view returns (uint256);

    /**
    * @notice the highest level of NFT, set by owner.
    * @return highestLevel 
    */
    function highestLevel() external view returns (uint256);

    /**
    * @notice check tokenId by address.
    * @dev fetch data from _ownerTokenId.
    * @param owner user_address.
    * @return tokenId
    */
    function tokenIdOf(address owner) external view returns (uint256[] memory);

    /**
    * @notice check token level by Id.
    * @dev fetch data from _tokenLevel.
    * @param tokenId uint256.
    * @return tokenLevel
    */
    function tokenLevelOf(uint256 tokenId) external view returns (uint256);

    /**
    * @notice Metadata of NFT. 
    * @dev Combination of baseURI and tokenLevel
    * @param tokenId uint256.
    * @return json
    */
    function tokenURI(uint256 tokenId) external view returns (string memory);
    
    /**
    * @notice Use for airdrop.
    * @dev access: onlyOwner.
    * @param recipient address.
    * @return newTokenId
    */
    function mintTo(address recipient) external returns (uint256);

    /**
    * @notice Use for Multi address airdrop.
    * @dev access: onlyOwner.
    * @param recipients address[].
    */
    function multiMintTo(address[] memory recipients) external;

    /**
    * @notice Use for firecat proxy.
    * @dev access: onlyProxy.
    * @param recipient address.
    * @return newTokenId
    */
    function proxyMint(address recipient) external returns (uint256);
    
    /**
    * @notice Required two contracts to upgrade NFT: upgradeProxy and upgradeStorage.
    * @dev Upgrade needs to get permission from upgradeProxy.
    * @param tokenId uint256.
    */
    function upgradeToken(uint256 tokenId) external;

    /**
    * @notice Increase the supply of NFT as needed.
    * @dev set to _supplyLimit.
    * @param amount_ uint256.
    */
    function addSupply(uint256 amount_) external;

    /**
    * @dev Burn an ERC721 token.
    * @param tokenId_ uint256.
     */
    function burn(uint256 tokenId_) external;

    /**
    * @notice Set the highest level of NFT.
    * @dev set to _highestLevel.
    * @param level_ uint256.
    */
    function setHighestLevel(uint256 level_) external;

    /**
    * @notice set the upgrade logic contract of NFT.
    * @dev set to upgradeProxy.
    * @param upgradeProxy_ address.
    */
    function setUpgradeProxy(address upgradeProxy_) external;

    /**
    * @notice set the upgrade condtiions contract of NFT.
    * @dev set to upgradeStorage.
    * @param upgradeStorage_ address.
    */
    function setUpgradeStorage(address upgradeStorage_) external;

    /**
    * @notice The proxy contract is responsible for the minting。
    * @dev set to fireCatProxy.
    * @param fireCatProxy_ address.
    */
    function setFireCatProxy(address fireCatProxy_) external;
}