// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMarmottoshisIsERC1155 {

    // @notice Structure to store artist's infos (by token ID)
    struct Metadata {
        uint id;
        string artist_name;
        string marmot_name;
        string link;
        string uri;
    }

    // @notice Enum of different steps of the contract process
    enum Step {
        SaleNotStarted,
        WLReservation,
        FreeMint,
        ReservationMint,
        FirstWhitelistMint,
        SecondWhitelistMint,
        PublicMint,
        SoldOut
    }

    event newReservation(address indexed sender); // New reservation
    event newRedeemRequest(address indexed sender, uint256 nftIdRedeemed, uint256 burnAmount, string btcAddress, uint256 satoshisAmount); // Redeem event (user want to claim sats)
    event newMint(address indexed sender, uint256 nftIdMinted); // New mint
    event stepUpdated(Step currentStep); // Step updated

    // @notice Returns the sum of all supplies for each NFT ID
    function totalSupply() external view returns (uint256);

    // @notice return max supply of NFTs
    function maxSupply() external view returns (uint256);

    // @notice return max token by NFT Id
    function maxToken() external view returns (uint256);

    /*
    * @notice return supply by ID of NFT
    * @param _tokenId : id of NFT
    */
    function supplyByID(uint256) external view returns (uint256);

    /*
    * @notice get number of Satoshis redeemable by NFT ID
    * @param uint : id of NFT
    */
    function redeemableById(uint256 _id) external view returns (uint256);

    /*
    * @notice get number of NFT's ID with supply left
    */
    function getNumberOfIdLeft() external view returns (uint256);

    // @notice return free mint merkle root
    function freeMintMerkleRoot() external view returns (bytes32);

    // @notice return first whitelist merkle root
    function firstMerkleRoot() external view returns (bytes32);

    // @notice return second whitelist merkle root
    function secondMerkleRoot() external view returns (bytes32);

    /*
    * @notice return if a user is in reservation list (true/false)
    * @param _account : address of user
    */
    function reservationList(address) external view returns (bool);

    /*
    * @notice return number of NFTs minted by user for reservation step
    * @param _account : address of user
    */
    function reservationMintByWallet(address) external view returns (uint256);

    /*
    * @notice return number of NFTs minted by user for free mint step
    * @param _account : address of user
    */
    function freeMintByWallet(address) external view returns (uint256);

    /*
    * @notice return number of NFTs minted by user for first whitelist step
    * @param _account : address of user
    */
    function firstWhitelistMintByWallet(address) external view returns (uint256);

    /*
    * @notice return number of NFTs minted by user for second whitelist step
    * @param _account : address of user
    */
    function secondWhitelistMintByWallet(address) external view returns (uint256);

    /*
    * @notice know if user is on a list
    * @param _account : address of user
    * @param _proof : Merkle proof
    * @param _step : step of the list (0 = free mint, 1 = first whitelist, 2 = second whitelist)
    */
    function isOnList(address _account, bytes32[] calldata _proof, uint256 _step) external view returns (bool);

    // @notice return reservation price
    function reservationPrice() external view returns (uint256);

    // @notice return reservation mint price
    function reservationNFTPrice() external view returns (uint256);

    // @notice return whitelist mint price (first and second)
    function whitelistPrice() external view returns (uint256);

    // @notice return public mint price
    function publicPrice() external view returns (uint256);

    // @notice return current reservation number
    function currentReservationNumber() external view returns (uint256);

    // @notice return balance of Satoshis of this contract
    function balanceOfSatoshis() external view returns (uint256);

    /*
    * @notice return balance infos by NFT Id
    * @param _tokenId : id of NFT
    */
    function balanceOfSatoshiByID(uint256) external view returns (uint256);

    /*
    * @notice return metadata infos by NFT Id
    * @param _tokenId : id of NFT
    */
    function metadataById(uint256) external view returns (uint id, string memory artist_name, string memory marmot_name, string memory link, string memory uri);

    // @notice return current step
    function currentStep() external view returns (Step);

    // @notice return if metadata are locked (true/false)
    function isMetadataLocked() external view returns (bool);

    // @notice return if NFT are revealed (true/false)
    function isRevealed() external view returns (bool);

    // @notice return marmott address
    function marmott() external view returns (address);

    ////////// Functions //////////
    /// Setter functions ///

    /*
    * @notice Mints a new token to msg.sender
    * @param uint : Id of NFT to mint.
    * @param bytes32[] : Proof of whitelist (could be empty []).
    */
    function mint(uint256 idToMint, bytes32[] calldata _proof) external payable;

    /*
    * @notice update step
    * @param _step step to update
    */
    function updateStep(Step _step) external;

    /*
    * @notice update Marmott's address
    * @param address : new Marmott's address
    */
    function updateMarmott(address _marmott) external;

    /*
    * @notice lock metadata
    */
    function lockMetadata() external;

    /*
    * @notice reveal NFTs
    */
    function reveal() external;

    /*
    * @notice update URI
    * @param string : new URI
    */
    function updateURI(string memory _newUri) external;

    /*
    * @notice create Metadata struct of an NFT and add it in metadataById mapping
    * @param uint[] : array of NFT Ids
    * @param string[] : array of artist names
    * @param string[] : array of marmot names
    * @param string[] : array of links
    * @param string[] : array of URIs
    */
    function addMetadata(uint[] calldata _id, string[] calldata _artists_names, string[] calldata _marmot_name, string[] calldata _links, string[] calldata _uri) external;

    /*
    * @notice add satoshis to balanceOfSatoshis
    * @param uint : amount of satoshis to add
    */
    function addSats(uint256 satoshis) external;

    /*
    * @notice remove satoshis from balanceOfSatoshis
    * @param uint : amount of satoshis to remove
    */
    function subSats(uint256 satoshis) external;

    /*
    * @notice redeem satoshis and burn NFT
    * @param uint : id of NFT to burn/redeem
    * @param string : bitcoin address to send satoshis to
    */
    function burnAndRedeem(uint256 _idToRedeem, string memory _btcAddress) external;

    /*
    * @notice function for user to be preWhitelist
    */
    function reservationForWhitelist() external payable;

    /*
    * @notice update first whitelist merkle root
    * @param _merkleRoot : new merkle root
    */
    function updateFirstWhitelistMerkleRoot(bytes32 _merkleRoot) external;

    /*
    * @notice update free mint merkle root
    * @param _merkleRoot : new merkle root
    */
    function updateFreeMintMerkleRoot(bytes32 _merkleRoot) external;

    /*
    * @notice update public price
    * @param _publicPrice : new public price
    */
    function updatePublicPrice(uint256 _publicPrice) external;

    /*
    * @notice update reservation NFT price
    * @param _reservationNFTPrice : new reservation NFT price
    */
    function updateReservationNFTPrice(uint256 _reservationNFTPrice) external;

    /*
    * @notice update reservation price
    * @param _reservationPrice : new reservation price
    */
    function updateReservationPrice(uint256 _reservationPrice) external;

    /*
    * @notice update second whitelist merkle root
    * @param _merkleRoot : new merkle root
    */
    function updateSecondWhitelistMerkleRoot(bytes32 _merkleRoot) external;

    /*
    * @notice update whitelist price
    * @param _whitelistPrice : new whitelist price
    */
    function updateWLPrice(uint256 _whitelistPrice) external;

    /*
    * @notice withdraw ether from contract
    */
    function withdraw() external;

    // @notice EIP2981 royalties
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;
}