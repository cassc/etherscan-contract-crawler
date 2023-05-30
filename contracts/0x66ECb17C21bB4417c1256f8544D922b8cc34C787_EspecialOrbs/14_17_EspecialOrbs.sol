// SPDX-License-Identifier: MIT

/*
 _____                  _        _                 _                       
/  __ \                | |      | |               | |                    _ 
| /  \/_ __ _   _ _ __ | |_ ___ | |__   __ _ _   _| |__   __ _ _   _ ___(_)
| |   | '__| | | | '_ \| __/ _ \| '_ \ / _` | | | | '_ \ / _` | | | / __|  
| \__/\ |  | |_| | |_) | || (_) | |_) | (_| | |_| | | | | (_| | |_| \__ \_ 
 \____/_|   \__, | .__/ \__\___/|_.__/ \__,_|\__,_|_| |_|\__,_|\__,_|___(_)
             __/ | |                                                       
            |___/|_|                                                       
 _____                    _       _   _____      _                         
|  ___|                  (_)     | | |  _  |    | |                        
| |__ ___ _ __   ___  ___ _  __ _| | | | | |_ __| |__  ___                 
|  __/ __| '_ \ / _ \/ __| |/ _` | | | | | | '__| '_ \/ __|                
| |__\__ \ |_) |  __/ (__| | (_| | | \ \_/ / |  | |_) \__ \                
\____/___/ .__/ \___|\___|_|\__,_|_|  \___/|_|  |_.__/|___/                
         | |                                                               
         |_|                                                               
*/

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./rarible/library/LibPart.sol";
import "./rarible/library/LibRoyaltiesV2.sol";
import "./rarible/RoyaltiesV2.sol";

contract EspecialOrbs is Ownable, ERC721Enumerable, RoyaltiesV2 {
    using SafeMath for uint256;

    // ---
    // Constants
    // ---
    uint256 constant public royaltyFeeBps = 1000; // 10%
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;

    // ---
    // Properties
    // ---
    uint256 public nextTokenId = 0;
    string private contractUri;
    address public payoutAddress;

    // ---
    // Events
    // ---
    event PermanentURI(string _value, uint256 indexed _id); // OpenSea Freezing Metadata

    // ---
    // Mappings
    // ---
    mapping(address => bool) private isAdmin;
    mapping(uint256 => string) private metadataByTokenId;

    // ---
    // Security
    // ---

    modifier onlyValidTokenId(uint256 tokenId) {
        require(_exists(tokenId), "Token ID does not exist.");
        _;
    }

    // ---
    // Constructor
    // ---
    constructor() ERC721("Cryptobauhaus Especial Orbs", "ESPECIALORBS") {
        isAdmin[msg.sender] = true;
        payoutAddress = msg.sender;
        contractUri = "ipfs://QmZiJtGr433haMVdmxsvhzRz8NTnoZjko7EffiGR4f4291";
    }

    // ---
    // Supported Interfaces
    // ---
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165
        || interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES
        || interfaceId == _INTERFACE_ID_ERC721
        || interfaceId == _INTERFACE_ID_ERC721_METADATA
        || interfaceId == _INTERFACE_ID_ERC721_ENUMERABLE
        || interfaceId == _INTERFACE_ID_EIP2981
        || super.supportsInterface(interfaceId);
    }

    // ---
    // Minting
    // ---
    function mintToken(string memory metadataUri) public onlyOwner returns (uint256 tokenId) {
        tokenId = nextTokenId;
        nextTokenId = nextTokenId.add(1);
        _mint(msg.sender, tokenId);
        metadataByTokenId[tokenId] = metadataUri;
    }

    // ---
    // Burning
    // ---
    function burn(uint256 tokenId) public virtual onlyOwner {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only owners.");
        _burn(tokenId);
    }

    // ---
    // Update Functions
    // ---

    function updateContractUri(string memory updatedContractUri) public onlyOwner {
        contractUri = updatedContractUri;
    }

    function updatePayoutAddress(address newPayoutAddress) public onlyOwner {
        payoutAddress = newPayoutAddress;
    }

    function updateTokenMetadata(uint256 tokenId, string memory metadataUri, bool permanent) public onlyOwner onlyValidTokenId(tokenId) {
        metadataByTokenId[tokenId] = metadataUri;

        if (permanent) {
            emit PermanentURI(metadataUri, tokenId);
        }
    }

    // ---
    // Contract Retrieve Functions
    // ---
    
    function tokenURI(uint256 tokenId) public view override virtual onlyValidTokenId(tokenId) returns (string memory) {
        return metadataByTokenId[tokenId];
    }

    function contractURI() public view virtual returns (string memory) {
        return contractUri;
    }

    function getTokensOfOwner(address walletAddress) public view returns (uint256[] memory tokenIds) {
        uint256 tokenCount = balanceOf(walletAddress);

        if (tokenCount == 0) {
            tokenIds = new uint256[](0);
        } else {
            tokenIds = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                tokenIds[index] = tokenOfOwnerByIndex(walletAddress, index);
            }
        }

        return tokenIds;
    }

    // ---
    // Secondary Marketplace Functions
    // ---

    /* Rarible Royalties V2 */
    function getRaribleV2Royalties(uint256 id) external view override onlyValidTokenId(id) returns (LibPart.Part[] memory) {
        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0] = LibPart.Part({
            account: payable(payoutAddress),
            value: uint96(royaltyFeeBps)
        });

        return royalties;
    }

    /* EIP-2981 */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view onlyValidTokenId(tokenId) returns (address receiver, uint256 amount) {
        uint256 fivePercent = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
        return (payoutAddress, fivePercent);
    }
}