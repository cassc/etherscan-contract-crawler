// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

interface ISuperBearScores {
    function getBearScore(uint256 tokenId) external view returns (uint256 score);
    function getBearBoost(uint256[] calldata tokenIds) external view returns (uint256 score);
}


contract SuperBearClub is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum Stage { NotOpen, PreSale, PublicSale }

    uint256 public maxBears;

    bytes32 public whitelistRoot;
    bytes32 public banagerRoot;
    bytes32 public ogRoot;
    bytes32 public teamRoot;

    mapping(address => bool) private preSaleMinted;

    uint64 public whitelistMintCounts;
    uint64 public banagerMintCounts;
    uint64 public ogMintCounts;
    uint64 public teamMintCounts;
    uint64 public giftedMintCounts;

    uint256 constant WHITELIST_INDEX = 0;
    uint256 constant BANAGER_INDEX = 1;
    uint256 constant OG_INDEX = 2;
    uint256 constant TEAM_INDEX = 3;
    
    uint256 public constant WL_MINT_MAX_PER_WALLET = 2;
    uint256 public constant BANAGER_MINT_MAX_PER_WALLET = 3;
    uint256 public constant OG_MINT_MAX_PER_WALLET = 5;
    uint256 public constant TE_MINT_MAX_PER_WALLET = 10;
    uint256 public constant PUBLIC_SALE_PRICE = 0.03 ether;

    bool public isWlActive;
    bool public isBanagerActive;
    bool public isOGActive;
    bool public isTeamActive;
    bool public isPublicSaleActive;
    
    string private baseTokenURI = "ipfs://QmaVqj5sX15acwcjiT32SjLToMUeYKKpoAvheBHeQt84YE/";

    address public scoresContractAddress;
    address public stakeAddress;

    address public vaultAddress;

    bool private isOpenSeaProxyActive = true;
    address proxyRegistryAddress;

    event BearMinted(address account, uint256 startTokenId,uint256 amount);
    event BearBurned(address account, uint256 tokenId);

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============
    modifier isNotContract() {
        require(tx.origin == msg.sender,"contract is not allowed to operate");
        _;
    }

    modifier preSaleActive(){
        require(!isPublicSaleActive && (isWlActive || isBanagerActive || isOGActive || isTeamActive),"Presale is not open");
        _;
    }

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier canMintBearsGlobal(uint256 numberOfTokens) {
        require(numberOfTokens > 0,"Mint count must be greater than 0");
        require(
            _currentIndex + numberOfTokens <=
                maxBears,
            "Not enough bears remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _openSeaProxyRegistryAddress,
        uint256 _maxBears
        ) ERC721A(name, symbol) {
        proxyRegistryAddress = _openSeaProxyRegistryAddress;
        maxBears = _maxBears;
        vaultAddress = owner();
        isTeamActive = true;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setWhiteListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistRoot = merkleRoot;
    }

    function setBanagerMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        banagerRoot = merkleRoot;
    }

    function setOGMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        ogRoot = merkleRoot;
    }

    function setTeamMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        teamRoot = merkleRoot;
    }

    function setAllMerkleRoot(bytes32[4] calldata merkleRoots) external onlyOwner {
        whitelistRoot = merkleRoots[WHITELIST_INDEX];
        banagerRoot = merkleRoots[BANAGER_INDEX];
        ogRoot = merkleRoots[OG_INDEX];
        teamRoot = merkleRoots[TEAM_INDEX];
    }

    function setWhiteListSaleActive(bool isActive) external onlyOwner{
        require(whitelistRoot != 0,"whitelist root not assigned");
        isWlActive = isActive;
    }

    function setBanagerSaleActive(bool isActive) external onlyOwner{
        require(banagerRoot != 0,"banager root not assigned");
        isBanagerActive = isActive;
    }

    function setOGSaleActive(bool isActive) external onlyOwner{
        require(ogRoot != 0,"OG root not assigned");
        isOGActive = isActive;
    }

    function setTeamSaleActive(bool isActive) external onlyOwner{
        require(teamRoot != 0,"team root not assigned");
        isTeamActive = isActive;
    }

    function setPublicSaleActive(bool isActive) external onlyOwner{
        isPublicSaleActive = isActive;
    }

    function setScoresContractAddress(address _scoresAddress) external onlyOwner {
        scoresContractAddress = _scoresAddress;
    }

    function setStakeAddress(address _stakeAddress) external onlyOwner {
        stakeAddress = _stakeAddress;
    }

    function setVaultAddress(address _vaultAddress) external onlyOwner {
        vaultAddress = _vaultAddress;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getBearScore(uint256 tokenId) public view returns (uint256 score) {
      if (scoresContractAddress == address(0x0)) {
        return 0;
      }

      require(_exists(tokenId), "ERC721: owner query for nonexistent token");

      return ISuperBearScores(scoresContractAddress).getBearScore(tokenId);
    }

    function getBearBoost(uint256[] calldata tokenIds) public view returns (uint256 score) {
      if (scoresContractAddress == address(0x0)) {
        return 10000;
      }
      return ISuperBearScores(scoresContractAddress).getBearBoost(tokenIds);
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function getCurrentStage() public view returns (Stage){
        Stage curStage;
        if(isPublicSaleActive){
            curStage = Stage.PublicSale;
        }else if(isWlActive || isBanagerActive || isOGActive || isTeamActive){
            curStage = Stage.PreSale;
        }else{
            curStage = Stage.NotOpen;
        }
        
        return curStage;
    }

    function getLeftBearCount() public view returns(uint256){
        uint256 numMintedSoFar = _currentIndex;
        return maxBears - numMintedSoFar;
    }

    function getCanFreeMintCount(bytes32[][4] calldata merkleProofs) public view returns (uint256 )
    {
        require(merkleProofs.length == 4, "Not right length");
        uint256[] memory counts = new uint256[](4);
        int256 power = -1;
        if(merkleProofs[WHITELIST_INDEX].length != 0){
            require(whitelistRoot != 0,"whitelist root not assigned");
            require(MerkleProof.verify(merkleProofs[WHITELIST_INDEX],whitelistRoot,keccak256(abi.encodePacked(msg.sender))),"MerkleProof: Invalid whitelist proof.");
            power = int256(WHITELIST_INDEX);
            if(isWlActive && !preSaleMinted[msg.sender]){
                counts[WHITELIST_INDEX] = WL_MINT_MAX_PER_WALLET;
            }
        }

        if(merkleProofs[BANAGER_INDEX].length != 0){
            require(banagerRoot != 0,"banager root not assigned");
            require(MerkleProof.verify(merkleProofs[BANAGER_INDEX],banagerRoot,keccak256(abi.encodePacked(msg.sender))),"MerkleProof: Invalid banager proof.");
            power = int256(BANAGER_INDEX);
            if(isBanagerActive && !preSaleMinted[msg.sender]){
                counts[BANAGER_INDEX] = BANAGER_MINT_MAX_PER_WALLET;
            }
        }

        if(merkleProofs[OG_INDEX].length != 0){
            require(ogRoot != 0,"og root not assigned");
            require(MerkleProof.verify(merkleProofs[OG_INDEX],ogRoot,keccak256(abi.encodePacked(msg.sender))),"MerkleProof: Invalid og proof.");
            power = int256(OG_INDEX);
            if(isOGActive && !preSaleMinted[msg.sender]){
                counts[OG_INDEX] = OG_MINT_MAX_PER_WALLET;
            }
        }

        if(merkleProofs[TEAM_INDEX].length != 0){
            require(teamRoot != 0,"team root not assigned");
            require(MerkleProof.verify(merkleProofs[TEAM_INDEX],teamRoot,keccak256(abi.encodePacked(msg.sender))),"MerkleProof: Invalid team proof.");
            power = int256(TEAM_INDEX);
            if(isTeamActive && !preSaleMinted[msg.sender]){
                counts[TEAM_INDEX] = TE_MINT_MAX_PER_WALLET;
            }
        }

        uint256 count = 0;
        if(power != -1){
            count = counts[uint256(power)];
        }
        return count;
    }

    function mintNFTPresale(uint256 amount,bytes32[][4] calldata merkleProofs) 
    external
    nonReentrant
    isNotContract
    preSaleActive
    {
        require(merkleProofs.length == 4, "Not right merkleProofs length");
        uint256 count = getCanFreeMintCount(merkleProofs);
        require(amount == count,"Invalid amount");
        require(amount > 0,"Mint count must be greater than 0");
        require(_currentIndex + count <= maxBears,"Not enough bears remaining to mint");

        if(count == WL_MINT_MAX_PER_WALLET){
            preSaleMinted[msg.sender] = true;
            whitelistMintCounts += uint64(count);
        }else if(count == BANAGER_MINT_MAX_PER_WALLET){
            preSaleMinted[msg.sender] = true;
            banagerMintCounts += uint64(count);
        }else if(count == OG_MINT_MAX_PER_WALLET){
            preSaleMinted[msg.sender] = true;
            ogMintCounts += uint64(count);
        }else if(count == TE_MINT_MAX_PER_WALLET){
            preSaleMinted[msg.sender] = true;
            teamMintCounts += uint64(count);
        }

        _mintNFT(msg.sender,count);
    }

    function mintNFTPublicSale(uint256 amount)
    external
    payable
    nonReentrant
    isNotContract
    publicSaleActive
    canMintBearsGlobal(amount)
    isCorrectPayment(PUBLIC_SALE_PRICE, amount)
    {
        _mintNFT(msg.sender,amount);
    }

    function mintNFTGifted(address to, uint256 amount) 
    external
    nonReentrant
    onlyOwner
    canMintBearsGlobal(amount)
    {
        giftedMintCounts += uint64(amount);
        _mintNFT(to, amount);
    }

    function _mintNFT(address to, uint256 amount) internal {
        _safeMint(to, amount);
        emit BearMinted(msg.sender, _currentIndex, amount);
    }

    function burnNFT(uint256 tokenId) external {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        require(ownerOf(tokenId) == msg.sender, "not your token");
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        require(vaultAddress != address(0x0), "vault address is not set");
        payable(vaultAddress).transfer(address(this).balance);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress != address(0x0)) {
          ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
          if (isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
              return true;
          }
        }

        if (operator == stakeAddress) {
          return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    // should never be used inside of transaction because of gas fee
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 i = 0;
            uint256 numMintedSoFar = _currentIndex;
            while(i < numMintedSoFar){
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned || ownership.addr != owner) {
                    i++;
                }else{
                    TokenOwnership memory interShip = _ownerships[i];
                    while(!interShip.burned && (interShip.addr == owner || interShip.addr == address(0)) && resultIndex < tokenCount){
                        result[resultIndex] = i;
                        resultIndex++;
                        i++;
                        interShip = _ownerships[i];
                    }
                }
            }
            
            return result;
        }
    }
}