//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IRandomNumberProvider.sol";
import "../interfaces/IRegistryConsumer.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../extras/recovery/BlackHolePreventionForCROwner.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ITraitStorage {
    function setValue(uint16 _tokenId, uint8 _value) external;
    function getValue(uint16 _tokenId) external view returns (uint8);
    function getValues(uint16[] memory _tokenIds) external view returns (uint8[] memory);
    function traitId() external view returns (uint16);
    function maxTokensToRedeem() external view returns (uint8);
    function collectionToRedeemFrom() external view returns (address);
    function redeemMode() external view returns (uint8);
}

abstract contract UTDigitalRedeemVault is ERC721Holder, BlackHolePreventionForCROwner {
    string                         public constant  REGISTRY_KEY_RANDOM_CONTRACT = "RANDOMV2_SSP_TRAIT_DROPPER";
    string                         public constant  REGISTRY_KEY_FACTORY = "TRAIT_TYPE_6_FACTORY";
    uint8                                 constant  TRAIT_OPEN_VALUE = 1;
    IRegistryConsumer              public constant  GalaxisRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet tokenContracts;

    enum RedeemMode {
        random,                                         // 0 - Random redeem from the vault (with VRF)
        first                                           // 1 - Nonrandom redeem from the vault (transfer first card from vault) (no VRF)
        // pick                                         // 2 - Nonrandom redeem from the vault (user may select which card to transfer from vault) (no VRF) - NOT supported yet
    }

    enum ErrorCode {
        ok,                                             // 0 - 
        non_erc721,                                     // 1 - 
        not_enough_token,                               // 2 - 
        claim_over_limit,                               // 3 - 
        random_already_processed                        // 4 - 
    }

    struct dropStruct {
        uint256                     requestId;          // Request Id from chainlink
        address                     originalERC721;     // The NFT contract the trait was claimed on
        address                     rewardERC721;       // Token contract the reward is minted from
        address                     traitStorage;       // The trait storage is needed to handle race conditions (the user requested the claim so we need to check if someone changing the trait value before the callback)
        uint16                      tokenId;            // Token Id that initiated the request
        address                     recipient;          // Address that initiated the request (not necessary the winner, in case they sell it before VRF callback)
        uint8                       tokensToDrop;       // Number of digital redeemable NFTs the user requested
        uint256                     randomNumber;       // Filled by VRF callback
        bool                        randomReceived;     // VRF was received
        bool                        randomProcessed;    // The token was transfered
        ErrorCode                   errorCode;          // Stores error on VRF callback side (here we do not want to revert)
    }

    struct vaultDetails {                               // Structure to return detailed data from vault token contracts
        address                     erc721;
        string                      name;
        string                      symbol;
        uint256                     balance;
        string                      firstTokenURI;
    }

    uint32                          public              currentDropCount;

    mapping(address => uint16)      public              pendingPerCollection;
    mapping(uint32 => dropStruct)   public              drops;
    mapping(uint256 => uint32)      public              requestToDropIndex;

    // claimedTokens[traitId][tokenId][n] --> n-th received NFT for the trait+token
    mapping(uint16 => mapping(uint16 => mapping(uint16 => uint16) ) ) public claimedTokens;

    // traitTokenToDropIndex[traitId][tokenId] --> the used dropIndex for the trait+token
    mapping(uint16 => mapping(uint16 => uint32) ) public traitTokenToDropIndex;

    // Events
    event vaultDropRequested(uint32 index);
    event vaultDropProcess(uint32 index);
    event vaultDropProcessError(uint32 index);

    // Errors
    error claimOverLimit(uint8);
    error notEnoughToken(uint8);
    error notERC721Enumerable(address);
    error unauthorisedCall(address);
    error invalidCollection(address);
    error UTDigitalRedeemVaultNotAuthorized(address);

    /**
     * @dev Called from the trait controller when user claims the digital redeemable
     *      Depending on redeem mode:
     *          - Transfer cards directly
     *          - Calls VRF
     */
    function _requestDropFromVault(address _originalERC721, uint16 _tokenId, address _traitStorage, uint8 _tokensToDrop, address _rewardERC721) internal {
        // Pre-check
        IERC721Enumerable  token = IERC721Enumerable(_rewardERC721);
        if (!token.supportsInterface(type(IERC721Enumerable).interfaceId)) {
            revert notERC721Enumerable(_rewardERC721);
        }

        uint256 balance = token.balanceOf(address(this));
        if (balance - pendingPerCollection[_rewardERC721] < _tokensToDrop ) {
            revert notEnoughToken(_tokensToDrop);
        }

        pendingPerCollection[_rewardERC721] += _tokensToDrop;                      // Count the pending tokens to give

        ITraitStorage traitStorage = ITraitStorage(_traitStorage);
        uint8 newTraitValue = traitStorage.getValue(_tokenId) + _tokensToDrop;
        if (newTraitValue > TRAIT_OPEN_VALUE + traitStorage.maxTokensToRedeem()) {
            revert claimOverLimit(newTraitValue);
        }

        uint16 traitId = traitStorage.traitId();

        // Prepare drop structure
        dropStruct storage currentDrop = drops[++currentDropCount];
        currentDrop.rewardERC721       = _rewardERC721;
        currentDrop.originalERC721     = _originalERC721;
        currentDrop.traitStorage       = _traitStorage;
        currentDrop.tokenId            = _tokenId;
        currentDrop.tokensToDrop       = _tokensToDrop;
        currentDrop.recipient          = msg.sender;
        if (traitStorage.redeemMode() == uint8(RedeemMode.random)) {
            // Random drop requested
            currentDrop.requestId          = IRandomNumberProvider(GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
            requestToDropIndex[currentDrop.requestId] = currentDropCount;
            emit vaultDropRequested(currentDropCount);
        } else {
            // Nonrandom (first) drop requested
            for(uint16 i = 0; i < _tokensToDrop; i++) {       
                uint256 tokenId = token.tokenOfOwnerByIndex(address(this), 0);
                token.safeTransferFrom(address(this), msg.sender, tokenId);
                claimedTokens[traitId][_tokenId][i] = uint16(tokenId);
            }
            traitStorage.setValue(_tokenId, newTraitValue);         // Set storage to new state value
            emit vaultDropProcess(currentDropCount);
        }

        traitTokenToDropIndex[traitId][_tokenId] = currentDropCount;
    }

    /**
     * @dev Chainlink VRF callback
     */
    function process(uint256 _random, uint256 _requestId) external {

        if (msg.sender != GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)) {
            revert unauthorisedCall(msg.sender);
        }

        uint32 dropIndex = requestToDropIndex[_requestId];
        dropStruct storage drop = drops[dropIndex];

        if (drop.randomReceived) {
            drop.errorCode = ErrorCode.random_already_processed;
            return;
        }

        pendingPerCollection[drop.rewardERC721] -= drop.tokensToDrop;       // Count the pending tokens yet to give

        drop.randomNumber = _random;
        drop.randomReceived = true;
        // #TODO check gasLeft and decide if we can do the transfer or need a separate user transaction for that
        transferRandom(dropIndex);
        if(drop.errorCode != ErrorCode.ok) {
            emit vaultDropProcessError(dropIndex);
        } else {
            emit vaultDropProcess(dropIndex);
        }
    }

    /**
     * @dev Called in the VRF callback part - transfers the randomly picked token from the vault to the user
     */
    function transferRandom(uint32 _dropId) internal {

        // dropStruct memory drop = drops[_dropId];
        dropStruct storage drop = drops[_dropId];
        uint8 tokensToDrop = drop.tokensToDrop;
        uint256 initRandom = drop.randomNumber;
        uint256 random = initRandom;
        drop.randomProcessed = true;

        IERC721Enumerable  rewardToken = IERC721Enumerable(drop.rewardERC721);

        uint256 balance = rewardToken.balanceOf(address(this));
        if (balance < tokensToDrop ) {
            // UTDigitalRedeemVault: Not enough tokens in vault
            drop.errorCode = ErrorCode.not_enough_token;
            return;
        }

        ITraitStorage traitStorage = ITraitStorage(drop.traitStorage);
        uint8 newTraitValue = traitStorage.getValue(drop.tokenId) + drop.tokensToDrop;
        if ( newTraitValue > TRAIT_OPEN_VALUE + traitStorage.maxTokensToRedeem()) {
            //  UTDigitalRedeemVault: claim over limit
            drop.errorCode = ErrorCode.claim_over_limit;
            return;
        }

        uint16 traitId = traitStorage.traitId();
        traitTokenToDropIndex[traitId][drop.tokenId] = _dropId;     // If the claim was started multiple times and if the VRF failed, then let the later callback update the dropId to show the latest try in the traitTokenToDropIndex mapping

        traitStorage.setValue(drop.tokenId, newTraitValue);         // Set storage to new state value

        // Transfer tokens
        for(uint16 i = 0; i < tokensToDrop; i++) {       
            uint256 tokenId = rewardToken.tokenOfOwnerByIndex(address(this), random % balance);
            rewardToken.transferFrom(address(this), IERC721Enumerable(drop.originalERC721).ownerOf(drop.tokenId), tokenId);
            claimedTokens[traitId][drop.tokenId][i] = uint16(tokenId);
            balance--;
            random = random >> 1;
            if (random < balance) {
                initRandom = uint256(keccak256(abi.encode(initRandom)));
                random = initRandom;
            }
        }
    }

    /**
     * @dev Called during token transfer if called with safeTransferFrom() from an ERC721 token
     * note The vault may receive its tokens via
     *        - using safeTransferFrom(): in this case it will check if the token is in the accepted list, else revert
     *        - directly minting to this vault address or using transferFrom: in this case the notifyVault() should be called for the contract to be registered
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {

        // Do not accept any kind of random tokens, only those approved by the community owner
        if (!tokenContracts.contains(msg.sender)) {
            revert invalidCollection(msg.sender);
        }

        return this.onERC721Received.selector;
    }

    /**
     * @dev Registers the new token contract into the tokenContract address set
     * note The vault may receive its tokens via
     *        - using safeTransferFrom(): in this case it will check if the token is in the accepted list, else revert
     *        - directly minting to this vault address or using transferFrom: in this case the notifyVault() should be called for the contract to be registered
     */
    function notifyVault(address tokenContractAddress) external {

        if (!communityRegistry.isUserCommunityAdmin(DEFAULT_ADMIN_ROLE, msg.sender) && GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_FACTORY) != msg.sender) {
            revert UTDigitalRedeemVaultNotAuthorized(msg.sender);
        }

        if (tokenContractAddress == address(0)) {
            revert notERC721Enumerable(tokenContractAddress);
        }

        if (!IERC721Enumerable(tokenContractAddress).supportsInterface(type(IERC721Enumerable).interfaceId)) {
            revert notERC721Enumerable(tokenContractAddress);
        }
        tokenContracts.add(tokenContractAddress);
    }

    function getVaultLength() public view returns (uint256) {
        return tokenContracts.length();
    }

    function getVaultAt(uint256 _index) public view returns (address) {
        return tokenContracts.at(_index);
    }

    function getVaultContains(address _addr) public view returns (bool) {
        return tokenContracts.contains(_addr);
    }

    /**
     * @dev Return all token contracts known by the vault
     *      Has an unbounded cost!
     */
    function getAllVaults() public view returns (address[] memory)
    {
        return tokenContracts.values();
    }

    /**
     * @dev Return detailed information about each token contract with a representative token's uri inside the vault's address
     *      Has an unbounded cost!
     */
    function getAllVaultsDetails() public view returns (vaultDetails[] memory retval)
    {
        uint256 vaultLength = tokenContracts.length();
        retval = new vaultDetails[](vaultLength);
        for(uint16 contractIdx = 0; contractIdx < vaultLength; contractIdx++) {
            address tokenContract = tokenContracts.at(contractIdx);
            IERC721Enumerable erc721 = IERC721Enumerable(tokenContract);
            uint256 balance = erc721.balanceOf(address(this));
            IERC165 erc165 = IERC165(tokenContract);
            if (erc165.supportsInterface(type(IERC721Metadata).interfaceId)) {
                // IERC721Metadata available
                IERC721Metadata metaData = IERC721Metadata(tokenContract);
                if (balance > 0) {
                    // Use the first token owned by the vault as a representative
                    retval[contractIdx] = vaultDetails(tokenContract , metaData.name(), metaData.symbol(), balance, metaData.tokenURI(erc721.tokenOfOwnerByIndex(address(this), 0)));
                } else {
                    try metaData.tokenURI(1) returns (string memory uri) {
                        // Use the first token as a representative
                        retval[contractIdx] = vaultDetails(tokenContract , metaData.name(), metaData.symbol(), balance, uri);
                    } catch {
                        // Not even a minted token
                        retval[contractIdx] = vaultDetails(tokenContract , metaData.name(), metaData.symbol(), balance, "");
                    }
                }
            } else {
                // No IERC721Metadata available
                retval[contractIdx] = vaultDetails(tokenContract , "", "", balance, "");
            }
        }
    }
}