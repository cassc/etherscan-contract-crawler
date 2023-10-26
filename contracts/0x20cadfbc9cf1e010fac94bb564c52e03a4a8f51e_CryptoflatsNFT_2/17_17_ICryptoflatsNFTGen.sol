/**
* @author NiceArti (https://github.com/NiceArti) 
* To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
* @title The interface for implementing the CryptoFlatsNft smart contract 
* with a full description of each function and their implementation 
* is presented to your attention.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;



interface ICryptoflatsNFTGen
{
    /**
    * @notice an event that trigers when team wallet is transferred
    * @param from - address of user who called transfer event
    * @param oldTeamWalletAddress - old address of team wallet
    * @param newTeamWalletAddress - new address of team wallet
    */
    event TeamWalletTransferred (
        address indexed from,
        address indexed oldTeamWalletAddress,
        address indexed newTeamWalletAddress
    );

    /**
    * @notice an event that trigers when nft type changed
    * @param id - token id
    * @param newNftType - new nft type setted
    */
    event CryptoflatsNftTypeChanged (
        uint256 id,
        string newNftType
    );


    /**
    * @notice an event that trigers when whitelist root changed
    * @param from - address of user who called change whitelist event
    * @param oldWhitelistRoot - old whitelist root
    * @param newWhitelistRoot - new whitelist root
    * @param whitelistNaming - naming of whitelist (free purchase or early access)
    */
    event WhitelistRootChanged (
        address indexed from,
        bytes32 oldWhitelistRoot,
        bytes32 newWhitelistRoot,
        string whitelistNaming
    );


    /**
    * @notice displays the price for the whitelist of users
    * who received early access to the purchase of this NFT
    * @return uint256 - price for early access
    */
    function EARLY_ACCESS_PRICE()
        external
        view
        returns (uint256);


    /**
    * @notice determines the price of the NFT for everyone
    * who wants to purchase this asset
    * @return uint256 - price for public sale
    */
    function PUBLIC_SALE_PRICE()
        external
        view
        returns (uint256);


    /**
    * @notice the public address of the team that receives a reward 
    * in the form of 5% from the resale of the NFT. Also, to maintain 
    * the project, you can also donate to this address
    * @return address 
    */
    function teamWallet()
        external
        view
        returns (address payable);


    /**
    * @dev user data is stored on the backend, a complete merkle tree
    * has already been collected in the blockchain, which is recreated
    * every time you try to determine whether a user is a member of the whitelist
    * @notice The root of the Merkle tree as proof that the user is
    * a whitelist participant in this project who has the opportunity
    * to purchase a one-time NFT for free
    * @return bytes32 - Merkle proof root of free purchase whitelist
    */
    function whitelistFreePurchaseRoot()
        external
        view
        returns (bytes32);


    /**
    * @dev user data is stored on the backend, a complete merkle tree
    * has already been collected in the blockchain, which is recreated
    * every time you try to determine whether a user is a member of the whitelist
    * @notice The root of the Merkle tree as proof that the user is a
    * whitelist participant in this project who has the opportunity
    * to purchase NFT three times at a low price
    * @return bytes32 - Merkle proof root of early accessed whitelist
    */
    function whitelistEarlyAccessRoot()
        external
        view
        returns (bytes32);


    /**
    * @param user - wallet address of any user
    * @notice allows participants of the free mint to receive NFT
    * completely free paying only a transaction fee
    * @return bool - returns 'true' if user has already been minted 
    * NFT for free once
    */ 
    function isWhitelistFreePurchaseUserMintedOnce(address user)
        external
        view
        returns (bool);


    /**
    * @param user - wallet address of any user
    * @notice returns how many NFT-es were screwed up at a discount by
    * a user from a whitelist with early access. The maximum value is three
    * @return uint256
    */ 
    function getMintCountForEarlyAccessUser(address user)
        external
        view
        returns(uint256);


    /**
    * @notice current genesis of Cryptoflats NFT
    * @return uint256
    */ 
    function gen()
        external
        view
        returns(uint256);


    /**
    * @dev returns struct with user whitelist status
    * @param whitelistMerkleProof - bytes32 array of merkle proofs
    * @param account - address of user who may be whitelisted
    * @notice free purchasing is available only once for whitelisted
    * @return bool
    */ 
    function isUserFreePurchaseWhitelist(
        bytes32[] calldata whitelistMerkleProof,
        address account,
        uint256 wlBox
    ) 
        external
        view
        returns(bool);

    /**
    * @dev returns true if user is from early access whitelist
    * @param whitelistMerkleProof - bytes32 array of merkle proofs
    * @param account - address of user who may be whitelisted
    * @notice discount for users with early access is available only thee times
    * @return bool
    */ 
    function isUserEarlyAccessWhitelist(
        bytes32[] calldata whitelistMerkleProof,
        address account
    ) 
        external
        view
        returns(bool);


    /**
    * @dev accessible only via contract owner
    * @param newTeamWallet - new team wallet address
    * @notice if for some reason there is a need to change the address of the 
    * team's wallet to a new one, then the owner will have the opportunity to
    * do this in order to save the assets received for the contract
    */ 
    function setNewTeamWallet(address payable newTeamWallet) external;


    /**
    * @dev accessible only via contract owner
    * @param newFreePurchaseWhitelistRoot - new free purchase whitelist root
    * @notice during the promotion of the project, the whitelist can both grow
    * and decrease, and in order for each user to be properly encouraged by
    * the team, the team allowed a change in the root tree of the whitelist
    */ 
    function setNewFreePurchaseWhitelistRoot(bytes32 newFreePurchaseWhitelistRoot) external;


    /**
    * @dev accessible only via contract owner
    * @param newEarlyAccessWhitelistRoot - new early access whitelist root
    * @notice during the promotion of the project, the whitelist can both grow
    * and decrease, and in order for each user to be properly encouraged by
    * the team, the team allowed a change in the root tree of the whitelist
    */ 
    function setNewEarlyAccessWhitelistRoot(bytes32 newEarlyAccessWhitelistRoot) external;


    /**
    * @dev accessible only via contract owner
    * @notice since the funds that users pay for the purchase of NFT go
    * into the contract, it is necessary to allow the owner to collect
    * the funds accumulated in the contract after user purchases
    * @return bool if balance withdraw was success
    */
    function withdrawBalance() external returns(bool);
}