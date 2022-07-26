// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

                                                                                          
/*
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,     8                           8            8       8                                        ,,,,,,,,,,,,,,,,,
,,  .d88 .d8b. Yb  db  dP 8d8b.    88b. .d88 .d88    .d88 .d8b. .d8b. 8d8b.d8b. .d88b 8d8b d88b  ,,,,,,,,,,,,,,,,,
,,  8  8 8' .8  YbdPYbdP  8P Y8    8  8 8  8 8  8    8  8 8' .8 8' .8 8P Y8P Y8 8.dP' 8P   `Yb.  ,,,,,,,,,,,,,,,,,
,,  `Y88 `Y8P'   YP  YP   8   8    88P' `Y88 `Y88    `Y88 `Y8P' `Y8P' 8   8   8 `Y88P 8    Y88P  ,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,((((#%%//######(//////#########&&((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@&(((((////@@//////(&&&&//&&&&&##&&##&&/,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@///////////@&@@@@%/(&@//##&&%####&@##//%@%,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/@@######&&&&&##&&#######&&&&##&&&&&##&@////(#%@&,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#@&######&&, *&&##&&#######&&####&&#////@@//#######@@,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@#///(##@@    *&&##@@#######@&@@//&&@@&//@@@@@@%####@@,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@#////@@&&@@, ,##,.###########///////////////////(##@@,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@#(#&&,,&%%%%%%&&%%(#######################/////////((&&,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@%####&&&&&&&%%%%%%&&&&&&&&% ............. &&&&&&&&&//(/&&*,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@%##@&  @&##&&&&&&@    (#######%         %###     ,,@@//@@*,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#####&&&@##&&*                   %#                  ,,@@@@*,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@%####&&&@.                                         ,,,,@@/,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@@@@@@&@ ...           (########         %###    ,##,,,,@@/,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@(,,,,@@  ....         (#*  @&##      .##  @@##, ,##@@@@@@*,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(##((@@,,   .           ,////        .//////       ,,,,@@*,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,**@@,,,,.  .... ...               .##        ,&%,,,,@@*,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@,,,,.  .... .           %%       %%      *%%,,,,@@*,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%&&&%&&&&&&&&,   .#% .             ##* .##         ,,,,,,@@*,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&&&&&&&#,,@@,,,,.   .###%                             ,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,%&&%&&&&&&&&&&&#,,,,,,      .#%  %%.      %##########      #@#,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,%%&&&&&&&&&&&&&/,,,,,,,,      .%%    #%/               //@@&&/,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,&&&%&&&&&&&&&&&&&/,,,,,,                 ,((**,,         &&**(((//,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,&&&%&&&&&&&&&&&&&%%#,,                      ..,.&&%%%%#//((**%%*.*&%,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,%%&&&&&&&&&&&&&&&&&&&&                          .....,,(/&&&&&@%((,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,%%&&&&&&&&&&&&&&&&%%%%&&.                         .....&&%%%%%%%&&&&&&,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,%%&&&&&&&&&&&&&&%%%%%%%%%%*                       /%%%%%%%%%%&&&%%%%%%%&*,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,#&&&&&&&&&&&&&&&&&&&&&&%%%%%%&&&&&&&&&&%               &%%%%%%%%%&&&&&&%%%%%%%%%%%%&&%,,,,,,,,,,,,,,,
,,,,,,,,,,,%&%&&&&%%%%%%%%%%&&&&&%%%%%%%%%&&&%&%&%&%&%%%%%%%%%%%%%%%%%%%%%%%%%&%&%%%%%%%%%%%%%%%%%&&&,,,,,,,,,,,,,
,,,,,,,//&&&&&&&&&&&&&&%&%%%%%%%%%%&&&&&%%%&&&&&&&&&&&&%&%%%%%%%%%%%%%&&&&&&&&&&%%%%%%%%%%%%%%%%%%%%%&&,,,,,,,,,,,
,,,,/%%&&&&%%&&&&&&&&&&%&%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%&&&&&&%%%%&&&&&%&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%*,,,,,,,,
,,,,/&&&&%%%%%%%%%%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&%&&&&&%&&&&&&%%%&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&*,,,,,,,,
,,(&&&&%&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&%&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&(,,,,,,
,,(&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&%,,,,
,,,,/&&%&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&%,,,,
,,,,/&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&%,,
*/

import '@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol';
import '@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol';
import '@divergencetech/ethier/contracts/sales/FixedPriceSeller.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '../base/SignatureVerifier.sol';

contract DownBadDoomers is ERC721ACommon, BaseTokenURI, FixedPriceSeller, ERC2981, SignatureVerifier {

    // signs whitelist mints
     mapping(address=>bool) public _whitelistSigners;

    constructor(address payable beneficiary, address royaltyReceiver)
        ERC721ACommon('Down Bad Doomers', 'DOOMER')
        BaseTokenURI('')
        FixedPriceSeller(
            0.05 ether,
            Seller.SellerConfig({
                 // total 1050 supply
                totalInventory: 975,
                lockTotalInventory: true,
                maxPerAddress: 0,
                maxPerTx: 10,
                // reserved for the beneficiary
                freeQuota: 75,
                lockFreeQuota: true,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        _setDefaultRoyalty(royaltyReceiver, 500);
    }

    /**
    @dev Mint tokens purchased via the Seller.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        _safeMint(to, n);
    }

    /**
    @notice Flag indicating that public minting is open.
     */
    bool public publicMinting;

    /**
    @notice Set the `publicMinting` flag.
     */
    function setPublicMinting(bool _publicMinting) external onlyOwner {
        publicMinting = _publicMinting;
    }

    /**
    @notice Add a whitelist signer.
     */
    function addWhitelistSigner(address signer) external onlyOwner {
        _whitelistSigners[signer] = true;
    }

    /**
    @notice Remove a whitelist signer.
     */
    function removeWhitelistSigner(address signer) external onlyOwner {
        _whitelistSigners[signer] = false;
    }


    /**
    @notice Mint as a member of the public.
     */
    function mintPublic(address to, uint256 n) external payable {
        require(publicMinting, 'Public minting closed');
        _purchase(to, n);
    }

    /**
    @dev Record of already-used whitelist signatures.
     */
    mapping(bytes32 => bool) public _usedWhitelistHashes;

    function mintWhitelist(
        uint16 nonce,
        bytes calldata sig
    ) external nonReentrant {
        require(publicMinting, 'Whitelist minting closed');
        bytes32 wlHash = getHashToSign(_msgSender(), nonce);
        require(!_usedWhitelistHashes[wlHash], 'Nonce already used');
        (address signer, , ) = getSigner(wlHash, sig);
        require(_whitelistSigners[signer], 'Invalid signature');
        _usedWhitelistHashes[wlHash] = true;

        _safeMint(_msgSender(), 1);
    }

    /**
    @dev Constructs the buffer that is hashed for validation with a minting
    signature.
     */
    function getHashToSign(address to, uint16 nonce)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(to, nonce));
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI() internal view override(BaseTokenURI, ERC721A) returns (string memory) {
        return BaseTokenURI._baseURI();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721ACommon, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    @dev Utility function to replace the funtionality provided to clients by ERC721Enumerable.
    Warning: Highly gas inefficient. Do not use as part of write operations.
     */
    function getTokensOfOwner(address addr) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(addr);
        uint256[] memory ownedTokens = new uint256[](balance);
        if (balance == 0) {
            return ownedTokens;
        }
        uint256 ownedTokenCount = 0;
        for (uint256 tokenId = 1; tokenId < totalSupply(); tokenId++) {
            if (ownerOf(tokenId) == addr) {
                ownedTokens[ownedTokenCount] = tokenId;
                ownedTokenCount++;
                if (ownedTokenCount == ownedTokenCount) {
                    break;
                }
            }
        }
        return ownedTokens;
    }
}