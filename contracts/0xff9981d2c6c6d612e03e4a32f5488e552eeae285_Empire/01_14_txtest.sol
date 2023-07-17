// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**


 */

contract Empire is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    mapping(address => uint256) public numberOfWLMintsOnAddress;
    mapping(address => uint256) public numberOfOGMintsOnAddress;
    mapping(address => uint256) public totalClaimed;
    mapping(address => uint256) public airdropList;

    //Sale flags
    bool public OGsaleActive = false;
    bool public WLsaleActive = false;
    bool public saleActive = false;

    //Mint limits
    uint256 public ADDRESS_MAX_MINTS = 12;
    uint256 public ADDRESS_OG_MAX_MINTS = 3;
    uint256 public ADDRESS_WL_MAX_MINTS = 3;
    uint256 public PUBLIC_MINT_PER_TX = 12;

    //Supply
    uint256 public maxSupply= 11111; 

    //Pricing
    uint256 public OGprice = 0.12 ether;
    uint256 public WLprice = 0.15 ether;
    uint256 public price = 0.18 ether;

    //Pre-reveal IPFS link
    string private _baseTokenURI = ""; 

    //Merkle roots
    bytes32 public OGMerkleRoot =
        0x6d12278b2d68e55f9c61119f2018ce4f288f75af823d843681dd21849042fd55;
    bytes32 public WLMerkleRoot =
        0xe00e8ad387d9334d504c18dc3372436de4508944554c9531eabccfdaa186ce57;
  	bytes32 private freeMint; 

    //Payable addresses
    address private constant AA_ADDRESS =
        0xaBffc43Bafd9c811a351e7051feD9d8be2ad082f;
   
    event Claimed(uint256 count, address sender);
    event FreeMintActive(bool live);
    event ClaimAirdrop(uint256 count, address sender);
    event Airdrop(uint256 count, address sender);

       constructor() ERC721A("TRIBE-X-ACT-1", "TRIBEX") {}

    /**
     * OG mint
     */
    function mintOGSale(uint256 numberOfMints, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(OGsaleActive, "Family presale must be active to mint");

        require(
            MerkleProof.verify(
                _merkleProof,
                OGMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Invalid Family proof - Caller not on family whitelisted"
        );

        require(numberOfMints > 0, "Sender is trying to mint zero token"); 

        require(
            numberMinted(msg.sender) + numberOfMints <= ADDRESS_MAX_MINTS,
            "You are trying to mint more than allocated tokens"
        ); 

        require(
            numberOfOGMintsOnAddress[msg.sender] + numberOfMints <=
                ADDRESS_OG_MAX_MINTS,
            "You are trying to mint more than their whitelist amount"
        );
        require(
            totalSupply() + numberOfMints <= maxSupply,
            "This would exceed the max number of mints allowed"
        ); 
        require(
            msg.value >= numberOfMints * OGprice,
            "Not enough ether to mint, please add more eth to your wallet"
        );

        numberOfOGMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);
    }

    /**
     * Whitelist mint
     */
    function mintWLSale(uint256 numberOfMints, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(WLsaleActive, "Sale must be active before you can mint");

        require(
            MerkleProof.verify(
                _merkleProof,
                WLMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Invalid Merkle proof - Caller not whitelisted"
        );

        require(numberOfMints > 0, "Sender is trying to mint zero, please mint 1 or more");
        require(
            numberMinted(msg.sender) + numberOfMints <= ADDRESS_MAX_MINTS,
            "Sender is trying to mint more than allocated tokens"
        );
        require(
            numberOfWLMintsOnAddress[msg.sender] + numberOfMints <=
                ADDRESS_WL_MAX_MINTS,
            "Sender is trying to mint more than their whitelist amount"
        );
        require(
            totalSupply() + numberOfMints <= maxSupply,
            "Mint would exceed max supply of mints"
        );
        require(
            msg.value >= numberOfMints * WLprice,
            "Amount of ether is not enough to mint, please send more eth based on price"
        );

        numberOfWLMintsOnAddress[msg.sender] += numberOfMints;
        _safeMint(msg.sender, numberOfMints);
    }

    /**
     * Public mint
     */
    function mint(uint256 numberOfMints) external payable {
        require(saleActive, "Public sale must be active to mint");
        require(numberOfMints > 0, "Sender is trying to mint zero");
        require(
            numberOfMints <= PUBLIC_MINT_PER_TX,
            "Sender is trying to mint too many in a single transaction, please reduce qty"
        );
        require(
            numberMinted(msg.sender) + numberOfMints <= ADDRESS_MAX_MINTS,
            "Sender is trying to mint more than allocated tokens"
        );
        require(
            totalSupply() + numberOfMints <= maxSupply,
            "Mint would exceed max supply of mints"
        );
        require(
            msg.value >= numberOfMints * price,
            "Amount of ether is not enough, please add more eth"
        );

        _safeMint(msg.sender, numberOfMints);
    }

    /**
     * Reserve mint for founders
     */

    function reserveMint(uint256 quantity, address _recipient)
        external
        onlyOwner
    {
        require(quantity > 0, "Need to mint more than 0");

        _safeMint(_recipient, quantity);
    }

    function airdropMint(uint256 quantity, address _recipient)
        external
        onlyOwner
    {
        require(quantity > 0, "Need to mint more than 0");

        _safeMint(_recipient, quantity);
    }

    //SETTERS FOR SALE PHASES
    function setOnlyOG() public onlyOwner {
        OGsaleActive = true;
        WLsaleActive = false;
        saleActive = false;
    }

    function setOnlyWhitelisted() public onlyOwner {
        OGsaleActive = false;
        WLsaleActive = true;
        saleActive = false;
    }

    function setOnlyPublicSale() public onlyOwner {
        OGsaleActive = false;
        WLsaleActive = false;
        saleActive = true;
    }

    function toggleSaleOff() external onlyOwner {
        OGsaleActive = false;
        WLsaleActive = false;
        saleActive = false;
    }

    function toggleAllsaleOn() external onlyOwner {
        OGsaleActive = true;
        WLsaleActive = true;
        saleActive = true;
    }

    function setOGMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        OGMerkleRoot = newMerkleRoot;
    }

    function setWLMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        WLMerkleRoot = newMerkleRoot;
    }

    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No balance to withdraw");
        uint256 contractBalance = address(this).balance;

        _withdraw(AA_ADDRESS, (contractBalance * 100) / 100);
   
    
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Withdrawl Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function tokenIdOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = totalSupply();

        uint256[] memory tokensId = new uint256[](tokenCount);
        uint256 arrayIndex;
        for (uint256 i; i < tokenCount; i++) {
            TokenOwnership memory owner = _ownershipOf(i);
            if (owner.addr == _owner) {
                tokensId[arrayIndex] = i;
                arrayIndex++;
            }
        }
        return tokensId;
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // withdraw all funds to owners address
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //change the supply limit
    function changeSupplyLimit(uint256 _new) external onlyOwner {
        maxSupply = _new;
    }

    //set public mint price
    function setOGprice(uint256 _new) external onlyOwner {
        OGprice = _new;
    }

    function setWLprice(uint256 _new) external onlyOwner {
        WLprice = _new;
    }

    function setMintPrice(uint256 _new) external onlyOwner {
        price = _new;
    }

    function setMaxAddress(uint256 _new) external onlyOwner {
        ADDRESS_MAX_MINTS = _new;
    }

    function setOGMax(uint256 _new) external onlyOwner {
        ADDRESS_OG_MAX_MINTS = _new;
    }

    function setWLMax(uint256 _new) external onlyOwner {
        ADDRESS_WL_MAX_MINTS = _new;
    }

    function setPublicMax(uint256 _new) external onlyOwner {
        PUBLIC_MINT_PER_TX = _new;
    }
}