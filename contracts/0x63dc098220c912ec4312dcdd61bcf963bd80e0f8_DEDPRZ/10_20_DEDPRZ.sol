// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc1155delta/contracts/extensions/ERC1155DeltaQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 /$$$$$$$  /$$$$$$$$ /$$$$$$$  /$$$$$$$  /$$$$$$$  /$$$$$$$$
| $$__  $$| $$_____/| $$__  $$| $$__  $$| $$__  $$|_____ $$ 
| $$  \ $$| $$      | $$  \ $$| $$  \ $$| $$  \ $$     /$$/ 
| $$  | $$| $$$$$   | $$  | $$| $$$$$$$/| $$$$$$$/    /$$/  
| $$  | $$| $$__/   | $$  | $$| $$____/ | $$__  $$   /$$/   
| $$  | $$| $$      | $$  | $$| $$      | $$  \ $$  /$$/    
| $$$$$$$/| $$$$$$$$| $$$$$$$/| $$      | $$  | $$ /$$$$$$$$
|_______/ |________/|_______/ |__/      |__/  |__/|________/

www.dedprz.io
*/

/**
 * @title DEDPRZ Contract
 * @dev Extends ERC1155Delta Non-Fungible Token Standard
 * @author @devgod_eth
 */
contract DEDPRZ is ERC1155DeltaQueryable, ERC2981, DefaultOperatorFilterer {
    address public admin; // contract admin

    uint256 public constant NUM_MAX = 10000; // max supply
    uint256 public mintPrice; // mint price
    uint16 internal constant _MAX_MINTS_PER_ADDRESS = 10; // max per wallet

    bool public mintable; // mintable state

    uint256 internal adminMint = 0; // admin minted

    event Minted(address indexed to, uint256 indexed amount); // minted event

    constructor()
        ERC1155Delta(
            "https://dedprz.s3.amazonaws.com/{id}"
        )
    {
        admin = msg.sender;

        mintable = false;

        mintPrice = 0.099 ether;

        _setDefaultRoyalty(admin, 690);
    }

    /// @dev Receive ether
    receive() external payable {}

    /// @dev Modifier for admin only functions
    modifier onlyAdmin() {
        require(msg.sender == admin, "OnlyAdmin");
        _;
    }

    /// @dev Override to use filter operator
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev Override transfer to use filter operator
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /// @dev Override batch transfer to use filter operator
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @dev Override ERC1155Delta to also support ERC2981 royalty standard
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC1155Delta, ERC2981)
        returns (bool)
    {
        // dm nickp on twitter and tell him devs are based af
        return ERC1155Delta.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /// @notice Mint tokens to address
    /// @param to Address to mint to
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external payable {
        require(mintable, "Not mintable");
        require(_totalMinted() + amount <= NUM_MAX, "Minted out");
        require(msg.value >= mintPrice * amount, "Insufficient funds");
        require(balanceOf(to) + amount <= _MAX_MINTS_PER_ADDRESS, "Limit 10");

        _mint(to, amount);

        emit Minted(to, amount);
    }

    /// @notice Mint tokens to address for multisig only
    /// @param to Address to mint to
    /// @param amount Amount to mint
    function mintAdmin(address to, uint256 amount) external onlyAdmin {
        // max 20 for admin
        require(adminMint + amount <= 20, "Limit 20");

        // mint
        _mint(to, amount);

        // update multisig minted
        adminMint += amount;

        emit Minted(to, amount);
    }

    /// @notice Burn token
    /// @param tokenId Token ID to burn
    function burn(uint256 tokenId) external {
        _burn(msg.sender, tokenId);
    }

    /// @notice Burn tokens
    /// @param tokenIds Token IDs to burn
    function burnBatch(uint256[] memory tokenIds) external {
        _burnBatch(msg.sender, tokenIds);
    }

    /// @notice Claim admin funds
    function adminClaim() external {
        payable(admin).transfer(address(this).balance);
    }

    /// @notice Get total minted
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /// @notice Set admin address
    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    /// @notice Set minting state
    function setMintable(bool _mintable) external onlyAdmin {
        mintable = _mintable;
    }

    /// @notice Set URI of tokens for later reveal to protect randomness
    function setURI(string memory newuri) external virtual onlyAdmin {
        _setURI(newuri);
    }

    /// @notice Set royalty for marketplaces complying with ERC2981 standard
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyAdmin {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}