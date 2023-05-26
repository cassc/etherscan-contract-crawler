// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

// @author: aerois.dev
// dsc array#0007

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
//                                                ........       .......,,,,,,,,,,,  ///
//                                         .........................,,,,,,,,,,,,,**  ///
//                                       .......................,,,,,,,,,,,,*******  ///
//                                      ...............,,,,,,,,,,,,,,,*************  ///
//                                     .............,,,,,,,,,,,,,,***************//  ///
//                                   ..........,,,,,,,,,,,,,,,************/////////  ///
//                                   ......,,,,,,,,,,,,*************///////////////  ///
//                                  ....,,,,,,,,,,,,*************/////////////////(  ///
//                    . .....       ..,,,,,,,,,,************/////////////((((((((((  ///
//                    .................,,,,,,**********/////////////(((((((((((((((  ///
//                      ...........,,,,,,,,*********////////////(((((((((((((((((((  ///
//                      ......,,..,,************/////////((((((((((((((((((((((((((  ///
//                        ...,,,,..**,********////////(((((((((((((((((###(((((#(((  ///
//                         .,,,,,,*********/////////(((((((((((((((###########(((((  ///
//                       .. ,,,,********,**/////////(((((((((((((###############(#(  ///
//                       .. ,**,**********/////////((((((((#####################(((  ///
//                      ... .**,**////***//////////(((((((###################((((((  ///
//                   ....... .,**//////**//*////////(((((###################(((((((  ///
//                  .......  ..**////////********////(((((#################(((/////  ///
//              ..........    ./////////***,,,,,,****/((((###############((///*****  ///
//            ............ .. .////////*,.        .,,**//((#############((/**,       ///
//        ............... .,..((((///**             .*/*///####%%#####((/*.          ///
// ..     ............,,,, ,**.(((((///*.             ,/////((##%%%####((/           ///
// ..    ......,,,,,,,,,,.,((((,((((((///**,,,,,,,,***/**/(/((#%%%%%####((/*****,,,  ///
// ...   ....,,,,,,,,,,,.**(((((##((**,/(////////////((((##(/*(%%%%%%#%####((//////  ///
// ..    ...,,,,,,,,,,*.*//(##/####((**//((((((((((((###%%##%%%%%%%%%%%%%%%##((((((  ///
// ..    ...,,,,,,***,*//(###/#######(*//#############%%%%%%%%%%%%%%%%%%%%%%#######  ///
// ..     ..,,,,,,**.*/#########%%%%###(/(#########%%%%%%%%%%%%&&%%%%%%%%%%%%%%####  ///
//        ....,,,,,.*(########(%#%%%%%%##/(##%%%%%%%%%%%%%%%%&&&&&&&&%%%%%%%%%%%%%%  ///
//         ....,,,.((#######%%%(#%%%%%%%%#((#%%%%%%%%%%%%%&&&&&&&&&&&&&&&&&%%%%%%%%  ///
// ..       ....,,*((######%(/.(#%%%%&%%%%%%##%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&%%%%%%%  ///
// ....     ....,,/((####.******.#%%&&&&%%%%%%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&%%%%%%  ///
// ,,...      ..../((##*******/*/,%&&&&&&%%%%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%%  ///
// ,,,,...      ..,/(((*********//////(#&%&&&&&%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%  ///
// **,,,..,,,,..   *((#*********//////////&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%#  ///
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

contract MetaLegends is ERC721Enumerable, AccessControl, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    using Address for address payable;

    address private creatorAddr = 0xFD36e0798f12eB63715F7fed4E31d658617d2995;

    struct dutchAuctionParams {
        uint256 startTime;
        uint256 startPrice;
        uint256 reservePrice;
        uint256 priceStep;
        uint256 timeRange;
    }

    // Roles
    bytes32 private constant whitelistedRole = keccak256("wl");

    // Public parameters
    uint256 public maxSupply = 12345;
    uint256 public whitelistSupply = 1000;
    uint256 public publicSupply = 10726;
    uint256 public totalWhitelistClaimable = 1;
    uint256 public totalPublicSaleClaimable = 2;
    uint256 public totalWhitelistClaimed = 0;
    uint256 public totalPublicSaleClaimed = 0;
    uint256 public whitelistSalePrice = 0.3 ether;
    bool public whitelistSaleActivated = false;
    bool public publicSaleActivated = false;
    dutchAuctionParams public dutchAuction;

    // Public variables
    string public baseURI;
    mapping(address => uint256) public whitelistClaimed;
    mapping(address => uint256) public publicSaleClaimed;
    mapping(address => uint256) public givewaysClaimed;

    // Private variables
    Counters.Counter private _tokenIds;
    bool internal revealed = false;

    // Events
    event PublicSaleClaim(
        address indexed from,
        uint256 price,
        uint256 timestamp,
        uint256[] tokenIds
    );
    event WhitelistSaleClaim(
        address indexed from,
        uint256 timestamp,
        uint256[] tokenIds
    );
    event GivewayClaim(
        address indexed from,
        uint256 timestamp,
        uint256[] tokenIds
    );

    /**
    @dev Gives the owner of the contract the admin role
    */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setRoleAdmin(whitelistedRole, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// MODIFIERS

    /**
    @dev Modifier for only admins
     */
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Restricted to admins."
        );
        _;
    }

    /// PUBLIC FUNCTIONS

    /**
    @dev Withdraw balance of contract to The Creator
     */
    function withdrawAll() public onlyAdmin {
        payable(creatorAddr).sendValue(address(this).balance);
    }

    /**
    @dev Base URI setter
     */
    function _setBaseURI(string memory _newBaseURI) public onlyAdmin {
        baseURI = _newBaseURI;
    }

    /**
    @dev Returns token URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();
        if (!revealed) {
            return bytes(base).length > 0 ? string(abi.encodePacked(base)) : "";
        }
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString()))
                : "";
    }

    /**ip
    @dev Give current price of the dutch auction
     */
    function getPublicSalePriceFor(uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        require(publicSaleActivated, "Public sale is not active.");
        _timestamp = Math.max(_timestamp, dutchAuction.startTime);
        uint256 priceDiff = _timestamp
            .sub(dutchAuction.startTime)
            .div(dutchAuction.timeRange)
            .mul(dutchAuction.priceStep);
        if (priceDiff > dutchAuction.startPrice - dutchAuction.reservePrice) {
            return dutchAuction.reservePrice;
        }
        return dutchAuction.startPrice.sub(priceDiff);
    }

    /// EXTERNAL FUNCTIONS

    /**
    @dev Add an account as an admin of this contract
     */
    function addAdmin(address account) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
    @dev Remove an account as an admin of this contract
     */
    function removeAdmin(address account) external onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
    @dev Setter for the total of tokens claimable for whitelisted accounts
     */
    function setTotalWhitelistClaimable(uint256 _nb) external onlyAdmin {
        totalWhitelistClaimable = _nb;
    }

        /**
    @dev Setter for the total of tokens claimable for public sale
     */
    function setTotalPublicSaleClaimable(uint256 _nb) external onlyAdmin {
        totalPublicSaleClaimable = _nb;
    }
    /**
    @dev Setter for price of whitelist sale
     */
    function setWhitelistMintPrice(uint256 _nb) external onlyAdmin {
        whitelistSalePrice = _nb;
    }

    /**
    @dev Setter for whitelist supply
     */
    function setWhitelistSupply(uint256 _nb) external onlyAdmin {
        whitelistSupply = _nb;
    }

    /**
    @dev Setter for public sale supply
     */
    function setPublicSupply(uint256 _nb) external onlyAdmin {
        publicSupply = _nb;
    }

    /**
    @dev Grant whitelist role for given addresses
     */
    function addAddressesToWhitelist(address[] calldata addresses)
        external
        onlyAdmin
    {
        for (uint32 i = 0; i < addresses.length; i++) {
            grantRole(whitelistedRole, addresses[i]);
        }
    }

    /**
    @dev Remove given addresses from the whitelist role
     */
    function removeAddressesOfWhitelist(address[] calldata addresses)
        external
        onlyAdmin
    {
        for (uint32 i = 0; i < addresses.length; i++) {
            revokeRole(whitelistedRole, addresses[i]);
        }
    }

    /**
    @dev Active or deactivate whitelist sale
     */
    function flipWhitelistSale() external onlyAdmin {
        whitelistSaleActivated = !whitelistSaleActivated;
    }

    /**
    @dev Switch status of revealed
     */
    function flipRevealed() external onlyAdmin {
        revealed = !revealed;
    }

    /**
    @dev Activate the public sale as a dutch auction
     */
    function activatePublicSale(
        uint256 _start,
        uint256 _reserve,
        uint256 _step,
        uint256 _timeRange
    ) external onlyAdmin {
        require(_start > _reserve, "Invalid prices");
        require(
            _start != 0 && _reserve != 0 && _step != 0 && _timeRange != 0,
            "Invalid parameters"
        );
        publicSaleActivated = true;
        dutchAuction = dutchAuctionParams(
            block.timestamp,
            _start,
            _reserve,
            _step,
            _timeRange
        );
    }

    /**
    @dev Deactivate the public mint
     */
    function deactivatePublicSale() external onlyAdmin {
        publicSaleActivated = false;
    }

    /**
    @dev Mint for giveways
     */
    function givewayMint(address _to, uint256 _nb) external onlyAdmin {
        require(totalSupply().add(_nb) <= maxSupply, "Not enough tokens left.");

        uint256[] memory _tokenIdsMinted = new uint256[](_nb);
        for (uint32 i = 0; i < _nb; i++) {
            _tokenIdsMinted[i] = _mint(_to);
        }
        givewaysClaimed[_to] = givewaysClaimed[_to].add(_nb);
        emit GivewayClaim(_to, block.timestamp, _tokenIdsMinted);
    }

    /**
    @dev Mint for whitelisted address
     */
    function whitelistSaleMint(uint256 _nb)
        external
        payable
        onlyRole(whitelistedRole)
    {
        require(whitelistSaleActivated, "Whitelisted sale is not active.");
        require(totalSupply().add(_nb) <= maxSupply, "Not enough tokens left.");
        require(
            totalWhitelistClaimed.add(_nb) <= whitelistSupply,
            "Not enough supply."
        );
        require(
            msg.value >= whitelistSalePrice.mul(_nb),
            "Insufficient amount."
        );
        require(
            whitelistClaimed[msg.sender].add(_nb) <= totalWhitelistClaimable,
            "Limit exceeded."
        );

        uint256[] memory _tokenIdsMinted = new uint256[](_nb);
        for (uint32 i = 0; i < _nb; i++) {
            _tokenIdsMinted[i] = _mint(msg.sender);
        }
        totalWhitelistClaimed = totalWhitelistClaimed.add(_nb);
        whitelistClaimed[msg.sender] = whitelistClaimed[msg.sender].add(_nb);
        emit WhitelistSaleClaim(msg.sender, block.timestamp, _tokenIdsMinted);
    }

    /**
    @dev Public mint as a dutch auction
     */
    function publicSaleMint(uint256 _nb) external payable {
        require(publicSaleActivated, "Public sale is not active.");
        require(totalSupply().add(_nb) <= maxSupply, "Not enough tokens left.");
        require(
            totalPublicSaleClaimed.add(_nb) <= publicSupply,
            "Not enough supply."
        );
        uint256 currentTimestamp = block.timestamp;

        uint256 currentPrice = getPublicSalePriceFor(currentTimestamp);
        require(msg.value >= currentPrice.mul(_nb), "Insufficient amount.");
        require(
            publicSaleClaimed[msg.sender].add(_nb) <= totalPublicSaleClaimable,
            "Limit exceeded."
        );

        uint256[] memory _tokenIdsMinted = new uint256[](_nb);
        for (uint32 i = 0; i < _nb; i++) {
            _tokenIdsMinted[i] = _mint(msg.sender);
        }
        totalPublicSaleClaimed = totalPublicSaleClaimed.add(_nb);
        publicSaleClaimed[msg.sender] = publicSaleClaimed[msg.sender].add(_nb);
        emit PublicSaleClaim(
            msg.sender,
            currentPrice,
            currentTimestamp,
            _tokenIdsMinted
        );
    }

    /**
    @dev Check if an address is whitelisted
     */
    function isWhitelisted(address account) external view returns (bool) {
        return hasRole(whitelistedRole, account);
    }

    /**
    @dev Check if an address is admin
     */
    function isAdmin(address account) external view returns (bool) {
        return hasRole(whitelistedRole, account);
    }

    /// INTERNAL FUNCTIONS

    /**
    @dev Returns base token URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _mint(address _to) internal returns (uint256) {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();
        _safeMint(_to, _tokenId);
        return _tokenId;
    }

    /// Necessary overrides
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}