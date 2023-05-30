// SPDX-License-Identifier: MIT
// Smart Contract Written by: Ian Olson

/*

    ____                      __               ______                                __
   / __ )________  ____  ____/ /___ _____     / ____/__  _________  ____ _____  ____/ /__  ______
  / __  / ___/ _ \/ __ \/ __  / __ `/ __ \   / /_  / _ \/ ___/ __ \/ __ `/ __ \/ __  / _ \/ ___(_)
 / /_/ / /  /  __/ / / / /_/ / /_/ / / / /  / __/ /  __/ /  / / / / /_/ / / / / /_/ /  __(__  )
/_____/_/   \___/_/ /_/\__,_/\__,_/_/ /_/  /_/    \___/_/  /_/ /_/\__,_/_/ /_/\__,_/\___/____(_)
  / ___/____  __  ___   _____  ____  (_)____
  \__ \/ __ \/ / / / | / / _ \/ __ \/ / ___/
 ___/ / /_/ / /_/ /| |/ /  __/ / / / / /
/____/\____/\__,_/ |___/\___/_/ /_/_/_/

We are not moving our lives into the digital space any more than we moved our lives into the tactile space with the
advent of woodblock printing in the 9th century. The digital is not infinite or transcendent, but maybe we can use it to
create systems in our material world that are. It is our duty not to shy away from new spaces, but to transform them
into new possibilities; something that reflects our own visions.

In 2010 Brendan Fernandes began to investigate ideas of “authenticity” explored through the dissemination of Western
notions of an exotic Africa through the symbolic economy of "African" masks. These masks were removed from their place
of origin and displayed in the collections of museums such as The Metropolitan Museum of Art. They lost their
specificity and cultural identity as they became commodifiable objects, bought and sold in places like Canal Street in
New York City.

In traditional West African masquerade when the performer puts on the mask, it becomes a bridge between the human and
spiritual realms. The work examines the  authenticity of these objects in the context of Western museums where they have
been placed at rest and serve as exotified objects as opposed to serving their original aforementioned spiritual purpose.

In Fernandes’ genesis NFT project he is coming back to this work and thinking through the mask as an object that is
still in flux and that lives within a cryptographic and digital space.  Conceptually in this new work the masks now take
on an alternate form of existence as we re-imbue them with the ability to morph and change in both physical form as well
as economic value. The piece is constantly in a state of becoming and in that it can be seen as a take away or a
souvenir. These NFT masks take inspiration from three specific masks housed in the Metropolitan Museum's African
collection. The artist has scanned different materials: Gold, Textiles, Wood and Shells to create layers that will
become the foundation of these “new” masks.

*/

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IRaribleRoyaltiesV2.sol";
import "./libraries/StringsUtil.sol";

contract Souvenir is Ownable, ERC721, IRaribleRoyaltiesV2 {
    using SafeMath for uint256;

    // ---
    // Constants
    // ---

    uint256 constant public imnotArtInitialSaleBps = 2860; // 28.6%
    uint256 constant public royaltyFeeBps = 1000; // 10%
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_RARIBLE_ROYALTIES = 0xcad96cca; // bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca

    // ---
    // Events
    // ---

    event Mint(uint256 indexed tokenId, string metadata, address indexed owner);
    event Payout(address indexed to, uint256 indexed value);
    event Refund(address indexed to, uint256 indexed value);

    // ---
    // Properties
    // ---

    string public contractUri;
    string public metadataBaseUri;
    address public royaltyContractAddress;
    address public imnortArtPayoutAddress;
    address public artistPayoutAddress;

    uint256 public nextTokenId = 0;
    uint256 public maxPerAddress = 10;
    uint256 public invocations = 0;
    uint256 public maxInvocations = 1000;
    uint256 public mintPriceInWei = 100000000000000000; // 0.1 ETH
    bool public active = false;
    bool public presale = true;
    bool public paused = false;
    bool public completed = false;

    // ---
    // Mappings
    // ---

    mapping(address => bool) public isAdmin;
    mapping(address => bool) private isPresaleWallet;
    mapping(uint256 => bool) private tokenIdMinted;

    // ---
    // Modifiers
    // ---

    modifier onlyValidTokenId(uint256 tokenId) {
        require(_exists(tokenId), "Token ID does not exist.");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[_msgSender()], "Only admins.");
        _;
    }

    modifier onlyActive() {
        require(active, "Minting is not active.");
        _;
    }

    modifier onlyNonPaused() {
        require(!paused, "Minting is paused.");
        _;
    }

    // ---
    // Constructor
    // ---

    constructor(address _royaltyContractAddress) ERC721("Brendan Fernandes Souvenir", "SOUVENIR") {
        royaltyContractAddress = _royaltyContractAddress;

        // Defaults
        contractUri = 'https://ipfs.imnotart.com/ipfs/QmZTPfna2V16oqqdsZz7SQNcqtSgkk3DxRHKdYqHFHiH7Y';
        metadataBaseUri = 'https://ipfs.imnotart.com/ipfs/QmXdiQriG11LQoNfrZrCdWwxa5CdDVYCEMGgZGEQJKxutf/';

        artistPayoutAddress = address(0x711c0385795624A338E0399863dfdad4523C46b3); // Brendan Fernandes Address
        imnortArtPayoutAddress = address(0x12b66baFc99D351f7e24874B3e52B1889641D3f3); // imnotArt Gnosis Safe

        // Add admins
        isAdmin[_msgSender()] = true;
        isAdmin[imnortArtPayoutAddress] = true;
        isAdmin[artistPayoutAddress] = true;

        // Mint the artist proof
        uint256 tokenId = nextTokenId;
        _mint(artistPayoutAddress, tokenId);
        invocations = invocations.add(1);
        emit Mint(tokenId, tokenURI(tokenId), artistPayoutAddress);

        // Setup the next tokenId
        nextTokenId = nextTokenId.add(1);
    }

    // ---
    // Supported Interfaces
    // ---

    // @dev Return the support interfaces of this contract.
    // @author Ian Olson
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165
        || interfaceId == _INTERFACE_RARIBLE_ROYALTIES
        || interfaceId == _INTERFACE_ID_ERC721
        || interfaceId == _INTERFACE_ID_ERC721_METADATA
        || interfaceId == _INTERFACE_ID_EIP2981
        || super.supportsInterface(interfaceId);
    }

    // ---
    // Minting
    // ---

    // @dev Mint a new token from the contract.
    // @author Ian Olson
    function mint(uint quantity) public payable onlyActive onlyNonPaused {
        require(quantity <= 10, "Max limit per transaction is 10.");

        if (presale) {
            require(isPresaleWallet[_msgSender()], "Wallet is not part of pre-sale.");
        }

        uint256 requestedInvocations = invocations.add(quantity);
        require(requestedInvocations <= maxInvocations, "Must not exceed max invocations.");
        require(msg.value >= (mintPriceInWei * quantity), "Must send minimum value.");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = nextTokenId;
            _mint(_msgSender(), tokenId);
            emit Mint(tokenId, tokenURI(tokenId), _msgSender());

            // Setup the next tokenId
            nextTokenId = nextTokenId.add(1);
        }

        invocations = invocations.add(quantity);

        uint256 balance = msg.value;
        uint256 refund = balance.sub((mintPriceInWei * quantity));
        if (refund > 0) {
            balance = balance.sub(refund);
            payable(_msgSender()).transfer(refund);
            emit Refund(_msgSender(), refund);
        }

        // Payout imnotArt
        uint256 imnotArtPayout = SafeMath.div(SafeMath.mul(balance, imnotArtInitialSaleBps), 10000);
        if (imnotArtPayout > 0) {
            balance = balance.sub(imnotArtPayout);
            payable(imnortArtPayoutAddress).transfer(imnotArtPayout);
            emit Payout(imnortArtPayoutAddress, imnotArtPayout);
        }

        // Payout Artist
        payable(artistPayoutAddress).transfer(balance);
        emit Payout(artistPayoutAddress, balance);
    }

    // ---
    // Update Functions
    // ---

    // @dev Add an admin to the contract.
    // @author Ian Olson
    function addAdmin(address adminAddress) public onlyAdmin {
        isAdmin[adminAddress] = true;
    }

    // @dev Remove an admin from the contract.
    // @author Ian Olson
    function removeAdmin(address adminAddress) public onlyAdmin {
        require((_msgSender() != adminAddress), "Cannot remove self.");

        isAdmin[adminAddress] = false;
    }

    // @dev Update the contract URI for the contract.
    // @author Ian Olson
    function updateContractUri(string memory updatedContractUri) public onlyAdmin {
        contractUri = updatedContractUri;
    }

    // @dev Update the artist payout address.
    // @author Ian Olson
    function updateArtistPayoutAddress(address _payoutAddress) public onlyAdmin {
        artistPayoutAddress = _payoutAddress;
    }

    // @dev Update the imnotArt payout address.
    // @author Ian Olson
    function updateImNotArtPayoutAddress(address _payoutAddress) public onlyAdmin {
        imnortArtPayoutAddress = _payoutAddress;
    }

    // @dev Update the royalty contract address.
    // @author Ian Olson
    function updateRoyaltyContractAddress(address _payoutAddress) public onlyAdmin {
        royaltyContractAddress = _payoutAddress;
    }

    // @dev Update the base URL that will be used for the tokenURI() function.
    // @author Ian Olson
    function updateMetadataBaseUri(string memory _metadataBaseUri) public onlyAdmin {
        metadataBaseUri = _metadataBaseUri;
    }

    // @dev Bulk add wallets to pre-sale list.
    // @author Ian Olson
    function bulkAddPresaleWallets(address[] memory presaleWallets) public onlyAdmin {
        require(presaleWallets.length > 1, "Use addPresaleWallet function instead.");
        uint amountOfPresaleWallets = presaleWallets.length;
        for (uint i = 0; i < amountOfPresaleWallets; i++) {
            isPresaleWallet[presaleWallets[i]] = true;
        }
    }

    // @dev Add a wallet to pre-sale list.
    // @author Ian Olson
    function addPresaleWallet(address presaleWallet) public onlyAdmin {
        isPresaleWallet[presaleWallet] = true;
    }

    // @dev Remove a wallet from pre-sale list.
    // @author Ian Olson
    function removePresaleWallet(address presaleWallet) public onlyAdmin {
        require((_msgSender() != presaleWallet), "Cannot remove self.");

        isPresaleWallet[presaleWallet] = false;
    }

    // @dev Update the max invocations, this can only be done BEFORE the minting is active.
    // @author Ian Olson
    function updateMaxInvocations(uint256 newMaxInvocations) public onlyAdmin {
        require(!active, "Cannot change max invocations after active.");
        maxInvocations = newMaxInvocations;
    }

    // @dev Update the mint price, this can only be done BEFORE the minting is active.
    // @author Ian Olson
    function updateMintPriceInWei(uint256 newMintPriceInWei) public onlyAdmin {
        require(!active, "Cannot change mint price after active.");
        mintPriceInWei = newMintPriceInWei;
    }

    // @dev Update the max per address, this can only be done BEFORE the minting is active.
    // @author Ian Olson
    function updateMaxPerAddress(uint newMaxPerAddress) public onlyAdmin {
        require(!active, "Cannot change max per address after active.");
        maxPerAddress = newMaxPerAddress;
    }

    // @dev Enable pre-sale on the mint function.
    // @author Ian Olson
    function enableMinting() public onlyAdmin {
        active = true;
    }

    // @dev Enable public sale on the mint function.
    // @author Ian Olson
    function enablePublicSale() public onlyAdmin {
        presale = false;
    }

    // @dev Toggle the pause state of minting.
    // @author Ian Olson
    function toggleMintPause() public onlyAdmin {
        paused = !paused;
    }

    // ---
    // Get Functions
    // ---

    // @dev Get the token URI. Secondary marketplace specification.
    // @author Ian Olson
    function tokenURI(uint256 tokenId) public view override virtual onlyValidTokenId(tokenId) returns (string memory) {
        return StringsUtil.concat(metadataBaseUri, StringsUtil.uint2str(tokenId));
    }

    // @dev Get the contract URI. OpenSea specification.
    // @author Ian Olson
    function contractURI() public view virtual returns (string memory) {
        return contractUri;
    }

    // ---
    // Withdraw
    // ---

    // @dev Withdraw ETH funds from the given contract with a payout address.
    // @author Ian Olson
    function withdraw(address to) public onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount > 0, "Contract balance empty.");
        payable(to).transfer(amount);
    }

    // ---
    // Secondary Marketplace Functions
    // ---

    // @dev Rarible royalties V2 implementation.
    // @author Ian Olson
    function getRaribleV2Royalties(uint256 id) external view override onlyValidTokenId(id) returns (LibPart.Part[] memory) {
        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0] = LibPart.Part({
        account : payable(royaltyContractAddress),
        value : uint96(royaltyFeeBps)
        });

        return royalties;
    }

    // @dev EIP-2981 royalty standard implementation.
    // @author Ian Olson
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view onlyValidTokenId(tokenId) returns (address receiver, uint256 amount) {
        uint256 royaltyPercentageAmount = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
        return (royaltyContractAddress, royaltyPercentageAmount);
    }
}