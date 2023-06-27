// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IStakeDucks} from "./interfaces/IStakeDucks.sol";

/**
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0O0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNK0OxxOOOO00KKNWMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMNKOO0KXXXXXXXK000K0KNMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMNKOOKXXXXXXXXXXXXXXNXK0KNMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMN0OOKXXXXXXXXXXXXXXXXXNNN0OXWMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMXkdOXXXXXXXXXXXXXXXXXXXXXNN0OXWMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMXkdOKXXXXXXXNNNNXXXXXXXXXXXXXkkNMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMWOdOKXXXXXKkddkOKNNXXXXXXXXX0dodkXMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMKxkKXXXXX0d;;oxld0XXXXXXXXXXkclxd0MMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMXxdkKXXXXXk:,;ooc:dKXXXXXXXXXOc;;cOWMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMXddOKXXXXXk:,,,,,;dKXX0OOkxxxdl:cdO0XWMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMXdoOKXXXXX0xlcccldOKkdoolllooooooodokNMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMNkdk0KXXXXXK0OO0KKOdooddoooodddddxxlxNMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMN0kkOKXXXXXXXXXXXxlllooddddddxkkkkkKWMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMWKxoxOKXXXXXXXXXKOxdllllllllloxkKWMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMN0OkxxdxxxkkO0KXKKKK0OkxdollloOXWMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMN0OOKK0OOkkxdddxxxddddddddddxkkkkKNMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMWKkk0KKXXKK00OOOOkkkkkkkkkkkOOOOOOOO0KWMMMMMMMMMMMMMMM
 * MMMMMMMMMMN00K000xxOO0KXXXXXXKKK00000000000000000KKNXO0WMMMMMMMMMMMMMM
 * MMMMMMMMMMKdoolcldkOKKKKKKXXXXXXKKKKXXXXXXXXXXXXXXKKXXO0WMMMMMMMMMMMMM
 * MMMMMMMMMMXxxkoccdkO0KK00KXKKKKOk0KXXXXXXXXXXXXXXXXKO0kONMMMMMMMMMMMMM
 * MMMMMMMMMMWOdkkolodxkOOO0Oxkkkxk0XXXXXXXXXXXXXXXXXXX0ddONMMMMMMMMMMMMM
 * MMMMMMMMMMMNOxxxxdoooodxxxdxkO0KKKXXXXXXXXXXXXXXXXXKOkKNMMMMMMMMMMMMMM
 * MMMMMMMMMMMMWXOxxkOxdxO0KKKXXXXOx0XXXXXXXXXXXXXXXXKO0NMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMWXOkxold0XXXXXXX0ddk0KKXXXXXXXXXXXK00KWMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWX0xlxOKXXXX0dlooxxkOO0O000OOkO0XWMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMWKkdxOO0OO0K0OOOOOxlllllllxNMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMWWN0oclookXMMMMMMMMNOlclllo0NNNNWMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMNOxolooloxOOXWMMMMMN0dlcclclxkddkOKWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWkccccloc:odlxNMMMMWOlcccc;;cddlcoodKMMMMMMMMMMMMMMMM
 *
 * @title DuckFrens Contract (V2)
 * @custom:website www.duckfrens.com
 * @author @lozzereth (www.allthingsweb3.com)
 * @notice A non-sequential mint of 5000 ducks, 1000 of which are migrated
 *         from the old Duck contract and the remaining 4000 as a free mint.
 */
contract DuckFrensV2 is ERC721, Ownable {
    /// @dev Number of mint types
    uint256 public constant MAX_MINT_TYPES = 2;

    /// @dev A mint type is either a migration or a new mint
    enum MintType {
        Migration,
        New
    }

    /// @dev Attributes for each of the mint types
    struct MintAttributes {
        uint256 supply;
        uint256 startingId;
        uint256 minted;
        uint256 burnt;
    }

    /// @dev Mapping for mint types and its attributes
    mapping(MintType => MintAttributes) public mint;

    /// @dev The DuckFrens contract to migrate
    IERC721 public immutable legacy721Contract;

    /// @dev The DuckFrens legacy contract
    IStakeDucks public immutable legacyStakingContract;

    /// @dev The public sale will be based on a per txn basis
    uint256 public maxMintPerTxn = 2;

    /// @dev Modify number of maximum mints using whitelist
    uint256 public maxMintPerWallet = 1;

    /// @dev Toggle public sale
    bool public publicSale = false;

    /// @dev Toggle whitelist sale
    bool public whitelistSale = false;

    /// @dev Toggle swapping
    bool public swapEnabled = false;

    /// @dev Whitelist sale merkle root
    bytes32 public whitelistSaleMerkleRoot;

    /// @dev Track the mint counts for whitelisted wallets
    mapping(address => uint256) public whitelistMintCount;

    constructor(IERC721 _legacy721Contract, IStakeDucks _legacyStakingContract)
        ERC721("Duck Frens", "DUCK")
    {
        legacy721Contract = _legacy721Contract;
        legacyStakingContract = _legacyStakingContract;
        mint[MintType.Migration] = MintAttributes(1000, 0, 0, 0);
        mint[MintType.New] = MintAttributes(4000, 1000, 0, 0);
        baseURI = "ipfs://QmSXH6kSYaigqQKqrVbhXq79NpF7xwWAjjSt79C34szgZ6/";
    }

    /**
     * @notice Toggle the public sale
     */
    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    modifier publicSaleActive() {
        require(publicSale, "Public sale not started");
        _;
    }

    /**
     * @notice Toggle the whitelist sale
     */
    function toggleWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    modifier whitelistSaleActive() {
        require(whitelistSale, "Whitelist sale not started");
        _;
    }

    /**
     * @notice Toggle swapping of original NFTs
     */
    function toggleSwapping() external onlyOwner {
        swapEnabled = !swapEnabled;
    }

    /**
     * @notice Set the maximum mints per txn as owner
     * @param max Maximum to set
     */
    function setMaxMintPerTxn(uint256 max) external onlyOwner {
        maxMintPerTxn = max;
    }

    /**
     * @notice Set the maximum mints per whitelist wallet
     * @param max Maximum to set
     */
    function setMaxMintPerWallet(uint256 max) external onlyOwner {
        maxMintPerWallet = max;
    }

    /**
     * @notice Public minting functionality
     * @param quantity Quantity
     */
    function mintPublic(uint256 quantity)
        public
        publicSaleActive
        withinSupplyLimit(MintType.New, quantity)
        withinMaximumPerTxn(quantity)
    {
        _mintMany(MintType.New, msg.sender, quantity);
    }

    modifier withinMaximumPerTxn(uint256 quantity) {
        require(quantity > 0 && quantity <= maxMintPerTxn, "Over max per txn");
        _;
    }

    /**
     * @notice Set the whitelist merkle root
     * @param merkleRoot Merkle root for the whitelist
     */
    function setWhitelistSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistSaleMerkleRoot = merkleRoot;
    }

    /**
     * @notice Mint as a whitelisted wallet address
     * @param merkleProof Proof of whitelist
     * @param quantity Quantity
     */
    function mintWhitelist(bytes32[] calldata merkleProof, uint256 quantity)
        public
        whitelistSaleActive
        hasWhitelistedAddress(merkleProof)
        withinSupplyLimit(MintType.New, quantity)
        withinMaximumPerWallet(quantity)
    {
        whitelistMintCount[msg.sender] += quantity;
        _mintMany(MintType.New, msg.sender, quantity);
    }

    modifier withinMaximumPerWallet(uint256 _quantity) {
        require(
            _quantity > 0 &&
                whitelistMintCount[msg.sender] + _quantity <= maxMintPerWallet,
            "Over max per wallet"
        );
        _;
    }

    modifier hasWhitelistedAddress(bytes32[] calldata merkleProof) {
        require(
            _hasWhitelistProof(msg.sender, merkleProof) ||
                _hasLegacyDucks(msg.sender),
            "Address not eligible"
        );
        _;
    }

    /**
     * @dev Check if the address is a part of a valid whitelist proof
     * @param _address Address to query
     * @param merkleProof Proof for verification
     * @return hasValidProof
     */
    function _hasWhitelistProof(
        address _address,
        bytes32[] calldata merkleProof
    ) private view returns (bool) {
        return
            MerkleProof.verify(
                merkleProof,
                whitelistSaleMerkleRoot,
                keccak256(abi.encodePacked(_address))
            );
    }

    /**
     * @dev Check if the address is an owner of legacy ducks
     * @param _address Address to query
     * @return hasDucks
     */
    function _hasLegacyDucks(address _address) private view returns (bool) {
        return
            legacy721Contract.balanceOf(_address) > 0 ||
            legacyStakingContract.depositsOf(_address).length > 0;
    }

    /**
     * @notice Swap your old Ducks for new Ducks.
     * @dev This will send the old tokens to the standard burn address and issue
     *      new tokens.
     * @param tokenIds Tokens to migrate
     */
    function swap(uint256[] calldata tokenIds) public {
        require(swapEnabled, "Swapping not enabled");
        uint256 numTokens = tokenIds.length;
        unchecked {
            mint[MintType.Migration].minted += numTokens;
        }
        for (uint256 i; i < numTokens; ++i) {
            uint256 tokenId = tokenIds[i];
            IERC721(legacy721Contract).safeTransferFrom(
                msg.sender,
                0x000000000000000000000000000000000000dEaD,
                tokenId,
                ""
            );
            _mint(msg.sender, tokenId);
        }
    }

    /**
     * @notice Allows the contract owner to mint within limits
     * @param _recipient Mint to recipient
     * @param _quantity Quantity to mint
     */
    function mintAdmin(address _recipient, uint256 _quantity)
        public
        onlyOwner
        withinSupplyLimit(MintType.New, _quantity)
    {
        _mintMany(MintType.New, _recipient, _quantity);
    }

    /**
     * @notice Burn a token
     * @param tokenId Token to burn
     */
    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "DuckFrensV2: caller is not owner nor approved"
        );
        MintType _type = getMintType(tokenId);
        unchecked {
            mint[_type].burnt++;
        }
        _burn(tokenId);
    }

    /**
     * @notice Get the mint type for a token id
     * @param _tokenId Return the type of mint the token belongs in
     * @return mintType
     */
    function getMintType(uint256 _tokenId) public view returns (MintType) {
        for (uint256 s; s < MAX_MINT_TYPES; s++) {
            MintType _type = MintType(s);
            uint256 start = mint[_type].startingId;
            if (_tokenId >= start && _tokenId <= start + mint[_type].minted) {
                return _type;
            }
        }
        revert("DuckFrensV2: mint status query for nonexistent token");
    }

    /**
     * @notice Base URI for the NFT
     */
    string private baseURI;

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Mints many nfts
     * @param _type Mint type
     * @param _to Destination address
     * @param _quantity Quantity to mint
     */
    function _mintMany(
        MintType _type,
        address _to,
        uint256 _quantity
    ) private {
        uint256 startingId = mint[_type].minted + mint[_type].startingId;
        unchecked {
            mint[_type].minted += _quantity;
        }
        for (uint256 i; i < _quantity; i++) {
            _mint(_to, startingId + i);
        }
    }

    modifier withinSupplyLimit(MintType _type, uint256 _quantity) {
        require(
            mint[_type].minted + _quantity <= mint[_type].supply,
            "Surpasses supply"
        );
        _;
    }

    /**
     * @notice Fetch total supply
     * @return totalSupply
     */
    function totalSupply() public view returns (uint256) {
        uint256 total;
        for (uint256 s; s < MAX_MINT_TYPES; s++) {
            total += mint[MintType(s)].minted;
        }
        return total;
    }

    /**
     * @notice Track tokens of an account
     * @dev Intended for off-chain computation having O(totalSupply) complexity
     * @param account - Account to query
     * @return tokenIds
     */
    function tokensOfOwner(address account)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(account);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                if (!_exists(i)) {
                    continue;
                }
                if (ownerOf(i) == account) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}