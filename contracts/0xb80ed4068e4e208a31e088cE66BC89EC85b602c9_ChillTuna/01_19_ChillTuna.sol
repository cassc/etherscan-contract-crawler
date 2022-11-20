/*

   _,.----.  ,--.-,,-,--, .=-.-.                           ,--.--------.              .-._         ,---.      
 .' .' -   \/==/  /|=|  |/==/_ / _.-.      _.-.           /==/,  -   , -\.--.-. .-.-./==/ \  .-._.--.'  \     
/==/  ,  ,-'|==|_ ||=|, |==|, |.-,.'|    .-,.'|           \==\.-.  - ,-./==/ -|/=/  ||==|, \/ /, |==\-/\ \    
|==|-   |  .|==| ,|/=| _|==|  |==|, |   |==|, |            `--`\==\- \  |==| ,||=| -||==|-  \|  |/==/-|_\ |   
|==|_   `-' \==|- `-' _ |==|- |==|- |   |==|- |                 \==\_ \ |==|- | =/  ||==| ,  | -|\==\,   - \  
|==|   _  , |==|  _     |==| ,|==|, |   |==|, |                 |==|- | |==|,  \/ - ||==| -   _ |/==/ -   ,|  
\==\.       /==|   .-. ,\==|- |==|- `-._|==|- `-._              |==|, | |==|-   ,   /|==|  /\ , /==/-  /\ - \ 
 `-.`.___.-'/==/, //=/  /==/. /==/ - , ,/==/ - , ,/             /==/ -/ /==/ , _  .' /==/, | |- \==\ _.\=\.-' 
            `--`-' `-`--`--`-``--`-----'`--`-----'              `--`--` `--`..---'   `--`./  `--``--`          
                                                                                     
*/
                                                                                     
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import {DefaultOperatorFiltererUpgradeable} from './operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol';

contract ChillTuna is ERC721AUpgradeable, ERC721AQueryableUpgradeable, DefaultOperatorFiltererUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;
    
    uint256 public constant MAX_SUPPLY = 5000;

    string public baseURI;
    uint256 public ogSupply;
    uint256 public wlSupply;

    uint256 public mintPrice;
    uint256 public wlMintPrice;
    uint256 public ogMintPrice;

    struct IsMintLive {
        bool og;
        bool koiplus;
        bool wl;
        bool pub;
    }

    struct MerkleTreeRoot {
        bytes32 og;
        bytes32 koiplus;
        bytes32 wl;
    }

    IsMintLive public isMintLive;
    uint256 public maxTxOg;
    uint256 public maxTxWl;
    uint256 public maxTxPub;

    MerkleTreeRoot private merkleTreeRoot;
    address private signerAddress;

    mapping(address => uint256) public ogMintBalance;
    mapping(address => uint256) public wlMintBalance;
    mapping(address => uint256) public mintBalance;
    
    function initialize(address _signer) initializerERC721A initializer public {
        __ERC721A_init('ChillTuna', 'CHILLTUNA');
        __Ownable_init();
        __DefaultOperatorFilterer_init();

        signerAddress = _signer;

        ogSupply = 777;
        wlSupply = 2500;

        ogMintPrice = 0.025 ether;
        wlMintPrice = 0.03 ether;
        mintPrice = 0.035 ether;
        
        maxTxOg = 1;
        maxTxWl = 2;
        maxTxPub = 2;
    }

    function mint(uint256 quantity, bytes32 hash, bytes calldata signature) external payable nonReentrant {
        require(isMintLive.pub, "Mint not live");
        require(quantity > 0, "Mint atleast 1");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds total supply");
        require(quantity <= maxTxPub, "Exceeds max per transaction");

        uint256 mintCount = mintBalance[_msgSender()];
        require(mintCount + quantity <= maxTxPub, "Exceeds max per wallet");
        require(msg.value >= mintPrice * quantity, "Not enough ETH");

        require(hash == keccak256(abi.encodePacked(msg.sender, "allow", address(this))), "Invalid hash");
        require(_verify(hash, signature), "Invalid data signature");

        _mint(_msgSender(), quantity);
        mintBalance[_msgSender()] += quantity;
    }

    function ogMint(uint256 quantity, bytes32[] memory _proof) external payable nonReentrant {
        require(isMintLive.og, "Mint not live");
        require(quantity > 0, "Mint atleast 1");
        require(totalSupply() + quantity <= ogSupply, "Exceeds OG supply");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds total supply");
        require(quantity <= maxTxOg, "Exceeds max per transaction");

        uint256 mintCount = ogMintBalance[_msgSender()];
        require(mintCount + quantity <= maxTxOg, "Exceeds max per wallet");
        require(msg.value >= ogMintPrice * quantity, "Not enough ETH");


        require(
            MerkleProofUpgradeable.verify(_proof, merkleTreeRoot.og, keccak256(abi.encodePacked(_msgSender()))),
            "Not eligible for OG mint."
        );

        _mint(_msgSender(), quantity);
        ogMintBalance[_msgSender()] += quantity;
    }

    function wlMint(uint256 quantity, bytes32[] memory _proof) external payable nonReentrant {
        require((isMintLive.koiplus || isMintLive.wl), "Mint not live");
        require(quantity > 0, "Mint atleast 1");
        require(totalSupply() + quantity <= wlSupply, "Exceeds WL supply");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds total supply");
        require(quantity <= maxTxWl, "Exceeds max per transaction");

        uint256 mintCount = wlMintBalance[_msgSender()];
        require(mintCount + quantity <= maxTxWl, "Exceeds max per wallet");
        require(msg.value >= wlMintPrice * quantity, "Not enough ETH");

        require(
            MerkleProofUpgradeable.verify(_proof, merkleTreeRoot.koiplus, keccak256(abi.encodePacked(_msgSender()))) || 
            MerkleProofUpgradeable.verify(_proof, merkleTreeRoot.wl, keccak256(abi.encodePacked(_msgSender()))),
            "Not eligible for whitelist mint."
        );

        _mint(_msgSender(), quantity);
        wlMintBalance[_msgSender()] += quantity;
    }

    function giveaway(address to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds total supply");
        _mint(to, quantity);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setOgMintPrice(uint256 _mintPrice) external onlyOwner {
        ogMintPrice = _mintPrice;
    }

    function setWlMintPrice(uint256 _mintPrice) external onlyOwner {
        wlMintPrice = _mintPrice;
    }

    function setIsMintLive(IsMintLive memory _isMintLive) external onlyOwner {
        isMintLive = _isMintLive;
    }

    function setOgSupply(uint256 _supply) external onlyOwner {
        ogSupply = _supply;
    }

    function setWlSupply(uint256 _supply) external onlyOwner {
        wlSupply = _supply;
    }

    function setMaxTxOg(uint256 _maxTx) external onlyOwner {
        maxTxOg = _maxTx;
    }

    function setMaxTxWl(uint256 _maxTx) external onlyOwner {
        maxTxWl = _maxTx;
    }

    function setMaxTxPub(uint256 _maxTx) external onlyOwner {
        maxTxPub = _maxTx;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleTreeRoot(MerkleTreeRoot memory _merkleTreeRoot) external onlyOwner {
        merkleTreeRoot = _merkleTreeRoot;
    }

    function updateSignerAddress(address _signer) external onlyOwner {
        signerAddress = _signer;
    }

    function _verify(bytes32 data, bytes memory signature) internal view returns (bool) {
        return data
            .toEthSignedMessageHash()
            .recover(signature) == signerAddress;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(0xE5BC04fB8B4cD138d39B76227E9DAD8785b95f45).call{value: address(this).balance}("");
        require(success, "Withdraw Failed");
    }
}