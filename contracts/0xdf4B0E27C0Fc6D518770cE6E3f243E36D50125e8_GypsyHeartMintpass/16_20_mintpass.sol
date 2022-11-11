// ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
// ─██████──────────██████─██████████████─██████████─██████████████████────────██████████████─██████████████─██████──██████─
// ─██░░██──────────██░░██─██░░░░░░░░░░██─██░░░░░░██─██░░░░░░░░░░░░░░██────────██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░██─
// ─██░░██──────────██░░██─██░░██████████─████░░████─████████████░░░░██────────██░░██████████─██████░░██████─██░░██──██░░██─
// ─██░░██──────────██░░██─██░░██───────────██░░██───────────████░░████────────██░░██─────────────██░░██─────██░░██──██░░██─
// ─██░░██──██████──██░░██─██░░██████████───██░░██─────────████░░████──────────██░░██████████─────██░░██─────██░░██████░░██─
// ─██░░██──██░░██──██░░██─██░░░░░░░░░░██───██░░██───────████░░████────────────██░░░░░░░░░░██─────██░░██─────██░░░░░░░░░░██─
// ─██░░██──██░░██──██░░██─██░░██████████───██░░██─────████░░████──────────────██░░██████████─────██░░██─────██░░██████░░██─
// ─██░░██████░░██████░░██─██░░██───────────██░░██───████░░████────────────────██░░██─────────────██░░██─────██░░██──██░░██─
// ─██░░░░░░░░░░░░░░░░░░██─██░░██████████─████░░████─██░░░░████████████─██████─██░░██████████─────██░░██─────██░░██──██░░██─
// ─██░░██████░░██████░░██─██░░░░░░░░░░██─██░░░░░░██─██░░░░░░░░░░░░░░██─██░░██─██░░░░░░░░░░██─────██░░██─────██░░██──██░░██─
// ─██████──██████──██████─██████████████─██████████─██████████████████─██████─██████████████─────██████─────██████──██████─
// ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract GypsyHeartMintpass is ERC721A, ERC721ABurnable, AccessControl, PaymentSplitter, ERC2981, ReentrancyGuard {

    using Strings for uint256;

    // MAPPINGS

    mapping(address => uint256) public addressPublicMintCount;
    mapping(address => uint256) public referralCount;

    // PUBLIC VARIABLES

    string public baseTokenURI; // Can be combined with the tokenId to create the metadata URI
    bool public mintbossAllowed = true; // Toggles mintboss on/off
    uint256 public mintPhase = 0; // 0 = closed, 1 = open
    bool public allowBurn = false; // Admin toggle for allowing the burning of tokens
    uint256 public maxMintCap = 50; // Variable maximum mint count
    uint256 public maxSupplyCap = 500; // Variable maximum mint limit
    uint256 public mintPrice = 0.06 ether; // Public mint price

    // PUBLIC CONSTANTS

    uint256 public constant REFERRER_FEE = 0.01 ether; // The amount sent to the referrer on each mint
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // EVENTS

    event SetBaseURI(address _from);
    event MintPhaseChanged(address _from, uint newPhase);
    event ToggleAllowBurn(bool isAllowed);
    event ReferralMint(address _referrer, string _eid, uint count);

    constructor(string memory _baseUri, address[] memory _payees, uint256[] memory _shares) ERC721A("Gypsy Heart Mintpass", "GHM") PaymentSplitter(_payees, _shares) {
        baseTokenURI = _baseUri;
        _setDefaultRoyalty(address(this), 1000);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, address(0xD06D855652A73E61Bfe26A3427Dfe51f3b827fe3));
    }

    function _mintTo(address _recipient, uint256 _quantity) internal {
        uint256 supply = totalSupply();
        uint256 mintCount = addressPublicMintCount[_recipient];
        require(mintPhase==1, "Sale is not active");
        require(_quantity > 0, "Mint amount can't be zero");
        require(mintCount + _quantity <= maxMintCap, "Exceeded max mint count");
        require(supply + _quantity <= maxSupplyCap, "Max mint supply has been reached");

        addressPublicMintCount[_recipient] = mintCount + _quantity;
			
        _safeMint(_recipient, _quantity);
    }

    function mint(address _recipient, uint256 _quantity) external payable {
        require(_quantity * mintPrice == msg.value, "Check mint price");
        _mintTo(_recipient, _quantity);
    }

    function mintReferrer(address _recipient, uint256 _quantity, address payable _referrer, string memory _eid) external payable nonReentrant {
        require(_referrer != _recipient, "Referrer cannot be the same as sender");
        require(_quantity * mintPrice == msg.value, "Check mint price");
        require(mintbossAllowed == true, "Mintboss is currently disabled");

        referralCount[_referrer] += _quantity;
        emit ReferralMint(_referrer, _eid, _quantity);

        _mintTo(_recipient, _quantity);
        _payReferrer(_referrer, _quantity);
    }

    function airdrop(uint256 _quantity, address _recipient) external onlyRole(ADMIN_ROLE) {
        uint256 supply = totalSupply();
        require(_quantity > 0, "Mint amount can't be zero");
        require(supply + _quantity <= maxSupplyCap, "Max supply is reached");
        
        _safeMint(_recipient, _quantity);
    }

    // Allows the contract owner to set a new base URI string
    function setBaseURI(string calldata _baseURI) external onlyRole(ADMIN_ROLE) {
        baseTokenURI = _baseURI;
    }

    // Allows the contract owner to set the wl cap
    function setMintCap(uint _newCap) external onlyRole(ADMIN_ROLE) {
        maxMintCap = _newCap;
    }

    // An owner-only function which toggles the public sale on/off
    function changeMintPhase(uint256 _newPhase) external onlyRole(ADMIN_ROLE) {
        mintPhase = _newPhase;
        emit MintPhaseChanged(msg.sender, _newPhase);
    }

    // An owner-only function which toggles the allowBurn variable
    function toggleAllowBurn() external onlyRole(ADMIN_ROLE) {
        allowBurn = !allowBurn;
        emit ToggleAllowBurn(allowBurn);
    }

    function toggleMintbossAllowed() external onlyRole(ADMIN_ROLE) {
        mintbossAllowed = !mintbossAllowed;
    }

    function setMaxSupplyCap(uint256 _newMaxSupply) external onlyRole(ADMIN_ROLE) {
        maxSupplyCap = _newMaxSupply;
    }

    function setMintPrice(uint256 _newMintPrice) external onlyRole(ADMIN_ROLE) {
        mintPrice = _newMintPrice;
    }

    function _payReferrer(address payable _referrer, uint256 _amount) internal {
        payable(_referrer).transfer(REFERRER_FEE * _amount);
    }

    // Overrides the ERC721A burn function
    function burn(uint256 _tokenId) public virtual override(ERC721ABurnable) {
        require(allowBurn, "Burning is not currently allowed");
        _burn(_tokenId, true);
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

    // Overrides the tokenURI function so that the base URI can be returned
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory baseURI = baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}