// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721-templates/chirulabsERC721A.sol";

/**
    Metaclub Genesis Collection
    by CryptoChile, laurin.eth
 */

contract metaclub is chirulabsERC721A { 
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Strings for uint;

    IPaperKeyManager paper; 

    address internal fundReciever;
    address internal usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    string public baseURI = "ar://P1fjtIvwJG7iXl3vzFDPeJLPXtoo5Ab2UsT_x5h9q2I/";

    uint256 constant public MAX_SUPPLY = 2500; 
    bool public mintActive = true;

    uint256 mintPrice = 120000000;
    uint256 discountPrice = 80000000;

    /**
     * @param name The NFT collection name
     * @param symbol The NFT collection symbol
     * @param receiver The wallet address to recieve the royalties
     * @param feeNumerator Numerator of royalty % where Denominator default is 10000
     */
    constructor (
        string memory name, 
        string memory symbol,
        address receiver,
        uint96 feeNumerator,
        address paper_
        ) 
    chirulabsERC721A(name, symbol, receiver, feeNumerator)
    {
        fundReciever = receiver;
        paper = IPaperKeyManager(paper_);

        _mint(0x911eDBA290F75c1119D3045846fE88dE4F357107, 500); // metaclub 
    }

    //@dev https://docs.paper.xyz
    // onlyPaper modifier to easily restrict multiple different function
    modifier onlyPaper(bytes32 _hash, bytes32 _nonce, bytes calldata _signature) {
        bool success = paper.verify(_hash, _nonce, _signature);
        require(success, "Paper: Failed to verify signature");
        _;
    }

    /**
     * Allows owner to send aribitrary amounts of tokens to arbitrary adresses
     * Used to get offchain PreSale buyers their tokens
     * @param recipient Array of addresses of which recipient[i] will recieve amount [i]
     * @param amount Array of integers of which amount[i] will be airdropped to recipient[i]
     */
    function airdrop(
        address[] memory recipient,
        uint256[] memory amount
    )
    public onlyOwner
    {
        for(uint i = 0; i < recipient.length; ++i)
        {
            require(totalSupply().add(amount[i]) <= MAX_SUPPLY, "705 no more token available");
            _safeMint(recipient[i], amount[i]);
        }
    }

    /**
     * If mint is active, set it to not active.
     * If mint is not active, set it to active.
     */
    function flipMintState() 
    public onlyOwner
    {
        mintActive = !mintActive;
    }


    /**
     * Allows owner to set usdc contract address
     * @param usdc_ the address of USDC contract
     */
    function setUSDC(
        address usdc_
    )
    public onlyOwner
    {
        usdc = usdc_;
    }

    /**
     * Allows owner to set paper contract address
     * @param paper_ the new paper contract address
     */
    function setPaper(
        address paper_
    )
    public onlyOwner
    {
        paper = IPaperKeyManager(paper_);
    }

    /**
     * Allows owner to set paper key
     * @param _paperKey the key to be registered
     */
    function registerPaperKey(address _paperKey) external onlyOwner {
        require(paper.register(_paperKey), "Error registering key");
    }

    /**
     * Allows to check allowlist eligibility
     * @dev implements https://docs.paper.xyz/reference/eligibilitymethod
     * @param quantity amount to check for
     */
    function checkClaimEligibility(
        uint256 quantity
    ) 
    public view returns (
        string memory
    ){
        require(mintActive, "mint not active");
        require(totalSupply().add(quantity) <= MAX_SUPPLY, "705 no more token available"); 

        return "";
    }

    /**
     * Allows you to buy tokens
     * @dev implements https://docs.paper.xyz/reference/mintmethod
     * @param toAddress wallet to mint to
     * @param quantity amount of tokens to get
     * @param _nonce nonce for paper
     * @param _signature Signature for paper
     */
    function paperMint(
        address toAddress,
        uint256 quantity,
        bytes32 _nonce,
        bytes calldata _signature
    )
    public payable 
    onlyPaper(keccak256(abi.encode(toAddress, quantity)), _nonce, _signature)
    {
        require(mintActive, "702 Feature disabled/not active"); 
        require(totalSupply().add(quantity) <= MAX_SUPPLY, "705 no more token available"); 

        // transfer 120 usdc to fundReciever
        IERC20(usdc).transferFrom(msg.sender, fundReciever, quantity*mintPrice);

        _safeMint(toAddress, quantity); 
    }

    /**
     * Allows you to buy tokens at discount
     * @dev implements https://docs.paper.xyz/reference/mintmethod
     * @param toAddress wallet to mint to
     * @param quantity amount of tokens to get
     * @param _nonce nonce for paper
     * @param _signature Signature for paper
     */
    function paperMintDiscount(
        address toAddress,
        uint256 quantity,
        bytes32 _nonce,
        bytes calldata _signature
    )
    public payable 
    onlyPaper(keccak256(abi.encode(toAddress, quantity)), _nonce, _signature)
    {
        require(mintActive, "702 Feature disabled/not active"); 
        require(totalSupply().add(quantity) <= MAX_SUPPLY, "705 no more token available");

        // transfer 84 usdc to fundReciever
        IERC20(usdc).transferFrom(msg.sender, fundReciever, quantity*discountPrice);

        _safeMint(toAddress, quantity); 

    }

    /**
     * Allows owner to set the mintPrice
     */
    function setMintPrice(uint256 _mintPrice)
    public onlyOwner
    {
        mintPrice = _mintPrice;
    }

    
    /**
     * Allows owner to set the mintPrice
     */
    function setDiscountPrice(uint256 _discountPrice)
    public onlyOwner
    {
        discountPrice = _discountPrice;
    }

    /**
     * Allows owner to set reciever of withdrawl
     * @param reciever who to recieve the balance of the contract
     */
    function setReciever(address reciever)
    public onlyOwner
    {
        fundReciever = reciever;
    }

    /**
     * Allows owner to set baseURI for all tokens
     * @param newBaseURI_ new baseURI to be used in tokenURI generation
     */
    function setBaseURI(
        string calldata newBaseURI_
    ) external onlyOwner 
    {
        baseURI = newBaseURI_;
    }

    /**
     * Allows owner to withdraw all ETH
     */
    function withdraw()
    public onlyOwner 
    {
        payable(fundReciever).transfer(address(this).balance); 
    }

    /**
     * Allows owner to set new EIP2981 Royalty share and/or reciever for the whole collection
     * @param reciever_ new royalty reciever to be used
     * @param feeNumerator_ new royalty share in basis points to be used e.g. 100 = 1%
     */
    function setRoyalty(
        address reciever_,
        uint96 feeNumerator_
    ) public onlyOwner
    {
        _setDefaultRoyalty(reciever_, feeNumerator_);
    }

    /**
     * Returns the URI (Link) to the given tokenId
     * @param tokenId_ tokenId of which to get the URI
     */
    function tokenURI(
        uint tokenId_
    ) public override view
    returns (string memory)
    {
        require(_exists(tokenId_), "704 Query for nonexistent token");

        string memory _baseURI = baseURI;
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId_.toString(), '.json')) : "https://dtech.vision";
    }

}

// License-Identifier: MIT
/// @title Paper Key Manager
/// @author Winston Yeo
/// @notice PaperKeyManager makes it easy for developers to restrict certain functions to Paper.
/// @dev Developers are in charge of registering the contract with the initial Paper key.
///      Paper will then help you  automatically rotate and update your key in line with good security hygiene
interface IPaperKeyManager {
    /// @notice Registers a Paper Key to a contract
    /// @dev Registers the @param _paperKey with the caller of the function (your contract)
    /// @param _paperKey The Paper key that is associated with the checkout. 
    /// You should be able to find this in the response of the checkout API or on the checkout dashbaord.
    /// @return bool indicating if the @param _paperKey was successfully registered with the calling address
    function register(address _paperKey) external returns (bool);

    /// @notice Verifies if the given @param _data is from Paper and have not been used before
    /// @dev Called as the first line in your function or extracted in a modifier. Refer to the Documentation for more usage details.
    /// @param _hash The bytes32 encoding of the data passed into your function.
    /// This is done by calling keccak256(abi.encode(...your params in order))
    /// @param _nonce a random set of bytes Paper passes your function which you forward. This helps ensure that the @param _hash has not been used before.
    /// @param _signature used to verify that Paper was the one who sent the @param _hash
    /// @return bool indicating if the @param _hash was successfully verified
    function verify(
        bytes32 _hash,
        bytes32 _nonce,
        bytes calldata _signature
    ) external returns (bool);
}