//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./SignedMinting.sol";

contract SurrealMintPassFactory is
    ERC1155,
    ERC1155Supply,
    AccessControlEnumerable,
    PaymentSplitter,
    SignedMinting,
    ReentrancyGuard
{
    using Address for address;
    using Strings for string;

    struct MintPass {
        uint256 mintPrice;
        uint256 passMintLimit;
        uint256 walletMintLimit;
        uint256 totalMinted;
        string tokenURI;
        bool requiresSignature;
        bool saleActive;
        uint256 numberMinted;
        mapping(address => uint256) mintsPerAddress;
    }

    bytes32 private constant INTEGRATION_ROLE = keccak256("INTEGRATION_ROLE");
    mapping(uint256 => MintPass) private mintPasses;
    uint256 private currentMintPassIndex = 0;
    address private surrealContractAddress;

    constructor(
        address signer_,
        address adminAddress,
        address devAddress,
        address surrealContractAddress_,
        address[] memory payees,
        uint256[] memory shares_
    )
        ERC1155("")
        PaymentSplitter(payees, shares_)
        SignedMinting(signer_)
        ReentrancyGuard()
    {
        surrealContractAddress = surrealContractAddress_;
        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, devAddress);
    }

    function createNewMintPass(
        uint256 mintPrice,
        uint256 passMintLimit,
        uint256 walletMintLimit,
        string memory tokenURI,
        bool requiresSignature
    ) public onlyAuthorized {
        currentMintPassIndex++;

        updateMintPass(
            currentMintPassIndex,
            mintPrice,
            passMintLimit,
            walletMintLimit,
            requiresSignature
        );
        MintPass storage newPass = mintPasses[currentMintPassIndex];
        newPass.tokenURI = tokenURI;
    }

    function updateMintPass(
        uint256 id,
        uint256 mintPrice,
        uint256 passMintLimit,
        uint256 walletMintLimit,
        bool requiresSignature
    ) public onlyAuthorized {
        MintPass storage newPass = mintPasses[id];
        newPass.mintPrice = mintPrice;
        newPass.passMintLimit = passMintLimit;
        newPass.walletMintLimit = walletMintLimit;
        newPass.requiresSignature = requiresSignature;
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return mintPasses[tokenId].tokenURI;
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public {
        require(
            surrealContractAddress == _msgSender(),
            "Only surreal contract can burn mint passes"
        );

        _burn(account, id, value);
    }

    function publicMint(
        address to,
        uint256 amount,
        bytes memory signature
    ) public payable nonReentrant {
        MintPass storage mintPass = mintPasses[currentMintPassIndex];
        require(mintPass.saleActive, "Sale not active");
        require(
            !mintPass.requiresSignature || validateSignature(signature),
            "Requires valid signature"
        );
        require(
            msg.value == (mintPass.mintPrice * amount),
            "Incorrect eth value sent"
        );
        require(
            (mintPass.mintsPerAddress[_msgSender()] + amount) <=
                mintPass.walletMintLimit,
            "Exceeds wallet mint limit"
        );
        require(
            (mintPass.numberMinted + amount) <= mintPass.passMintLimit,
            "Not enough tokens remaining in this pass"
        );
        mintPass.mintsPerAddress[_msgSender()] += amount;

        uint256 tokenId = currentMintPassIndex;
        mintPass.numberMinted += amount;

        _mint(to, tokenId, amount, "");
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public onlyAuthorized {
        _mint(to, tokenId, amount, "");
    }

    /*
     * @note Emergency override. Should never been needed.
     */
    function overrideCurrentActiveMintPass(uint256 overrideIndex)
        public
        onlyAuthorized
    {
        currentMintPassIndex = overrideIndex;
    }

    function toggleSale(uint256 tokenId) public onlyAuthorized {
        mintPasses[tokenId].saleActive = !mintPasses[tokenId].saleActive;
    }

    /*
     * @note For OpenSea Integration
     */
    function owner() public view returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function addIntegration(address account) public {
        grantRole(INTEGRATION_ROLE, account);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function removeIntegration(address account) public {
        require(account != _msgSender(), "Cannot revoke yourself");
        revokeRole(INTEGRATION_ROLE, account);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function grantAdminRole(address account) public {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /*
     * @dev Function access control handled by AccessControl contract
     * @dev Internal role admin check resolves to DEFAULT_ADMIN_ROLE at 0x00
     */
    function removeAdminRole(address account) public {
        require(account != _msgSender(), "Cannot revoke yourself");
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function setMintingSigner(address _signer) public onlyAuthorized {
        _setMintingSigner(_signer);
    }

    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        require(
            role != INTEGRATION_ROLE || account.isContract(),
            "Integration must be a contract"
        );
        super._grantRole(role, account);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    modifier onlyAuthorized() {
        require(
            hasRole(INTEGRATION_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Not authorized to perform that action"
        );
        _;
    }
}