// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import "@erc6551/reference/src/interfaces/IERC6551Registry.sol";

import "./storage/SapienzStorageV1.sol";

/*

      .7PG55PPG##P7:                                                                                                              
     ?#@B^     :7P&@G?:                                                                                                           
    [email protected]@@^         .?#@&?                                                                                                          
    [email protected]@@:            [email protected]@P.                                                                                                        
    [email protected]@@?             [email protected]@B.                                                                                                       
     [email protected]@@!             [email protected]@G                                                                                                       
      [email protected]@&!             [email protected]@5                                                               Y#B^                                   
       7&@@J.           [email protected]@@!                                                              ^@@B                                   
        ^[email protected]@B~           [email protected]@G                                                               [email protected]@?                                  
          7#@@5:         !PP7    ~!7^                                                       .#@&:          .:~7JYYYY7             
           .J&@&J.              :&@@@~       :~~:                ..                          [email protected]@5     :[email protected]@@@?             
             :J&@&J.            [email protected]@@@#.     [email protected]@@&GGGGPY?!^.    .G&&5          .:^!?JJ?^.::   :&@@~   7BBGY7^.  [email protected]@#!      .:^!!!!^
               :Y&@&J.          ^@@@@@J   ^P#&@@@5~!!7YG#@&PJ^  [email protected]@@7 .?YYYY5PP5Y?~~~!G&@&5   [email protected]@G           [email protected]&Y. .^!J5GBBBBBGY!
 !P!             :Y&@&J:        [email protected]@@@@@~   ::^#@@B      .^[email protected]@@~  [email protected]@&[email protected]@@@Y^.  .~YB&[email protected]@@@B7  #@@7        [email protected]@B??5GBBG5?!^.      
[email protected]#                .J&@&J:      [email protected]@@@@@#:     [email protected]@@Y      [email protected]@J   ^&@@[email protected]@@J:75GBBY!. .#@@@@@[email protected]@&:     [email protected]@@@&BPJ!:.            
J&@J                 .J&@&J.    [email protected]@@@@@@B.   .:[email protected]@@?   .7&@P^     [email protected]@@[email protected]@@@#GY!. 7P5. [email protected]@@[email protected]@&@@@5  ^J#@@&GJ~:                  
 :[email protected]#!                 .?&@#7   [email protected]@@@[email protected]@[email protected]@@?~YBG?:        [email protected]@@P&@@&~  [email protected]&?  [email protected]@@J [email protected]@@@@~.5G5?~.                      
   ^[email protected]~                 :[email protected]@G^ [email protected]@@@BB&@@@G:   [email protected]@@@&7:            [email protected]@[email protected]@&PGGGJ~.   .&@@5   ^JGG5!                             
     [email protected]?:                ~#@@[email protected]@@&7^[email protected]@B7. :[email protected]@@?             :#@@P.:~!~:.        ?Y7:                                      
       :Y&@G7:              [email protected]@#@@@G     ^Y#@&GJ~:7&@@P.            ^#@&~                                                        
         .7P&@BY~.           ^@@@5!~:        ^7Y5J! ^[email protected]@5             .:.                                                         
            .!YG##B5?!^:.  [email protected]@5                    .~:.                                                                         
                .~?5G####BBGP5?^                                                                                                  

Staple Pigeon started in 1997. It shook the entire streetwear industry and brought sneaker collabs
to the mainstream. STAPLEVERSE started in 2022 and it will show the world the power of co-creation.

Building the foundation that will inspire the next generation of creatives.

*/

contract Sapienz is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    SapienzStorageV1
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    error InvalidInputs();
    error AlreadyClaimed();
    error InvalidToken();
    error TokenNotFound();
    error NotClaimant();
    error ClaimDisabled();
    error MintDisabled();

    string BASE_URI;

    IERC6551Registry erc6551Registry;
    address erc6551AccountImplementation;

    bool public claimEnabled;
    bool public mintEnabled;

    mapping(address => BitMapsUpgradeable.BitMap) _erc721Minted;

    // END V2 STORAGE

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /// @dev Initializes the contract, setting the default merkle root and granting admin permissions to the caller
    function initialize(bytes32 _merkleRoot) public initializer {
        merkleRoot = _merkleRoot;

        __ERC721A_init("Sapienz", "SAPIENZ");

        __Ownable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Marks an ERC721/ERC1155 contract as eligible or ineligible to claim Sapienz
    function setAllowedContract(address tokenContract, bool allowed)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        allowedContracts[tokenContract] = allowed;
    }

    /// @dev Marks an ERC721/ERC1155 contract as controlled or uncontrolled
    function setControlledContract(address tokenContract, bool controlled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        controlledContracts[tokenContract] = controlled;
    }

    /// @dev Sets the merkle root for the tree of eligible ERC721/ERC1155 tokens
    function setMerkleRoot(bytes32 newMerkleRoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        merkleRoot = newMerkleRoot;
    }

    /// @dev Sets base URI for all token URIs
    function setBaseUri(string calldata baseUri)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        BASE_URI = baseUri;
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    /// @dev Sets the address of the ERC6551 registry
    function setERC6551Registry(address registry)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        erc6551Registry = IERC6551Registry(registry);
    }

    /// @dev Sets the address of the ERC6551 account implementation
    function setERC6551Implementation(address implementation)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        erc6551AccountImplementation = implementation;
    }

    /// @dev Sets claim enabled status
    function setClaimEnabled(bool enabled) public onlyRole(DEFAULT_ADMIN_ROLE) {
        claimEnabled = enabled;
    }

    /// @dev Sets mint enabled status
    function setMintEnabled(bool enabled) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintEnabled = enabled;
    }

    function airdrop1155Batch(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata balances,
        address[] calldata minters
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        _airdropERC1155(tokenAddress, tokenIds, balances, minters);
    }

    /// @dev Allows admin to mint one Sapienz for each eligible controlled token on a user's behalf,
    ///      transferring the token to the Sapienz' ERC6551 account
    function airdropBatch(
        address[] calldata tokenAddresses,
        uint256[][] calldata tokenIds,
        address[] calldata minters
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = tokenAddresses.length;

        for (uint256 i = 0; i < len; i++) {
            _airdropERC721(tokenAddresses[i], tokenIds[i], minters[i]);
        }
    }

    /// @dev Allows admin to mint one Sapienz for each controlled token in a single collection on a
    ///      user's behalf, transferring the token to the Sapienz' ERC6551 account
    function airdrop(
        address tokenAddress,
        uint256[] memory tokenIds,
        address minter
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        _airdropERC721(tokenAddress, tokenIds, minter);
    }

    /// @dev Mints one Sapienz for each eligible token across multiple collections, transferring
    ///      the token to the Sapienz' ERC6551 account
    function mintBatch(
        address[] calldata tokenAddresses,
        uint256[][] calldata tokenIds,
        bytes32[][][] calldata proofs
    ) external nonReentrant {
        if (!mintEnabled) revert MintDisabled();

        uint256 len = tokenAddresses.length;
        if (tokenIds.length != len || proofs.length != len) {
            revert InvalidInputs();
        }

        for (uint256 i = 0; i < len; i++) {
            _mintWithTokens(tokenAddresses[i], tokenIds[i], proofs[i]);
        }
    }

    /// @dev Mints one Sapienz for each eligible token in a single collection, transferring the
    ///      token to the Sapienz' ERC6551 account
    function mint(
        address tokenAddress,
        uint256[] memory tokenIds,
        bytes32[][] memory proof
    ) external nonReentrant {
        if (!mintEnabled) revert MintDisabled();
        _mintWithTokens(tokenAddress, tokenIds, proof);
    }

    /// @dev Claim for multiple tokens from multiple collections at once. Transfers each token to
    ///      this contract.
    function claimBatch(
        address[] calldata tokenAddresses,
        uint256[][] calldata tokenIds,
        uint256[][] calldata balances,
        bytes32[][][] calldata proofs
    ) external nonReentrant {
        if (!claimEnabled) revert ClaimDisabled();
        uint256 len = tokenAddresses.length;
        if (
            tokenIds.length != len ||
            balances.length != len ||
            proofs.length != len
        ) {
            revert InvalidInputs();
        }

        for (uint256 i = 0; i < len; i++) {
            _claim(
                tokenAddresses[i],
                tokenIds[i],
                balances[i],
                proofs[i],
                msg.sender
            );
        }
    }

    /// @dev Claim for multiple tokens from a single collection. Transfers each token to this
    ///      contract.
    function claim(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory balances,
        bytes32[][] memory proof
    ) external nonReentrant {
        if (!claimEnabled) revert ClaimDisabled();
        _claim(tokenAddress, tokenIds, balances, proof, msg.sender);
    }

    /// @dev Revoke claim for multiple tokens from multiple collections at once. Transfers each
    ///      token from this contract to the caller.
    function unclaimBatch(
        address[] calldata tokenAddresses,
        uint256[][] calldata tokenIds,
        uint256[][] calldata balances
    ) external nonReentrant {
        uint256 len = tokenAddresses.length;
        if (tokenIds.length != len || balances.length != len) {
            revert InvalidInputs();
        }

        for (uint256 i = 0; i < len; i++) {
            _unclaim(tokenAddresses[i], tokenIds[i], balances[i]);
        }
    }

    /// @dev Revoke claim for multiple tokens from a single collection. Transfers each token from
    ///      this contract to the caller.
    function unclaim(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory balances
    ) external nonReentrant {
        _unclaim(tokenAddress, tokenIds, balances);
    }

    /// @dev Returns the minted status for a given token used to claim Sapienz
    function isMintedWith(address tokenAddress, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return _erc721Minted[tokenAddress].get(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlUpgradeable,
            ERC1155ReceiverUpgradeable,
            ERC721AUpgradeable
        )
        returns (bool)
    {
        return
            // ERC-4906 support (metadata updates)
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }

    function _airdropERC721(
        address tokenAddress,
        uint256[] memory tokenIds,
        address minter
    ) internal {
        uint256 quantity = tokenIds.length;

        uint256 startTokenId = _currentIndex;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIds[i];

            // revert if token has not been claimed
            if (claimedBalances[tokenAddress][tokenId][minter] == 0) {
                revert InvalidToken();
            }

            // revert if token has already been minted
            if (_erc721Minted[tokenAddress].get(tokenId)) {
                revert InvalidToken();
            }

            // clear claimed slot
            claimedBalances[tokenAddress][tokenId][minter] = 0;

            // mark claimed token as minted
            _erc721Minted[tokenAddress].set(tokenId);

            // calculate ERC6551 account address
            address tba = erc6551Registry.account(
                erc6551AccountImplementation,
                block.chainid,
                address(this),
                startTokenId + i,
                0
            );

            IERC721Upgradeable(tokenAddress).safeTransferFrom(
                address(this),
                tba,
                tokenId
            );
        }

        _safeMint(minter, quantity);
    }

    function _airdropERC1155(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory balances,
        address[] memory minters
    ) internal {
        uint256 len = minters.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = tokenIds[i];
            address minter = minters[i];
            uint256 balance = balances[i];

            // revert if balance has not been claimed
            if (claimedBalances[tokenAddress][tokenId][minter] != balance) {
                revert InvalidToken();
            }

            // clear claimed slot
            claimedBalances[tokenAddress][tokenId][minter] = 0;

            uint256 startTokenId = _currentIndex;

            for (uint256 n = 0; n < balance; n++) {
                // calculate ERC6551 account address
                address tba = erc6551Registry.account(
                    erc6551AccountImplementation,
                    block.chainid,
                    address(this),
                    startTokenId + n,
                    0
                );

                IERC1155Upgradeable(tokenAddress).safeTransferFrom(
                    address(this),
                    tba,
                    tokenId,
                    1,
                    ""
                );
            }

            _safeMint(minter, balance);
        }
    }

    function _mintWithTokens(
        address tokenAddress,
        uint256[] memory tokenIds,
        bytes32[][] memory proof
    ) internal {
        if (!allowedContracts[tokenAddress]) {
            revert InvalidToken();
        }

        uint256 quantity = tokenIds.length;
        bool isControlledContract = controlledContracts[tokenAddress];

        uint256 startTokenId = _currentIndex;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIds[i];

            // revert if token isn't controlled or in merkle tree
            if (
                !isControlledContract &&
                !verifyMerkleProof(tokenAddress, tokenId, proof[i])
            ) {
                revert InvalidToken();
            }

            address tba = erc6551Registry.account(
                erc6551AccountImplementation,
                block.chainid,
                address(this),
                startTokenId + i,
                0
            );

            // revert if token has already been minted
            if (_erc721Minted[tokenAddress].get(tokenId)) {
                revert InvalidToken();
            }

            // mark claimed token as minted
            _erc721Minted[tokenAddress].set(tokenId);

            // transfer from sender to recipient
            IERC721Upgradeable(tokenAddress).safeTransferFrom(
                msg.sender,
                tba,
                tokenId
            );
        }

        _safeMint(msg.sender, quantity);
    }

    function _claim(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory balances,
        bytes32[][] memory proof,
        address claimant
    ) internal {
        if (!allowedContracts[tokenAddress]) {
            revert InvalidToken();
        }

        bool isControlledContract = controlledContracts[tokenAddress];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                !isControlledContract &&
                !verifyMerkleProof(tokenAddress, tokenIds[i], proof[i])
            ) {
                revert InvalidToken();
            }

            if (balances[i] == 0) {
                _claimERC721(tokenAddress, tokenIds[i], claimant);
            } else {
                _claimERC1155(tokenAddress, tokenIds[i], balances[i], claimant);
            }
        }
    }

    function _claimERC721(
        address tokenAddress,
        uint256 tokenId,
        address claimant
    ) internal {
        if (claimedBalances[tokenAddress][tokenId][claimant] != 0) {
            revert AlreadyClaimed();
        }

        claimedBalances[tokenAddress][tokenId][claimant] = 1;

        IERC721Upgradeable(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
    }

    function _claimERC1155(
        address tokenAddress,
        uint256 tokenId,
        uint256 balance,
        address claimant
    ) internal {
        claimedBalances[tokenAddress][tokenId][claimant] += balance;

        IERC1155Upgradeable(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            balance,
            ""
        );
    }

    function _unclaim(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory balances
    ) internal {
        if (!allowedContracts[tokenAddress]) {
            revert InvalidToken();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (balances[i] == 0) {
                _unclaimERC721(tokenAddress, tokenIds[i]);
            } else {
                _unclaimERC1155(tokenAddress, tokenIds[i], balances[i]);
            }
        }
    }

    function _unclaimERC721(address tokenAddress, uint256 tokenId) internal {
        if (claimedBalances[tokenAddress][tokenId][msg.sender] != 1) {
            revert TokenNotFound();
        }

        claimedBalances[tokenAddress][tokenId][msg.sender] = 0;

        IERC721Upgradeable(tokenAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    function _unclaimERC1155(
        address tokenAddress,
        uint256 tokenId,
        uint256 balance
    ) internal {
        if (claimedBalances[tokenAddress][tokenId][msg.sender] < balance) {
            revert TokenNotFound();
        }

        claimedBalances[tokenAddress][tokenId][msg.sender] -= balance;

        IERC1155Upgradeable(tokenAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            balance,
            ""
        );
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function verifyMerkleProof(
        address tokenAddress,
        uint256 tokenId,
        bytes32[] memory proof
    ) private view returns (bool) {
        bytes32 node = keccak256(
            bytes.concat(keccak256(abi.encode(tokenAddress, tokenId)))
        );
        return MerkleProofUpgradeable.verify(proof, merkleRoot, node);
    }
}

// FUTURE PRIMITIVE ✍️