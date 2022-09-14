//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
    This is a dedicated contract written exclusievly for Pelicanos collection, which contain two phases.
    More info at: https://www.pelicanos.club
*/
contract PelikanNFT is ERC721A, Ownable, ReentrancyGuard {
    
    uint256 public constant MAX_SUPPLY = 7000;

    enum Sales { PRIVATE, FIRST_PHASE_PRESALE, FIRST_PHASE_PUBLIC, SECOND_PHASE_PRESALE, SECOND_PHASE_PUBLIC } 
    Sales public currentSale;

    string public baseExtension = ".json";
    string public baseURI = ""; // ipfs://ID/

    address public withdrawAddress;


    /*
        Private phase settings
    */ 

    uint256 public privateAvailablePool = 500;
   
    bytes32 public privateMerkleRoot = "";


    /*
        First phase settings
    */

    uint256 public firstPhasePreSaleMintRate = 0.2 ether;
    uint256 public firstPhasePublicMintRate = 0.3 ether;

    uint256 public firstPhaseMaxPreSaleMints = 15;

    uint256 public firstPhasePreSaleAvailablePool = 500;
    uint256 public firstPhasePublicAvailablePool = 1000;

    bytes32 public firstPhasePreSaleMerkleRoot = "";

    bool public firstPhaseRevealed = false;

    mapping(address => uint256) private firstPhaseWalletMintedInPreSale;
    mapping(address => uint256) private firstPhaseWalletMintedInPublicSale;


    /*
        Second phase settings
    */

    uint256 public secondPhasePreSaleMintRate = 0.32 ether;
    uint256 public secondPhasePublicMintRate = 0.35 ether;

    uint256 public secondPhaseMaxPreSaleMints = 15;

    uint256 public secondPhasePreSaleAvailablePool = 3500;
    uint256 public secondPhasePublicAvailablePool = 1500;

    bytes32 public secondPhasePreSaleMerkleRoot = "";

    bool public secondPhaseRevealed = false;

    mapping(address => uint256) private secondPhaseWalletMintedInPreSale;
    mapping(address => uint256) private secondPhaseWalletMintedInPublicSale;

   
    constructor(
        address baseWithdrawAddress,
        string memory initialNotRevealedURL
    ) ERC721A("Pelicanos", "PLCN") {
        require(
            baseWithdrawAddress != address(0),
            "Cannot withdraw to the burn address"
        );

        withdrawAddress = baseWithdrawAddress;
        baseURI = initialNotRevealedURL;
        currentSale = Sales.PRIVATE;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /*
        We track addresses and tokens on them
    */
    function mintedInFirstPhasePreSale() external view returns (uint256) {
        return firstPhaseWalletMintedInPreSale[msg.sender];
    }

    function mintedInFirstPhasePublicSale() external view returns (uint256) {
        return firstPhaseWalletMintedInPublicSale[msg.sender];
    }

     function mintedInSecondPhasePreSale() external view returns (uint256) {
        return secondPhaseWalletMintedInPreSale[msg.sender];
    }

    function mintedInSecondPhasePublicSale() external view returns (uint256) {
        return secondPhaseWalletMintedInPublicSale[msg.sender];
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), baseExtension));
    }


    function setWithdrawAddress(address payable newAddress) external onlyOwner {
        require(newAddress != address(0), "Cannot set zero address");
        withdrawAddress = newAddress;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    /*
        Reveal methods where we are setting new IPFS url
    */

    function revalFirstPhase(string memory _newBaseURI) external onlyOwner {
        firstPhaseRevealed = true;
        baseURI = _newBaseURI;
    }

     function revalSecondPhase(string memory _newBaseURI) external onlyOwner {
        secondPhaseRevealed = true;
        baseURI = _newBaseURI;
    }


    /*
        Max mints per wallet in both phases (both persale, because we don`t have any limit on public sales)
    */

    function setMaxFirstPhasePreSaleMintsPerWallet(uint256 maxMints) external onlyOwner {
        firstPhaseMaxPreSaleMints = maxMints;
    }

     function setMaxSecondPhasePreSaleMintsPerWallet(uint256 maxMints) external onlyOwner {
        secondPhaseMaxPreSaleMints = maxMints;
    }




    /*
        Merkle tree roots for private, first phase presale and second phase presale
    */

    function setPrivateMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        privateMerkleRoot = merkleRoot;
    }

    function setFirstPhasePreSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        firstPhasePreSaleMerkleRoot = merkleRoot;
    }

    function setSecondPhasePreSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        secondPhasePreSaleMerkleRoot = merkleRoot;
    }

    
    
    /*
        This is the place where can switch between sales, but only by going up. 
        It`s a guarantee that we won't be able to switch to old sales.
    */
    function togglePrivate() external onlyOwner {
       currentSale = Sales.PRIVATE;
    }

    function enableFirstPhasePresale() external onlyOwner {
       currentSale = Sales.FIRST_PHASE_PRESALE;
    }

    function enableFirstPhasePublicSale() external onlyOwner {
        firstPhasePublicAvailablePool = firstPhasePublicAvailablePool + firstPhasePreSaleAvailablePool;
        firstPhasePreSaleAvailablePool = 0;
        currentSale = Sales.FIRST_PHASE_PUBLIC;
    }

     function enableSecondPhasePresale() external onlyOwner {
        secondPhasePreSaleAvailablePool = secondPhasePreSaleAvailablePool + firstPhasePublicAvailablePool;
        firstPhasePublicAvailablePool = 0;
        currentSale = Sales.SECOND_PHASE_PRESALE;
    }

    function enableSecondPhasePublicSale() external onlyOwner {
        secondPhasePublicAvailablePool = secondPhasePublicAvailablePool + secondPhasePreSaleAvailablePool;
        secondPhasePreSaleAvailablePool = 0;
        currentSale = Sales.SECOND_PHASE_PUBLIC;
    }


    /*
        Withdraws methods
    */

    function withdrawAll() public payable onlyOwner {
        Address.sendValue(payable(withdrawAddress), address(this).balance);
    }

     function withdrawSpecifedAmount(uint256 amount) public payable onlyOwner {
         Address.sendValue(payable(withdrawAddress), amount);
    }


    /*
        Modifiers
    */
    modifier isValidPrice(uint256 mintRate, uint256 quantity) {
        require(msg.value == mintRate * quantity, "Wrong ether value");
        _;
    }

    modifier isTotalSupplyExceed(uint256 quantity) {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough tokens left in maxSupply"
        );
        _;
    }

    modifier isValidSale(Sales sale) {
        require(currentSale == sale, "Given sale is not active");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof, bytes32 merkleRoot) {
        require(
            MerkleProof.verify(
                _proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Invalid proof"
        );
        _;
    }
 
    modifier isEnoughTokensInSalePool(uint256 quantity, uint256 pool) {
        require(quantity <= pool, "Available pool exceeded");
        _;
    }

    modifier isPersonalMintLimitPerSaleExceed(uint256 quantity) {
        if (currentSale == Sales.FIRST_PHASE_PRESALE) {
            require(
                firstPhaseWalletMintedInPreSale[msg.sender] + quantity <= firstPhaseMaxPreSaleMints,
                "Wallet mint limit in first phase presale has been exceeded"
            );
        }

    
        if (currentSale == Sales.SECOND_PHASE_PRESALE) {
            require(
                secondPhaseWalletMintedInPreSale[msg.sender] + quantity <= secondPhaseMaxPreSaleMints,
                "Wallet mint limit in second wave sale has been exceeded"
            );
        }

       _;
    }


    /*
        First phase mints/airdrops
    */

    function mintPrivate(uint256 quantity, bytes32[] calldata _proof)
        external
        payable
        nonReentrant
        isValidSale(Sales.PRIVATE)
        isValidMerkleProof(_proof, privateMerkleRoot)
        isTotalSupplyExceed(quantity)
        isEnoughTokensInSalePool(quantity, privateAvailablePool)
    {
        privateAvailablePool = privateAvailablePool - quantity;
        _safeMint(msg.sender, quantity);
    }

    function firstPhaseAirdrop(address airdropAddress, uint256 quantity)
        external
        onlyOwner
        isEnoughTokensInSalePool(quantity, firstPhasePublicAvailablePool)
        isTotalSupplyExceed(quantity)
    {
        firstPhasePublicAvailablePool = firstPhasePublicAvailablePool - quantity;
        firstPhaseWalletMintedInPublicSale[airdropAddress] += quantity;
        _safeMint(airdropAddress, quantity);
    }

    function mintFirstPhasePreSale(uint256 quantity, bytes32[] calldata _proof)
        external
        payable
        nonReentrant
        isValidSale(Sales.FIRST_PHASE_PRESALE)
        isValidMerkleProof(_proof, firstPhasePreSaleMerkleRoot)
        isValidPrice(firstPhasePreSaleMintRate, quantity)
        isTotalSupplyExceed(quantity)
        isEnoughTokensInSalePool(quantity, firstPhasePreSaleAvailablePool)
        isPersonalMintLimitPerSaleExceed(quantity)
    {
        firstPhasePreSaleAvailablePool = firstPhasePreSaleAvailablePool - quantity;
        firstPhaseWalletMintedInPreSale[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

     function mintFirstPhasePublicSale(uint256 quantity)
        external
        payable
        nonReentrant
        isValidSale(Sales.FIRST_PHASE_PUBLIC)
        isValidPrice(firstPhasePublicMintRate, quantity)
        isTotalSupplyExceed(quantity)
        isEnoughTokensInSalePool(quantity, firstPhasePublicAvailablePool)
    {
        firstPhasePublicAvailablePool = firstPhasePublicAvailablePool - quantity;
        firstPhaseWalletMintedInPublicSale[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }


    /*
        Second phase mints/airdrops
    */

    function secondPhaseAirdrop(address airdropAddress, uint256 quantity)
        external
        onlyOwner
        isEnoughTokensInSalePool(quantity, secondPhasePublicAvailablePool)
        isTotalSupplyExceed(quantity)
    {
        secondPhasePublicAvailablePool = secondPhasePublicAvailablePool - quantity;
        secondPhaseWalletMintedInPublicSale[airdropAddress] += quantity;
        _safeMint(airdropAddress, quantity);
    }

    function mintSecondPhasePreSale(uint256 quantity, bytes32[] calldata _proof)
        external
        payable
        nonReentrant
        isValidSale(Sales.SECOND_PHASE_PRESALE)
        isValidMerkleProof(_proof, secondPhasePreSaleMerkleRoot)
        isValidPrice(secondPhasePreSaleMintRate, quantity)
        isTotalSupplyExceed(quantity)
        isEnoughTokensInSalePool(quantity, secondPhasePreSaleAvailablePool)
        isPersonalMintLimitPerSaleExceed(quantity)
    {
        secondPhasePreSaleAvailablePool = secondPhasePreSaleAvailablePool - quantity;
        secondPhaseWalletMintedInPreSale[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

     function mintSecondPhasePublicSale(uint256 quantity)
        external
        payable
        nonReentrant
        isValidSale(Sales.SECOND_PHASE_PUBLIC)
        isValidPrice(secondPhasePublicMintRate, quantity)
        isTotalSupplyExceed(quantity)
        isEnoughTokensInSalePool(quantity, secondPhasePublicAvailablePool)
    {
        secondPhasePublicAvailablePool = secondPhasePublicAvailablePool - quantity;
        secondPhaseWalletMintedInPublicSale[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

   
}