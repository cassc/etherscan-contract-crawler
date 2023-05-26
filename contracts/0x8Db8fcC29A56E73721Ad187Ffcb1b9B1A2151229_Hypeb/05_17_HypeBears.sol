// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract HypeBears is ERC721("HypeBears", "HB"), ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Strings for uint256;

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    string private baseURI = 'ipfs://bafybeidkik23lcp7my72udcgdbt5h6ytpnyph3a2lw3f7tnuo6zxzbehom/'; //todo test
    string private blindURI;
    uint256 public mintLimit = 1;
    uint256 private constant TOTAL_NFT = 10000;
    uint256 public mintPrice = 0.4 ether;
    bool public reveal;
    bool public mintActive;
    mapping (address => bool) public whitelist;
    mapping (address => bool) public addressMinted;
    address whitelistSigner;
    uint256 public partnerMintAmount = 100;
    mapping(address => uint256) public partnerMintAvailableBy;

    constructor() {
//        whitelistSigner = _whitelistSigner;
        partnerMintAvailableBy[0xBC3C2C6e7BaAeB7C7EA2ad4B2Fa8681a91d47Ccd] = 50;//todo test
        partnerMintAvailableBy[0xBC3C2C6e7BaAeB7C7EA2ad4B2Fa8681a91d47Ccd] = 49;
        partnerMintAvailableBy[0x6C63244f8efFE378abD24240EEea27c732f8fc6D] = 1;
    }


    function revealNow() external onlyOwner {
        reveal = true;
    }

    function setMintActive(bool _isActive) external onlyOwner {
        mintActive = _isActive;
    }

    function setURIs(string memory _blindURI, string memory _URI) external onlyOwner {
        blindURI = _blindURI;
        baseURI = _URI;
    }

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function addToWhitelist(address _newAddress) external onlyOwner {
        whitelist[_newAddress] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function addMultipleToWhitelist(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 10000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeMultipleFromWhitelist(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 10000, "Provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function canMint(address _address, bytes memory _signature) public view returns (bool, string memory) {
        if (!whitelist[_address]) {
            bytes32 hash = keccak256(abi.encodePacked(whitelistSigner, _address));
            bytes32 messageHash = hash.toEthSignedMessageHash();

            address signer = messageHash.recover(_signature);

            if (signer != whitelistSigner) {
                return (false, "Invalid signature");
            }
        }

        if (addressMinted[_address]) {
            return (false, "Already withdrawn");
        }
        return (true, "");
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 amount1 = balance * 70 / 100;
        uint256 amount2 = balance - amount1;
        payable(0xe0F7204f04b060715f858Ba8Ae357f57E5494d18).transfer(amount1);
        payable(0x029c2D9EDC080A5A077f30F3bf6122e100F2aDc6).transfer(amount2);
    }

    function updateMintLimit(uint256 _newLimit) public onlyOwner {
        mintLimit = _newLimit;
    }

    function updateMintPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function addPartnerMint(address account, uint256 amount) public onlyOwner {
        partnerMintAmount += amount;
        require(totalSupply().add(partnerMintAmount) <= TOTAL_NFT, "Can't add partner more than available");
        partnerMintAvailableBy[account] += amount;
    }

    function mintNFT(uint256 _numOfTokens, bytes memory _signature) public payable {
        require(mintActive, 'Not active');
        require(_numOfTokens <= mintLimit, "Can't mint more than limit per tx");
        require(mintPrice.mul(_numOfTokens) <= msg.value, "Insufficient payable value");
        require(totalSupply().add(_numOfTokens).add(partnerMintAmount) <= TOTAL_NFT, "Can't mint more than 10000");
        (bool success, string memory reason) = canMint(msg.sender, _signature);
        require(success, reason);

        for(uint i = 0; i < _numOfTokens; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        addressMinted[msg.sender] = true;
    }

    function partnersMintMultiple(address[] memory _to) public {
        uint256 amount = _to.length;
        require(partnerMintAmount >= amount, "Can't mint more than total available for partners");
        require(partnerMintAvailableBy[msg.sender] >= amount, "Can't mint more than available for msg.sender");
        for(uint256 i = 0; i < amount; i++){
            _safeMint(_to[i],totalSupply() + 1);
        }
        partnerMintAmount -= amount;
        partnerMintAvailableBy[msg.sender] -= amount;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!reveal) {
            return string(abi.encodePacked(blindURI));
        } else {
            return string(abi.encodePacked(baseURI, _tokenId.toString()));
        }
    }

    function supportsInterface(bytes4 _interfaceId) public view override (ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function isApprovedForAll(address owner, address operator) override public view returns(bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function updateProxy(address _proxy) external onlyOwner {
        proxyRegistryAddress = _proxy;
    }

}