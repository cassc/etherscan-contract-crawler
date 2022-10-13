// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


/***
 *    :::::::::   ::::::::  
 *    :+:    :+: :+:    :+: 
 *    +:+    +:+ +:+        
 *    +#+    +:+ +#++:++#++ 
 *    +#+    +#+        +#+ 
 *    #+#    #+# #+#    #+# 
 *    #########   ########  
 * 
 * FOUNDERS: @ghooost0x2a, @mizzy, @backslashed
 * DEV: @ghooost0x2a
 **********************************
 * @title: Disco Studios
 * @author: @ghooost0x2a ⊂(´･◡･⊂ )∘˚˳°
 **********************************
 * ERC1155 with marketplace (approval) blacklisting
 *****************************************************************
 *      .-----.
 *    .' -   - '.
 *   /  .-. .-.  \
 *   |  | | | |  |
 *    \ \o/ \o/ /
 *   _/    ^    \_
 *  | \  '---'  / |
 *  / /`--. .--`\ \
 * / /'---` `---'\ \
 * '.__.       .__.'
 *     `|     |`
 *      |     \
 *      \      '--.
 *       '.        `\
 *         `'---.   |
 *            ,__) /
 *             `..'
 */

import "./ERC1155X.sol";
import "./ERC1155BurnableX.sol";
import "./ERC1155PausableX.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract DSCOLL is Ownable, AccessControlEnumerable, ERC1155BurnableX, ERC1155PausableX {
    using Strings for uint256;
    event Withdrawn(address indexed payee, uint256 weiAmount);
    string public constant name = "Disco Studios Collector Pass";
    string public constant symbol = "DSCOLL";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    string internal baseURI = "";
    string internal uriSuffix = "";    
    bool internal use_new_uri_notation = false;
    mapping(uint256 => bool) public tokensLockedMinting;
    address public paymentRecipient = 0x252EFE04A7E496ad15aA47a4FC517a350F3A0257;
    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor() ERC1155X("overwritten URI") Ownable() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, 0x252EFE04A7E496ad15aA47a4FC517a350F3A0257);
        _setupRole(MINTER_ROLE, 0x252EFE04A7E496ad15aA47a4FC517a350F3A0257);
        _setupRole(PAUSER_ROLE, 0x252EFE04A7E496ad15aA47a4FC517a350F3A0257);
        _updateNonReselableTokens(5, true);
        _setDefaultRoyalty(0x252EFE04A7E496ad15aA47a4FC517a350F3A0257, 700);
    }
    
    fallback() external payable {
    }

    receive() external payable {}  

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }      

    function setPaymentRecipient(address addy) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paymentRecipient = addy;
    }    

    function setBaseSuffixURI(
        string calldata newBaseURI,
        string calldata newURISuffix
    ) external onlyRole(DEFAULT_ADMIN_ROLE){
        baseURI = newBaseURI;
        uriSuffix = newURISuffix;
    }

    function lockTokenMinting(
       uint256 tokenId
    ) external onlyRole(DEFAULT_ADMIN_ROLE){
        tokensLockedMinting[tokenId]=true;
    }

    function useNewUriStd(bool use_new) external onlyRole(DEFAULT_ADMIN_ROLE){
        use_new_uri_notation = use_new;
    }

    function updateBlackListedApprovals(address[] calldata addys, bool[] calldata blacklisted) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(addys.length == blacklisted.length, "Nb addys doesn't match nb bools.");
        for (uint256 i; i < addys.length; ++i) {
            _updateBlackListedApprovals(addys[i], blacklisted[i]);
        }
    }

    function updateNonReselableTokens(uint256[] calldata tokenIds, bool[] calldata non_reselable) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(tokenIds.length == non_reselable.length, "Nb addys doesn't match nb bools.");
        for (uint256 i; i < tokenIds.length; ++i) {
            _updateNonReselableTokens(tokenIds[i], non_reselable[i]);
        }
    }
        
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        if (use_new_uri_notation) {
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(baseURI, "{id}", uriSuffix)
                    )
                    : "";            
        }

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), uriSuffix)
                )
                : "";
    }    

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "DS_S01: must have minter role to mint");
        require(!tokensLockedMinting[id], "This token is locked for minting. No more of this one can be minted.");
        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "DS_S01: must have minter role to mint");
        for (uint256 ii; ii < ids.length; ++ii) {
            require(!tokensLockedMinting[ids[ii]], "This token is locked for minting. No more of this one can be minted.");
        }
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "DS_S01: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "DS_S01: must have pauser role to unpause");
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155X)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155X, ERC1155PausableX) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //Just in case some ETH ends up in the contract so it doesn't remain stuck.
    function withdraw() external {
        uint256 contract_balance = address(this).balance;

        address payable w_addy = payable(paymentRecipient);

        (bool success, ) = w_addy.call{value: (contract_balance)}("");
        require(success, "Withdrawal failed!");

        emit Withdrawn(w_addy, contract_balance);
    }

}