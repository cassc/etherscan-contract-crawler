// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice utils
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/// @notice Jupiter add-ons
import './FastSneaksProject/FastSneaksNFT.sol';

/**
 * @title ERC-721 Jupiter contract for FastSneaksProject NFT by Brendan Murphy
 * @notice This contract is used to mint Fast Sneakers 
 * @author Rodrigo Acosta
 */
contract FastSneaks is FastSneaksNFT{
    /// @notice using safe math operations with uint
    using SafeMath for uint;
    
    /// @notice using MerkleProof Library to verify Merkle proofs
    using MerkleProof for bytes32[];

    /// @dev root of the Merkle tree
    bytes32 public merkleRoot;

    bool public isMintEnabled;

    /// @notice defines id the allow list is enforced to trigger merkleroot validations
    bool public isAllowListEnabled;


    /// @dev struct that stores the price and status of each option
    struct Option {uint256 price; bool enabled;}

    /// @notice map to keep track of available options and their prices OptionNumber => Price in WEI
    mapping(uint8 => Option) public options;

    
    // @notice FastSneaks general minting event
    event MintFastSneaks(address indexed to, uint8 option, uint256 indexed tokenId);
    
    // @notice FastSneaks minting event
    event PublicMintFastSneaks(address indexed to, uint8 option, uint256 indexed tokenId);
    
    // @notice FastSneaks batch minting event
    event BatchMintFastSneaks(address indexed to, uint8 option, uint256 indexed tokenId, string orderId);

    // @notice FastSneaks admin minting event
    event AdminMintFastSneaks(address indexed to, uint8 option, uint256 indexed tokenId);
    
    /**
     * @notice STELLALUNA constructor
     * @param proxyRegistryAddress_ opensea proxy to allow approve all
     * @param name_ ERC721 token name
     * @param symbol_ ERC721 token symbol 
     * @param baseTokenURI_ metadata base URL
     * @param operators_ additional jupiter operators 
     */
    constructor(
		address proxyRegistryAddress_,
		string memory name_,
		string memory symbol_,
		string memory baseTokenURI_,
        address[] memory operators_
	) FastSneaksNFT(proxyRegistryAddress_, name_, symbol_, baseTokenURI_, operators_) {
        /// @notice initial options and their prices.
        options[1] = Option(10000000, true);

        /// @notice initializers
        isMintEnabled = true;
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
     * @notice changes if the general (not daily) mint is enabled or not
     * @param _enabled is enabled true, or not false
     */
    function setMintEnabled (bool _enabled) external {
        require(operators[msg.sender], "only operators");
        isMintEnabled = _enabled;
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
    function setOption(uint8 _option, uint256 price, bool enabled) public {
        require(operators[msg.sender], "only operators");
        options[_option] = Option(price, enabled);
    }

    /**
     * @notice allows an admin to withdrawn all ETH from the contract
     */
    function withdraw () external {
        require(operators[msg.sender], "only operators");
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice performs FastSneaks minting
     * @param to new owner of the NFT
     * @param option which option is being minted
     */
    function _fastSneaksMint (address to, uint8 option) internal  {
        currentTokenId++;
        _safeMint(to, currentTokenId);
        emit MintFastSneaks(to, option, currentTokenId);
    } 

    /**
     * @notice public mint without allow list. Everyone who pays can mint
     * @param to the address who will own the NFT
     * @param option a valid option
     * @param amount the number of tokens to mint
     */
    function publicMint(address to, uint8 option, uint amount) payable external whenNotPaused{
        require(isMintEnabled, "Minting is not enabled.");
        require(!isAllowListEnabled, "Minting only with allow list.");
        require(amount > 0 && amount < 11, "Invalid amount.");
        require(options[option].enabled, "Not a valid option");
        require(msg.value >= options[option].price, "Not enough ETH sent; check price!");
        
        /// we are ready to mint
        for(uint i = 0; i < amount; i++) {
			_fastSneaksMint(to, option);
            emit PublicMintFastSneaks(to, option, currentTokenId);
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
    function allowListMint(address to, uint8 option, uint amount, bytes32[] memory proof, bytes16 mintId_) payable external whenNotPaused{
        require(isAllowListEnabled, "Allow list not enabled.");
        require(amount > 0 && amount < 11, "Invalid amount.");
        require(options[option].enabled, "Not a valid option");
        require(msg.value >= options[option].price, "Not enough ETH sent; check price!");
        isAllowedToMint(proof, mintId_);
        
        // we are ready to mint
        for(uint i = 0; i < amount; i++) {
			_fastSneaksMint(to, option);
            emit PublicMintFastSneaks(to, option, currentTokenId);
		}
        return;
    }

    /**
     * @notice admin minting. Bypass most validations.
     * @param to the address who will own the NFT
     * @param option a valid option
     * @param amount the number of tokens to mint
     */
    function adminMint(address to, uint8 option, uint amount) payable external{
        require(operators[msg.sender], "only operators");
        require(amount > 0, "Invalid amount.");
        
        // we are ready to mint
        for(uint i = 0; i < amount; i++) {
			_fastSneaksMint(to, option);
            emit AdminMintFastSneaks(to, option, currentTokenId);
		}
        return;
    }

    /**
     * @notice batch minting. Bypass most validations. Triggered by operator after payment is confirmed
     * @param to the address who will own the NFT
     * @param option a valid option
     * @param amount the number of tokens to mint
     * @param orderId the order Id this token references to
     */
    function batchMint(address to, uint8 option, uint amount, string memory orderId) payable external{
        require(operators[msg.sender], "only operators");
        require(amount > 0, "Invalid amount.");
        
        // we are ready to mint
        for(uint i = 0; i < amount; i++) {
			_fastSneaksMint(to, option);
            emit BatchMintFastSneaks(to, option, currentTokenId, orderId);
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