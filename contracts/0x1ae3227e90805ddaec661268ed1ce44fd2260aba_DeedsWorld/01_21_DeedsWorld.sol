// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol';
import "./INumberSupply.sol";
import "./ISlave.sol";


contract DeedsWorld is ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ISlave {
    using StringsUpgradeable for uint256;
    uint256 public constant MAX_MINTS = 10;
    uint256 public startPrice;
    uint256 public priceRate;
    uint256 public totalMintedTerritories;
    uint256 public rate;
    uint256 public expiration;
    uint256 public startingBlock;
    bytes32 public deedsMerkleRoot;
    bytes32 public mintMerkleRoot;
    address public numberSupplyAddress;
    address public masterAddress;
    address public stardustTokenAddress;
    address public artistAddress;
    bool public saleActive;
    bool public presaleActive;
    bool public gameStarted;
    mapping(address => uint256) public usedPreMints;
    mapping(uint256 => uint256) public countryPoints;
    mapping(address => mapping(uint256 => uint256)) public lastRewardBlocks;
    mapping(address => uint256) public collectedRewards;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function initialize(address _masterAddress, address _stardustTokenAddress) initializer public {
        masterAddress = _masterAddress;
        stardustTokenAddress = _stardustTokenAddress;
        rate = 135e12;
        priceRate = 0.02 ether;
        __ERC1155_init("https://deedsworld.com/jsons/{id}.json");
        __Ownable_init();
        __UUPSUpgradeable_init();

    }
    modifier onlyMaster(){
        require(masterAddress == _msgSender(), "Caller is not the master");
        _;
    }
    function getPrice() public view returns (uint256){
        return startPrice + priceRate * (totalMintedTerritories / 1000);
    }

    function mint(uint256 _nbTokens) external payable {
        require(saleActive, "Sale not active");
        require(msg.sender == tx.origin, "Can't mint through another contract");
        require(_nbTokens <= MAX_MINTS, "Exceeds max token purchase.");
        uint256 currentPrice = getPrice();
        require(_nbTokens * currentPrice <= msg.value, "Sent incorrect ETH value");
        uint256[] memory ids = new uint256[](_nbTokens);
        uint256[] memory amountArray = new uint256[](_nbTokens);
        for (uint256 i = 0; i < _nbTokens; i++) {
            ids[i] = INumberSupply(numberSupplyAddress).getNumber(totalMintedTerritories + i);
            amountArray[i] = 1;
        }
        _mintBatch(msg.sender, ids, amountArray, "");
        totalMintedTerritories += _nbTokens;

    }

    function masterMint(address mintTo, uint256 /*parentId*/, uint8 /*breedInfo*/) external onlyMaster {
        uint256 tokenId = INumberSupply(numberSupplyAddress).getNumber(totalMintedTerritories);
        _mint(mintTo, tokenId, 1, "");
        emit Transfer(address(0), mintTo, tokenId);
        totalMintedTerritories++;
    }

    function preMint(bytes32[] calldata _proof) external  {
        require(presaleActive, "Presale not active");
        require(msg.sender == tx.origin, "Can't mint through another contract");
        uint256 used = usedPreMints[msg.sender];
        require(used == 0, "Exceeds mint limit");
        //require(_nbTokens <= MAX_MINTS, "Exceeds max token purchase.");
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(_proof, mintMerkleRoot, node), "Not on allow list");
        //require(getPrice() * _nbTokens <= msg.value, "Sent incorrect ETH value");
        usedPreMints[msg.sender] = 1;

        uint256    id = INumberSupply(numberSupplyAddress).getNumber(totalMintedTerritories);

        _mint(msg.sender, id, 1, "");
        totalMintedTerritories ++;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {

    }


    function setDeedsMerkleRoot(bytes32 root) external onlyOwner {
        deedsMerkleRoot = root;
    }

    function setMintMerkleRoot(bytes32 root) external onlyOwner {
        mintMerkleRoot = root;
    }

    function setArtist(address _artistAddress) public onlyOwner {
        artistAddress = _artistAddress;
    }

    function setStardustTokenAddress(address _stardustTokenAddress) external onlyOwner {
        stardustTokenAddress = _stardustTokenAddress;
    }

    function setNumberSupplyAddress(address numberSupply) public onlyOwner {
        numberSupplyAddress = numberSupply;
    }

    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function setPriceRate(uint256 _priceRate) public onlyOwner {
        priceRate = _priceRate;
    }

    function putTogether(uint256[] calldata deedsIndices, bytes32[] calldata _proof) external {
        require(deedsIndices.length > 2, "To few indices");
        bytes32 node = keccak256(abi.encodePacked(deedsIndices));
        require(MerkleProofUpgradeable.verify(_proof, deedsMerkleRoot, node), "wrong collection of deeds ");
        uint256 length = deedsIndices.length;
        uint256[] memory amounts = new uint256[](length - 2);
        uint256 countryId = deedsIndices[length - 2];
        for (uint256 i = 0; i < length - 2; i++) {
            amounts[i] = 1;
        }
        _burnBatch(msg.sender, deedsIndices[0 : length - 2], amounts);
        if (countryPoints[countryId] == 0) {
            countryPoints[countryId] = deedsIndices[length - 1];
        }
        _mint(msg.sender, countryId, 1, "");
    }


    function checkMerkleProof(uint256[] calldata deedsIndices, bytes32[] calldata _proof) external view returns (bool){
        //require(deedsIndices.length > 2);
        bytes32 node = keccak256(abi.encodePacked(deedsIndices));
        bool verified = MerkleProofUpgradeable.verify(_proof, deedsMerkleRoot, node);
        return verified;
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
        if (presaleActive && saleActive) {
            saleActive = false;
        }
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
        if (saleActive && presaleActive) {
            presaleActive = false;
        }
    }

    function startGame() external onlyOwner {
        gameStarted = true;
        startingBlock = block.number;
        expiration = block.number + 4851693;
    }

    function setStartPrice(uint256 _startPrice) external onlyOwner {
        startPrice = _startPrice;
    }


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 split = balance / 10;
        require(artistAddress != address(0), "Set an artist address!");
        require(payable(owner()).send(split), "owner not payable");
        require(payable(artistAddress).send(balance - split), "artist not payable");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function getCurrentRewards(address deedOwner, uint256[] memory ids) internal returns (uint256){
        uint256 blockCur = MathUpgradeable.min(block.number, expiration);
        uint256 reward;
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] > 2000) {
                uint256 b = balanceOf(deedOwner, ids[i]);
                reward += b * calculateRewardForToken(deedOwner, ids[i]);
                lastRewardBlocks[deedOwner][ids[i]] = blockCur;
            }
        }
        return reward;
        //if (reward > 0) {
        // collectedRewards[deedOwner] += reward;

    }

    function claimRewards(uint256[] calldata ids) public
    {
        require(gameStarted, "Game not started");
        //getCurrentRewards(msg.sender, ids);
        IERC20(stardustTokenAddress).transfer(msg.sender, collectedRewards[msg.sender] + getCurrentRewards(msg.sender, ids));
        if (collectedRewards[msg.sender] != 0) collectedRewards[msg.sender] = 0;
    }

    function calculateRewardForToken(address tokenOwner, uint256 tokenId) public view returns (uint256){
        return (MathUpgradeable.min(block.number, expiration) - MathUpgradeable.max(lastRewardBlocks[tokenOwner][tokenId], startingBlock)) * getRateForToken(tokenId);
    }

    function getRateForToken(uint256 tokenId) public view returns (uint256){
        return countryPoints[tokenId] * rate;
    }

    function _beforeTokenTransfer(
        address /*operator*/,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) internal override(ERC1155Upgradeable) {

        if (gameStarted) {
            if (from != address(0)) {
                uint rewards = getCurrentRewards(from, ids);
                if (rewards > 0) {
                    collectedRewards[from] += rewards;
                }
            }
            if (to != address(0)) {
                uint256 rewards = getCurrentRewards(to, ids);
                if (rewards > 0) {
                    collectedRewards[to] += rewards;
                }
            }

        }
    }

}