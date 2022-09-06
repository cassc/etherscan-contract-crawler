// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "erc721a/contracts/ERC721A.sol";

/**
 * MembershipToken. It uses ERC721A.
 */
contract MembershipToken is ERC721A, AccessControl {
    using SignatureChecker for address;

    /// @dev Allow whitelist mint
    bool public canWhitelistMint;

    /// @dev Allow public mint
    bool public canPublicMint;

    /// @dev Price for one token. Set after deploy.
    uint256 public publicPrice;

    /// @dev Price for one token. Set after deploy.
    uint256 public whitelistPrice;

    /// @dev address used to whitelist addresses
    address public signer;

    /// @dev Adress to receive a fee
    address public trustedWallet;

    /// @dev Max supply of tokens
    uint256 public maxSupply;

    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    /// @dev Uri of metada. Set after deploy.
    string public uri;

    event MembershipTokenRedeemed(address _sender, uint256 _tokenId);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor(address _signer) ERC721A("Feature3 Founders Pass", "F3") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        signer = _signer;

        publicPrice = 1 ether;
        whitelistPrice = 777000000 gwei; // 0.777 ether
        maxSupply = 2222;
    }

    /**
     * @dev Whitelisted mint using a signature.
     *
     * @param _signature Signature that authorizes an address to mint
     */
    function whitelistMint(bytes memory _signature) external payable {
        require(canWhitelistMint, "MST: Whitelist mint not allowed");
        require(isWhitelisted(_signature, 1), "MST: not authorized");
        require(msg.value >= whitelistPrice, "MST: Not enough value");

        payment();

        uint256 cumulativeMint = _numberMinted(msg.sender);
        require(cumulativeMint <= 1, "MST: already minted allowed"); // check this requirement

        mint(msg.sender, 1);
    }

    /**
     * @dev Public mint using a signature.
     *
     * @param _quantity Amount to mint
     */
    function publicMint(uint256 _quantity) external payable {
        require(canPublicMint, "MST: Public mint not allowed");
        require(msg.value >= publicPrice * _quantity, "MST: Not enough value");

        payment();

        mint(msg.sender, _quantity);
    }

    /**
     * @dev Private mint
     *
     * @param _quantity Max amount allowed to mint
     * @param _destination Destination wallet
     */
    function privateMint(uint256 _quantity, address _destination)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mint(_destination, _quantity);
    }

    function mint(address _destination, uint256 _quantity) internal {
        require(totalSupply() + _quantity <= maxSupply, "MST: Out of tokens to public mint");
        _safeMint(_destination, _quantity, "");
    }

    /**
     * @dev It burns a Token. To be called by another smart contract or wallet with the REDEEMER_ROLE role.
     *
     * Emits a {MembershipTokenRedeemed} event.
     *
     * @param _account Token owner address.
     * @param _tokenId Membership Token Id.
     */
    function redeem(address _account, uint256 _tokenId) external onlyRole(REDEEMER_ROLE) {
        require(ownerOf(_tokenId) == _account, "MST: Account is not owner.");
        _burn(_tokenId, false);

        emit MembershipTokenRedeemed(_account, _tokenId);
    }

    /**
     * @dev Check if an address can mint.
     * @param _signature Signature to check.
     * @param _qtyAllowed Quantity allowed to mint
     */
    function isWhitelisted(bytes memory _signature, uint256 _qtyAllowed)
        internal
        view
        returns (bool)
    {
        bytes32 result = keccak256(abi.encodePacked(_qtyAllowed, msg.sender));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    /// @dev Transfer value paid for a token
    function payment() internal {
        unchecked {
            (bool success, ) = trustedWallet.call{value: msg.value}("");
            require(success, "MST: Transfer failed");
        }
    }

    /// @dev Set base uri. OnlyOwner can call it.
    function setBaseURI(string memory _value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uri = _value;
    }

    /// @dev Returns base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Updates value of 'publicPrice'
     * @param _publicPrice  New value of 'publicPrice'
     */
    function setPublicPrice(uint256 _publicPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicPrice = _publicPrice;
    }

    /**
     * @dev Updates value of 'whitelistPrice'
     * @param _whitelistPrice  New value of 'whitelistPrice'
     */
    function setWhitelistPrice(uint256 _whitelistPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistPrice = _whitelistPrice;
    }

    /**
     * @dev Updates address of 'signer'
     * @param _signer  New address for 'signer'
     */
    function setSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = _signer;
    }

    /**
     * @dev Updates max supply of tokens
     * @param _maxSupply  New max supply of tokens
     */
    function setMaxSupply(uint256 _maxSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_maxSupply > 0, "MT: Max supply cannot be zero");
        maxSupply = _maxSupply;
    }

    /**
     * @dev Updates address of 'trustedWallet'
     * @param _trustedWallet  New address for 'trustedWallet'
     */
    function setTrustedWallet(address _trustedWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        trustedWallet = _trustedWallet;
    }

    /**
     * @dev Set 'canWhitelistMint'
     * @param _canWhitelistMint  New value for 'canWhitelistMint'
     */
    function setCanWhitelistMint(bool _canWhitelistMint) external onlyRole(DEFAULT_ADMIN_ROLE) {
        canWhitelistMint = _canWhitelistMint;
    }

    /**
     * @dev Set '_canPublicMint'
     * @param _canPublicMint  New value for '_canPublicMint'
     */
    function setCanPublicMint(bool _canPublicMint) external onlyRole(DEFAULT_ADMIN_ROLE) {
        canPublicMint = _canPublicMint;
    }
}