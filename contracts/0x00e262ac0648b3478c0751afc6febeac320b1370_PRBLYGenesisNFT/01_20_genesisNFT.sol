// SPDX-License-Identifier: MIT
//                                                      *****+=:.  .=*****+-.      -#@@#-.   .+*****=:.     .****+:   :*****+=:.   -***:  -+**=   =***.
//                ...:=*#%%#*=:..       .+%@*.          @@@@%@@@@* .#@@@%%@@@*.  [email protected]@@@%@@@-  :%@@@%%@@@-    [email protected]@@@@#   [email protected]@@@%@@@@+  [email protected]@@-   #@@@:  %@@%
//             .:=%@@@@@@@@@@@@@@#-.  .#@@@@%:          @@@% .#@@%=.#@@*  [email protected]@@= -%@@#: #@@@: :%@@- [email protected]@@@   [email protected]@@#@@#   [email protected]@@* :%@@*: [email protected]@@-   [email protected]@@+ [email protected]@@.
//           .-%@@@@@@%%%%%%%%@@@@@@+=%@@@%*.           @@@%  :@@@*.#@@*  [email protected]@@= [email protected]@@-  *@@@- :%@@=..%@@@   [email protected]@%[email protected]@%:  [email protected]@@* [email protected]@#: [email protected]@@-    *@@@:%@@+
//          -%@@@@%##=.      :*##@@@@@@@%#.             @@@@:-*@@%=.#@@#::*@@%- [email protected]@@-  [email protected]@@= :%@@*+#@@@=   [email protected]@%[email protected]@@#  [email protected]@@#+#@@@=  [email protected]@@-    .#@@[email protected]@%
//        [email protected]@@@#*:              *@@@@@#-               @@@@@@@@#+ .#@@@@@@@@=  [email protected]@@-  [email protected]@@+.:%@@%##@@#:   @@@#.%@@#  [email protected]@@%#%@@#-. [email protected]@@-     [email protected]@@@@:
//       :*@@@@+.              .=%@@@#*.                @@@@***+.  .#@@%+*%@@#: [email protected]@@-  *@@@+ :%@@-  %@@@. [email protected]@@#=*@@%- [email protected]@@* :*@@@= [email protected]@@-      #@@@#
//      .#@@@%=              .-#@@@%#:    :             @@@%       .#@@*  [email protected]@@= [email protected]@@=  *@@@- :%@@-  [email protected]@@= [email protected]@@@@@@@@* [email protected]@@*  [email protected]@@= [email protected]@@-      *@@@:
//      [email protected]@@@=              :*@@@@#-.   .-%:            @@@%       .#@@*  [email protected]@@= -%@@*=-%@@#. :%@@*=-%@@@: @@@@++*@@@# [email protected]@@#--*@@%- [email protected]@@*----. *@@@:
//     [email protected]@@@+             :=#@@@#+:    [email protected]@*.           @@@%       .#@@*  [email protected]@@=  -#@@@@@@#:  :%@@@@@@@*+ [email protected]@@#  .*@@%[email protected]@@@@@@@#-  [email protected]@@@@@@@: *@@@:
//     [email protected]@@%            .-#@@@%*:      *@@@@.           +++=       .=++-  :+++:   :++++++.   .++++++++.  :+++:   :+++-.+++++++=:   -++++++++. -+++.
//     #@@@%           :*@@@@#-.       -%@@@.
//     %@@@%         :+#@@@#=:         :%@@@.                             .                                                        .
//     [email protected]@@%       .=#@@@@*:           [email protected]@@@.           ++++=  :++=   :++***++: .=+++++++++. =++=  .+++-  +++=  .+++=. :+++-   :++***++:
//     :@@@%-     :*@@@@#-.            *@@@%.           @@@@%  [email protected]@#  :#@@@#%@@#:-%@@@@@@@@@: %@@%. :@@@*  @@@%  :@@@@+ [email protected]@@+  :#@@%#@@@#:
//      @@@@#   .*#@@@#=:             =%@@@=            @@@@@= [email protected]@# [email protected]@@+:=%@@*:---#@@@+--. %@@%. :@@@*  @@@%  :@@@@#:[email protected]@@+ :%@@*::*@@@-
//      [email protected]@@@+ =#@@@@*:              -%@@@#.            @@@#@% [email protected]@# :%@@*. [email protected]@%-   *@@@-    %@@%. :@@@*  @@@%  :@@@@@[email protected]@@+ [email protected]@@=  :---.
//       [email protected]@@@#%@@@#-.              =%@@@@-             @@@[email protected]@*[email protected]@# [email protected]@@*   [email protected]@@=   *@@@-    %@@@#*#@@@*  @@@%  :@@%[email protected]%*@@@+ [email protected]@@= -****:
//        [email protected]@@@@@%=.              :*@@@@%-              @@@-%@%[email protected]@# [email protected]@@*   [email protected]@@=   *@@@-    %@@@@@@@@@*  @@@%  :@@#[email protected]@%@@@+ [email protected]@@= [email protected]@@@-
//        [email protected]@@@@*.              -#%@@@@+:               @@@=:@@%@@# [email protected]@@*   [email protected]@@=   *@@@-    %@@%-:[email protected]@@*  @@@%  :@@#[email protected]@@@@+ [email protected]@@= .*@@@-
//      .%@@@@%:.    :*+-:-=*#%%@@@@@%-                 @@@=.#@@@@# .*@@%- :#@@#:   *@@@-    %@@%. :@@@*  @@@%  :@@# [email protected]@@@@+ [email protected]@@=  [email protected]@@-
//     *%@@@@=.    :#%@@@%@@@@@@@@@*:.                  @@@= :@@@@#  [email protected]@@%+#@@@+    *@@@-    %@@%. :@@@*  @@@%  :@@#  [email protected]@@@+ .*@@@*+%@@@- -#%%:
//   :%@@@@#.     .#@@@@@@@@@@@@*:.                     @@@= .#@@@#   [email protected]@@@@@@+     *@@@-    %@@%. :@@@*  @@@%  :@@#  [email protected]@@@+  -%@@@@@@@@- :%@@:
//    .:-:.         ....:::.....                        ..     ...     ..:::..       ...      ..    ...   ...    ..    ....     .::.....    ..
//
/// @title Probably Nothing Genesis NFT
/// @author audie.eth and 0xEwok
/// @notice An NFT for those who came to Probably Nothing early.

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PRBLYGenesisNFT is ERC2981, ERC721, AccessControlEnumerable, Ownable {
    // the maximum number that can be minted
    uint256 public constant MAX_SUPPLY = 777;
    //roles
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    // mutable properties
    bytes32 private _merkleRoot;
    string private _baseTokenURI = "https://probably0.mypinata.cloud/ipfs/QmZ5iiSJ2LGMNWHj4LtWNArSEt1Z41XUUBn3QyJKyuh8r2/";
    string private _contractUri = "https://probably0.mypinata.cloud/ipfs/QmZJxsJ9xk9Dh5JFf6zLc7ZDCoyJ7Mz5DjKNG26TgechFm";
    // the total number that have been minted
    uint256 private _mintedSupply;

    // dates below are in the future - must be set post deploy
    uint256 private _genesisHolderMintStartTime;
    uint256 private _genesisHolderMintEndTime;
    // we won't use the zero index
    // indexes are the token ids, cheap initialized array where we set bool to true when minted
    bool[MAX_SUPPLY + 1] private _tokenIds;
    bool[MAX_SUPPLY + 1] private _staked; // all start out unstaked.

    // EIP2981 properties
    address royaltyAddr = 0x11d18ea67e081aa239430093808b2721b87ca733;
    uint96 royaltyPercent = 1000; // denominator is 10000, so this is 10%

    /**
     *  @notice Contructor for the NFT
     *  @param name The long name of the NFT collection
     *  @param symbol The short, all caps symbol for the collection
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC2981() ERC721(name, symbol) Ownable() {
        _setDefaultRoyalty(royaltyAddr, royaltyPercent);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    /**
     *  @notice Sets the ERC2981 default royalty info
     *  @param receiver The address to receive default royalty payouts
     *  @param feeNumerator The royalty fee in basis points, set over a denominator of 10000
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     *  @notice Given a caller with a matching proof mints the next NFT specified by the ID
     *  @param proof A merkle proof that confirms the sender's address and token ID is in the list
     *  @param id The NFT number
     */
    function mint(bytes32[] calldata proof, uint256 id) external {
        // only the address on the merkle tree can mint, no others - means tree can be public
        address account = _msgSender();
        require(_verify(_leaf(account, id), proof), "Invalid merkle proof");
        _mintOne(account, id);
    }

    /**
     *  @notice Mint the NFT to the given account
     *  @param account The address to receive the minted NFT
     *  @param id The NFT number
     */
    function airdropMint(address account, uint256 id) external onlyOwner {
        _mintOne(account, id);
    }

    /**
     *  @notice Mint the NFTs to the given accounts
     *  @param accounts The addresses to receive the minted NFTs
     *  @param ids The NFT numbers
     */
    function airdropMintBatch(address[] calldata accounts, uint[] calldata ids) external onlyOwner {
        uint256 length = accounts.length;
        for (uint256 i = 0; i < length; ) {
            _mintOne(accounts[i], ids[i]);

            // can the (solc compiler) devs do something please
            unchecked {
                i++;
            }
        }
    }

    /**
     *  @notice Check if the given NFT has been minted
     *  @param id The NFT number to check
     */
    function isMinted(uint256 id) public view returns(bool) {
        return _tokenIds[id];
    }

    /**
     *  @notice Owner only mint function to mint reserves or giveaways - call only after mint period is over
     *  @param account The address to receive all the minted NFTs
     *  @param firstId The first NFT number to check
     *  @param lastId The last NFT number to check
     *  @dev This function will mint the collection out, skipping over any already minted tokens.
     */
    function ownerMintBlock(address account, uint256 firstId, uint256 lastId) external onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "Mint complete already");
        uint256 length = _tokenIds.length;
        for (uint256 i = firstId; i < length && i <= lastId; ) {
            if (!_tokenIds[i]) {
                _mintOne(account, i);
            }

            // can the (solc compiler) devs do something please
            unchecked {
                i++;
            }
        }
    }

    /**
     *   @notice Overrides EIP721 and EIP2981 supportsInterface function
     *   @param interfaceId Supplied by caller this function, as defined in ERC 165
     *   @return supports A boolean saying whether this contract supports the interface or not
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     *   @notice Shows maximum supply
     *   @return uint256 Returns the maximum number of mintable NFTs
     *   @dev The length of the controlling array is one larger than
     */
    function maxSupply() public view returns (uint256) {
        // do not include the zero index - won't mint that
        return _tokenIds.length - 1;
    }

    /**
     *   @notice Shows total supply
     *   @return uint256 Returns total existing supply
     */
    function totalSupply() public view returns (uint256) {
        // total supply is the total minted
        return _mintedSupply;
    }

    /**
     *  @notice Provides the merkle root being used to control the mint
     */
    function merkleRoot() public view returns (bytes32) {
        return _merkleRoot;
    }

    /**
     *  @notice Allows the owner to set a new merkle root
     *  @param newMerkleRoot A merkle root created from a list of approved minters and ids for them
     */
    function setMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
        _merkleRoot = newMerkleRoot;
    }

    /**
     *  @notice Retrieves the mint start time
     *  @return date The unix time stamp for when the mint starts
     */
    function getGenesisHolderMintStartTime() public view returns (uint256) {
        return _genesisHolderMintStartTime;
    }

    /**
     *  @notice Set the timestamp after which mint opens
     *  @param newMintStart The unix time stamp mint will begin
     */
    function setGenesisHolderMintStartTime(uint256 newMintStart)
        public
        onlyOwner
    {
        _genesisHolderMintStartTime = newMintStart;
    }

    /**
     *  @notice Retrieves the mint end time
     *  @return date The unix time stamp for when the mint ends
     */
    function getGenesisHolderMintEndTime() public view returns (uint256) {
        return _genesisHolderMintEndTime;
    }

    /**
     *  @notice Set the timestamp after which mint stops
     *  @param newMintEnd The unix time stamp mint will ends
     */
    function setGenesisHolderMintEndTime(uint256 newMintEnd) public onlyOwner {
        _genesisHolderMintEndTime = newMintEnd;
    }

    /**
     *   @notice Provides collection metadata URI
     *   @return string The contract metadata URI
     */
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    /**
     *   @notice Sets the collection metadata URI
     *   @param newContractUri The URI set for the collection metadata
     */
    function setContractURI(string memory newContractUri) public onlyOwner {
        _contractUri = newContractUri;
    }

    /**
     *   @notice Sets the token metadata base URI
     *   @param uri The baseURI for the token metadata
     *   @dev Make sure to include the trailing slash, as tokenURI adds only tokenID and ".json" to the end
     */
    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    /**
     *   @notice Sets a token as staked
     *   @param tokenId The Token ID to set as staked
     */
    function stake(uint256 tokenId) public onlyRole(OWNER_ROLE) {
        require (_exists(tokenId), "Token ID doesn't exist");
        _staked[tokenId] = true;
    }

    /**
     *   @notice Sets a token as unstaked
     *   @param tokenId The Token ID to set as unstaked
     */
    function unstake(uint256 tokenId) public onlyRole(OWNER_ROLE) {
        require (_exists(tokenId), "Token ID doesn't exist");
        _staked[tokenId] = false;
    }

    /**
     *   @notice gets whether a token is staked
     *   @param tokenId The Token ID to check if staked
     *   @return staked boolean indicating whether token is staked
     */
    function getTokenStaked(uint256 tokenId) public view returns(bool) {
        require (_exists(tokenId), "Token ID doesn't exist");
        return _staked[tokenId];
    }

    /**
     *  @notice Provides the URI for the specific token's metadata
     *  @param tokenId The token ID for which you want the metadata URL
     *  @dev This will only return for existing token IDs, and expects the file to end in .json
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory status = _staked[tokenId] ? "staked" : "standard";
        return
            bytes(_baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(
                        _baseTokenURI,
                        status,
                        "/",
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /**
     *  @notice Confirms an address, id, and proof will allow minting
     *  @param account The address to use as the first part of a merkle leaf
     *  @param id The address to use as the second part of a merkle leaf
     *  @param proof The merkle proof you want to check is valid
     *  @dev This needs the address, id, proof, and time to be correct. Time check is in internal _verify function
     */
    function canMint(
        address account,
        uint256 id,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return _verify(_leaf(account, id), proof);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override{
        require(_exists(tokenId), "Token Does Not Exist");
        require(_staked[tokenId] != true, "Token is staked, cannot transfer");
        super._transfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _mintOne(address account, uint256 id) internal {
        require(id > 0, "id #0 is invalid");
        require(id < _tokenIds.length, "TokenID too large");
        require(!_tokenIds[id], "Token already minted");
        _safeMint(account, id);
        unchecked {
            _mintedSupply += 1;
        }
        _tokenIds[id] = true;
    }

    function _leaf(address account, uint256 id)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, id));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        bool genesisMint = false;
        uint256 currentBlockTime = block.timestamp;

        // check mint has started
        if (currentBlockTime > _genesisHolderMintStartTime) {
            // check mint hasn't ended
            if (currentBlockTime < _genesisHolderMintEndTime) {
                // verify merkle root - only way result can be true
                genesisMint = MerkleProof.verify(proof, _merkleRoot, leaf);
            }
        }

        return (genesisMint);
    }
}