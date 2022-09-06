// SPDX-License-Identifier: MIT
/*

                               ,╓▄▄▄▓███████████████▓▄▄▄,
                         ,▄▓█████████████████████████████████▄,
                     ,▄███████████████████████▀└╙████████████████▄,
                  ╓▓██████████████▀┌_.╙██████▀___█████████▀▀█████████▄
                ▄████████████████▌______╙▀▀▀─____██████╙______╙████████▓
             ,▓██████████████████________________█████_________╟██████████,
            ▓███████████████████▀________________▀███___________╙▀▀▀╙└└╟████
          ╓███████████⌐__╙▀▀▀▀▀'_______________________________________╫█████▄
         ▄████████████_____________╫█████⌐______________█████▀_________████████
        ▓█████████████_____________▐█████_______________█████▌_________╫████████
       ▓███████▀╙█████______________▀███▀_______________╙████'__________└▀▀███▀██
      ▐███████▌__╙▀▀▀'__▄▄___________'└_____▐█⌐_____]█⌐___└└__________▄▄_______╙█▌
      ████████_________j█▌___________________▀██▄▄▄▓█▀________________╟█⌐_______╟█
     ▐█▌    █▌_________╟█______________________╙╙▀╙└___________________█▌_______╙█▌
     ▐█    ▐█▒_________██______________________________________________██________█▌
     ╫███████████████████_████████████████████████████████████████████ ████████████
                        ██        j█▌              █▌                 ▓█
                        _▀█⌐      j█▌              █▌               "█▀_
                                  j█▌,             ██,
                                   ╙▀▀▀▀           ╙╙▀▀▀¬

*/
pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MockoTaco is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_MINT_SUPPLY = 4005;
    uint256 public constant AMOUNT_FOR_OWNER = 100;
    uint256 public constant MAX_MINT_PER_TRANSACTION = 1;
    uint256 public ownerMinted = 0;
    uint256 public mintPrice = 0 ether;

    // Sale Status
    bool public publicSaleActive = false;
    bool public allowListSaleActive = false;
    bool public revealed = false;

    // PRESALE MERKLE MINT
    mapping (address => bool) public mintMerkleWalletList;
    bytes32 public mintMerkleRoot;

    string private baseURI;
    string private notRevealedURI;
    string private baseExtension;

    /**
     * @notice triggered when minted
     */
    event Minted(address minter, uint256 amount);

    /**
     * @notice triggered after owner withdraws funds
     */
    event Withdrawal(address to, uint amount);

    /**
     * @notice triggered after the owner sets the base uri
     */
    event BaseURIChanged(string newBaseURI);

    /**
     * @notice triggered after the public sale status in enabled/disabled
     */
    event TogglePublicSaleStatus(bool publicSaleStatus);

    /**
     * @notice triggered after the allowlist sale status in enabled/disabled
     */
    event ToggleAllowlistSaleStatus(bool allowlistSaleStatus);

    constructor() ERC721A("Mocko Taco", "MOCKOTACO") {
    }


    /**
     * @notice The function to call for allowlist minting
     * @param _merkleProof The merkle proof to validate on allowlist
     */
    function mintAllowlistTaco(bytes32[] calldata _merkleProof) external {
        require(
            allowListSaleActive,
            "Allowlist sale is not active"
        );
        require(
            mintMerkleWalletList[msg.sender] == false,
            "You are not on the wallet list or have already minted"
        );
        require(
            _totalMinted() + 1 <= MAX_MINT_SUPPLY,
            "Max mint supply reached"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, mintMerkleRoot, leaf), "Invalid Merkle Proof");
        mintMerkleWalletList[msg.sender] = true;

        _safeMint(msg.sender, 1);

        emit Minted(msg.sender, 1);
    }

    /**
     * @notice The function to call for public minting
     * @param quantity the number of tokens to mint (up to MAX_MINT_PER_TRANSACTION)
     */
    function mintPublicTaco(uint256 quantity) external payable {
        require(
            publicSaleActive,
            "Public sale is not active"
        );
        require(
            quantity <= MAX_MINT_PER_TRANSACTION,
            "Over mint limit"
        );
        require(
            _totalMinted() + quantity <= MAX_MINT_SUPPLY,
            "Max mint supply reached"
        );

        require(msg.value == quantity * mintPrice, "Wrong amount of eth sent");

         _safeMint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /**
     * @notice The function to call for owner minting
     * @param quantity the number of tokens to mint
     */
    function mintOwnerTaco(uint256 quantity) external onlyOwner {
        require(
            _totalMinted() + quantity <= MAX_MINT_SUPPLY,
            "Max mint supply reached"
        );
        require(
            ownerMinted + quantity <= AMOUNT_FOR_OWNER,
            "Exceeds maximum owner mint amount"
        );
        _safeMint(msg.sender, quantity);

        ownerMinted += quantity;
        emit Minted(msg.sender, quantity);
    }

    /**
     * @notice The function to call for owner gift mints
     * @param to the address to send the tokens to
     * @param quantity the number of tokens to mint
     */
    function giftTaco(address to, uint256 quantity) external onlyOwner {
        require(
            _totalMinted() + quantity <= MAX_MINT_SUPPLY,
            "Max mint supply reached"
        );
        require(
            ownerMinted + quantity <= AMOUNT_FOR_OWNER,
            "Exceeds maximum owner mint amount"
        );
        require(to != address(0), "Cannot Send To Zero Address");
        _safeMint(to, quantity);

        ownerMinted += quantity;

        emit Minted(msg.sender, quantity);
    }


    /**
     * @notice Withdraws owner funds from the contract after the refund window
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
        emit Withdrawal(owner(), balance);
    }

    /**
     * @notice Gets the baseURI to be used to build a token URI
     * @return the baseURI string
     */
    function _baseURI() internal view override returns (string memory) {
        if (!revealed) {
            return notRevealedURI;
        } else {
            return baseURI;
        }
    }

    /**
     * @notice Returns the token URI, taking into account reveal
     * @param tokenId The id of the token
     * @return The token URI string
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory currentBaseURI = _baseURI();
        if (!revealed) {
            return bytes(currentBaseURI).length != 0 ? string(
                abi.encodePacked(currentBaseURI)) : "";
        } else {
        return bytes(currentBaseURI).length != 0 ? string(
            abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
        }
    }

    /**
     * @notice Change the unrevealed URI
     * @param notRevealedURI_ The new string to be used
     */
    function setNotRevealedURI(string memory notRevealedURI_) external onlyOwner {
        notRevealedURI = notRevealedURI_;
    }

    /**
     * @notice Change the base URI
     * @param uri_ The new string to be used
     */
    function setBaseURI(string memory uri_) external onlyOwner {
        baseURI = uri_;
        emit BaseURIChanged(baseURI);
    }

    /**
     * @notice Change the extension to be included on token URIs
     * @param extension_ The new string to be used
     */
    function setBaseExtension(string memory extension_) external onlyOwner {
        baseExtension = extension_;
    }

    /**
     * @notice Toggle the public sale status
     */
    function togglePublicSaleStatus() external onlyOwner {
        publicSaleActive = !publicSaleActive;
        emit TogglePublicSaleStatus(publicSaleActive);
    }

    /**
     * @notice Toggle the public sale status
     */
    function toggleAllowlistSaleStatus() external onlyOwner {
        allowListSaleActive = !allowListSaleActive;
        emit ToggleAllowlistSaleStatus(allowListSaleActive);
    }

    /**
     * @notice Change the token URI from unrevealed to revealed status
     */
    function reveal() external onlyOwner {
        revealed = true;
    }

    /**
     * @notice Set the public mint price
     * @param newPrice The price to use for public mint
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    /**
     * @notice sets Merkle Root for mint
     */
    function setMerkleRoot(bytes32 _presaleMerkleRoot) public onlyOwner {
        mintMerkleRoot = _presaleMerkleRoot;
    }

    /**
     * @notice useful to reset a list of addresses to be able to presale mint again.
     */
    function initMintMerkleWalletList(address[] memory walletList) external onlyOwner {
        for (uint i; i < walletList.length; i++) {
            mintMerkleWalletList[walletList[i]] = false;
        }
    }

    /**
     * @notice check if address minted presale
     */
    function checkAddressOnMintMerkleWalletList(address wallet) public view returns (bool) {
        return mintMerkleWalletList[wallet];
    }
}