// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721.sol";

import "./common/ContextMixin.sol";
import "./common/NativeMetaTransaction.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./MetroverseVault.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


interface IMetroBlockScores {
    function getBlockScore(uint256 tokenId) external view returns (uint256 score);
    function getHoodBoost(uint256[] calldata tokenIds) external view returns (uint256 score);
}


contract MetroBlock is ERC721, Ownable {

    uint256 constant public MAX_BLOCKS = 10000;
    uint256 constant public MAX_BLOCKS_PER_ADDRESS = 2;

    uint256 constant public PRICE = 0.1 ether;

    string public baseTokenURI = "ipfs://QmUnpgvQ8Q29mCscbQeF6eL6YU8gvr2QktGsTHb13pUe4W/";

    bool public saleActive = false;
    bool public checkWhitelist = true;

    address public signerAddress;

    mapping(address => uint256) internal minters;

    uint256 private _tokenIdCounter = 0;

    address scoresAddress;
    address vaultAddress;

    address proxyRegistryAddress;

    event BlockMinted(address account, uint256 tokenId, bool staked);

    constructor() ERC721("Metroverse City Block", "METROBLOCK") {
      setSignerAddress(msg.sender);
    }

    function setVault(address _vaultAddress) external onlyOwner {
      vaultAddress = _vaultAddress;
    }

    function setScores(address _scoresAddress) public onlyOwner {
        scoresAddress = _scoresAddress;
    }

    function setSignerAddress(address signer) public onlyOwner {
        signerAddress = signer;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function startSale() public onlyOwner {
        saleActive = true;
    }

    function stopSale() public onlyOwner {
        saleActive = false;
    }

    function enableWhitelist() public onlyOwner {
        checkWhitelist = true;
    }

    function disableWhitelist() public onlyOwner {
        checkWhitelist = false;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getBlockScore(uint256 tokenId) external view returns (uint256 score) {
      if (scoresAddress == address(0x0)) {
        return 0;
      }

      require(_exists(tokenId), "ERC721: owner query for nonexistent token");

      return IMetroBlockScores(scoresAddress).getBlockScore(tokenId);
    }

    function getHoodBoost(uint256[] calldata tokenIds) external view returns (uint256 score) {
      if (scoresAddress == address(0x0)) {
        return 10000;
      }
      return IMetroBlockScores(scoresAddress).getHoodBoost(tokenIds);
    }

    function mintNFTWhitelist(uint256 amount, bytes32 signatureR, bytes32 signatureVS, bool stake) public payable {
        require(checkWhitelist, "Not whitelist mode");
        require(signerAddress != address(0x0), "signer address is not set");

        _mintNFT(amount, signatureR, signatureVS, stake);
    }

    function mintNFT(uint256 amount, bool stake) public payable {
        require(!checkWhitelist, "Not public mode");

        _mintNFT(amount, "", "", stake);
    }

    function verifyHash(bytes32 hash, bytes32 signatureR, bytes32 signatureVS) public pure returns (address signer) {
        bytes32 messageDigest = ECDSA.toEthSignedMessageHash(hash);
        return ECDSA.recover(messageDigest, signatureR, signatureVS);
    }

    function _mintNFT(uint256 amount, bytes32 signatureR, bytes32 signatureVS, bool stake) internal {
        require(saleActive, "Sales are disabled");
        if (stake) {require(vaultAddress != address(0x0), "vault is not set");}
        require(_tokenIdCounter + amount <= MAX_BLOCKS, "No more mints allowed");

        require(msg.value == PRICE * amount, "Insufficient Amount");

        if(checkWhitelist) {
          bytes32 addressHash = keccak256(abi.encodePacked(msg.sender));
          address signer = verifyHash(addressHash, signatureR, signatureVS);
          require(signer == signerAddress, "Not whitelisted");
        }

        require(minters[msg.sender] + amount <= MAX_BLOCKS_PER_ADDRESS, "Can not mint that many");
        minters[msg.sender] += amount;

        uint256 start = _tokenIdCounter;
        _tokenIdCounter += amount;

        uint256[] memory tokens = new uint256[](amount);
        for(uint256 i=0; i < amount; i++) {

          uint256 newItemId = start + i + 1;
          _mint(stake ? vaultAddress : msg.sender, newItemId);
          tokens[i] = newItemId;

          emit BlockMinted(msg.sender, newItemId, stake);
        }
        if (stake) {
          MetroverseVault(vaultAddress).stakeDuringMint(msg.sender, tokens);
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

        if (operator == vaultAddress) {
          return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function totalSupply()
        public
        view
        virtual
        returns (uint256 supply)
    {
      return _tokenIdCounter;
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
            uint256 tokenId;
            uint supply = totalSupply();

            for (tokenId = 1; tokenId <= supply; tokenId++) {
                if (_owners[tokenId] == owner) {
                  result[resultIndex] = tokenId;
                  resultIndex++;
                  if (resultIndex >= tokenCount) {break;}
                }
            }
            return result;
        }
    }

    // should never be used inside of transaction because of gas fee
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256 tokenId)
    {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        uint supply = totalSupply();
        uint256 indexFound;

        for (tokenId=1; tokenId <= supply; tokenId++) {
            if (_owners[tokenId] == owner) {
                if (index == indexFound) {
                  return tokenId;
                }
                indexFound += 1;
            }
        }

        // if did not found user tokens
        require(false, "ERC721Enumerable: owner index out of bounds");
    }
}