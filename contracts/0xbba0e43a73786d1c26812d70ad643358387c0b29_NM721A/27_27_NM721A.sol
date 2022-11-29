// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@      @@@@@@@@@@@@   @@@@@@@@*   @@@@@@@@                   @@@                      @@@@    &@@@@@@@@@@@@    @@@@@@
// @@@@@       @@@@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@    @@@@@@@@@@    @@@@@@@
// @@@@@   #@    @@@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@.   @@@@@@@    @@@@@@@@@
// @@@@@   #@@    @@@@@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@    @@@@    @@@@@@@@@@
// @@@@@   #@@@@    @@@@@@   @@@@@@@@*   @@@@@@@@                 @@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@   &    @@@@@@@@@@@@
// @@@@@   #@@@@@    @@@@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@     *@@@@@@@@@@@@@
// @@@@@   #@@@@@@@    @@@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@   &@   @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@       @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@   #@@@@@@@@@@@@     @@@@@@@@*   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@                                                                                                                   @@@
// @@@  @@@@@@@@         [email protected]@@@@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@       @@@@@*        &@@@@@@@@@@@@       @@@
// @@@  @@@@@@@@@        @@@@@@@@@    @@@@@@          @@@@@     @@@@@@@@@@@@@@@@@@     @@@@@*     /@@@@@@@@@@@@@@@@@@    @@@
// @@@  @@@@@*@@@,      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@          @@@@@    @@@@@*    @@@@@@,        @@@@@@   @@@
// @@@  @@@@@ @@@@      @@@@ @@@@@    @@@@@@          @@@@@    @@@@@                   @@@@@*   @@@@@@           @@@@@@  @@@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@    %@@@@@@@@@@@            @@@@@*   @@@@@                    @@@
// @@@  @@@@@  @@@@    @@@@  @@@@@    @@@@@@          @@@@@       @@@@@@@@@@@@@@@@     @@@@@*  &@@@@@                    @@@
// @@@  @@@@@   @@@@  @@@@   @@@@@    @@@@@@          @@@@@               @@@@@@@@@@   @@@@@*   @@@@@                    @@@
// @@@  @@@@@   @@@@ ,@@@    @@@@@    @@@@@@          @@@@@   @@@@@@           @@@@@   @@@@@*   @@@@@@           @@@@@@  @@@
// @@@  @@@@@    @@@@@@@@    @@@@@    @@@@@@@        @@@@@@    @@@@@#         ,@@@@@   @@@@@*    @@@@@@@        @@@@@@   @@@
// @@@  @@@@@    &@@@@@@     @@@@@     /@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@    @@@@@*      @@@@@@@@@@@@@@@@@     @@@
// @@@  @@@@@     @@@@@@     @@@@@        @@@@@@@@@@@@@            @@@@@@@@@@@@@       @@@@@*         @@@@@@@@@@@*       @@@
// @@@                                                                                                                   @@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/utils/StringsUpgradeable.sol";
import 'erc721a-upgradeable/ERC721AUpgradeable.sol';
import "closedsea/OperatorFilterer.sol";

contract NM721A is 
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ERC721AUpgradeable,
    OperatorFilterer,
    ERC2981Upgradeable,
    PaymentSplitterUpgradeable
{
    using StringsUpgradeable for uint256;

    // ROLES

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    string public baseTokenURI; // Can be combined with the tokenId to create the metadata URI
    uint256 public maxTotalSupply;

    event SetBaseURI(address _from);

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {     
        _disableInitializers();
    }
    
    function initialize(
        address owner,
        string memory _baseUri, 
        string memory _name, 
        string memory _symbol, 
        uint256 _maxTotalSupply,
        address[] memory _payees, 
        uint256[] memory _shares
    ) public initializer initializerERC721A {
        __UUPSUpgradeable_init();
        __ERC721A_init(_name, _symbol);
        __AccessControl_init();
        _registerForOperatorFiltering();
        __ERC2981_init();
        __PaymentSplitter_init(_payees, _shares);
        _setDefaultRoyalty(address(this), 1000);
        baseTokenURI = _baseUri;
        maxTotalSupply = _maxTotalSupply;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function mint(address _recipient, uint256 _quantity) external onlyRole(MINTER_ROLE) {
        require(totalSupply() + _quantity <= maxTotalSupply, "Max supply is reached");
        require(_quantity > 0, "Mint amount can't be zero");

        _safeMint(_recipient, _quantity);
    }

    // SETTER FUNCTIONS

    // Allows the contract owner to set a new base URI string
    function setBaseURI(string calldata _baseURI) external onlyRole(ADMIN_ROLE) {
        baseTokenURI = _baseURI;
        emit SetBaseURI(msg.sender);
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    // OVERRIDES

    // Overrides the tokenURI function so that the base URI can be returned
    function tokenURI(uint256 _tokenId) public view override(ERC721AUpgradeable) returns (string memory) {
        string memory baseURI = baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, ERC2981Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return ERC721AUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {   
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}