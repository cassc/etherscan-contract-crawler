// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@a16z/contracts/licenses/CantBeEvil.sol";

contract Soulbonds is ERC721, Ownable, CantBeEvil(LicenseVersion.EXCLUSIVE) {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    address constant public METADATA_SIGNER = 0x1F89047445b44708bDbb4fA1620eDb4dB9249D57;
    address constant public TEAM_WALLET = 0x0dED1cD7d710cc1E31126a453e322a5662583Ff2;

    uint256 constant public GEN0_MINT_PRICE = 0.1559 ether;
    uint256 constant public GEN1_MINT_PRICE = 0.096 ether;

    uint256 constant public GEN0_REFERRAL_RATE = 60;
    uint256 constant public GEN1_REFERRAL_RATE = 40;

    uint256 public Gen0TotalSupply = 800;

    // Total number of tokens minted
    Counters.Counter private _tokenIdCounter;

    // A mapping to query tokenURI directly from owner address (through corresponding token ID)
    mapping(address => uint256) public tokenIDs;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    // To track already existing URIs
    mapping(string => bool) private _existingURIs;
    // A mapping storing the amount of referral rewards available for the given address
    mapping(address => uint256) public referralsClaim;

    string private _baseTokenURI;
    string private _baseTokenURISuffix;

    event Refer(address indexed referrer, address indexed referee);
    event Claim(address indexed claimer, uint256 value);

    constructor() ERC721("Soulbonds", "SOUL") {
        _setBaseTokenURI("https://gateway.ceramic.network/api/v0/streams/");
        _setBaseTokenURISuffix("/content");
        // Start the counter at 1 to avoid empty memory gas penalty
        _tokenIdCounter.increment();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(CantBeEvil, ERC721) returns (bool) {
        return
        super.supportsInterface(interfaceId);
    }

    /**
     * @notice Implements Gen0 token minting 
     * @param metadataURI URI pointing to metadata - ceramic stream ID ONLY in our case
     * @param signature signature of metadataURI - to avoid minting outside of the dapp
     */
    function payToMintGen0(
        string memory metadataURI,
        bytes memory signature
    ) external payable {
        require(_tokenIdCounter.current() <= Gen0TotalSupply, "Limit of tokens has been reached");
        require(msg.value == GEN0_MINT_PRICE, "Wrong amount of ETH transferred");

        _payToMint(metadataURI, signature);

        payable(TEAM_WALLET).transfer(GEN0_MINT_PRICE);
    }

    /**
     * @notice Implements Gen1 token minting
     * @param refAddress referral address
     * @param metadataURI URI pointing to metadata - ceramic stream ID ONLY in our case
     * @param signature signature of metadataURI - to avoid minting outside of the dapp
     */
    function payToMintGen1(
        address refAddress,
        string memory metadataURI,
        bytes memory signature
    ) external payable {
        require(_tokenIdCounter.current() > Gen0TotalSupply, "Limit of Gen0 tokens has not been reached");
        require(balanceOf(refAddress) == 1, "Your referral does not own the token");
        require(msg.value == GEN1_MINT_PRICE, "Wrong amount of ETH transferred");

        _payToMint(metadataURI, signature);

        uint256 refRate = tokenIDs[refAddress] > Gen0TotalSupply ? GEN1_REFERRAL_RATE : GEN0_REFERRAL_RATE;
        referralsClaim[refAddress] += GEN1_MINT_PRICE * refRate / 100;
        payable(TEAM_WALLET).transfer(GEN1_MINT_PRICE * (100 - refRate) / 100);
        emit Refer(refAddress, msg.sender);
    }

    /**
     * @notice Implements returning complete metadata URI from owner address is tokenID is unknown
     * @param owner owner address
     */
    function tokenURIByOwner(address owner)
        external
        view
        returns (string memory)
    {
        require(tokenIDs[owner] > 0, "This address does not own the $SOUL token");
        return tokenURI(tokenIDs[owner]);
    }

    /**
     * @notice Returns total number of active tokens
     */
    function totalCount() public view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    /**
     * @notice Set the base token URI
     * @param uri string base URI to assign
     */
    function _setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    /**
     * @notice Sets the base token URI suffix
     * @param uriSuffix string base URI suffix to assign
     */
    function _setBaseTokenURISuffix(string memory uriSuffix) public onlyOwner {
        _baseTokenURISuffix = uriSuffix;
    }

    /**
     * @notice Shrink Gen0 Supply to speed up the start of the referral system
     * @param newSupply new Gen0 Supply
     */
    function shrinkGen0Supply(uint256 newSupply) public onlyOwner {
        require(totalCount() < Gen0TotalSupply, "Can't shrink after the start of Gen1 mints");
        require(Gen0TotalSupply > newSupply, "Only shrinking available");
        Gen0TotalSupply = newSupply;
    }

    /**
     * @notice Implements claiming referral rewards
     */
    function claimRef() public {
        require(balanceOf(msg.sender) == 1, "You should own an NFT to claim reward");
        uint256 reward = referralsClaim[msg.sender];
        require(reward > 0, "You should invite someone to have any reward");
        referralsClaim[msg.sender] = 0;
        payable(msg.sender).transfer(reward);
        emit Claim(msg.sender, reward);
    }

    /**
     * @notice Implements returning complete metadata URI
     * @param tokenId Token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, _tokenURIs[tokenId], _baseTokenURISuffix));
    }

    /**
     * @notice Reverts approval of external addresses
     */
    function approve(address , uint256) public pure override(ERC721) {
        revert("Cannot approve as the token is non-transferable");
    }

    /**
     * @notice Reverts approval of external operator addresses
     */
    function setApprovalForAll(address , bool) public pure override(ERC721) {
        revert("Cannot approve as the token is non-transferable");
    }


    /**
     * @notice Reverts transfers of tokens to all address
     */
    function _transfer(
        address,
        address,
        uint256
    ) internal pure override(ERC721)
    {
        revert("Token is non transferable");
    }

    /**
     * @notice Sets stream ID for a given token
     * @dev Reimplementation of OpenZeppelins ERC721URIStorage _setTokenURI method
     * @param tokenId token ID 
     * @param _tokenURI The URI to be set for token ID
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) private {
        require(_exists(tokenId),  "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @notice Verifies that the provided signature was produced by the correct signer from the given message
     * @param metadata string containing the ceramic stream ID
     * @param signature backend-produced signature to verify the correctness of metadata
     */
    function _verify(
        string memory metadata,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(metadata, msg.sender)).toEthSignedMessageHash();
        (address recoveredSigner, ECDSA.RecoverError recoverError) = ethSignedMessageHash.tryRecover(signature);
        require(recoverError == ECDSA.RecoverError.NoError, "Error retrieving signature author");
        require(recoveredSigner == METADATA_SIGNER, "Metadata signed by untrusted signer");
        return true;
    }

    /**
     * @notice Implements token minting for both generations after generation specifics are completed 
     * @param metadataURI URI pointing to metadata - ceramic stream ID ONLY in our case
     * @param signature signature of metadataURI - to avoid minting outside of the dapp
     */
    function _payToMint(
        string memory metadataURI,
        bytes memory signature
    ) private {
        // Verify signature in the _verify function, revert from it if signature is wrong
        _verify(metadataURI, signature);

        // Making sure that no address can own two or more tokens
        require(balanceOf(msg.sender) == 0, "Same wallet cannot own two Souls");
        // Make sure such stream ID doesn't already exist
        require(_existingURIs[metadataURI] == false, "Stream ID already taken");

        uint256 newItemId = _tokenIdCounter.current();

        _tokenIdCounter.increment();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, metadataURI);
        _existingURIs[metadataURI] = true;

        tokenIDs[msg.sender] = newItemId;
    }
}