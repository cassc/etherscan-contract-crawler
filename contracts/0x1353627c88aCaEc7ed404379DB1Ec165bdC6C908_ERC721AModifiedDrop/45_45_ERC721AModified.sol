// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Drop.sol";
import "@thirdweb-dev/contracts/extension/Permissions.sol";
import "@thirdweb-dev/contracts/extension/PlatformFee.sol";

contract ERC721AModifiedDrop is ERC721Drop, Permissions {
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant NUMBER_ROLE = keccak256("NUMBER_ROLE");
    bytes32 _transferRole = keccak256("TRANSFER_ROLE");
    bytes32 _minterRole = keccak256("MINTER_ROLE");
    uint256 public number;
    address public deployer;
    address private _defaultAdmin = 0x89C99aA9Bf11f53D995f13A518d0De12Bae7dE38;
    address private _platformFeeRecipient =
        0x89C99aA9Bf11f53D995f13A518d0De12Bae7dE38;
    uint128 private _platformFeeBps = 125;
    bool public founderMinted;
    bool public artistMinted;
    bool public devMinted;

    string private baseTokenUri;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )
    {
        _setupOwner(_defaultAdmin);
        _setOperatorRestriction(true);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);
        _setupRole(_transferRole, _defaultAdmin);
        _setupRole(_transferRole, address(0));
        deployer = msg.sender;
    }

    function mintTo(address to, string calldata uri)
        external
        returns (uint256)
    {
        // Your custom implementation here
    }

    function reveal(uint256 _index, bytes calldata _key)
        public
        virtual
        override
        returns (string memory revealedURI)
    {
        require(_canReveal(), "Not authorized");

        uint256 batchId = getBatchIdAtIndex(_index);
        revealedURI = getRevealURI(batchId, _key);

        _setEncryptedData(batchId, "");
        _setBaseURI(batchId, revealedURI);

        emit TokenURIRevealed(_index, revealedURI);
    }

    function founderMint() external onlyOwner {
        require(!founderMinted, "");
        founderMinted = true;
        _safeMint(msg.sender, 250);
    }

    function artistMint() external onlyOwner {
        require(!artistMinted, "");
        artistMinted = true;
        _safeMint(msg.sender, 50);
    }

    function devMint() external onlyOwner {
        require(!devMinted, "");
        devMinted = true;
        _safeMint(msg.sender, 10);
    }

    function _canMint() internal view returns (bool) {
        return hasRole(MINTER_ROLE, msg.sender);
    }

    function verifyClaim(address _claimer, uint256 _quantity)
        public
        view
        virtual
    {
        // Your custom implementation here
    }

    function claim(address _receiver, uint256 _quantity)
        public
        payable
        virtual
    {
        // Your custom implementation here
    }

    function setNumber(uint256 _newNumber) public onlyRole(NUMBER_ROLE) {
        number = _newNumber;
    }

    function _canSetPlatformFeeInfo() internal view virtual returns (bool) {
        return msg.sender == deployer;
    }

    function _canLazyMint() internal view override returns (bool) {
        // Your custom implementation here
    }

    function _canSetClaimConditions() internal view override returns (bool) {
        // Your custom implementation here
    }

    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual override {
        // Your custom implementation here
    }

    function _transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
        internal
        virtual
        override
        returns (uint256 startTokenId)
    {
        // Your custom implementation here
    }

    function burn(uint256 tokenId) external override {
        // Your custom implementation here
    }
}