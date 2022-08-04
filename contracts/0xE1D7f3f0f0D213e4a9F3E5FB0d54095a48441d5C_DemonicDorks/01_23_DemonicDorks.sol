// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/*
 *           ....                 ....
 *       .xH888888Hx.         .xH888888Hx.
 *     .H8888888888888:     .H8888888888888:
 *     888*"""?""*88888X    888*"""?""*88888X
 *    'f     d8x.   ^%88k  'f     d8x.   ^%88k
 *    '>    <88888X   '?8  '>    <88888X   '?8
 *     `:..:`888888>    8>  `:..:`888888>    8>
 *            `"*88     X          `"*88     X
 *       .xHHhx.."      !     .xHHhx.."      !
 *      X88888888hx. ..!     X88888888hx. ..!
 *     !   "*888888888"     !   "*888888888"
 *            ^"***"`              ^"***"`
 *
 * FOUNDER: @psychedemon
 * ART: @Cho_Though, @madison_nft, @ccalicobuns
 * DEV: @ghooost0x2a
 **********************************
 * @title: Demonic Dorks
 * @author: @ghooost0x2a ⊂(´･◡･⊂ )∘˚˳°
 **********************************
 * ERC721B2FA - Ultra Low Gas - 2 Factor Authentication
 *****************************************************************
 * ERC721B2FA is based on ERC721B low gas contract by @squuebo_nft
 * and the LockRegistry/Guardian contracts by @OwlOfMoistness
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

import "./ERC721B2FAEnumLitePausable.sol";
import "./GuardianLiteB2FA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DemonicDorks is ERC721B2FAEnumLitePausable, GuardianLiteB2FA {
    using MerkleProof for bytes32[];
    using Address for address;
    using Strings for uint256;

    event Withdrawn(address indexed payee, uint256 weiAmount);

    uint256 public MAX_SUPPLY = 10000;
    string internal baseURI = "";
    string internal uriSuffix = "";

    address private paymentRecipient =
        0x7a60BF1862c9ecA713fEEEA6b32C44c3AafaAE10;

    // dev: public mints
    uint256 public maxPublicMintsPerWallet = 1;
    uint256 public maxPreSaleMintsPerWallet = 3;

    uint256 public teamMinted = 0;

    bytes32 private merkleRoot = 0;
    mapping(address => uint256) public presaleMintedAddys;
    mapping(address => uint256) public publicMintedAddys;

    // 0 = Pause; 1 = Presale; 2 = Public
    uint256 public mintPhase = 0;

    constructor() ERC721B2FAEnumLitePausable("DemonicDorks", "DD", 1) {}

    fallback() external payable {
        revert("You hit the fallback fn, fam! Try again.");
    }

    receive() external payable {}

    //getter fns
    function getPaymentRecipient()
        external
        view
        onlyDelegates
        returns (address)
    {
        return paymentRecipient;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), uriSuffix)
                )
                : "";
    }

    function setBaseSuffixURI(
        string calldata newBaseURI,
        string calldata newURISuffix
    ) external onlyDelegates {
        baseURI = newBaseURI;
        uriSuffix = newURISuffix;
    }

    function setMaxPublicMintsPerWallet(uint256 maxPub) external onlyDelegates {
        maxPublicMintsPerWallet = maxPub;
    }

    function setMaxPreSaleMintsPerWallet(uint256 maxPre)
        external
        onlyDelegates
    {
        maxPreSaleMintsPerWallet = maxPre;
    }

    function setPaymentRecipient(address addy) external onlyDelegates {
        paymentRecipient = addy;
    }

    function setReducedMaxSupply(uint256 new_max_supply)
        external
        onlyDelegates
    {
        require(new_max_supply < MAX_SUPPLY, "Can only set a lower size.");
        require(
            new_max_supply >= totalSupply(),
            "New supply lower current totalSupply"
        );
        MAX_SUPPLY = new_max_supply;
    }

    function setMintPhase(uint256 newPhase) external onlyDelegates {
        mintPhase = newPhase;
    }

    function getMerkleRoot() public view onlyDelegates returns (bytes32) {
        return merkleRoot;
    }

    function setMerkleRoot(bytes32 mRoot) external onlyDelegates {
        merkleRoot = mRoot;
    }

    function isvalidMerkleProof(bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        if (merkleRoot == 0) {
            return false;
        }
        bool proof_valid = proof.verify(
            merkleRoot,
            keccak256(abi.encodePacked(msg.sender))
        );
        return proof_valid;
    }

    function teamMint(uint256 qty, address addy) external onlyDelegates {
        teamMinted += qty;
        _minty(qty, addy);
    }

    //pre-sale mint
    function dorkyMint(uint256 qty, bytes32[] memory proof) external {
        require(
            mintPhase == 1 || _isDelegate(_msgSender()),
            "Pre-Sale mint not open"
        );
        require(
            presaleMintedAddys[_msgSender()] + qty <= maxPreSaleMintsPerWallet,
            "Already minted max pre-sale"
        );
        require(
            isvalidMerkleProof(proof),
            "You are not authorized for pre-sale"
        );

        presaleMintedAddys[_msgSender()] += qty;
        _minty(qty, _msgSender());
    }

    function feelinMinty(uint256 quantity) external {
        require(
            mintPhase == 2 || _isDelegate(_msgSender()),
            "Public mint is not open yet!"
        );
        require(
            publicMintedAddys[_msgSender()] + quantity <=
                maxPublicMintsPerWallet,
            "You have reached limit mint"
        );

        publicMintedAddys[_msgSender()] += quantity;
        _minty(quantity, _msgSender());
    }

    function _minty(uint256 quantity, address addy) internal {
        require(quantity > 0, "Can't mint 0 tokens!");
        require(quantity + totalSupply() <= MAX_SUPPLY, "Max supply reached!");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(addy, next());
        }
    }

    //Just in case some ETH ends up in the contract so it doesn't remain stuck.
    function withdraw() external onlyDelegates {
        uint256 contract_balance = address(this).balance;

        address payable w_addy = payable(paymentRecipient);

        (bool success, ) = w_addy.call{value: (contract_balance)}("");
        require(success, "Withdrawal failed!");

        emit Withdrawn(w_addy, contract_balance);
    }
}