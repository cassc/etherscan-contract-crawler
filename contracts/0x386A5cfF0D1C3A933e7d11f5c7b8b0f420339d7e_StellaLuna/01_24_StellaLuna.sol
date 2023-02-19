// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice utils
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/// @notice Jupiter add-ons
import './jupiter/JupiterNFT.sol';
import './jupiter/JupiterCappedMint.sol';

/**
 * @title ERC-721 Jupiter contract for STELLALUNA NFT by NOIS7
 * @notice This contract is used to mint STELLALUNA NFT art pieces
 * @author https://jupitergroup.io/
 */
contract StellaLuna is JupiterNFT, JupiterCappedMint{
    /// @notice using safe math operations with uint
    using SafeMath for uint;
    
    /// @notice using MerkleProof Library to verify Merkle proofs
    using MerkleProof for bytes32[];

    /// @dev root of the Merkle tree
    bytes32 public merkleRoot;

    /// @notice start date for the daily mint calculations
    uint256 public dailyMintStartDate;

    /// @notice mapping that keeps track of daily mints. Days since start date => minted?
    mapping(uint256 => bool) public dailyMintStatus;

    /// @notice flags to enable/disable mint
    bool public isDailyMintEnabled;
    bool public isMintEnabled;

    /// @notice defines id the allow list is enforced to trigger merkleroot validations
    bool public isAllowListEnabled;

    /// @notice Indicates if the mint id has been already used
    mapping(bytes16 => bool) public mintId;

    /// @dev struct that stores the price and status of each option
    struct Option {uint256 price; bool enabled;}
    /// @notice map to keep track of available options and their prices OptionNumber => Price in WEI
    mapping(uint8 => Option) public options;

    // @notice STELLALUNA minting event
    event MintStellaLuna(address indexed to, uint8 option, uint256 indexed tokenId);
    
    /**
     * @notice STELLALUNA constructor
     * @param proxyRegistryAddress_ opensea proxy to allow approve all
     * @param name_ ERC721 token name
     * @param symbol_ ERC721 token symbol 
     * @param baseTokenURI_ metadata base URL
     * @param dailyMintStartDate_ unix start date of the daily mint
     * @param operators_ additional jupiter operators 
     */
    constructor(
		address proxyRegistryAddress_,
		string memory name_,
		string memory symbol_,
		string memory baseTokenURI_,
        uint256 dailyMintStartDate_,
        address[] memory operators_
	) JupiterNFT(proxyRegistryAddress_, name_, symbol_, baseTokenURI_, operators_) {
        dailyMintStartDate = dailyMintStartDate_;

        /// @notice initial options and their prices.
        options[1] = Option(1000000000000000, true); // without physical
        options[2] = Option(2000000000000000, true); // with physical


        /// @notice initializers
        isDailyMintEnabled = false;
        isMintEnabled = false;
        dailyMintStartDate = dailyMintStartDate_;
        isAllowListEnabled = false;
    }

    /**
     * @notice changes if the daily mint is enabled or not
     * @param _enabled is enabled true, or not false
     */
    function setDailyMintEnabled (bool _enabled) external {
        require(operators[msg.sender], "only operators");
        isDailyMintEnabled = _enabled;
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
     * @notice changes the start date of the daily mint
     * @param _startDate a unix uin256 date that marks the start of the daily mint
     */
    function setDailyMintStartDate (uint256 _startDate) external {
        require(operators[msg.sender], "only operators");
        require(_startDate > 0, "Invalid daily mint start date.");

        dailyMintStartDate = _startDate;
    }

    /**
     * @notice changes the status ofa single day of the daily mint period. An admin can reset or restrict a day
     * @param day which day since the start date is being enabled / disabled
     * @param enabled true if enabled and ready to mint, false if not enabled to mint
     */
    function setDailyMintStatus (uint256 day, bool enabled) external {
        require(operators[msg.sender], "only operators");
        dailyMintStatus[day] = enabled;
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
     * @notice performs STELLALUNA minting
     * @param to new owner of the NFT
     * @param option which option is being minted
     */
    function _stellalunaMint (address to, uint8 option) internal {
        currentTokenId++;
        _safeMint(to, currentTokenId);
        emit MintStellaLuna(to, option, currentTokenId);
    } 

    /**
     * @notice calculates days passed since dailyMintStartDate
     */
    function _daysSinceStart () internal view returns(uint256){
        uint256 daysDiff = block.timestamp.sub(dailyMintStartDate);
        return daysDiff.div(60).div(60).div(24);
    }

    /**
     * @notice mint a single NFT per day
     * @param to the owner of the new NFT
     * @param option an available option to mint
     */
    function dailyMint (address to, uint8 option) payable external whenNotPaused{
        require(isDailyMintEnabled, "Daily mint is not enabled.");
        require(options[option].enabled, "Not a valid option");
        require(msg.value >= options[option].price, "Not enough ETH sent; check price!");

        require(currentTokenId < cap, "Max token Id reached.");

        // we get how many days have passed since start of daily mint and we make sure this is the only mint
        uint256 dailyDay = _daysSinceStart();
        require(!dailyMintStatus[dailyDay], "Only one mint per day allowed.");
        dailyMintStatus[dailyDay] = true;

        /// we are ready to mint
        _stellalunaMint(to, option);
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
        require(amount > 0 && amount < 6, "Invalid amount.");
        require(options[option].enabled, "Not a valid option");
        require(msg.value >= options[option].price, "Not enough ETH sent; check price!");
        require(currentTokenId < cap, "Max token Id reached.");
        
        /// we are ready to mint
        for(uint i = 0; i < amount; i++) {
			_stellalunaMint(to, option);
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
        require(amount > 0 && amount < 6, "Invalid amount.");
        require(options[option].enabled, "Not a valid option");
        require(msg.value >= options[option].price, "Not enough ETH sent; check price!");
        require(currentTokenId < cap, "Max token Id reached.");
        
        require (!mintId[mintId_], "Mint id already used.");
        isAllowedToMint(proof, mintId_);
        
        // we are ready to mint
        mintId[mintId_] = true;
        for(uint i = 0; i < amount; i++) {
			_stellalunaMint(to, option);
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
        require(currentTokenId < cap, "Max token Id reached.");
        
        // we are ready to mint
        for(uint i = 0; i < amount; i++) {
			_stellalunaMint(to, option);
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