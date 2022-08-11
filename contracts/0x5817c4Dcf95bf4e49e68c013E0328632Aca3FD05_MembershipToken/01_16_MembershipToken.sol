pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IBaseToken.sol";
import "./interfaces/IMembershipToken.sol";


/**
    @notice Membership token contract
    @dev Only one token per address is allowed
*/
contract MembershipToken is IMembershipToken, ERC721, Ownable {
    using Strings for uint256;

    uint256 internal lastTokenId_;
    // Token metadata base Uri
    string internal baseURI;
    // Contract metadata Uri
    string public contractURI;

    // Base token contract address
    address public baseTokenAddress;

    mapping(address => bool) alreadyMinted;

    /**
        @notice A constructor function is executed once when a contract is created and it is used to initialize
                contract state.
        @param _name - membership token name (cannot be changed after)
        @param _symbol - membership token symbol (cannot be changed after)
        @param _baseURI - membership token address where NFT images are stored
        @param _contractURI - membership token contract metadata URI
    */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _contractURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        contractURI = _contractURI;
    }

    event Mint(address to, uint256 tokenId);

    // onlyOwner events
    event Initialize(address baseTokenAddress);
    event SetContractURI(string contractURI);
    event SetBaseURI(string baseUri);


    /**
        @notice A function to initialize contract and set Base token address
        @param _baseTokenAddress - Base token address
    */
    function initialize(address _baseTokenAddress)
    external
    override
    onlyOwner
    {
        baseTokenAddress = _baseTokenAddress;

        emit Initialize(_baseTokenAddress);
    }

    /**
        @notice This is an external function that is called to mint a membership token
        @dev Only one token per address is allowed
    */
    function mint() external override {
        address _txSender = msg.sender;
        require(
            IBaseToken(baseTokenAddress).membershipMintPass(_txSender),
            "MembershipToken: you are not allowed to mint tokens"
        );
        require(!alreadyMinted[_txSender] && balanceOf(_txSender) == 0, "MembershipToken: you already have token or have minted token");

        uint256 _tokenId = ++lastTokenId_;
        alreadyMinted[_txSender] = true;
        _mint(_txSender, _tokenId);

        emit Mint(_txSender, _tokenId);
    }

    /**
        @notice Contract URI address setter
        @dev Available for owner only
        @param _contractURI - new contract Uri
    */
    function setContractURI(string memory _contractURI)
    external
    override
    onlyOwner
    {
        contractURI = _contractURI;

        emit SetContractURI(_contractURI);
    }


    /**
        @notice Token base URI address setter
        @dev Available for owner only
        @param _baseUri - new base Uri
    */
    function setBaseURI(string memory _baseUri) external override onlyOwner {
        baseURI = _baseUri;

        emit SetBaseURI(_baseUri);
    }

    /**
        @dev Get a tokenURI
        @param _tokenId - an id whose `tokenURI` will be returned
        @return tokenURI string
    */
    function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(
            _exists(_tokenId),
            "MembershipToken: URI query for nonexistent token"
        );

        // Concatenate the tokenID to the baseURI, token symbol and token id
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    /**
        @notice Used to protect Owner from shooting himself in a foot
        @dev This function overrides same-named function from Ownable
             library and makes it an empty one
    */
    function renounceOwnership() public override onlyOwner {}
}