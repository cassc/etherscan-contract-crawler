// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ERC721PackedStruct.sol";
import "../../lib/Controllable.sol";
import "../../opensea/ContextMixin.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MetroPass is ERC721PackedStruct, Controllable {

    uint256 constant public MAX_PASSES = 3_579;

    string public baseTokenURI = "ipfs://QmbPrtTPT6dW2FDPez1uFRnMSLP8N2scJaejWH3Et3x4uU/";

    address public proxyRegistryAddress;
    address public signerAddress;

    uint16 private _tokenIdCounter = 0;
    uint16 private _burnedCounter = 0;

    bool public saleActive = false;

    constructor(address _signerAddress) ERC721PackedStruct("Metroverse Pass", "METROPASS") {
        signerAddress = _signerAddress;
    }

    function setSignerAddress(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function startSale() public onlyOwner {
        saleActive = true;
    }

    function stopSale() public onlyOwner {
        saleActive = false;
    }

    function mintPass(bytes32 signatureR, bytes32 signatureVS) public {
        require(saleActive, "Sale is not active");
        require(signerAddress != address(0x0), "Signer address is not set");
        require(_tokenIdCounter < MAX_PASSES, "No more mints allowed");

        bytes32 addressHash = keccak256(abi.encodePacked(msg.sender));
        address signer = verifyHash(addressHash, signatureR, signatureVS);
        require(signer == signerAddress, "Not whitelisted");

        require(hasAlreadyMinted(msg.sender) == false, "Already minted");

        _tokenIdCounter += 1;
        _mint(msg.sender, _tokenIdCounter);
    }

    function burn(uint256 tokenId) external onlyController {
        _burnedCounter++;
        _burn(tokenId);
    }

    function verifyHash(bytes32 hash, bytes32 signatureR, bytes32 signatureVS) public pure
        returns (address signer)
    {
        bytes32 messageDigest = ECDSA.toEthSignedMessageHash(hash);
        return ECDSA.recover(messageDigest, signatureR, signatureVS);
    }

    function isApprovedForAll(address owner, address operator) public view override 
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

    function totalSupply() public view virtual returns (uint256 supply) {
        return _tokenIdCounter - _burnedCounter;
    }

    // should never be used inside of transaction because of gas fee
    function tokensOfOwner(address owner) external view 
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 tokenId;
            uint supply = _tokenIdCounter;

            for (tokenId = 1; tokenId <= supply; tokenId++) {
                if (_owners[tokenId] == owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                    if (resultIndex >= tokenCount) { break; }
                }
            }
            return result;
        }
    }
}