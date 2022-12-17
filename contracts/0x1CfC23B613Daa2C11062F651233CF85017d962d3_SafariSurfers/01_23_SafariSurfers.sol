// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice utils
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/// @notice NFT add-ons
import './NFT/NFT.sol';

/**
 * @title ERC-721 contract for Safari Surfers
 * @notice This contract is used to mint Safari Surfers NFT art pieces
 */
contract SafariSurfers is NFT{
    /// @notice using safe math operations with uint
    using SafeMath for uint;
    
    /// @notice using MerkleProof Library to verify Merkle proofs
    using MerkleProof for bytes32[];

    /// @dev root of the Merkle tree
    bytes32 public merkleRoot;

    /// @notice defines id the allow list is enforced to trigger merkleroot validations
    bool public isAllowListEnabled;

    /// @notice Indicates if the mint id has been already used
    mapping(bytes16 => bool) public mintId;

    /// @notice map to keep track of available options and their prices OptionNumber => Price in WEI
    mapping(uint256 => uint256) public prices;

    // @notice SafariSurfers minting event
    event MintSafariSurfers(address indexed to, uint256 animal, uint256 option, uint256 indexed tokenId);
    
    // @notice SafariSurfers set price events
    event SetMintPrice(uint256 newPrice);
    event SetPhysicalPrice(uint256 newPrice);
    event SetAnimalPrice(uint256 newPrice);
    
    /**
     * @notice SafariSurfers constructor
     * @param proxyRegistryAddress_ opensea proxy to allow approve all
     * @param name_ ERC721 token name
     * @param symbol_ ERC721 token symbol 
     * @param baseTokenURI_ metadata base URL
     * @param operators_ additional SafariSurfers operators 
     */
    constructor(
		address proxyRegistryAddress_,
		string memory name_,
		string memory symbol_,
		string memory baseTokenURI_,
        address[] memory operators_
	) NFT(proxyRegistryAddress_, name_, symbol_, baseTokenURI_, operators_) {

        /// @notice initial options and their prices.
        prices[1] = 100000000000000; // minting price
        prices[2] = 50000000000000; // physical price
        prices[3] = 10000000000000; // choosing animal price

        /// @notice initializers
        isAllowListEnabled = false;
    }

    /**
     * @notice changes if the allow list is enforced or not
     * @param _enabled is enabled true, or not false
     */
    function setAllowListEnabled (bool _enabled) external {
        require(operators[msg.sender], "only operators");
        isAllowListEnabled = _enabled;
    }

    /**
     * @notice sets merkleRoot in case whitelist list updated
     * @param merkleRoot_ root of the Merkle tree
     **/
    function setMerkleRoot(bytes32 merkleRoot_) external {
        require(operators[msg.sender], "only operators");
        merkleRoot = merkleRoot_;
    }

    /**
     * @notice add a new or modifies an existing option to mint price.
     * @param _option the option to modify, can be new and will add a new one
     * @param price ETH price in wei, can be zero for free minting
     */
    function setPrice(uint256 _option, uint256 price) public {
        require(operators[msg.sender], "only operators");
        prices[_option] = price;

        // we emit the right event
        if (_option == 1){
            emit SetMintPrice(price);
        }

        if (_option == 2){
            emit SetPhysicalPrice(price);
        }

        if (_option == 3){
            emit SetAnimalPrice(price);
        }
            
    }

    /**
     * @notice sets all three prices at once
     * @param mint the price of the minting an NFT
     * @param physical the price of adding a physical print
     * @param animal the price of choosing an animal
     */
    function setPrices(uint256 mint, uint256 physical, uint256 animal) public {
        require(operators[msg.sender], "only operators");
        prices[1] = mint;
        prices[2] = physical;
        prices[3] = animal;

        // we emit the price events
        emit SetMintPrice(mint);
        emit SetPhysicalPrice(physical);
        emit SetAnimalPrice(animal);
    }

    /**
     * @notice allows an admin to withdrawn all ETH from the contract
     */
    function withdraw () external {
        require(operators[msg.sender], "only operators");
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice performs SafariSurgers minting
     * @param to new owner of the NFT
     * @param option which option is being minted
     * @param animal which animal is being minted
     */
    function _safariSurfersMint (address to, uint256 option, uint256 animal) internal {
        currentTokenId++;
        _safeMint(to, currentTokenId);
        emit MintSafariSurfers(to, animal, option, currentTokenId);
    } 

    /**
     * @notice validates if value sent is correct to pay for the option and animal
     * @param value the amount of wei sent to the mint method
     * @param option which option has been choosen. 1 is without physical 2 is with physical
     * @param animal which animal has been choose. Zero is no animal, between 1 and 12 is an specific animal
     * @param amount how many NFTs we are minting.
     */
    function isPriceCorrect (uint256 value, uint256 option, uint256 animal, uint256 amount ) internal view returns (bool){
        if (option == 1 && animal == 0)
            return value >= prices[1] * amount;

        if (option == 1 && animal > 0)
            return value >= (prices[1] + prices[3]) * amount;

        if (option == 2 && animal == 0)
            return value >= (prices[1] + prices[2]) * amount;

        if (option == 2 && animal > 0)
            return value >= (prices[1] + prices[2] + prices[3]) * amount;

        return false;
    }

    /**
     * @notice public mint without allow list. Everyone who pays can mint
     * @param to the address who will own the NFT
     * @param option a valid option, 1 without physical 2 with physical
     * @param amount the number of tokens to mint
     */
    function publicMint(address to, uint256 option,uint256 animal, uint256 amount) payable external whenNotPaused{
        require(!isAllowListEnabled, "Minting only with allow list.");
        require(amount > 0 && amount < 11, "Invalid amount");
        require(option > 0 && option < 3, "Not a valid option");
        require(animal < 13, "Not a valid animal");
        require(isPriceCorrect(msg.value, option, animal, amount), "Not enough ETH sent; check price!");
        
        /// we are ready to mint
        for(uint i = 0; i < amount; i++) {
			_safariSurfersMint(to, option, animal);
		}
        return;
    }

    /**
     * @notice public mint with allow list. Only the ones submitting proof can mint
     * @param to the address who will own the NFT
     * @param option a valid option
     * @param amount the number of tokens to mint
     * @param proof merkle tree proof
     * @param mintId_ address of the minter
     */
    function allowListMint(address to, uint256 option,uint256 animal, uint256 amount, bytes32[] memory proof, bytes16 mintId_) payable external whenNotPaused{
        require(isAllowListEnabled, "Allow list not enabled.");
        require(amount > 0 && amount < 11, "Invalid amount.");
        require(option > 0 && option < 3, "Not a valid option.");
        require(animal < 13, "Not a valid animal.");
        require(isPriceCorrect(msg.value, option, animal, amount), "Not enough ETH sent; check price!");
        
        require (!mintId[mintId_], "Mint id already used.");
        isAllowedToMint(proof, mintId_);
        
        // we are ready to mint
        mintId[mintId_] = true;
        for(uint i = 0; i < amount; i++) {
			_safariSurfersMint(to, option, animal);
		}
        return;
    }

    /**
     * @notice admin minting. Bypass most validations.
     * @param to the address who will own the NFT
     * @param option a valid option
     * @param amount the number of tokens to mint
     */
    function adminMint(address to, uint256 option, uint256 animal, uint256 amount) payable external{
        require(operators[msg.sender], "only operators");
        require(amount > 0, "Invalid amount.");
        
        // we are ready to mint
        for(uint i = 0; i < amount; i++) {
			_safariSurfersMint(to, option, animal);
		}
        return;
    }

    

    /**
     * @notice the public function validating addresses
     * @param proof_ hashes validating that a leaf exists inside merkle tree aka merkleRoot
     **/
    function isAllowedToMint(bytes32[] memory proof_, bytes16 mintId_)
        internal
        view
        returns (bool)
    {
        require(
            MerkleProof.verify(
                proof_,
                merkleRoot,
                keccak256(abi.encodePacked(mintId_))
            ),
            "Not in allowed list."
        );
        return true;
    }

    
}