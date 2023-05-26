// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error PrivateMintNotStarted();
error PublicMintNotStarted();
error InsufficientPayment();
error NotInWhitelist();
error ExceedSupply();
error ExceedMaxPerWallet();
error ExceedMaxPerTransaction();

     /*########################################################################################|
     ||                                                                                       ||
     ||                                                                                       ||
     ||                                                                                       ||
     ||                              ####  ####         ####  ####                            ||
     ||                              ####  ####         ####  ####                            ||
     ||                             #####  ####         ####  #####                           ||
     ||                            ############         ############                          ||
     ||                         ###############         ###############                       ||
     ||                       #################         #################                     ||
     ||                   *    ################ ### ### ################    *                 ||
     ||                   *   * ############### ### ### ############### *   *                 ||
     ||                 *  *  * *###################################* *  * **                 ||
     ||                      * *** * **#########################** * **  *                    ||
     ||                        *   ** *  **#################**  * **  **                      ||
     ||                         ##***  ** *  #############  * **  ***##                       ||
     ||                         ######*** ** *###########* ** ***######                       ||
     ||                         ################*     *################                       ||
     ||                         ############### *     * ###############                       ||
     ||                         ###############   * *   ###############                       ||
     ||                         ###############  ** **  ###############                       ||
     ||                        ################  * * *  ################                      ||
     ||                        ################   * *   ################                      ||
     ||                        ################   ***   ################                      ||
     ||                                                                                       ||
     ||                                                                                       ||
     ||     #####  #####   ########   ##########      ########     ########    #########      ||
     ||     #####  #####   ########   ###########    ##### #####   ########   ##### #####     ||
     ||     #####  #####   #####      #####  ####    ####  #####   #####      ##### #####     ||
     ||     ############   ########   ###########    ####  #####   ########    ########       ||
     ||     ############   ########   ##### #####    ####  #####   ########       #######     ||
     ||     #####  #####   #####      #####  ####    ####  #####   #####      #####  ####     ||
     ||     #####  #####   #########  #####  ####    ##### #####   #########  ##### #####     ||
     ||     #####  #####   #########  #####  ####     ########     #########    ########      ||
     ||                                                                                       ||
     ||                                                                                       ||
     |########################################################################################*/

contract CastleHeroes is ERC721A, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    uint16 private devSupply = 76;
    uint16 private presaleSupply = 1700;
    uint16 private collectionSupply = 1876;

    bool private privateMintStarted;
    bool private publicMintStarted;

    uint8 private presaleMaxItemsPerWallet = 1;
    uint8 private presaleMaxItemsPerTransaction = 1;
    uint8 private maxItemsPerWallet = 1;
    uint8 private maxItemsPerTransaction = 1;

    uint256 private presalePrice = 0 ether;
    uint256 private mintPrice = 0 ether;

    string private baseTokenURI;
    string private contractMetadataURI;

    bytes32 private presaleMerkleRoot;

    constructor() ERC721A("Castle Heroes", "CH") {}

    modifier whenPrivateMint() {
        if (!privateMintStarted || publicMintStarted) revert PrivateMintNotStarted();
        _;
    }

    modifier whenPublicMint() {
        if (!publicMintStarted) revert PublicMintNotStarted();
        _;
    }

    function devMint(uint8 quantity, address _destination) external onlyOwner {
        if(totalSupply() + quantity > devSupply) revert ExceedSupply();
        _mint(_destination, quantity);
    }

    function privateMint(bytes32[] memory proof, uint16 quantity) external payable nonReentrant whenPrivateMint {
        if(msg.value < presalePrice * quantity) revert InsufficientPayment();
        if(totalSupply() + quantity > presaleSupply) revert ExceedSupply();
        if(quantity > presaleMaxItemsPerTransaction) revert ExceedMaxPerTransaction();
        if(_numberMinted(msg.sender) + quantity > presaleMaxItemsPerWallet) revert ExceedMaxPerWallet();
        if(!isAddressWhitelisted(proof, msg.sender)) revert NotInWhitelist();

        _mint(msg.sender, quantity);        
    }

    function mint(uint8 quantity) external payable nonReentrant whenPublicMint {
        if(msg.value < mintPrice * quantity) revert InsufficientPayment();
        if(totalSupply() + quantity > collectionSupply) revert ExceedSupply();
        if(quantity > maxItemsPerTransaction) revert ExceedMaxPerTransaction();
        if(_numberMinted(msg.sender) + quantity > maxItemsPerWallet) revert ExceedMaxPerWallet();

        _mint(msg.sender, quantity);        
    }

    function isAddressWhitelisted(bytes32[] memory proof, address _address) internal view returns (bool) {
        return proof.verify(presaleMerkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function withdraw() external onlyOwner nonReentrant {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory value) external onlyOwner {
        baseTokenURI = value;
    }

    function setContractMetadataURI(string memory value) external onlyOwner {
        contractMetadataURI = value;
    }

    function startPrivateMint() external onlyOwner {
        privateMintStarted = true;
    }

    function startPublicMint() external onlyOwner {
        publicMintStarted = true;
    }

    function emergencyStop() external onlyOwner {
        privateMintStarted = false;
        publicMintStarted = false;
    }

    function setPresaleMaxItemsPerWallet(uint8 value) external onlyOwner {
        presaleMaxItemsPerWallet = value;
    }

    function setPresaleMaxItemsPerTransaction(uint8 value) external onlyOwner {
        presaleMaxItemsPerTransaction = value;
    }

    function setMaxItemsPerWallet(uint8 value) external onlyOwner {
        maxItemsPerWallet = value;
    }

    function setMaxItemsPerTransaction(uint8 value) external onlyOwner {
        maxItemsPerTransaction = value;
    }

    function setPresalePrice(uint256 value) external onlyOwner {
        presalePrice = value;
    }

    function setMintPrice(uint256 value) external onlyOwner {
        mintPrice = value;
    }

    function setDevSupply(uint16 value) external onlyOwner {
        devSupply = value;
    }

    function setPresaleSupply(uint16 value) external onlyOwner {
        presaleSupply = value;
    }

    function setCollectionSupply(uint16 value) external onlyOwner {
        collectionSupply = value;
    }

    function setPresaleMerkleRoot(bytes32 value) external onlyOwner {
        presaleMerkleRoot = value;
    }
}