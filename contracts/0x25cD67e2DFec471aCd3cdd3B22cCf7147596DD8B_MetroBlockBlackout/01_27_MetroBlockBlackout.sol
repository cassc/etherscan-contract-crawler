// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "../../lib/enumerable/ERC721.sol";
import "../../lib/Controllable.sol";

import "../../opensea/ContextMixin.sol";
import "../../opensea/NativeMetaTransaction.sol";

import "../../vault/v2/interfaces/IMetroVaultStorage.sol";
import "../../MetToken.sol";
import "../interfaces/IMetroBlockInfo.sol";


contract MetroBlockBlackout is ERC721, Controllable, IMetroBlockInfo {

    uint256 public constant MAX_BLOCKS = 10_000;
    uint256 public constant BLOCK_ID_OFFSET = 10_000;
    uint256 public constant TEAM_BLOCKS = 50;

    uint256 public metPrice = 25_000 ether;
    uint256 public ethPrice = 2 ether;

    bool public metSaleActive = false;
    bool public ethSaleActive = false;

    uint256 private _blockIdCounter = BLOCK_ID_OFFSET;
    uint256 public teamMinted;

    string public baseTokenURI = "ipfs://QmXLDf3E2GLKDsRPy7yEYt3YRJiax3gz2Vyq3viaEWvLqZ/";

    address public metTokenAddress;
    address public proxyRegistryAddress;
    address public vaultStorageAddress;
    address public blockInfoAddress;

    address immutable deployerAddress;

    event BlockMinted(address indexed account, uint256 indexed tokenId);

    constructor(address _metTokenAddress) ERC721("Metroverse Blackout City Block", "METROBLOCK2") {
        metTokenAddress = _metTokenAddress;
        deployerAddress = msg.sender;
    }

    function setMetTokenAddress(address _metTokenAddress) external onlyOwner {
        metTokenAddress = _metTokenAddress;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setVaultAddress(address _vaultStorageAddress) external onlyOwner {
        vaultStorageAddress = _vaultStorageAddress;
    }

    function setBlockInfoAddress(address _blockInfoAddress) external onlyOwner {
        blockInfoAddress = _blockInfoAddress;
    }

    function setMetPrice(uint256 price) public onlyOwner {
        metPrice = uint80(price); 
    }

    function setEthPrice(uint256 price) public onlyOwner {
        ethPrice = uint72(price);
    }

    function startMetSale() public onlyOwner {
        metSaleActive = true;
    }

    function stopMetSale() public onlyOwner {
        metSaleActive = false;
    }

    function startEthSale() public onlyOwner {
        ethSaleActive = true;
    }

    function stopEthSale() public onlyOwner {
        ethSaleActive = false;
    }

    function setBaseURI(string calldata URI) public onlyOwner {
        baseTokenURI = URI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getBlockScore(uint256 tokenId) external view returns (uint256 score) {
        if (blockInfoAddress == address(0x0)) {
            return 0;
        }
        
        return IMetroBlockInfo(blockInfoAddress).getBlockScore(tokenId);
    }

    function getBlockInfo(uint256 tokenId) external view returns (uint256 info) {
        if (blockInfoAddress == address(0x0)) {
            return 0;
        }

        return IMetroBlockInfo(blockInfoAddress).getBlockInfo(tokenId);
    }

    function getHoodBoost(uint256[] calldata tokenIds) external view returns (uint256 score) {
      if (blockInfoAddress == address(0x0)) {
          return 0;
      }

      return IMetroBlockInfo(blockInfoAddress).getHoodBoost(tokenIds);
    }

    function totalSupply() public view virtual returns (uint256 supply)
    {
        return _blockIdCounter - BLOCK_ID_OFFSET;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function metMint(uint256 amount, bool stake) public {
        bool isDeployer = msg.sender == deployerAddress;
        require(metSaleActive || isDeployer, "MET sale is not active");

        if (isDeployer) {
            require(teamMinted + amount <= TEAM_BLOCKS, "Exceeded team limit");
            teamMinted += amount;
        }

        MetToken metToken = MetToken(metTokenAddress);
        metToken.burnFrom(msg.sender, metPrice * amount); 
        _mintBlock(amount, stake);
    }

    function ethMint(uint256 amount, bool stake) public payable {
        bool isDeployer = msg.sender == deployerAddress;
        require(ethSaleActive || isDeployer, "ETH sale is not active");
        require(msg.value == ethPrice * amount, "Wrong amount of ETH");

        if (isDeployer) {
            require(teamMinted + amount <= TEAM_BLOCKS, "Exceeded team limit");
            teamMinted += amount;
        }

        _mintBlock(amount, stake);
    }

    function teamMint(uint256 amount, bool stake) public {
        require(msg.sender == deployerAddress, "Team mint forbidden");
        require(teamMinted + amount <= TEAM_BLOCKS, "Exceeded team limit");
        teamMinted += amount;
        _mintBlock(amount, stake);
    }

    function _mintBlock(uint256 amount, bool stake) internal {
        require(totalSupply() + amount <= MAX_BLOCKS, "Exceeded max block count");

        if (stake) {
            require(vaultStorageAddress != address(0x0), "VaultAddress is not defined");
            uint256[] memory tokenIds = new uint256[](amount);

            unchecked {
                uint256 newBlockId = _blockIdCounter;
                _blockIdCounter += amount;
                for (uint256 i = 0; i < amount; i++) {
                    newBlockId++;
                    _mint(vaultStorageAddress, newBlockId);
                    tokenIds[i] = newBlockId;

                    emit BlockMinted(msg.sender, newBlockId);
                }
            }

            IMetroVaultStorage(vaultStorageAddress).stakeFromMint(msg.sender, tokenIds, 0, 0);
        }
        else {
            unchecked {
                uint256 newBlockId = _blockIdCounter;
                _blockIdCounter += amount;
                for (uint256 i = 0; i < amount; i++) {
                    newBlockId++;
                    _mint(msg.sender, newBlockId);
                    emit BlockMinted(msg.sender, newBlockId);
                }
            }
        }
    }    
    
    /// Returns tokens of user, should never be used inside of transaction because of high gas fee.
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
            uint256 tokenId;
            uint supply = totalSupply();

            for (tokenId = BLOCK_ID_OFFSET + 1; tokenId <= supply + BLOCK_ID_OFFSET; tokenId++) {
                if (_owners[tokenId] == owner) {
                  result[resultIndex] = tokenId;
                  resultIndex++;
                  if (resultIndex >= tokenCount) {break;}
                }
            }
            return result;
        }
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
          if (address(proxyRegistry.proxies(owner)) == operator) {
              return true;
          }
        }

        return isController(operator) || (operator == vaultStorageAddress) || super.isApprovedForAll(owner, operator);
    }

}