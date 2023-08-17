// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


contract LOVI is ERC721, ERC721Enumerable,ERC2981, Ownable,ReentrancyGuard {
    using Counters for Counters.Counter;

    /// @notice A counters instance to manage tokenId.
    Counters.Counter private _tokenIdCounter;

    /// @notice The cost of minting a single token.
    uint256 public mintingFees = 0.025 ether; 

    /// @notice The maximum supply of LOVI tokens
    uint256 private immutable _cap ;

    /// @notice The maximum number of LOVI tokens that can be minted by an individual wallet
    uint256 constant MAX_INDIVIDUAL_MINT = 2;

    /// @notice The address where minting fees are sent
    address payable public treasuryAddress; 

    /// @notice The number of LOVI tokens minted by each address
    mapping(address => uint) public mintedAmount;

    /// @notice The Merkle root used for whitelisting
    bytes32 immutable public merkleRoot;

    /// @notice The URI for the contract's metadata
    string public contractURI;

    /// @notice The base URI for token metadata
    string public baseURI;

    /// @notice Indicates whether the contract metadata has been revealed
    bool public isReveled = false;

    /// @notice The timestamp when token minting starts
    uint256 public saleStartTime;

    /// @notice // The quantity at which whitelisted sale starts
    uint private immutable wlSaleStartQ ;

    /// @notice The timestamp when whitelisted sale started
    uint public wlSaleStartT;

    /// @notice The duration for whitelisted sale
    uint public constant wlSaleI = 24 hours;

    //------------------EVENT-------------------------------
    event UpdateFee(uint256 fee);
    //------------------CONSTRUCTOR-------------------------------

    /**
     *  @notice Creates the LOVI contract with the provided parameters.
     *  @dev Initializes the LOVI contract
     *  @param _treasury The address where minting fees are sent.
     *  @param _saleStartTime The timestamp when token minting starts.
     *  @param feeNumerator The royalty fee numerator for ERC2981.
     *  @param _merkleRoot The Merkle root used for whitelisting.
     *  @param _contractURI The URI for the contract's metadata.
     *  @param _baseurl TThe URI for the contract's metadata.
     */

    constructor(address payable _treasury, uint _saleStartTime, uint96 feeNumerator, bytes32 _merkleRoot, string memory _contractURI,string memory _baseurl, uint _max_cap, uint _thresholdQ) ERC721("LOVI", "LOVI") {
        require(_treasury != address(0),"Treasury can not be 0 address");
        treasuryAddress = _treasury;
        merkleRoot = _merkleRoot;
        contractURI = _contractURI;
        _setDefaultRoyalty(_treasury, feeNumerator);
        baseURI = _baseurl;
        saleStartTime = _saleStartTime;
        _cap = _max_cap;
        wlSaleStartQ = _thresholdQ;
    }

    //-------------------CONSTANT FUNCTIONS -------------------

    /// @dev Returns the maximum supply of LOVI tokens
    /// @return The maximum supply of LOVI tokens
    function maxSupply() external view returns(uint){
        return _cap;
    }

    /// @dev Returns the base URI for LOVI token metadata
    /// @return The base URI for LOVI token metadata
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //-------------------STATE-CHANGE FUNCTIONS ----------------

    /// @dev Changes the base URL for LOVI token metadata
    /// @param _baseURL The new base URL for LOVI token metadata
    /// @param isFinalReveled Indicates whether the contract metadata has been revealed and the change is final
    function changeBaseURI(string calldata _baseURL, bool isFinalReveled) external onlyOwner {
        require(!isReveled,"Already revealed");
        isReveled = isFinalReveled;
        baseURI = _baseURL;
    }


    /// @dev Updates the treasury address where minting fees are sent
    /// @param _treasury The new treasury address
    function updateTreasury(address payable _treasury) external onlyOwner{
        require(_treasury != address(0),"Treasury can not be 0 address");
        treasuryAddress = _treasury;
    }

    /// @dev Updates the minting fees required to mint a LOVI token
    /// @param _fee The new minting fee
    function updateMintingFees(uint _fee) external onlyOwner {
        mintingFees = _fee;
        emit UpdateFee(_fee);
    }

    /// @dev Updates the royalty receiver address and fee numerator for LOVI tokens
    /// @param _royaltyReceiver The new address to receive royalties
    /// @param feeNumerator The new royalty fee numerator
    function updateRoyalty(address _royaltyReceiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_royaltyReceiver, feeNumerator);
    }

    /// @dev Sets the contract URI for LOVI token metadata
    /// @param _contractURI The new contract URI
    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /**
     *  @notice This function verifies if the token minting has started and validates the Merkle proof for whitelisted addresses
     *  @dev Checks the eligibility of an address to participate in the token sale based on the provided Merkle proof
     *  @param merkleProof The Merkle proof for the address
     */
    function checkEligiblity(bytes32[] calldata merkleProof) internal view {
        require(saleStartTime < block.timestamp,"Minting not started");
        if(wlSaleStartT != 0 && block.timestamp <= wlSaleStartT + wlSaleI ){
            require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))) == true, "invalid merkle proof");
        }
    }

    /**
     *  @notice This function mints the specified number of LOVI tokens for the given address, charging the appropriate fees.
     *  It also verifies the Merkle proof for whitelisted addresses and updates the mintedAmount mapping accordingly.
     *  @dev Mints LOVI tokens for the specified address
     *  @param to The address to mint tokens to.
     *  @param amount The number of tokens to mint.
     *  @param merkleProof The Merkle proof for the address
     */
    function safeMint(address to, uint amount, bytes32[] calldata merkleProof) public payable nonReentrant{
        require(amount !=0 && mintedAmount[msg.sender]+amount <= MAX_INDIVIDUAL_MINT,"Invalid Amount");
        uint reqAmount = amount * mintingFees;
        require(reqAmount == msg.value,"Invalid Price");
        checkEligiblity(merkleProof);
        mintedAmount[msg.sender] = mintedAmount[msg.sender] + amount;
       // treasuryAddress.transfer(msg.value); // update this with appropriate method
        (bool sent, bytes memory data) = treasuryAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        for(uint i = 0; i < amount ; i++){
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            require(tokenId <= _cap,"Max Supply Reached");
            _safeMint(to, tokenId);
            if(tokenId == wlSaleStartQ){
                wlSaleStartT = block.timestamp;
            }
        }
    }

    function mintByAdmin(address to, uint amount) public onlyOwner {
        require(to != address(0), "mint to zero address");
        require(amount != 0, "atleast 1 token should be minted");
        for(uint i =0; i < amount; i++){

            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            require(tokenId <= _cap,"Max Supply Reached");
            _safeMint(to, tokenId);
            if(tokenId == wlSaleStartQ){
                wlSaleStartT = block.timestamp;
            }

        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}