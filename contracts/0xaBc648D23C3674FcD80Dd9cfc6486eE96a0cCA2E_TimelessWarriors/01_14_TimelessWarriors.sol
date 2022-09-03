// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/**
___________.__               .__                          __      __                     .__                     
\__    ___/|__| _____   ____ |  |   ____   ______ ______ /  \    /  \_____ ______________|__| ___________  ______
  |    |   |  |/     \_/ __ \|  | _/ __ \ /  ___//  ___/ \   \/\/   /\__  \\_  __ \_  __ \  |/  _ \_  __ \/  ___/
  |    |   |  |  Y Y  \  ___/|  |_\  ___/ \___ \ \___ \   \        /  / __ \|  | \/|  | \/  (  <_> )  | \/\___ \ 
  |____|   |__|__|_|  /\___  >____/\___  >____  >____  >   \__/\  /  (____  /__|   |__|  |__|\____/|__|  /____  >
                    \/     \/          \/     \/     \/         \/        \/                                  \/ 

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC2981.sol";

contract TimelessWarriors is ERC721, ERC2981, Ownable {
    using Strings for uint256;

    uint256 public constant NUMBER_OF_TWX = 14888;
    uint256 public constant NUMBER_OF_RESERVED_TWX = 500;

    uint256 public maxPerTx = 11;
    uint256 public maxAllowedPerAddress = 6;

    uint256 public mintPrice = 0.8 ether;
    uint256 public supplyLimit;
    uint256 public burned;

    uint256 private _totalSupply = 1;

    string private _defaultUri;
    string private _tokenBaseURI;

    address private adminSigner;
    address private ewallet;
    address private twxAccount;

    enum SalePhase {
        Locked,
        PreSale,
        PublicSale,
        LimitedSale
    }

    SalePhase public phase = SalePhase.Locked;
    bool public metadataIsFrozen = false;

    mapping(address => bool) public proxyToApproved;
    mapping(address => uint256) public addressToMinted;
    mapping(address => uint256) public addressToMintedLimited;

    constructor(
        string memory _baseURI,
        address _royaltyRecipient,
        address _adminSigner,
        address _ewallet,
        address _twxAccount
    ) ERC721("Timeless Warriors", "TWX") {
        _defaultUri = _baseURI;
        _setRoyalties(_royaltyRecipient, 1000); // 10% royalties
        setAdminSigner(_adminSigner);
        setEwallet(_ewallet);
        twxAccount = _twxAccount;
    }

    // ======================================================== Owner Functions

    /// Set the adminSigner address
    function setAdminSigner(address _adminSigner) public onlyOwner {
        adminSigner = _adminSigner;
    }

    /// Set the collection royalties
    function setRoyalties(address _recipient, uint256 _value) public onlyOwner {
        _setRoyalties(_recipient, _value);
    }

    /// Set communication pipeline between contracts
    function flipProxyState(address proxyAddress) external onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    /// Set the base URI for the metadata
    /// @dev modifies the state of the `_tokenBaseURI` variable
    /// @param URI the URI to set as the base token URI
    function setBaseURI(string memory URI) external onlyOwner {
        require(!metadataIsFrozen, "TW: Metadata is permanently frozen");
        _tokenBaseURI = URI;
    }

    /// Freezes the metadata
    /// @dev sets the state of `metadataIsFrozen` to true
    /// @notice permamently freezes the metadata so that no more changes are possible
    function freezeMetadata() external onlyOwner {
        require(!metadataIsFrozen, "TW: Metadata is already frozen");
        metadataIsFrozen = true;
    }

    /// @dev Modifies the state of the `supplyLimit`
    /// @param _supplyLimit The new amount of presale supply limit of TimelessWarriors
    function setSupplyLimit(uint256 _supplyLimit) external onlyOwner {
        supplyLimit = _supplyLimit;
    }

    /// @dev Modifies the state of the `maxPerTx`
    function updateMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    /// @dev Modifies the state of the `maxAllowedPerAddress`
    function updateMaxAllowedPerAddress(uint256 _maxAllowedPerAddress)
        external
        onlyOwner
    {
        maxAllowedPerAddress = _maxAllowedPerAddress;
    }

    /// Adjust the mint prices
    /// @dev modifies the state of the `mintPrice` variables
    /// @notice sets the price for minting a token
    /// @param _newPrice The new price for minting of TimelessWarriors
    function adjustMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    /// Update Phase
    /// @dev Update the sale phase state
    function enterPhase(SalePhase _phase) external onlyOwner {
        phase = _phase;
    }

    /// Allows to configure sale phase
    function configureSalephase(
        SalePhase _phase,
        uint256 _newPrice,
        uint256 _supplyLimit
    ) external onlyOwner {
        phase = _phase;
        mintPrice = _newPrice;
        supplyLimit = _supplyLimit;
    }

    /// Set the e-wallet address
    function setEwallet(address _ewallet) public onlyOwner {
        ewallet = _ewallet;
    }

    /// Set the twx account address
    function setTwxAccount(address _twxAccount) external {
        require(_msgSender() == twxAccount, "TW: Not allowed");
        twxAccount = _twxAccount;
    }

    /// @dev Withdraw funds to the address
    /// @param fundsReceiver address of funds receiver
    function withdraw(address fundsReceiver) external payable {
        require(_msgSender() == twxAccount, "TW: Not allowed");
        (bool success, ) = payable(fundsReceiver).call{
            value: address(this).balance
        }("");
        require(success, "TW: Withdraw failed");
    }

    // ======================================================== External Functions

    /// Mint TimelessWarriors during presale
    /// @dev mints by addresses
    /// @param count number of tokens to mint in transaction
    /// @notice mints tokens with counter token IDs to addresses eligible for presale
    /// @notice tokens number of presale mints allowed is maxAllowedPerAddress - 1
    /// @notice supplyLimit updates during all presale iterations, supplyLimit <= NUMBER_OF_TWX - NUMBER_OF_RESERVED_TWX
    function presaleMintTWX(uint256 count, bytes calldata signature)
        external
        payable
    {
        require(phase == SalePhase.PreSale, "TW: Presale event is not active.");
        _validateSignature(signature);
        require(
            mintPrice * count == msg.value,
            "TW: Ether value sent is not correct"
        );
        require(
            addressToMinted[_msgSender()] + count < maxAllowedPerAddress,
            "TW: Exceeds number of presale mints allowed."
        );
        if (supplyLimit > 0) {
            require(
                _totalSupply + count <= supplyLimit,
                "TW: Exceeds max presale supply of TimelessWarriors."
            );
        }
        require(
            _totalSupply + count <= NUMBER_OF_TWX - NUMBER_OF_RESERVED_TWX,
            "TW: Exceeds max supply of TimelessWarriors."
        );

        addressToMinted[_msgSender()] += count;
        _mintTimelessWarriors(_msgSender(), count);
    }

    /// @dev Mints tokens during public sale
    /// @param count number of tokens to mint in transaction
    /// @notice tokens number per transaction is maxPerTx - 1
    function publicMintTWX(uint256 count) external payable {
        require(
            phase == SalePhase.PublicSale,
            "TW: Public sale is not active."
        );
        require(
            mintPrice * count == msg.value,
            "TW: Ether value sent is not correct"
        );
        require(
            _totalSupply + count <= NUMBER_OF_TWX - NUMBER_OF_RESERVED_TWX,
            "TW: Exceeds max supply of TimelessWarriors."
        );
        require(count < maxPerTx, "TW: Exceeds max per transaction.");

        _mintTimelessWarriors(_msgSender(), count);
    }

    /// @dev Mints tokens during limited sale
    /// @param count number of tokens to mint in transaction
    /// @notice tokens number of presale mints allowed is maxAllowedPerAddress - 1
    function reserveMintTWX(uint256 count, bytes calldata signature)
        external
        payable
    {
        require(
            phase == SalePhase.LimitedSale,
            "TW: Limited sale is not active."
        );
        _validateSignature(signature);
        require(
            mintPrice * count == msg.value,
            "TW: Ether value sent is not correct"
        );
        require(
            addressToMintedLimited[_msgSender()] + count < maxAllowedPerAddress,
            "TW: Exceeds number of mints allowed."
        );
        require(
            _totalSupply + count <= NUMBER_OF_TWX,
            "TW: Exceeds max supply of TimelessWarriors."
        );

        addressToMintedLimited[_msgSender()] += count;
        _mintTimelessWarriors(_msgSender(), count);
    }

    /// @dev Mints tokens during presale with e-wallet
    /// @param to address to mint in transaction
    /// @param count number of tokens to mint in transaction
    function presaleMintTWXWithEwallet(address to, uint256 count) external {
        require(phase == SalePhase.PreSale, "TW: Presale event is not active.");
        require(_msgSender() == ewallet, "TW: Only for ewallet.");
        require(
            addressToMinted[to] + count < maxAllowedPerAddress,
            "TW: Exceeds number of presale mints allowed."
        );
        if (supplyLimit > 0) {
            require(
                _totalSupply + count <= supplyLimit,
                "TW: Exceeds max presale supply of TimelessWarriors."
            );
        }
        require(
            _totalSupply + count <= NUMBER_OF_TWX - NUMBER_OF_RESERVED_TWX,
            "TW: Exceeds max supply of TimelessWarriors."
        );

        addressToMinted[to] += count;
        _mintTimelessWarriors(to, count);
    }

    /// @dev Mints tokens during public sale with e-wallet
    /// @param to address to mint in transaction
    /// @param count number of tokens to mint in transaction
    function publicMintTWXWithEwallet(address to, uint256 count) external {
        require(
            phase == SalePhase.PublicSale,
            "TW: Public sale is not active."
        );
        require(_msgSender() == ewallet, "TW: Only for ewallet.");
        require(
            _totalSupply + count <= NUMBER_OF_TWX - NUMBER_OF_RESERVED_TWX,
            "TW: Exceeds max supply of TimelessWarriors."
        );
        require(count < maxPerTx, "TW: Exceeds max per transaction.");

        _mintTimelessWarriors(to, count);
    }

    /// @dev Mints tokens during limited sale with e-wallet
    /// @param to address to mint in transaction
    /// @param count number of tokens to mint in transaction
    function reserveMintTWXWithEwallet(address to, uint256 count) external {
        require(
            phase == SalePhase.LimitedSale,
            "TW: Limited sale is not active."
        );
        require(_msgSender() == ewallet, "TW: Only for ewallet.");
        require(
            addressToMintedLimited[to] + count < maxAllowedPerAddress,
            "TW: Exceeds number of mints allowed."
        );
        require(
            _totalSupply + count <= NUMBER_OF_TWX,
            "TW: Exceeds max supply of TimelessWarriors."
        );

        addressToMintedLimited[to] += count;
        _mintTimelessWarriors(to, count);
    }

    // ======================================================== Internal Functions

    /// @dev Perform actual minting of the tokens
    function _mintTimelessWarriors(address to, uint256 count) internal {
        uint256 totalSupply_ = _totalSupply;
        for (uint256 index = 0; index < count; index++) {
            _mint(to, totalSupply_);
            unchecked {
                totalSupply_++;
            }
        }
        _totalSupply = totalSupply_;
    }

    /// @dev Validate signature
    function _validateSignature(bytes calldata signature) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(_msgSender()));
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(messageHash),
                signature
            ) == getAdminSigner(),
            "TW: Signature invalid or unauthorized."
        );
    }

    // ======================================================== Public

    /// Return the totalSupply
    function totalSupply() public view returns (uint256) {
        return (_totalSupply - 1) - burned;
    }

    /// Get the adminSigner address
    function getAdminSigner() public view returns (address) {
        return adminSigner;
    }

    /// @dev Burns `tokenId`
    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "TW: Not approved to burn."
        );
        _burn(tokenId);
        unchecked {
            burned++;
        }
    }

    /// @dev Batch transfer from
    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            transferFrom(from, to, tokenIds[i]);
        }
    }

    /// @dev Batch safe transfer from
    function batchSafeTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        bytes memory data
    ) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(from, to, tokenIds[i], data);
        }
    }

    // ======================================================== Overrides

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// Return the tokenURI for a given ID
    /// @dev overrides ERC721's `tokenURI` function and returns either the `_tokenBaseURI` or a custom URI
    /// @notice reutrns the tokenURI using the `_tokenBase` URI if the token ID hasn't been suppleid with a unique custom URI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "TW: Cannot query non-existent token");

        return
            bytes(_tokenBaseURI).length > 0
                ? string(
                    abi.encodePacked(_tokenBaseURI, "/", tokenId.toString())
                )
                : _defaultUri;
    }

    /// @dev Allow gas less future collection approval for cross-collection interaction.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (proxyToApproved[operator]) return true;
        return super.isApprovedForAll(owner, operator);
    }
}