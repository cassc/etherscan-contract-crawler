// SPDX-License-Identifier: MIT

/*
              _                     
 _ ._  _|  __|_  _ _..__|_ _  _|_ o 
(/_| |(_| (_)|  _>(_||  |_(_)_>| ||
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract endofsartoshi is ERC721Royalty, Ownable, AccessControl {
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    uint256 public constant MAX_PUBLIC_MINT = 20 + 1; // max mints per tx (+1 intentional for gas checks)
    uint256 public totalSupply;
    uint256 public price = 0.069 ether;
    uint256 public reserveSupply = 100;
    string private _baseURIExtended;
    address payable public immutable receiverAddress;
    bool public saleActive; // public sale flag (false on deploy)

    constructor(address payable receiverAddress_) ERC721("end of sartoshi", "END") {
        require(receiverAddress_ != address(0), "Receiver can't be 0x0");

        // set up support role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORT_ROLE, msg.sender);

        receiverAddress = payable(receiverAddress_);
    }

    modifier saleIsActive() {
        require(saleActive, "Sale not live");
        _;
    }

    /**
     * @notice Start or stop the public mint.
     * @param state bool "true" (sale open) or "false" (sale closed)
     */
    function setSaleActive(bool state) external onlyRole(SUPPORT_ROLE) {
        saleActive = state;
    }

    /**
     * @notice Mint reserve tokens.
     * @param to Recipient address.
     * @param numberToMint Quantity of tokens to mint.
     */
    function devMint(address to, uint256 numberToMint) external onlyRole(SUPPORT_ROLE) {
        uint256 reserveSupply_ = reserveSupply;
        require(numberToMint <= reserveSupply_, "Exceeds reserve limit");
        reserveSupply = reserveSupply_ - numberToMint;
        _mintTokens(to, numberToMint);
    }

    /**
     * @notice Public mint function.
     * @param numberToMint Quantity of tokens to mint.
     */
    function mint(uint256 numberToMint) external payable saleIsActive {
        require(numberToMint < MAX_PUBLIC_MINT, "Exceeds max mints per tx");
        require(msg.value == price * numberToMint, "Wrong ETH value");
        _mintTokens(msg.sender, numberToMint);
    }

    /**
     * @notice Set a new base URI for token metadata.
     * @param baseURI_ The new base URI to set.
     */
    function setBaseURI(string calldata baseURI_) external onlyRole(SUPPORT_ROLE) {
        _baseURIExtended = baseURI_;
    }

    /**
     * @notice Withdraw funds.
     */
    function withdraw() external onlyRole(SUPPORT_ROLE) {
        uint256 balance = address(this).balance;
        (bool success, ) = receiverAddress.call{value: balance}("");
        require(success, "Withdraw failed");
    }

    /**
     * @dev Handles minting from multiple functions.
     * @param to Recipient of the tokens.
     * @param numberToMint Quantity of tokens to mint.
     */
    function _mintTokens(address to, uint256 numberToMint) internal {
        require(numberToMint > 0, "Zero mint");
        uint256 currentSupply_ = totalSupply; // memory variable
        for (uint256 i; i < numberToMint; ++i) {
            _safeMint(to, currentSupply_++); // mint then increment
        }
        totalSupply = currentSupply_; // update storage
    }

    /**
     * @dev Override ERC721 to return a baseURI prefix on tokenURI().
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * @dev Override supers.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ERC2981 Royalty functions
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(SUPPORT_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(SUPPORT_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(SUPPORT_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(SUPPORT_ROLE) {
        _resetTokenRoyalty(tokenId);
    }
}