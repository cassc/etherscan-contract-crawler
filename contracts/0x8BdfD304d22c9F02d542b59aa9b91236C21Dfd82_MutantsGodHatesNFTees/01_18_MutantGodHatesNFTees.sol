/*

 $$$$$$\   $$$$$$\  $$$$$$$\        $$\   $$\  $$$$$$\ $$$$$$$$\ $$$$$$$$\  $$$$$$\        $$\   $$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$$$$$$$\  $$$$$$\  
$$  __$$\ $$  __$$\ $$  __$$\       $$ |  $$ |$$  __$$\\__$$  __|$$  _____|$$  __$$\       $$$\  $$ |$$  _____|\__$$  __|$$  _____|$$  _____|$$  __$$\ 
$$ /  \__|$$ /  $$ |$$ |  $$ |      $$ |  $$ |$$ /  $$ |  $$ |   $$ |      $$ /  \__|      $$$$\ $$ |$$ |         $$ |   $$ |      $$ |      $$ /  \__|
$$ |$$$$\ $$ |  $$ |$$ |  $$ |      $$$$$$$$ |$$$$$$$$ |  $$ |   $$$$$\    \$$$$$$\        $$ $$\$$ |$$$$$\       $$ |   $$$$$\    $$$$$\    \$$$$$$\  
$$ |\_$$ |$$ |  $$ |$$ |  $$ |      $$  __$$ |$$  __$$ |  $$ |   $$  __|    \____$$\       $$ \$$$$ |$$  __|      $$ |   $$  __|   $$  __|    \____$$\ 
$$ |  $$ |$$ |  $$ |$$ |  $$ |      $$ |  $$ |$$ |  $$ |  $$ |   $$ |      $$\   $$ |      $$ |\$$$ |$$ |         $$ |   $$ |      $$ |      $$\   $$ |
\$$$$$$  | $$$$$$  |$$$$$$$  |      $$ |  $$ |$$ |  $$ |  $$ |   $$$$$$$$\ \$$$$$$  |      $$ | \$$ |$$ |         $$ |   $$$$$$$$\ $$$$$$$$\ \$$$$$$  |
 \______/  \______/ \_______/       \__|  \__|\__|  \__|  \__|   \________| \______/       \__|  \__|\__|         \__|   \________|\________| \______/ 
                                                                                                                                                       
                                                                                                                                                                                                                                                                                              
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "Bnno.sol";
import "RtBnno.sol";

contract MutantsGodHatesNFTees is ERC721Enumerable, ERC2981, ReentrancyGuard, Ownable {
    // IDs 1 - 200: M1
    // IDs 201 - 4696: M2
    using Strings for uint256;
    // Public Constants
    uint256 public constant MAX_SUPPLY = 4696;
    uint256 public constant M1_MAX_SUPPLY = 200;
    uint256 public constant M2_MAX_SUPPLY = 4496;

    string public uriPrefix = "";
    string public uriSuffix = "";

    // Mappings
    Bnno private immutable bnno;
    RtBnno private immutable rtbnno;
    IERC721 private ahc;
    IERC721 private ghnft;

    address public BURNADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Variables
    string private baseURI;
    uint256 public M1_minted = 0;
    uint256 public M2_minted = 0;
    uint256 public M2_index = 200;

    /// @dev Required by EIP-2981: NFT Royalty Standard
    // 1000 / 10000 -> %10 royalty fee
    uint96 public royaltyDividend = 1000;

    /// Royalties Wallet
    address payable RoyaltiesWallet =
        payable(0x8C020fe9F8DF1D2b4E1645AF03B35474b3C4d09f);

    // Sale controllers
    bool public MutationActive = false;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        bnno = Bnno(0x50BEfFd8A0808314d3cc81B3cbF7f1AFA3A6B56c);
        rtbnno = RtBnno(0x0912DAD1db4643368B029166AF217B8A9818dB15);
        ahc = IERC721(0x9370045CE37F381500ac7D6802513bb89871e076);
        ghnft = IERC721(0xE6d48bF4ee912235398b96E16Db6F310c21e82CB);
        _setDefaultRoyalty(RoyaltiesWallet, royaltyDividend);
    }


    function MutateMint(uint256 MutationType, uint256 Amount, uint256[] memory ApeTokenIDs
    ) external
    nonReentrant {
        require(MutationActive, "Free Mutation is not active");
        require(ghnft.balanceOf(msg.sender) > 0, "Must own at least 1 GodHatesNFTees to Mutate");
        require(
            ahc.balanceOf(msg.sender) >= Amount,
            "Must own at least the Ape Amount to mutate."
        );
        if (MutationType == 1) {
            require(
                bnno.balanceOf(msg.sender, 0) > 0 &&
                    bnno.balanceOf(msg.sender, 0) >= Amount,
                "Must own at least 1 Sr Banano to mutate, or Sr Bananos you want to Mutate."
            );
            require(M1_minted + Amount <= M1_MAX_SUPPLY, "Exceed max supply");

            for (uint256 i = 0; i < Amount; i++) {
                require(
                    isOwnerOfApe(msg.sender, ApeTokenIDs[i]),
                    "Must own the Ape that you want to mutate."
                );
                M1_minted++;
                uint256 M1_index = M1_minted;
                ahc.safeTransferFrom(msg.sender, BURNADDRESS, ApeTokenIDs[i]);
                bnno.burnBanana(msg.sender);
                _safeMint(msg.sender, M1_index);
            }
        } else if (MutationType == 2) {
            require(
                rtbnno.balanceOf(msg.sender, 0) > 0 &&
                    rtbnno.balanceOf(msg.sender, 0) >= Amount,
                "Must own at least 1 Rotten Banano to mutate, or Rotten Bananos you want to Mutate."
            );
            require(M2_minted + Amount <= M2_MAX_SUPPLY, "Exceed max supply");
            for (uint256 i = 0; i < Amount; i++) {
                require(
                    isOwnerOfApe(msg.sender, ApeTokenIDs[i]),
                    "Must own the Ape that you want to mutate."
                );
                M2_minted++;
                M2_index++;
                ahc.safeTransferFrom(msg.sender, BURNADDRESS, ApeTokenIDs[i]);
                rtbnno.burnBanana(msg.sender);
                _safeMint(msg.sender, M2_index);
            }
        }
    }

    function internalMintM1andM2(uint256 MutationType, uint256 Amount)
        external
        onlyOwner
    {
        if (MutationType == 1) {
            require(M1_minted + Amount <= M1_MAX_SUPPLY, "Exceed max supply");
            for (uint256 i = 0; i < Amount; i++) {
                M1_minted++;
                uint256 M1_index = M1_minted;
                _safeMint(msg.sender, M1_index);
            }
        } else if (MutationType == 2) {
            require(M2_minted + Amount <= M2_MAX_SUPPLY, "Exceed max supply");
            for (uint256 i = 0; i < Amount; i++) {
                M2_minted++;
                M2_index++;
                _safeMint(msg.sender, M2_index);
            }
        }
    }

    function isOwnerOfApe(address account, uint256 apeId)
        public
        view
        returns (bool)
    {
        bool isOwner = false;
        address ownerApe = ahc.ownerOf(apeId);
        if (ownerApe == account) {
            isOwner = true;
        }
        return isOwner;
    }

    //SETS
    function setMutationMint(bool _state) public onlyOwner {
        MutationActive = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    // Note "feeDenominator" is a constant value: 10000
    // -> 1000/10000 = %10

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        require(
            feeBasisPoints <= 1000,
            "OS-Royalty: Royalty fee can't exceed %10"
        );
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        //suppress error
        _tokenId;
        return (RoyaltiesWallet, (_salePrice * royaltyDividend) / 10000);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721Enumerable)
        returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}