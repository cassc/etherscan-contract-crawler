//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
    CAT BRICKS CLUBHOUSE
    
    @INVADERETH  - DEV
    @OOFFSETT    - ART
    @ITSFUJIFUJI - FINANCE
    @HUMZAH_ETH  - COMMUNITY
    @SHARK_IDK   - COMMUNITY
    @DAKL__      - MARKETING
    @1KIWEE      - MARKETING

    This contract has been insanely gas optimized with the latest best practices.
    Features such as off-chain whitelisting and permanent OpenSea approval have been 
    implemented - saving gas both on the minting and secondary market end.

    LEGAL NOTICE

    The following addresses the issues of copyright or trademark infringement.

    LEGO® is a trademark of the LEGO Group, which does not sponsor, authorize       
    or endorse the Cat Bricks Clubhouse project. The LEGO Group is neither endorsing 
    the modification in any way, shape, or form, nor accepting any responsibility for 
    unforeseen and/or adverse consequences.

    The patent for the Toy figure model expired in 1993. The models are open to usage 
    so long as the aforementioned LEGO brand is not infringed upon.

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721SeqEnumerable.sol";
import "./common/ContextMixin.sol";
import "./common/NativeMetaTransaction.sol";

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CatBricksClubhouse is ERC721SeqEnumerable, ContextMixin, NativeMetaTransaction, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant CBC_MAX = 9999;
    uint256 public constant CBC_PRIVATE = 8888;
    uint256 public constant CBC_PRICE = 0.08 ether;
    uint256 public constant PRIV_PER_MINT = 2;
    uint256 public constant PUB_PER_MINT = 4;
    uint256 public lostCats;

    string private _contractURI = "https://cbc.mypinata.cloud/ipfs/Qmdbo4z1WLduLoMe7sU9YXe8SDGkiFc7uXwnnodJ2anfc5"; 
    string private _tokenBaseURI = "https://cbc.mypinata.cloud/ipfs/QmZZ5FiQ8FVroynJ4e9v7q5NPygojWv3xFxpJZjaxSkx1H/";
    string private _tokenExtension = ".json";

    address private _vault = 0x563e6750e382fe86E458153ba520B89F986471aa;
    address private _signer = 0xb82209b16Ab5c56716f096dc1a51B95d424f755a;
    address private _proxy = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    bool public presaleLive; 
    bool public saleLive; 

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) public presalerListPurchases;
    
    constructor() ERC721Sequencial("Cat Bricks Clubhouse", "CATBRICK") {
        _initializeEIP712("Cat Bricks Clubhouse");
    }

    // Mint during public sale
    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "Sale Inactive");
        require(!presaleLive, "Only Presale");
        require(tokenQuantity <= PUB_PER_MINT, "Exceed Max");
        require(_owners.length + tokenQuantity <= CBC_MAX, "Out of Stock");
        require(CBC_PRICE * tokenQuantity <= msg.value, "More ETH Needed");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender);
        }
    }

    // Mint during presale - disables contract minting
    function privateBuy(uint256 tokenQuantity, bytes32 hash, bytes memory signature) external payable {
        require(!saleLive && presaleLive, "Presale Inactive");
        require(matchAddressSigner(hash, signature), "Contract Disabled for Presale");
        require(tokenQuantity <= PRIV_PER_MINT, "Exceed Max");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= PRIV_PER_MINT, "Holding Max Allowed");
        require(CBC_PRICE * tokenQuantity <= msg.value, "More ETH");
        require(_owners.length + tokenQuantity <= CBC_PRIVATE, "Exceed Supply");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender);
        }

        presalerListPurchases[msg.sender] += tokenQuantity;
    }

    // Close or open the private sale
    function togglePrivateSaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    // Close or open the public sale
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    // Withdraw funds for team expenses and payment
    function withdraw() external onlyOwner {
        (bool success, ) = _vault.call{value: address(this).balance}("");
        require(success, "Failed to send to vault.");
    }

    // Approves OpenSea - bypassing approval fee payment
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(_proxy);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    // ** - SETTERS - ** //

    // Set the vault address for payments
    function setVaultAddress(address addr) external onlyOwner {
        _vault = addr;
    }

    // Set the proxy address for payments
    function setProxyAddress(address addr) external onlyOwner {
        _proxy = addr;
    }

    // For future proxy approval management
    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    // Set the contract URL for OpenSea Metadata
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    } 
    
    // Set image path for metadata
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // Set file extension for metadata
    function setTokenExtension(string calldata extension) external onlyOwner {
        _tokenExtension = extension;
    }

    function gift(address[] calldata _recipients) external onlyOwner {
        uint256 recipients = _recipients.length;
        require(
            recipients + _owners.length <= CBC_MAX,
            "Exceeds Supply"
        );

        for (uint256 i = 0; i < recipients; i++) {
            _safeMint(_recipients[i]);
        }
    }

    // Future game usage or user choice
    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
        lostCats++;
    }


    // ** - READ - ** //
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    } 

    function tokenExtension() public view returns (string memory) {
        return _tokenExtension;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), _tokenExtension));
    }

    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    } 

    function matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signer == hash.recover(signature);
    }
}