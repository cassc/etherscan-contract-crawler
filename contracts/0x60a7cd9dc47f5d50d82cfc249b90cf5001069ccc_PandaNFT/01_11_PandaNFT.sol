// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";

contract PandaNFT is ERC721A, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct SaleConfig {
        uint SupplyMaximum;
        uint MaximumMint;
        uint PublicSale;
        uint WhiteSale;
    }

    struct CustomConfig {
        bytes32 Root;
        uint StartSaleTime;
        string ContractURI;
        string BaseURI;
    }

    struct GameToken {
        address PandaToken;
        uint PreReward;
    }

    SaleConfig public saleConfig;
    CustomConfig public customConfig;
    GameToken public gameToken;

    // contract and token
    mapping(address => uint) userHasMint;

    constructor(string memory _name, string memory _symbol) ERC721A(_name, _symbol) {
        _tokenIds.increment();
    }

    // ============================= SALE ====================================

    function publicMint(uint8 times) external payable {
        require((_tokenIds.current() + times - 1) <= saleConfig.SupplyMaximum && (userHasMint[msg.sender] + times) <= saleConfig.MaximumMint, "OVERFLOW");
        require(block.timestamp >= customConfig.StartSaleTime, "NOT_START");
        require(msg.value >= saleConfig.PublicSale * times, "NOT_ENOUGH_ETH");

        _mint(msg.sender, times);

        userHasMint[msg.sender] += times;
        IERC20(gameToken.PandaToken).transfer(msg.sender, gameToken.PreReward * times);
    }

    function whiteMint(bytes32[] memory proof, uint times) external payable {
        require((_tokenIds.current() + times - 1) <= saleConfig.SupplyMaximum && (userHasMint[msg.sender] + times) <= 1, "OVERFLOW");
        require(block.timestamp >= customConfig.StartSaleTime, "ERR_NOT_START");
        require(msg.value >= saleConfig.WhiteSale * times, "NOT_ENOUGH_ETH");
        require(isWhiteLists(proof, keccak256(abi.encodePacked(msg.sender))), "NOT_WHITELIST");

        _mint(msg.sender, 1);

        userHasMint[msg.sender] += times;
        IERC20(gameToken.PandaToken).transfer(msg.sender, gameToken.PreReward);
    }

    function isWhiteLists(bytes32[] memory proof, bytes32 leaf) private view returns (bool) {
        return MerkleProof.verify(proof, customConfig.Root, leaf);
    }

    receive() external payable {}

    // ============================= ADMINS CONFIG ====================================

    function setSaleConfig(SaleConfig memory config) external onlyOwner {
        saleConfig = config;
    }

    function setCustomConfig(CustomConfig memory config) external onlyOwner {
        customConfig = config;
    }

    function setRoot(bytes32 root) external onlyOwner {
        customConfig.Root = root;
    }

    function setTokenInfo(GameToken calldata tokenInfo) external onlyOwner {
        gameToken = tokenInfo;
    }

    function adminMint(address reciver, uint times) external onlyOwner {
        require((_tokenIds.current() + times - 1) <= saleConfig.SupplyMaximum, "OVERFLOW");
        _mint(reciver, times);
    }

    function adminBonus(address[] calldata addrs, uint[] calldata amounts) external onlyOwner {
        require((_tokenIds.current() + addrs.length - 1) <= saleConfig.SupplyMaximum, "OVERFLOW");
        for (uint i; i < addrs.length; i++) {
            _mint(addrs[i], amounts[i]);
            IERC20(gameToken.PandaToken).transfer(addrs[i], gameToken.PreReward * amounts[i]);
        }
    }

    function withdraw(address receiver) external payable onlyOwner {
        payable(receiver).call{value: address(this).balance}("");
    }

    // ============================= INTERFACE ====================================

    function tokenURI(uint tokenId) public view override returns (string memory) {
        return string.concat(customConfig.BaseURI, Strings.toString(tokenId), ".json");
    }

    function contractURI() public view returns (string memory) {
        return customConfig.ContractURI;
    }
}