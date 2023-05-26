// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../../lib/enumerable/ERC721AMultiMint.sol";

import "../../lib/Controllable.sol";

import "../../opensea/ContextMixin.sol";
import "../../opensea/NativeMetaTransaction.sol";

import "../../vault/v2/interfaces/IMetroVaultStorage.sol";
import "../../vault/v2/MetroVaultDoor.sol";
import "../../MetToken.sol";


contract MetroMiniBlock is Controllable, ERC721AMultiMint, IMetroBlockInfo {

    uint256 public constant MIN_MET_BLOCKS = 20_000;
    uint256 public constant MAX_ETH_BLOCKS = 20_000;
    uint256 public constant MAX_TRADE_BLOCKS = 10_000;
    uint256 public constant MAX_BLOCKS = MIN_MET_BLOCKS + MAX_ETH_BLOCKS + MAX_TRADE_BLOCKS;

    uint256 public constant BLOCK_ID_OFFSET = 20_000;
    uint256 public constant BLOCKS_PER_TRADE = 10;
    uint256 private constant MAX_GENESIS_BLOCK_ID = 10_000;

    uint256 public constant MAX_BLOCKS_PER_WHITELIST = 2;
    uint256 public constant MAX_BLOCKS_PER_MINT = 100;

    uint256 public constant CEIL_MET_PRICE = 10_000 ether;
    uint256 public constant FLOOR_MET_PRICE = 4_000 ether;
    uint256 private constant MET_PRICE_MAX_DELTA = CEIL_MET_PRICE - FLOOR_MET_PRICE;

    uint256 public constant PRICE_STEP = 50 ether;
    uint256 public constant PRICE_PERIOD = 10 minutes;

    uint32 public metMinted;
    uint32 public ethMinted;
    uint32 public tradeMinted;

    uint32 public auctionStartTimestamp;

    bool public metSaleActive = false;
    bool public ethSaleActive = false;
    bool public tradeSaleActive = false;

    uint128 public ethPrice = 0.1 ether;

    string public baseTokenURI = "ipfs://QmZGfurTKSkKp3DycpKV1AhnDtcSRtDyUZtRZnUwGQ9Ynr/";

    address immutable public metTokenAddress;
    address immutable public vaultStorageAddress;

    address public blockInfoAddress;
    address public proxyRegistryAddress;
    address public signerAddress;
    address public genesisLockerAddress;
    address immutable public metroPassAddress;

    constructor(
      address _metTokenAddress, 
      address _vaultStorageAddress, 
      address _proxyRegistryAddress, 
      address _signerAddress, 
      address _genesisLockerAddress,
      address _metroPassAddress) ERC721AMultiMint("Metroverse Mini City Block", "METROMINIBLOCK")
    {
        metTokenAddress = _metTokenAddress;
        vaultStorageAddress = _vaultStorageAddress;
        proxyRegistryAddress = _proxyRegistryAddress;
        signerAddress = _signerAddress;
        genesisLockerAddress = _genesisLockerAddress;
        metroPassAddress = _metroPassAddress;
    }

    function setBlockInfoAddress(address _blockInfoAddress) external onlyOwner {
        blockInfoAddress = _blockInfoAddress;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function setGenesisLockerAddress(address _genesisLockerAddress) external onlyOwner {
        genesisLockerAddress = _genesisLockerAddress;
    }

    function setEthPrice(uint128 price) public onlyOwner {
        ethPrice = price;
    }

    function startMetSale() public onlyOwner {
        metSaleActive = true;
        auctionStartTimestamp = uint32(block.timestamp);
    }

    function stopMetSale() public onlyOwner {
        metSaleActive = false;
    }

    function resumeMetSale() public onlyOwner {
        metSaleActive = true;
    }

    function startEthSale() public onlyOwner {
        ethSaleActive = true;
    }

    function stopEthSale() public onlyOwner {
        ethSaleActive = false;
    }

    function startTradeSale() public onlyOwner {
        tradeSaleActive = true;
    }

    function stopTradeSale() public onlyOwner {
        tradeSaleActive = false;
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

    function getAux(address owner) public view returns (uint176) {
        return _getAux(owner);
    }

    function setAux(address owner, uint176 extra) public onlyController {
        _setAux(owner, extra);
    }

    function numberWhitelistMinted(address owner) public view returns (uint8) {
        return _numberWhitelistMinted(owner);
    }

    function timestampOf(uint256 tokenId) public view returns (uint64) {
        return _ownershipOf(tokenId).startTimestamp;
    }

    function setTimestampOf(uint256 tokenId, uint64 timestamp) public onlyController returns (uint64) {
        return _setTimestampOf(tokenId, timestamp);
    }

    function setTimestampsOf(address owner, uint256[] calldata tokenIds, uint64 timestamp) external onlyController returns (uint64[] memory) {
        return _setTimestampsOf(owner, tokenIds, timestamp);
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return BLOCK_ID_OFFSET + 1;
    }

    function totalMinted() public view virtual returns (uint256 supply)
    {
        return _totalMinted();
    }

    function currentMetPrice() public view returns (uint256) {
        if (auctionStartTimestamp == 0) { 
            return CEIL_MET_PRICE;
        }

        uint256 passedPeriods = (block.timestamp - auctionStartTimestamp) / PRICE_PERIOD;
        uint256 priceChange = PRICE_STEP * passedPeriods;

        if (priceChange < MET_PRICE_MAX_DELTA) {
            return CEIL_MET_PRICE - priceChange;
        } else {
            return FLOOR_MET_PRICE;
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function metMint(uint256 amount) public {
        require(metSaleActive, "MET sale is not active");
        require(amount > 0, "Cannot mint zero blocks");
        require(amount <= MAX_BLOCKS_PER_MINT, "Cannot mint that many blocks");

        metMinted += uint32(amount);
        require(totalMinted() + amount <= MAX_BLOCKS, "Exceeded max MET block count");

        uint256 currentPrice = currentMetPrice();
        MetToken metToken = MetToken(metTokenAddress);
        metToken.burnFrom(msg.sender, currentPrice * amount); 

        _mintBlocks(amount);
    }

    function ethMint(bytes32 signatureR, bytes32 signatureVS, uint256 amount) public payable {
        require(ethSaleActive, "ETH sale is not active");
        require(signerAddress != address(0x0), "Signer address is not set");

        require(amount > 0, "Cannot mint zero blocks");
        require(amount <= MAX_BLOCKS_PER_MINT, "Cannot mint that many blocks");

        ethMinted += uint32(amount);
        require(ethMinted <= MAX_ETH_BLOCKS, "Exceeded max ETH block count");
        require(totalMinted() + amount <= MAX_BLOCKS, "Exceeded max ETH block count");

        bytes32 addressHash = keccak256(abi.encodePacked(msg.sender));
        address signer = verifyHash(addressHash, signatureR, signatureVS);
        require(signer == signerAddress, "Not whitelisted");

        uint256 whitelistTotal = numberWhitelistMinted(msg.sender) + amount;
        require(whitelistTotal <= MAX_BLOCKS_PER_WHITELIST, "Already minted");

        require(msg.value == ethPrice * amount, "Wrong amount of ETH");

        _setNumberWhitelistMinted(msg.sender, uint8(whitelistTotal));
        _mintBlocks(amount);
    }

    function tradeMint(uint256[] calldata stakedTokenIds, uint256[] calldata unstakedTokenIds) public {
        require(tradeSaleActive, "Trade sale is not active");
        require(genesisLockerAddress != address(0), "No genesis locker available");
        require(vaultStorageAddress != address(0), "No vault storage available");

        uint256 amount = (stakedTokenIds.length + unstakedTokenIds.length) * BLOCKS_PER_TRADE;
        require(amount > 0, "Cannot mint zero blocks");
        require(amount <= MAX_BLOCKS_PER_MINT, "Cannot mint that many blocks");

        tradeMinted += uint32(amount);
        require(tradeMinted <= MAX_TRADE_BLOCKS, "Exceeded max trade block count");
        require(totalMinted() + amount <= MAX_BLOCKS, "Exceeded max trade block count");
        
        IERC721 metroPass = IERC721(metroPassAddress);
        require(metroPass.balanceOf(msg.sender) > 0, "Only MetroPass holders are eligible");

        IMetroVaultStorage vaultStorage = IMetroVaultStorage(vaultStorageAddress);

        if (stakedTokenIds.length > 0) {
            unchecked {
                uint256 prevTokenId;
                for (uint256 i = 0; i < stakedTokenIds.length; ++i) {
                    uint256 tokenId = stakedTokenIds[i];
                    require(prevTokenId < tokenId, 'no duplicates allowed');
                    prevTokenId = tokenId;

                    require(tokenId <= MAX_GENESIS_BLOCK_ID, "Only genesis blocks allowed");

                    Stake memory staked = vaultStorage.getStake(tokenId);
                    require(staked.owner == msg.sender, "not an owner");
                }
            }

            vaultStorage.setStakeOwner(stakedTokenIds, genesisLockerAddress, true);
        }

        if (unstakedTokenIds.length > 0) {
            unchecked {
                for (uint256 i = 0; i < unstakedTokenIds.length; ++i) {
                    require(unstakedTokenIds[i] <= MAX_GENESIS_BLOCK_ID, "Only genesis blocks allowed");
                }
            }

            vaultStorage.stakeBlocks(msg.sender, unstakedTokenIds, 0, 0);
            vaultStorage.setStakeOwner(unstakedTokenIds, genesisLockerAddress, false);
        }

        _mintBlocks(amount);
    }

    function _mintBlocks(uint256 amount) internal {
        _mint(msg.sender, amount, '', false);
    }    
    
    function burn(uint256[] calldata tokenIds) public onlyController {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function verifyHash(bytes32 hash, bytes32 signatureR, bytes32 signatureVS) public pure
        returns (address signer)
    {
        bytes32 messageDigest = ECDSA.toEthSignedMessageHash(hash);
        return ECDSA.recover(messageDigest, signatureR, signatureVS);
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

        return isController(operator) || super.isApprovedForAll(owner, operator);
    }
}