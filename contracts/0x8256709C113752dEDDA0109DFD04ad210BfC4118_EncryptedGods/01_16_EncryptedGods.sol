// SPDX-License-Identifier: None

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

pragma solidity ^0.8.4;
// @author: Norkaan
// discord : Norkaan#0443
// twitter: @Norkaan_

contract EncryptedGods is  Ownable, ERC721A, ReentrancyGuard, PaymentSplitter {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public preSalePrice = 0.06 ether;
    uint256 public mintPrice = 0.07 ether;
    uint256 public mintLimit = 10;

    uint256 public maxSupply = 9999;

    bool public preSaleState = false;
    bool public publicSaleState = false;
    bool public revealState = false;

    string public baseURI;

    address private deployer;

    address[] private _team = [
        0x240F440292330F891804B6804cDB462c32B682F6,
        0xb53C00cBa98836E71FCD73ee75d5e02672D5abaA,
        0x5fa56Dfea580cDbC985831eC2fd6b87C3A9F12B1,
        0xC19D7065049D85F69324A995ba76603a78363Cad,
        0x6051f4C712939f2A309D8c36eF05a238Ba8829a8,
        0x21791bB57e414BE2aFD94A6334D18892c017258b,
        0x04A8A81D1Db995fdf30357184E94d95d9679C86B,
        0xeE3Bab783abBB83cc7836b64f4738ed1Cb0be2E5

    ];

    uint256[] private _teamShares = [50000,20000,8000,5000,5000, 5000, 5000, 2000];

    constructor() ERC721A("EncryptedGods", "EG")  PaymentSplitter(_team, _teamShares) {
        deployer = msg.sender;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata _newBaseUri) external onlyOwner {
        baseURI = _newBaseUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        if (!revealState) {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
        }

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function changeStatePreSale() public onlyOwner returns(bool) {
        preSaleState = !preSaleState;
        return preSaleState;
    }

    function changeStatePublicSale() public onlyOwner returns(bool) {
        publicSaleState = !publicSaleState;
        return publicSaleState;
    }

    function changeStateReveal() public onlyOwner returns(bool) {
        revealState = !revealState;
        return revealState;
    }

    function changePreSalePrice(uint256 _newPrice) public onlyOwner returns(uint256) {
        preSalePrice = _newPrice;
        return preSalePrice;
    }

    function changeMintPrice(uint256 _newPrice) public onlyOwner returns(uint256) {
        mintPrice = _newPrice;
        return mintPrice;
    }

    function changeDeployer(address _newDeployer) public onlyOwner returns(address) {
        deployer = _newDeployer;
        return deployer;
    }

    function changeMintLimit(uint256 _newMintLimit) public onlyOwner returns(uint256) {
        mintLimit = _newMintLimit;
        return mintLimit;
    }

    function changeMaxSupply(uint256 _newMaxSupply) public onlyOwner returns(uint256) {
        maxSupply = _newMaxSupply;
        return maxSupply;
    }

    function airdropToWallet(address walletAddress, uint amount) external onlyOwner{
        mintInternal(walletAddress, amount);
    }

    function mintPreSale(uint numberOfTokens, uint maxAllocation, bytes calldata _signature) external payable {
        require(preSaleState, "Presale is not active");

        (uint32 numPublicSaleMinted, uint32 numPreSaleMinted) = unpackAux(_getAux(_msgSender()));
        numPreSaleMinted = numPreSaleMinted + uint32(numberOfTokens);
        require(numPreSaleMinted <= maxAllocation, "Too many public mint for this wallet");


        require(msg.value >= preSalePrice * numberOfTokens, "Insufficient payment");

        bytes32 _messageHash = hashMessage(abi.encode("presale", address(this), msg.sender, maxAllocation));
        require(verifyAddressSigner(_messageHash, _signature), 'Invalid Presale Signature');

        mintInternal(msg.sender, numberOfTokens);
        _setAux(_msgSender(), packAux(numPublicSaleMinted, numPreSaleMinted));
    }

    function mint(uint numberOfTokens) external payable {
        require(publicSaleState, "Sale is not active");

        (uint32 numPublicSaleMinted, uint32 numPreSaleMinted) = unpackAux(_getAux(_msgSender()));
        numPublicSaleMinted = numPublicSaleMinted + uint32(numberOfTokens);
        require(numPublicSaleMinted <= mintLimit, "Too many public mint for this wallet");

        require(msg.value >= mintPrice * numberOfTokens, "Insufficient payment");

        mintInternal(msg.sender, numberOfTokens);
        _setAux(_msgSender(), packAux(numPublicSaleMinted, numPreSaleMinted));
    }

    function mintInternal(address wallet, uint amount) internal {
        uint currentTokenSupply = _currentIndex -1 ;
        require(currentTokenSupply + amount <= maxSupply, "Not enough tokens left");

        _safeMint(wallet, amount);
    }

    function tokensOfWallet(address _wallet)public view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_wallet);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = 1; tokenId <= totalSupply(); tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _wallet) {
                    result[index] = tokenId;
                    index++;
                }
            }
            return result;
        }
    }

    function withdrawAll() external onlyOwner nonReentrant {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }

    function verifyAddressSigner(bytes32 _messageHash, bytes memory _signature) private view returns (bool) {
        return deployer == _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    function hashMessage(bytes memory _msg) private pure returns (bytes32) {
        return keccak256(_msg);
    }

    function packAux(uint32 numPublicSaleMinted, uint32 numPreSaleMinted) private pure returns(uint64) {
        return (uint64(numPublicSaleMinted) << 32) | uint64(numPreSaleMinted);
    }

    function unpackAux(uint64 aux) private pure returns(uint32 numPublicSaleMinted, uint32 numPreSaleMinted) {
        numPublicSaleMinted = uint32(aux >> 32);
        numPreSaleMinted = uint32(aux);
    }
}