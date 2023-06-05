// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
contract ClashOfDragonz is ERC721Enumerable, ERC721Burnable, ERC721Pausable, Ownable {
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //______   __       ______   ______   __  __       ______   ______     _____    ______   ______   ______   ______   __   __   ______
    ///\  ___\ /\ \     /\  __ \ /\  ___\ /\ \_\ \     /\  __ \ /\  ___\   /\  __-. /\  == \ /\  __ \ /\  ___\ /\  __ \ /\ "-.\ \ /\___  \
    //\ \ \____\ \ \____\ \  __ \\ \___  \\ \  __ \    \ \ \/\ \\ \  __\   \ \ \/\ \\ \  __< \ \  __ \\ \ \__ \\ \ \/\ \\ \ \-.  \\/_/  /__
    //\ \_____\\ \_____\\ \_\ \_\\/\_____\\ \_\ \_\    \ \_____\\ \_\      \ \____- \ \_\ \_\\ \_\ \_\\ \_____\\ \_____\\ \_\\"\_\ /\_____\
    //\/_____/ \/_____/ \/_/\/_/ \/_____/ \/_/\/_/     \/_____/ \/_/       \/____/  \/_/ /_/ \/_/\/_/ \/_____/ \/_____/ \/_/ \/_/ \/_____/
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////made by Link42///////////////


    // Usings

    // Pricing and supply
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant WHITELIST_PRICE = 0.05 ether;
    uint256 public constant PUBLIC_PRICE = 0.07 ether;
    uint256 public constant PUBLIC_PRICE_OF_3 = 0.18 ether;
    uint256 public constant PUBLIC_PRICE_OF_5 = 0.25 ether;
    uint256 public constant PUBLIC_PRICE_OVER_5_PER_NFT = 0.05 ether;
    uint256 public constant PRESALES_PRICE = 0.06 ether;
    uint256 public NUMBER_OF_RESERVED_DRAGONZ;

    // *knock knock*
    // "who's there?"
    // housekeeping!
    uint256 currentIndex = 1;
    bool public _revealed;
    bool public _private_sale_open;
    bool public _public_sale_open;
    bool public _frozen;

    // will be updated later on obviously :)
    // if you want to know; this is used for the whitelist
    bytes32 public merkleRoot;
    // to make it easier to do some housekeeping
    mapping(address => bool) devAddresses;

    // One URI to rule them all
    string public baseTokenURI = "ipfs://QmcjoNXm8EFgqGyqCELDp6C576juDmgWR8xnpW7gym1rHq/";

    constructor() ERC721("ClashOfDragonz", "COFDT")
    {
    }

    /**
     * @notice Update the list of whitelisted users
     */
    function setMerkleRootForWhitelist(bytes32 _merkleRoot) public ownerOrDevAccessOnly {
        merkleRoot = _merkleRoot;
    }

    function addDevAddress(address _dev) public onlyOwner {
        devAddresses[_dev] = true;
    }

    // We only use this function from SafeMath so no need to import the full library :)
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    // Overrides because we import ERC721 multiple times
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    ///////////////
    // Modifiers //
    ///////////////


    // Function to check if the contract is unfrozen, when it's frozen, it's cold and you can't heat it up anymore
    // All crazyness on a stick, this is a watchdog to make sure that once all is revealed, even the owner can not change the baseURI etc.
    modifier unfrozen() {
        require(!_frozen, "The contract is frozen");
        _;
    }

    modifier saleIsOpen() {
        require(_public_sale_open || _private_sale_open, "Sale is not open!");
        _;
    }

    // Check if all requirements to mint when being on a whitelist are met
    modifier mintRequirementsWhitelist(uint256 count) {
        require((currentIndex + count) <= MAX_SUPPLY + 1, "Not enough Dragonz left!");
        require(msg.value >= mul(WHITELIST_PRICE, count), "Not enough ether to purchase dragons when whitelisted");
        _;
    }

    // Modifier for house keeping stuff
    modifier ownerOrDevAccessOnly {
        require(_msgSender() == owner() || devAddresses[_msgSender()], "Only access for owner or dev.");
        _;
    }

    // This acts de facto as a pricing table
    modifier mintRequirementsSale(uint256 count) {
        require((currentIndex + count) <= MAX_SUPPLY + 1, "Not enough Dragonz left!");

        uint256 price = PUBLIC_PRICE;

        if (_private_sale_open) {
            require(_private_sale_open, "Private sale needs to be open!");
            price = PRESALES_PRICE;
        } else {
            require(_public_sale_open, "Public sale needs to be open!");
        }

        if (count == 1) {
            // Public sale - 1 NFT - 0.07
            require(msg.value >= price, "Not enough ether to purchase the Dragonz.");
        } else if (count == 2) {
            // Public sale - 2 NFT - 0.14
            require(msg.value >= mul(price, 2), "Not enough ether to purchase the Dragonz.");
        } else if (count == 3) {
            // You pay 0.18
            require(msg.value >= PUBLIC_PRICE_OF_3, "Not enough ether to purchase the Dragonz.");
        } else if (count == 4) {
            // You pay 0.18 + 0.07 = 0.25, but hey, you can buy 5 for the same price...
            // If private sale; you pay 0.18 + 0.06 = 0.24, I still would buy 5...
            require(msg.value >= (price + PUBLIC_PRICE_OF_3), "Not enough ether to purchase the Dragonz.");
        } else if (count == 5) {
            // You pay 0.25; the discounted price for 5
            require(msg.value >= PUBLIC_PRICE_OF_5, "Not enough ether to purchase the Dragonz.");
        } else if (count > 5) {
            require(msg.value >= mul(PUBLIC_PRICE_OVER_5_PER_NFT, count), "Not enough ether to purchase the Dragonz.");
        }
        _;
    }

    /**
     * @notice Checks if an addresses is on the whitelist
     */
    modifier whitelistOnly(bytes32[] calldata _merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Address is not on the whitelist!");
        _;
    }

    // end of modifiers :)

    /**
     * @notice Reserve NFTs for promotions, marketing
     */
    function reserveNFTs(uint256 numberToReserve) external onlyOwner unfrozen {
        uint256 totalMinted = currentIndex;
        require((totalMinted + numberToReserve) < MAX_SUPPLY + 1, "There are not enough NFTs remaining to reserve");
        _internalMintMultiple(msg.sender, numberToReserve);
        NUMBER_OF_RESERVED_DRAGONZ = NUMBER_OF_RESERVED_DRAGONZ + numberToReserve;
    }

    /**
     * @notice Let's hatch the eggs! After reveal and all is ok, contract should be frozen by using the freeze command.
     */
    function revealNFTs(string memory _metadataURI) public ownerOrDevAccessOnly unfrozen {
        baseTokenURI = _metadataURI;
        _revealed = true;
    }

    /**
     * @notice Open the doors! (or close them)
     */
    function togglePublicSaleActive() external unfrozen ownerOrDevAccessOnly {
        _public_sale_open = !_public_sale_open;
    }

    /**
     * @notice Open the VIP doors :)
     */
    function togglePrivateSaleActive() external unfrozen ownerOrDevAccessOnly {
        _private_sale_open = !_private_sale_open;
    }

    /**
     * @notice Get's the base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Set the base URI, only when contract is unfrozen, after reveal, frozen will be called.
     */
    function setBaseURI(string memory _baseTokenURI) public unfrozen ownerOrDevAccessOnly {
        baseTokenURI = _baseTokenURI;
    }

    // Use the force wisely!
    // Once frozen, contract is set in stone!
    /**
     * @notice Freezes the contract so base URI can't be changed anymore
     */
    function freezeAll() external ownerOrDevAccessOnly unfrozen {
        _frozen = true;
    }

    // If you burn it, it's gone. Can't apply water. It's really gone.
    /**
     * @notice Burn NFTs, let's hope this is not needed :)
     */
    function theBurn(uint256[] memory tokenIds) external ownerOrDevAccessOnly unfrozen {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.

     */

    function pause() public virtual ownerOrDevAccessOnly {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.

     */
    function unpause() public virtual ownerOrDevAccessOnly {
        _unpause();
    }

    ///////////////////////////////
    // Enter the Dragon Dungeon! //
    ///////////////////////////////
    /**
     * @notice Minting for whitelisted people only
       to be able to mint you need to register on the discord and follow the steps to be whitelisted.
       While you're here, here is a little something to think about;
       There are 10 types of people in the world, those who understand binary and those who don't.
       If you are reading this, head over to our discord and tell us this in the #support channel to also get whitelisted:
       *** Beam me up Scotty! ***
     */
    function mintDragonsWhitelisted(uint256 count, bytes32[] calldata _merkleProof)
        external
        payable
        unfrozen
        saleIsOpen
        whitelistOnly(_merkleProof)
        mintRequirementsWhitelist(count)
    {
        _internalMintMultiple(msg.sender, count);
    }

    /**
     * @notice Release the krak..- dragon eggs :)
     */
    function mintDragons(uint256 count) external payable unfrozen mintRequirementsSale(count) {
        _internalMintMultiple(msg.sender, count);
    }

    function _internalMintMultiple(address to, uint256 count) private {
        uint256 newTokenID = currentIndex;
        for (uint256 i = 0; i < count; i++) {
            _safeMint(to, newTokenID);
            newTokenID++;
        }
        currentIndex = newTokenID;
    }

    function gift(address to, uint256 amount) external onlyOwner {
        require((currentIndex + amount) <= MAX_SUPPLY + 1, "Not enough Dragonz left!");
        _internalMintMultiple(to, amount);
    }

    /**
     * @notice Will be used later for utility and some nice airdrops :)
     */
    function tokensOfOwner(address _owner)
    external
    view
    returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
     * @notice Withdraw the balance, only the contract owner can do this obviously.
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}