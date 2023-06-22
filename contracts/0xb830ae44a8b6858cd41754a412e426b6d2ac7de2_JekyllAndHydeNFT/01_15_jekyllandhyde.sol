// SPDX-License-Identifier: MIT
/*                                                                          ▄▄    ▄▄  
                ▀███▀▀▀██▄                 ▀████▀       ▀███                 ▀███  ▀███  
                ██    ▀██▄                 ██           ██                   ██    ██  
                ██     ▀█████▄███          ██   ▄▄█▀██  ██  ▄██▀▀██▀   ▀██▀  ██    ██  
                ██      ██ ██▀ ▀▀          ██  ▄█▀   ██ ██ ▄█     ██   ▄█    ▓█    ▓█  
                █▓     ▄██ █▓              ██  ▓█▀▀▀▀▀▀ ▓█▄██      ██ ▄▓     ▓█    ▓█  
                █▓    ▄█▓▀ █▓         ██▓  ██  ▓█▄    ▄ ▓█ ▀██▄     ██▓      ▓█    ▓█  
                ▓▓     ▓▓▓ ▓▓              ▓▓  ▓▓▀▀▀▀▀▀ ▓▓▓▓▓       █▓▓      ▓▓    ▓▓  
                ▓▒    ▓▓▒▀ ▓▒    ▓▓   ▓▓▓  ▓▓  ▒▓▓      ▒▓ ▀▓▓▓     ▓▓▒      ▒▓    ▒▓  
                ▒ ▒ ▒ ▒ ▒  ▒ ▒▒▒   ▒     ▒▓▒ ▒    ▒ ▒ ▒▒▒ ▒ ▒  ▒ ▒    ▓▓     ▒ ▒ ▒ ▒ ▒ ▒ 
                                                                    ▒▒▓                  
                                                                ▒▒▒                
                           ▄▄                                                                 ▄▄          
                         ▀███     ▀████▄     ▄███▀            ▀████▀  ▀████▀▀               ▀███          
                           ██       ████    ████                ██      ██                    ██          
 ▄█▀██▄ ▀████████▄    ▄█▀▀███       █ ██   ▄█ ██ ▀███▄███       ██      ██  ▀██▀   ▀██▀  ▄█▀▀███   ▄▄█▀██ 
██   ██   ██    ██  ▄██    ██       █  █▓  █▀ ██   ██▀ ▀▀       ██████████    ██   ▄█  ▄██    ██  ▄█▀   ██
 ▄███▓█   █▓    ██  █▓█    █▓       ▓  █▓▄█▀  ██   █▓           ▓█      █▓     ██ ▄▓   █▓█    █▓  ▓█▀▀▀▀▀▀
█▓   ▓█   █▓    ▓█  ▀▓█    █▓       ▓  ▀▓█▀   ██   █▓           ▓█      █▓      ██▓    ▀▓█    █▓  ▓█▄    ▄
 ▓▓▓▓▒▓   ▓▓    ▓▓  ▓▓▓    ▓▓       ▓  ▓▓▓▓▀  ▓▓   ▓▓           ▒▓      ▓▓      █▓▓    ▓▓▓    ▓▓  ▓▓▀▀▀▀▀▀
▓▓   ▒▓   ▓▓    ▓▓  ▀▒▓    ▓▒       ▒  ▀▓▓▀   ▓▓   ▓▒    ▓▓     ▒▓      ▒▓      ▓▓▒    ▀▒▓    ▓▒  ▒▓▓     
▒▓▒ ▒ ▓▒▒ ▒▒▒  ▒▓▒ ▒ ▒ ▒ ▒ ▓ ▒    ▒ ▒▒▒ ▒   ▒ ▒▒▒▒ ▒▒▒   ▒    ▒▒▒ ▒   ▒ ▒▓▒▒    ▓▓      ▒ ▒ ▒ ▓ ▒  ▒ ▒ ▒▒ 
                                                                              ▒▒▓                         
                                                                            ▒▒▒                           

*/
/// @title The Strange Case of Dr. Jekyll and Mr. Hyde NFT
/// @author audie.eth
/// @notice An NFT for the book with art by Rata

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract JekyllAndHydeNFT is ERC2981, ERC721, Ownable {
    // fixed values
    uint256 private constant _collectionSize = 1100; 
    uint256 private constant _earnableNFTs = 100; 
    uint256 private _mintableNFTsAvailable = _collectionSize - _earnableNFTs;
    uint256 private _nextEarnedNFTId;
    uint256 private _nextMintedNFTId = _earnableNFTs; // the first mintable ID

    // mutable properties
    string private _baseTokenURI =
        "https://bookcoin.mypinata.cloud/ipfs/QmQo1G8DyuZuytTnCKkmX94LgyTXMJWLdkcdG2ohmzBzXr/";
    string private _contractUri =
        "https://bookcoin.mypinata.cloud/ipfs/QmWpgMsiQnp8CUf6LSXcmcy7Eo77mspVvhqnc3hxc29KLs";
    bytes32 private _merkleRoot; // the merkle root for the claims
    bytes32 private _earnedMerkle; // the merkle root for the readers who won and got a code
    uint256 private _mintedSupply = 0;
    uint256 private _mintPrice = 0.03 ether;

    uint256 private _bookMintStartTime = 1657638000; // 10:00 CST Jul 12, 2022
    uint256 private _bookMintEndTime = 1665414000; // 10:00 CST Oct 10, 2022 

    // used for psuedo-Random mint mechanic
    uint256[_collectionSize] private _tokenIds;

    // track claims and used codes
    mapping(string => address) private _codesBurnt;
    mapping(address => bool) private _claims;
    mapping(address => bool) private _earns;

    // EIP2981 properties
    address royaltyAddr = 0xADdA604Da5Ad57cF8c9AB1bD41945A5DffBf8467;
    uint96 royaltyPercent = 750; // denominator is 10000, so this is 7.5%

    //events
    event MintPriceChanged(uint256 newMintPrice);
    event MintStartChanged(uint256 newMintStart);
    event MintEndChanged(uint256 newMintEnd);
    event ClaimRootChanged(bytes32 newMerkleRoot);
    event EarnRootChanged(bytes32 newMerkleRoot);
    event ContractURIChanged(string newContractURI);
    event BaseURIChanged(string newBaseURI);

    // reused strings
    string private constant BAD_PROOF = "Bad Proof";

    /**
     *  @notice Contructor for the NFT
     *  @param name The long name of the NFT collection
     *  @param symbol The short, all caps symbol for the collection
     *  @param merkleroot The merkle root for the allowed claimers
     *  @param earnedMerkle The merkle root for the earnable NFTs - from a code they'll receive
     */
    constructor(
        string memory name,
        string memory symbol,
        bytes32 merkleroot,
        bytes32 earnedMerkle
    ) ERC2981() ERC721(name, symbol) Ownable() {
        _setDefaultRoyalty(royaltyAddr, royaltyPercent);
        _merkleRoot = merkleroot;
        _earnedMerkle = earnedMerkle;
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
     *  @notice Allows a gas only claim of one of the NFTs
     *  @param proof A merkle proof that confirms the sender's address is in list of eligible claimers
     */
    function claim(bytes32[] calldata proof) external {
        // only the address on the merkle tree can mint, no others - means tree can be public
        address account = _msgSender();
        require(_claims[account] == false, "Claimed Already");
        require(_verifyClaim(_leafAddress(account), proof), BAD_PROOF);
        _claims[account] = true;
        _mintOne(account);
    }

    /**
     *  @notice Allows a person with a code to "earn" a rare NFT
     *  @param proof A merkle proof that confirms code sent is in the earn list
     */
    function earn(string calldata code, bytes32[] calldata proof) external {
        address account = _msgSender();
        require(canEarn(account, code, proof), BAD_PROOF);
        _earns[account] = true;
        _codesBurnt[code] = account;
        _mintEarned(account);
    }

    /**
     *  @notice Allows anyone to mint an NFT for the Mint Price
     */
    function mint() external payable {
        address account = _msgSender();
        require(msg.value >= _mintPrice, "Must send Mint Price");
        require(_inMintTime(), "Mint not open");
        _mintOne(account);
    }

    /**
     *  @notice Owner only mint function to mint reserves or giveaways - call only after mint period is over
     *  @param account The address to receive all the minted NFTs
     */
    function ownerMintBlock(address account, uint256 count) external onlyOwner {
        for (uint256 i = 1; i < _tokenIds.length && i <= count; i++) {
            if (_nextMintedNFTId < _collectionSize) {
                _mintOne(account);
            }
        }
    }

    /**
     *  @notice Allows the owner or approved spender to destroy the book
     *  @param tokenId The token ID of the token to destroy
     */    
    function burn(uint256 tokenId)
        public
        virtual
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not Owner Or Approved");
        _burn(tokenId);
    }

    /**
     *  @notice Allows the owner to withdraw the Ether collected from minting
     */
    function withdrawEther() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
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
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     *   @notice Shows maximum supply
     *   @return uint256 Returns the maximum number of mintable NFTs
     */
    function maxSupply() public view returns (uint256) {
        return _tokenIds.length;
    }

    /**
     *   @notice Shows minted supply
     *   @return uint256 Returns total existing supply
     */
    function mintedSupply() public view returns (uint256) {
        // total supply is the total minted
        return _mintedSupply;
    }

    /**
     *   @notice Shows mintable supply
     *   @return uint256 Returns total mintable supply
     *   @dev This is collection size less the premium earnable NFTs
     */
    function mintableSupply() public view returns (uint256) {
        // total supply is the total minted
        return maxSupply() - _earnableNFTs;
    }

    /**
     *  @notice Provides the mint price needed to mint an NFT
     */
    function mintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    /**
     *  @notice Allows the owner to set a new mint price
     *  @param newMintPrice The new mint price as a uint256
     *  @dev Don't forget the 18 zeros
     */
    function setMintPrice(uint256 newMintPrice) public onlyOwner {
        _mintPrice = newMintPrice;
        emit MintPriceChanged(newMintPrice);
    }

    /**
     *  @notice Provides the merkle root being used to allow gas only claims
     */
    function merkleRoot() public view returns (bytes32) {
        return _merkleRoot;
    }

    /**
     *  @notice Allows the owner to set a new merkle root for gas free claim
     *  @param newMerkleRoot A merkle root created from a list of approved claimers
     */
    function setMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
        _merkleRoot = newMerkleRoot;
        emit ClaimRootChanged(newMerkleRoot);
    }

    /**
     *  @notice Provides the merkle root being used to control the mint of earnable NFTs
     */
    function earnedMerkleRoot() public view returns (bytes32) {
        return _earnedMerkle;
    }

    /**
     *  @notice Allows the owner to set a new merkle root for the earnable NFTs
     *  @param newMerkleRoot A merkle root created from a list of codes people can earn
     */
    function setEarnedMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
        _earnedMerkle = newMerkleRoot;
        emit EarnRootChanged(newMerkleRoot);
    }

    /**
     *  @notice Retrieves the mint start time
     *  @return date The unix time stamp for when the mint starts
     */
    function getBookMintStartTime() public view returns (uint256) {
        return _bookMintStartTime;
    }

    /**
     *  @notice Set the timestamp after which mint opens
     *  @param newMintStart The unix time stamp mint will begin
     *  @dev First block after the mint time allows minting or claiming
     */
    function setBookMintStartTime(uint256 newMintStart) public onlyOwner {
        _bookMintStartTime = newMintStart;
        emit MintStartChanged(newMintStart);
    }

    /**
     *  @notice Retrieves the mint end time
     *  @return date The unix time stamp for when the mint ends
     */
    function getBookMintEndTime() public view returns (uint256) {
        return _bookMintEndTime;
    }

    /**
     *  @notice Set the timestamp after which mint stops
     *  @param newMintEnd The unix time stamp mint will ends
     *  @dev First block after the set time won't allow minting or claiming
     */
    function setBookMintEndTime(uint256 newMintEnd) public onlyOwner {
        _bookMintEndTime = newMintEnd;
        emit MintEndChanged(newMintEnd);
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
        emit ContractURIChanged(newContractUri);
    }

    /**
     *   @notice Sets the token metadata base URI
     *   @param uri The baseURI for the token metadata
     *   @dev Make sure to include the trailing slash, as tokenURI adds only tokenID and ".json" to the end
     */
    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
        emit BaseURIChanged(uri);
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
            "No such token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /**
     *  @notice Confirms an address and proof will allow minting
     *  @param account The address to use as the first part of a merkle leaf
     *  @param proof The merkle proof you want to check is valid
     *  @dev This needs the address proof, and time to be correct. Time check is in internal _verifyClaim function
     */
    function canClaim(address account, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        return
            _claims[account] == true
                ? false
                : _verifyClaim(_leafAddress(account), proof);
    }

    /**
     *  @notice Confirms minting is open
     *  @dev Minting is only available between book mint start time and end time
     */
    function canMint() public view returns(bool)
    {
        return _inMintTime();
    }

    /**
     *  @notice Confirms code and proof work can earn an premium NFT
     */
    function canEarn(address account, string calldata code, bytes32[] calldata proof) public view returns(bool)
    {
        require(_earns[account] == false, "Address already earned");
        require(_codesBurnt[code] == address(0), "Code Already Used");
        require(super.balanceOf(account) > 0, "Must own NFT to earn");
        return _verifyEarn(_leafString(code), proof);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // mints a single earnable NFT
    function _mintEarned(address account) internal {
        // will only mint ids from 0 to one less than earnable NFTs
        require(_nextEarnedNFTId < _earnableNFTs, "No more earnable NFTs");
        uint256 nextToken = _nextEarnedNFTId;
        _safeMint(account, nextToken);
        _nextEarnedNFTId += 1;
        _mintedSupply += 1;
    }

    // mints a single NFT
    function _mintOne(address account) internal {
        require(_nextMintedNFTId < _collectionSize, "No more mintable NFTs");
        uint256 nextToken = _nextMintedNFTId;
        _safeMint(account, nextToken);
        _nextMintedNFTId += 1;
        _mintedSupply += 1;
    }

    // will hash an address for use in the Merkle tree verification
    function _leafAddress(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    // will hash a string for use in the Merkle tree verification
    function _leafString(string memory str) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }

    // checks if the address and proof work for a gas free claim
    function _verifyClaim(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        // Claim is only available during the mint window
        return
            _inMintTime()
                ? MerkleProof.verify(proof, _merkleRoot, leaf)
                : false;
    }

    // checks the code and proof will work
    function _verifyEarn(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        // earn doesn't depend on time - can earn after mint ends
        return MerkleProof.verify(proof, _earnedMerkle, leaf);
    }

    // checks if the current block is within the mint window
    function _inMintTime() internal view returns (bool) {
        uint256 currentBlockTime = block.timestamp;
        // check mint has started
        if (currentBlockTime > _bookMintStartTime) {
            // check mint hasn't ended
            if (currentBlockTime < _bookMintEndTime) {
                // verify merkle root - only way result can be true
                return true;
            }
        }
        return false;
    }
}