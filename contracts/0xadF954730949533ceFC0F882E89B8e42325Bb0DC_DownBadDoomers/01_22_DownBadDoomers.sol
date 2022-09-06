// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

                                                                                          
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
import '../base/SignatureVerifier.sol';

contract DownBadDoomers is ERC721ACommon, FixedPriceSeller, BaseTokenURI, SignatureVerifier {

    // signs whitelist mints
     mapping(address=>bool) public _whitelistSigners;

     // fixed royalty
        uint public _royaltyAmount;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(address payable beneficiary, address royaltyReceiver)
        ERC721ACommon('Down Bad Doomers', 'DOOMERS')
        BaseTokenURI('')
        FixedPriceSeller(
            0.05 ether,
            Seller.SellerConfig({
                 // total 1050 supply
                totalInventory: 975,
                lockTotalInventory: true,
                maxPerAddress: 0,
                maxPerTx: 10,
                freeQuota: 75,
                lockFreeQuota: true,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        _royaltyAmount = 500;
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

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (owner(), ((_salePrice * _royaltyAmount) / 10000));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721ACommon) returns (bool) {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
    
}