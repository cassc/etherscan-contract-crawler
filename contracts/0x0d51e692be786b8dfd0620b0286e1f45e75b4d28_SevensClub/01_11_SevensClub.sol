// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * MMMMMMMMMMMMMMMMMMMMMMMMWKx:'..  ..':kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMWKl'........   .c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMWO,    ........   .;cldOXWMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMNOo;.. ....................';okXWMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMWOl,...,'...........,:cokko;......'ckXWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMXx;. .,xOl;ol........oO0llKXkxo........'l0WMMMMMMMMMMMMMM
 * MMMMMMMMMMMXd'....,dOl..dXo......;k0KlcKXll0c.....,;;::l0WMMMMMMMMMMMM
 * MMMMMMMMMWO,......;c'',,,xd......,xOOxx00xk0c....:o::c:..lKMMMMMMMMMMM
 * MMMMMMMMWx. .......:;',,':,.......;ldOOdooxl.....;o:cl:,. ,kWMMMMMMMMM
 * MMMMMMMWk. ..........'....     ......;:c:;.. .....''.,;'....oNMMMMMMMM
 * MMMMMMMK; ........    ......................           ......oXWMMMMMM
 * MMMMMMWx.    .........................................   ... .,oXMMMMM
 * MMMWKx:.  ....................................................:olkWMMM
 * WXx:............... .........................................'dKl,dNMM
 * l'             .:llooddxxxkkkkOOOOOOOkkkkxxxddollc::;,'.. .,loc,...,xN
 * '       ...... ,0WNNNNNNNNNNXklcd0NNNNNNNNNNNNNNNNNKxlc:;,:ooo;  ....:
 * Ko'.    .......lXNNNNNNNNNNKl.   'kNNNNNNNNNNNNNNKdcldxxxdoool.    . .
 * WO:':odxdoc,..lKNNNNNNNNNNNx.     ,d0NNNNNNNNNNNk:ckOxollolcl:.... .cO
 * d,c0NKxxXNNXOkXNNNNNNNNNNNNo.     .,xNNNNNNNNNNO;c00occoo:ckKx'c0o.cNM
 * ,:KNNKl':0NNNNNNNNNNNNNNNNNx.     .'dNNNNNNNNNNo;xXkcclxo:OWK:'kNK;;KM
 * 'lXNNNKo.cXNNNNNNNNNNNNNNNNK:     'oONNNNNNNNNNd,xXkllxx:oXXo.lXNO,cNM
 * ,:KWNNXk,,ONNNNNNNNNNNNNNNNNKl. .,kXNNNNNNNNNNNKl;oxdlccxXXo'cKNO;;0MM
 * o'dXNNXk';0WNNNXxcxNNNNNNNNNNNKkOKNWNNNNNNNNNNNNXkooookKN0c.:kkl;l0WMM
 * No,lKNXd;dNNNNKd.,xKNNNNNNNNNNNNNNNWNNNNNNXXXNNNNNNNNNNKd;,;:cld0WMMMM
 * MWk:;okOOKXK0d;'',cdOKXNNNNNNNNNNNNNNNNNNNOdOXNNNNNNN0d::xXWNNWMMMMMMM
 * MMMNkl:::::::cdKXOl;;cdOKXNNNNNNNNNNNNNNNNNNNNNNNX0xc:ckNMMMMMMMMMMMMM
 * MMMMMMNX0OO0XWMMMMWXOoc::cok0KNNNNNNNNNNNNNNXKOdlc:lxKWMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMWXOdlc::ccloooooooollccclox0NMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdllccc::clodk0XWMMMMMMMMMMMMMMMMMMMMMMM
 *
 * @title SevensClub
 * @custom:website www.7sclub.io
 * @author @lozzereth (www.allthingsweb3.com)
 * @notice The NFT contract for 7sClub NFT using ERC721AQueryable and ERC721ABurnable.
 */
contract SevensClub is ERC721AQueryable, ERC721ABurnable, Ownable {
    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public mintableSupply = MAX_SUPPLY;

    uint256 public maxMintPublic = 5;
    uint256 public maxMintWhitelist = 3;
    uint256 public freeMintAmount = 1;
    uint256 public mintRound = 0;

    uint256 public publicMintPrice = 0.047 ether;
    uint256 public whitelistMintPrice = 0.037 ether;

    bool public publicSale = false;
    bool public whitelistSale = false;
    bytes32 public whitelistMerkleRoot;
    mapping(uint256 => mapping(address => uint256)) whitelistMintCount;

    string private baseURI;

    constructor() ERC721A("7sClub", "7SCLUB") {
        baseURI = "ipfs://QmRoMyWtFN1xQGk34QbB3Gvqx1Z6myBqVdnXSqGWPPxe8c/";
    }

    /**
     * @notice Toggle the public sale
     */
    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    modifier publicSaleActive() {
        require(publicSale, "Public Sale Not Started");
        _;
    }

    /**
     * @notice Toggle the whitelist sale
     */
    function toggleWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    modifier whitelistSaleActive() {
        require(whitelistSale, "Whitelist Sale Not Started");
        _;
    }

    /**
     * @notice Public minting
     * @param _quantity - Quantity to mint
     */
    function mintPublic(uint256 _quantity)
        public
        payable
        publicSaleActive
        hasCorrectAmount(publicMintPrice, _quantity)
        withinMintableSupply(_quantity)
        withinMaximumPerTxn(_quantity)
    {
        _mint(msg.sender, _quantity);
    }

    modifier hasCorrectAmount(uint256 price, uint256 quantity) {
        require(msg.value >= price * quantity, "Insufficent Funds");
        _;
    }

    modifier withinMintableSupply(uint256 quantity) {
        require(
            _totalMinted() + quantity <= mintableSupply,
            "Surpasses Supply"
        );
        _;
    }

    modifier withinMaximumPerTxn(uint256 quantity) {
        require(quantity > 0 && quantity <= maxMintPublic, "Over Max Per Txn");
        _;
    }

    /**
     * @notice Set the merkle root for the whitelist verification
     * @param merkleRoot - Whitelist merkle root
     */
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    /**
     * @notice Whitelist mint (max mint to get a free mint!)
     * @param quantity - The quantity to mint
     * @param merkleProof - Proof to verify whitelist
     */
    function mintWhitelist(uint256 quantity, bytes32[] calldata merkleProof)
        public
        payable
        whitelistSaleActive
        hasValidMerkleProof(merkleProof, whitelistMerkleRoot)
        hasCorrectAmount(whitelistMintPrice, quantity)
        withinMintableSupply(quantity + freeMintAmount)
        withinMaximumPerWallet(quantity)
    {
        uint256 netMinted = (whitelistMintCount[mintRound][
            msg.sender
        ] += quantity);
        if (netMinted == maxMintWhitelist) {
            quantity += freeMintAmount;
        }
        _mint(msg.sender, quantity);
    }

    modifier withinMaximumPerWallet(uint256 quantity) {
        require(
            quantity > 0 &&
                whitelistMintCount[mintRound][msg.sender] + quantity <=
                maxMintWhitelist,
            "Over Max Per Wallet"
        );
        _;
    }

    modifier hasValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address Not Whitelisted"
        );
        _;
    }

    /**
     * @notice Admin mint
     * @param recipient - The receiver of the NFT
     * @param quantity - The quantity to mint
     */
    function mintAdmin(address recipient, uint256 quantity)
        external
        onlyOwner
        withinMintableSupply(quantity)
    {
        _mint(recipient, quantity);
    }

    /**
     * @notice Allow adjustment of minting price
     * @param publicPrice - Public mint price in wei
     * @param whitelistPrice - Whitelist mint price in wei
     */
    function setMintPrice(uint256 publicPrice, uint256 whitelistPrice)
        external
        onlyOwner
    {
        publicMintPrice = publicPrice;
        whitelistMintPrice = whitelistPrice;
    }

    /**
     * @notice Allow adjustment of minting price
     * @param publicLimit - Public mint price in wei
     * @param whitelistLimit - Whitelist mint price in wei
     */
    function setMaxMintLimit(uint256 publicLimit, uint256 whitelistLimit)
        external
        onlyOwner
    {
        maxMintPublic = publicLimit;
        maxMintWhitelist = whitelistLimit;
    }

    /**
     * @notice Allow adjustment of mintable supply
     * @param supply - Mintable supply, limited to the maximum supply
     */
    function setMintableSupply(uint256 supply) external onlyOwner {
        require(
            supply >= _totalMinted() && supply <= MAX_SUPPLY,
            "Invalid Supply"
        );
        mintableSupply = supply;
    }

    /**
     * @dev Set the minting round
     */
    function setMintRound(uint256 round) external onlyOwner {
        mintRound = round;
    }

    /**
     * @dev Set the free mint distribution amount
     */
    function setFreeMintAmount(uint256 amount) external onlyOwner {
        freeMintAmount = amount;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param baseURI_ - The Base URI of the NFT
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Returns the Base URI of the NFT
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Withdrawal of funds
     */
    address private constant address1 =
        0x7ee2C3B70f916DAB6f10B521EfcA9D2C8e4fCB33;
    address private constant address2 =
        0x17144733018d937C83a319891Bdb055ee7E55E1b;
    address private constant address3 =
        0xe047A3f65116d0ea8bf421c48B4021077AA40a05;
    address private constant address4 =
        0xb3d22698af9D580C00Fc2673cA2D8AA90Eb41798;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(address1), (balance * 7) / 100);
        Address.sendValue(payable(address2), (balance * 11) / 100);
        Address.sendValue(payable(address3), (balance * 67) / 100);
        Address.sendValue(payable(address4), (balance * 15) / 100);
    }
}