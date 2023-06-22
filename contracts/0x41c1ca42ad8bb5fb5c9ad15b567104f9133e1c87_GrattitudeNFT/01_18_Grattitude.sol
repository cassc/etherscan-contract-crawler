//
//    ██████╗ ██████╗  █████╗ ████████╗████████╗██╗████████╗██╗   ██╗██████╗ ███████╗
//   ██╔════╝ ██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██║╚══██╔══╝██║   ██║██╔══██╗██╔════╝
//   ██║  ███╗██████╔╝███████║   ██║      ██║   ██║   ██║   ██║   ██║██║  ██║█████╗
//   ██║   ██║██╔══██╗██╔══██║   ██║      ██║   ██║   ██║   ██║   ██║██║  ██║██╔══╝
//   ╚██████╔╝██║  ██║██║  ██║   ██║      ██║   ██║   ██║   ╚██████╔╝██████╔╝███████╗
//    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚═════╝ ╚══════╝
//
//   Grattitude is the second NFT drop in the Tunney Munney collection by artist Peter Tunney. Each NFT is a unique AI
//   generated piece of art residing on the Ethereum blockchain. The digital collection is a gift of Grattitude and
//   claimable by Tunney Munney collectors only. It is not for sale or mint to the public.
//
//   Arist          : Peter Tunney
//   Year           : 2022
//   Owner          : Tunney Munney, LLC (https://tunneymunney.io)
//   Author         : Ben Hakim ([email protected])
//

pragma solidity 0.8.14;

import "./ERC721.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Royalties: Rarible
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";

interface ITunneyMunney {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract GrattitudeNFT is Ownable, ERC721, ReentrancyGuard, RoyaltiesV2Impl {
    address payable private constant _ROYALTY_ADDRESS = payable(0x1F1Fd08ED5f3dBC2158D96Cd5eC063A7A5AeBc67);
    address private _tunneyMunneyContractAddress;
    uint16 private _totalMinted = 0;
    uint96 private constant _ROYALTY_PERCENTAGE_BASIS_POINTS = 1000;
    uint256 private constant _MAXIMUM_PURCHASE = 20;
    string private __baseURI = "ipfs://bafybwihxgxez3htnxlj2n3siv64xh2w2xfejil2vxbikeij25ngdmp6wlu/";
    bool private _freezeMetadataCalled = false;
    bool private _mintActive = false;

    // Tunney Munney Id redeemed
    mapping(uint16 => bool) tunneyMunneyIdRedeemed;

    bytes4 private constant _INTERFACE_TO_ERC2981 = 0x2a55205a;

    function getOwnedTunneyMunneyTokenIds() public view returns (uint256[] memory) {
        uint256 balance = ITunneyMunney(_tunneyMunneyContractAddress).balanceOf(msg.sender);
        uint256[] memory ownedTokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            ownedTokenIds[i] = ITunneyMunney(_tunneyMunneyContractAddress).tokenOfOwnerByIndex(msg.sender, i);
        }
        return ownedTokenIds;
    }

    function getClaimedTunneyMunneyTokenIds() public view onlyOwner returns (uint256[] memory) {
        uint256[] memory claimedTokenIds = new uint256[](_totalMinted); // Initialize return array of size _totalMinted
        uint256 j = 0; // Initialize return array index counter

        for (uint16 i = 1; i <= 5000; i++) { // Cycle through all possible TM tokens
            if (tunneyMunneyIdRedeemed[i] == true) {
                claimedTokenIds[j] = i;
                j++;
            }
        }

        return claimedTokenIds;
    }

    constructor(address tunneyMunneyContractAddress) ERC721("Grattitude NFT", "GRAT", 20, 5000) {
        _tunneyMunneyContractAddress = tunneyMunneyContractAddress;

        // Royalties Implementation: Rarible
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _ROYALTY_PERCENTAGE_BASIS_POINTS;
        _royalties[0].account = _ROYALTY_ADDRESS;
        _saveRoyalties(1, _royalties);
    }

    function DANGER_freezeMetadata() public onlyOwner {
        _freezeMetadataCalled = true;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
       require(_freezeMetadataCalled == false, "Metadata is frozen.");
       __baseURI = newBaseURI;
    }

    function toggleMintActive() public onlyOwner {
        _mintActive = !_mintActive;
    }

    function getMintActive() public view returns (bool) {
        return _mintActive;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted;
    }

    function getMaximumMintCountPermittedAndClaimedCount() public view returns (uint256, uint256, uint256) {
        // Get all Tunney Munney tokens owned by sender
        uint256[] memory ownedTunneyMunneyTokenIds = getOwnedTunneyMunneyTokenIds();

        uint256 maximumMintCountPermitted = 0;
        uint256 grattitudeClaimedCount = 0;

        // Cycle through all ownedTunneyMunneyTokenIds and increment maximumMintCountPermitted if that Id has not yet been minted
        for (uint256 i = 0; i < ownedTunneyMunneyTokenIds.length; i++) {
            if (tunneyMunneyIdRedeemed[uint16(ownedTunneyMunneyTokenIds[i])] == false) {
                maximumMintCountPermitted++;
            } else {
                grattitudeClaimedCount++;
            }
        }

        return (maximumMintCountPermitted, grattitudeClaimedCount, ownedTunneyMunneyTokenIds.length);
    }

    function mint(uint256 numberOfTokensToMint) public nonReentrant {
        require(_mintActive == true, "Minting is not currently active.");
        require(numberOfTokensToMint <= _MAXIMUM_PURCHASE, "You can only mint 20 GrattitudeNFT at a time.");
        require(numberOfTokensToMint > 0, "You should mint at least one token.");

        // Get all Tunney Munney tokens owned by sender
        uint256[] memory ownedTunneyMunneyTokenIds = getOwnedTunneyMunneyTokenIds();

        uint256 numberOfTokensToMintAuthoritative = 0;

        // Cycle through all ownedTunneyMunneyTokenIds and increment numberOfTokensToMintAuthoritative if that Id has not yet been minted
        for (uint256 i = 0; i < ownedTunneyMunneyTokenIds.length; i++) {
            if (tunneyMunneyIdRedeemed[uint16(ownedTunneyMunneyTokenIds[i])] == false && numberOfTokensToMintAuthoritative < numberOfTokensToMint) {
                tunneyMunneyIdRedeemed[uint16(ownedTunneyMunneyTokenIds[i])] = true;
                numberOfTokensToMintAuthoritative++;
            }
        }

        if (numberOfTokensToMintAuthoritative > 0) {
            _totalMinted += uint16(numberOfTokensToMintAuthoritative);

            // Mint
            _safeMint(msg.sender, numberOfTokensToMintAuthoritative);
        }
    }

    // Royalties Implementation: ERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external pure returns (address receiver, uint256 royaltyAmount) {
        return (_ROYALTY_ADDRESS, _salePrice * _ROYALTY_PERCENTAGE_BASIS_POINTS / 10000);
    }

    // OpenSea Contract-level metadata implementation (https://docs.opensea.io/docs/contract-level-metadata)
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(__baseURI, "contract"));
    }

    // Supports Interface Override
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        // Rarible Royalties Interface
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        // ERC2981 Royalty Standard
        if (interfaceId == _INTERFACE_TO_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }
}