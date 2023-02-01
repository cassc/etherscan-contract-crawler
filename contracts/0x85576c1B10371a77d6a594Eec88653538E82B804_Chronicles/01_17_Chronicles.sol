// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./MutableOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/***
   ________                     _      __                   ____   __  __            
  / ____/ /_  _________  ____  (_)____/ /__  _____   ____  / __/  / /_/ /_  ___      
 / /   / __ \/ ___/ __ \/ __ \/ / ___/ / _ \/ ___/  / __ \/ /_   / __/ __ \/ _ \     
/ /___/ / / / /  / /_/ / / / / / /__/ /  __(__  )  / /_/ / __/  / /_/ / / /  __/     
\____/_/ /_/_/__ \____/_/ /_/_/\___/_/\___/____/_  \____/_/ __  \__/_/ /_/\___/__    
   /  _/___  / /_  ____ _/ /_  (_) /____  ____/ /  | |     / /___  _____/ /___/ /____
   / // __ \/ __ \/ __ `/ __ \/ / __/ _ \/ __  /   | | /| / / __ \/ ___/ / __  / ___/
 _/ // / / / / / / /_/ / /_/ / / /_/  __/ /_/ /    | |/ |/ / /_/ / /  / / /_/ (__  ) 
/___/_/ /_/_/ /_/\__,_/_.___/_/\__/\___/\__,_/     |__/|__/\____/_/  /_/\__,_/____/  

***/

contract Chronicles is MutableOperatorFilterer, ERC721A, ERC721AQueryable, ERC2981 {

    string private baseURI;
    address public ownerAddr = 0xdb275FaC4239aa53e3c56b7e999Dfc2B2406b671;
    address public clbAddr;

    // total NFTs that can be minted
    uint256 public maxSupply = 2000;

    /***
    Military Departments ID Mapping

    3101: Space Army / Marine Corps
    3102: Space Army / Pilot Corps
    3103: Space Army / Medical Services Corps
    3104: Space Army / Engineering Corps
    3200: Space Navy
    3300: Communications Service
    3401: Intelligence Service / Special Operations Department
    3402: Intelligence Service / Federal Department of Investigation
    3403: Intelligence Service / Justice Department
    
    */



    /**
     * CLB BURN TO MINT
     */ 

    // Guarantee info when burning a CLB to mint a COIW NFT
    // During burnToMint time, we save their preference for department, and whether it's a guaranteed rare
    struct ClbBurnPreference {
        uint16 department;        // This is set for yellow (legendary) and purple (uncommon) CLBs.  This is also set for common CLBs, which is its predetermined Dept.  See above comment for ID mapping.
        bool isRare;              // TRUE for yellow (legendary) CLBs
        uint256 clbTokenId;       // The token id of the CLB that was burned
    }
    // Map COIW NFT token ID to its original burn preferences
    mapping(uint256 => ClbBurnPreference) public tokenIdToClbBurnPreferences;
    uint256 public clbPrice = 0.05 ether;
    bool public pausedClbMint = true;
    uint256 public numReservedForClbs = 555;


    /**
     * WHITELIST1 MINT (non clb SJ holders)
     */ 
    uint256 public whitelistPrice1 = 0.1 ether;
    uint256 public maxWhitelistMintPerWallet1 = 2;
    bytes32 public whitelistMerkleRoot1;
    mapping(address => uint256) public whitelistClaimCount1;     // Number of NFTs claimed per whitelist1 address
    bool public pausedWhitelistMint1 = true;
    uint256 public numAllowedForWhitelist1 = 350;

    /**
     * WHITELIST2 MINT (partners)
     */ 
    uint256 public whitelistPrice2 = 0.1 ether;
    uint256 public maxWhitelistMintPerWallet2 = 1;
    bytes32 public whitelistMerkleRoot2;
    mapping(address => uint256) public whitelistClaimCount2;     // Number of NFTs claimed per whitelist2 address
    bool public pausedWhitelistMint2 = true;
    uint256 public numAllowedForWhitelist2 = 845;

    /**
     * PUBLIC MINT
     */ 
    uint256 public publicPrice = 0.1 ether;
    bool public pausedPublicMint = true;

    /**
     * GIVEAWAY
     */ 
    uint256 public numReservedForGiveAways = 250;
     

    bool public pausedAll = false;

    constructor(
      string memory name,
      string memory symbol,
      string memory initBaseURI,
      address operatorFilterRegistryAddress,
      address operatorFilterRegistrant
    ) ERC721A(name, symbol)
      MutableOperatorFilterer(operatorFilterRegistryAddress,operatorFilterRegistrant) {
        setBaseURI(initBaseURI);
    }

    /**
     * Init setup.
     */
    function setClbContractAddr(address addr) external onlyOwner {
        clbAddr = addr;
    }

    /**
     * Called by CoiwLootbox contract ONLY, to mint a Chronicles NFT.  Requires payment.
     * @return the newly minted NFT's token id
     */
    function mintFromBurn(address recipient, uint256 clbTokenId, bool isRare, uint16 department) external payable returns (uint256) {
        require(!pausedAll, "Mint paused");
        require(!pausedClbMint, "Burn-to-mint paused");
        require(_msgSender() == clbAddr, "mintFromBurn: Only CoiwLootbox can call this.");
        require( msg.value == clbPrice, "Ether sent is not correct" );
        require( 1 <= numReservedForClbs, "Exceeds reserved burn supply" );

        uint256 coiwTokenId = _nextTokenId();

        _safeMint( recipient, 1 );

        ClbBurnPreference memory prefs = ClbBurnPreference(
            department,
            isRare,
            clbTokenId
        );
        tokenIdToClbBurnPreferences[coiwTokenId] = prefs;
        numReservedForClbs -= 1;

        return coiwTokenId;
    }

    function mintFromBurnBatch(address recipient, uint256[] memory clbTokenIds, bool[] memory isRares, uint16[] memory departments) external payable returns (uint256[] memory) {
        require(!pausedAll, "Mint paused");
        require(!pausedClbMint, "Burn-to-mint paused");
        require(_msgSender() == clbAddr, "mintFromBurn: Only CoiwLootbox can call this.");
        require( clbTokenIds.length == isRares.length, "Length mismatch between clbTokenIds and isRares");
        require( clbTokenIds.length == departments.length, "Length mismatch between clbTokenIds and departments");
        require( msg.value == clbPrice * clbTokenIds.length, "Ether sent is not correct" );
        require( clbTokenIds.length <= numReservedForClbs, "Exceeds reserved burn supply" );

        uint256[] memory coiwTokenIds = new uint256[](clbTokenIds.length);

        for (uint256 i = 0; i < clbTokenIds.length; i++) {
            uint16 department = departments[i];
            bool isRare = isRares[i];
            uint256 clbTokenId = clbTokenIds[i];
            uint256 coiwTokenId = _nextTokenId();

            _safeMint( recipient, 1 );

            ClbBurnPreference memory prefs = ClbBurnPreference(
                department,
                isRare,
                clbTokenId
            );
            tokenIdToClbBurnPreferences[coiwTokenId] = prefs;
            coiwTokenIds[i] = coiwTokenId;
        }
        numReservedForClbs -= clbTokenIds.length;
        return coiwTokenIds;
    }


    // Intended for non CLB SJ holders
    function mintFromWhitelist1(uint256 num, bytes32[] calldata _merkleProof) external payable {
        uint256 supply = totalSupply();
        require( !pausedAll,           "Sale paused" );
        require( !pausedWhitelistMint1, "Whitelist sale paused" );
        require( supply + num <= maxSupply - numReservedForGiveAways - numReservedForClbs, "Exceeds maximum NFTs supply" );

        require( msg.value == whitelistPrice1 * num, "Ether sent is not correct" );
        require(whitelistClaimCount1[msg.sender] + num <= maxWhitelistMintPerWallet1, "Too many to claim");

        require(numAllowedForWhitelist1 >= num, "No more allocation for whitelist");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot1, leaf), "Invalid proof");

        whitelistClaimCount1[msg.sender] += num;
        numAllowedForWhitelist1 -= num;

        _safeMint( msg.sender, num );
    }

    // Intended for partners
    function mintFromWhitelist2(uint256 num, bytes32[] calldata _merkleProof) external payable {
        uint256 supply = totalSupply();
        require( !pausedAll,           "Sale paused" );
        require( !pausedWhitelistMint2, "Whitelist sale paused" );
        require( supply + num <= maxSupply - numReservedForGiveAways - numReservedForClbs, "Exceeds maximum NFTs supply" );

        require( msg.value == whitelistPrice2 * num, "Ether sent is not correct" );
        require(whitelistClaimCount2[msg.sender] + num <= maxWhitelistMintPerWallet2, "Too many to claim");

        require(numAllowedForWhitelist2 >= num, "No more allocation for whitelist");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot2, leaf), "Invalid proof");

        whitelistClaimCount2[msg.sender] += num;
        numAllowedForWhitelist2 -= num;

        _safeMint( msg.sender, num );
    }
    

    // Public mint
    function mintPublic(uint256 num) external payable {
        uint256 supply = totalSupply();
        require( !pausedAll,                     "Sale paused" );
        require( !pausedPublicMint,              "Public sale paused" );
        require( supply + num < maxSupply - numReservedForGiveAways - numReservedForClbs, "Exceeds maximum NFTs supply" );
        require( msg.value == publicPrice * num, "Ether sent is not correct" );
        _safeMint( msg.sender, num );
    }


    // Contract owner pays gas fee and awards the `recipient` `num` NFT(s).
    function giveAway(address recipient, uint256 num) external onlyOwner {
        require( num <= numReservedForGiveAways, "Exceeds reserved giveaway supply" );
        numReservedForGiveAways -= num;
        _safeMint( recipient, num );
    }


    /**
     * SETTERS FOR
     * CLB BURN TO MINT 
     */ 

    function setClbPrice(uint256 priceInWei) external onlyOwner {
        clbPrice = priceInWei;
    }

    function setPausedClbMint(bool val) external onlyOwner {
        pausedClbMint = val;
    }

    function setNumReservedForClbs(uint256 count) external onlyOwner {
        numReservedForClbs = count;
    }


    /**
     * SETTERS FOR
     * WHITELIST1 MINT
     */ 

    function setWhitelistPrice1(uint256 priceInWei) external onlyOwner {
        whitelistPrice1 = priceInWei;
    }    

    function setMaxWhitelistMintPerWallet1(uint256 count) external onlyOwner {
        maxWhitelistMintPerWallet1 = count;
    }

    function setWhitelistMerkleRoot1(bytes32 root) external onlyOwner {
        whitelistMerkleRoot1 = root;
    }

    function setPausedWhitelistMint1(bool val) external onlyOwner {
        pausedWhitelistMint1 = val;
    }

    function setNumAllowedForWhitelis1(uint256 count) external onlyOwner {
        numAllowedForWhitelist1 = count;
    }


    /**
     * SETTERS FOR
     * WHITELIST2 MINT
     */ 

    function setWhitelistPrice2(uint256 priceInWei) external onlyOwner {
        whitelistPrice2 = priceInWei;
    }    

    function setMaxWhitelistMintPerWallet2(uint256 count) external onlyOwner {
        maxWhitelistMintPerWallet2 = count;
    }

    function setWhitelistMerkleRoot2(bytes32 root) external onlyOwner {
        whitelistMerkleRoot2 = root;
    }

    function setPausedWhitelistMint2(bool val) external onlyOwner {
        pausedWhitelistMint2 = val;
    }

    function setNumAllowedForWhitelist2(uint256 count) external onlyOwner {
        numAllowedForWhitelist2 = count;
    }


    /**
     * SETTERS FOR
     * PUBLIC MINT
     */ 

    function setPublicPrice(uint256 priceInWei) external onlyOwner {
        publicPrice = priceInWei;
    }

    function setPausedPublicMint(bool val) external onlyOwner {
        pausedPublicMint = val;
    }


    /**
     * SETTERS FOR
     * GIVEAWAY
     */ 

    function setNumReservedForGiveAways(uint256 val) external onlyOwner {
        numReservedForGiveAways = val;
    }


    /**
     * MISC GETTERS AND SETTERS
     */ 

    function setPausedAll(bool val) external onlyOwner {
        pausedAll = val;
    }

    function setMaxSupply(uint256 val) external onlyOwner {
        maxSupply = val;
    }

    function getNumReservedForClbs() external view returns (uint256) {
        return numReservedForClbs;
    }

    struct Settings {
        bool pausedAll;

        uint256 clbPrice;
        bool pausedClbMint;

        uint256 whitelistPrice1;
        uint256 maxWhitelistMintPerWallet1;
        bool pausedWhitelistMint1;
        uint256 numAllowedForWhitelist1;
        uint256 whitelistClaimCount1ForUser;

        uint256 whitelistPrice2;
        uint256 maxWhitelistMintPerWallet2;
        bool pausedWhitelistMint2;
        uint256 numAllowedForWhitelist2;
        uint256 whitelistClaimCount2ForUser;

        uint256 publicPrice;
        bool pausedPublicMint;
    }

    function getSettings() external view returns (Settings memory) {
        Settings memory settings = Settings(
            pausedAll,

            clbPrice,
            pausedClbMint,

            whitelistPrice1,
            maxWhitelistMintPerWallet1,
            pausedWhitelistMint1,
            numAllowedForWhitelist1,
            whitelistClaimCount1[msg.sender], // user specific!

            whitelistPrice2,
            maxWhitelistMintPerWallet2,
            pausedWhitelistMint2,
            numAllowedForWhitelist2,
            whitelistClaimCount2[msg.sender], // user specific!

            publicPrice,
            pausedPublicMint
        );
        return settings;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Include trailing slash in uri
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 all = address(this).balance;
        require(payable(ownerAddr).send(all));
    }

    /********************
     *  OPERATOR FILTER
     ********************/
   
    function setApprovalForAll(address operator, bool approved) public override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable 
        override(ERC721A,IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /************
     *  IERC165
     ************/
    
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /*************
     *  IERC2981
     *************/

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     * - `feeNumerator` defaults to basis points e.g. 500 is 5%
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }


}