// SPDX-License-Identifier: MIT

//                                                           _
//                                                     _,▄███████▄_
//                                                     ▄█████▀▀▀████▄
//                                                   ▄███▀└_    _╙███µ
//                   ▄████████▄,_   _ ,▄▄▄██████████████└     _╓█████_
//                _▄████▀▀▀▀█████████████████▀▀▀▀▀▀███▌_        ,████▄
//                ████└       └╙████▀▀└─__                      └╙████
//               _███▌          ___                              _███▌
//                ████_                     _  ___ _             _╙███▌
//                _███▌_                _▄██████████_              `███▌
//                 '████_             _███▀└,,,,____                ▐███_
//                  _▀███_           ╒██▀_ ╟██▀▀▀██                 _███▌
//                   ▐███           _██▌   ██▌__▄██_                 ███▌
//                   ║██▌           ]██_  _████████ç                 ║██▌
//                   ╟██▌           ▐██_   ██▌__─╙██▌                ╫██▌
//                   ▐███           _██▌   ╟█▌,╓▄▄██▌                ███▌
//                   "███_           └███_ └████▀▀╙'                ▐███_
//                   _███▌            _▀███▄▄,_,,▄▄███             ,███▌
//                    ╙███µ             _└▀▀██████▀▀└            ,████▀
//                     ╙███▄                                  ,▄████▀¬
//                      ╙█████▄▄__                      __▄▄█████▀╙_
//                       _└╙▀████████▄▄▄▄,,,,,,,,▄▄▄▄████████▀▀└_
//                           __└╙▀▀████████████████████▀▀▀└_
//                                   __`└└└╙╙╙╙└└└'__

pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ClubbieBear is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_MINT_SUPPLY = 3000;
    uint256 public constant AMOUNT_FOR_OWNER = 250;
    uint256 public constant MAX_TEAM_MINT = 3;
    uint256 public constant MAX_ALLOWLIST_MINT = 2;
    uint256 public constant MAX_MINT_PER_TRANSACTION = 2;
    uint256 public ownerMinted = 0;
    uint256 public mintPrice = .15 ether;

    // Sale Status
    bool public publicSaleActive = false;
    bool public allowListSaleActive = false;
    bool public revealed = false;

    // ALLOWLIST MERKLE MINT
    mapping (address => bool) public mintMerkleWalletList;
    bytes32 public mintMerkleRoot;

    // FREE MINT MERKLE MINT
    mapping (address => bool) public freeMintMerkleWalletList;
    bytes32 public freeMintMerkleRoot;

    // TEAM MINT
    mapping (address => uint256) private teamMintWalletList;

    // RARE REWARDS
    mapping (uint256 => bool) public hasUnclaimedReward;

    string private baseURI;
    string private rareRewardBaseURI;
    string private notRevealedURI = "ipfs://bafkreie4h5rudjdg4axvtsxmylquetz6xq4xgbmke57lbtuk72dcrfnhhu";
    string private baseExtension = ".json";

    address public withdrawalAddress;

    /**
     * @notice Triggered when minted
     */
    event Minted(address minter, uint256 amount);

    /**
     * @notice Triggered after owner withdraws funds
     */
    event Withdrawal(address to, uint amount);

    /**
     * @notice Triggered after the owner sets the base uri
     */
    event BaseURIChanged(string newBaseURI);

    /**
     * @notice Triggered after the public sale status in enabled/disabled
     */
    event TogglePublicSaleStatus(bool publicSaleStatus);

    /**
     * @notice Triggered after the allowlist sale status in enabled/disabled
     */
    event ToggleAllowlistSaleStatus(bool allowlistSaleStatus);

    /**
     * @notice Triggered when the payment address is set
     */
    event SetWithdrawalAddress(address withdrawalAddress);

    constructor() ERC721A("Clubbie Bear", "CLUBBIE") {
        withdrawalAddress = msg.sender;
    }

    /**
     * @notice The function to call for free minting
     * @param _merkleProof The merkle proof to validate on free mint
     */
    function freeMint(bytes32[] calldata _merkleProof) external {
        require(
            allowListSaleActive,
            "Allowlist sale is not active"
        );
        require(
            freeMintMerkleWalletList[msg.sender] == false,
            "Free mint already claimed"
        );
        require(
            _totalMinted() + 1 + (AMOUNT_FOR_OWNER - ownerMinted) <= MAX_MINT_SUPPLY,
            "Max mint supply reached"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, freeMintMerkleRoot, leaf), "Invalid Merkle Proof");
        freeMintMerkleWalletList[msg.sender] = true;


        _safeMint(msg.sender, 1);

        emit Minted(msg.sender, 1);
    }

    /**
     * @notice The function to call for allowlist minting
     * @param quantity The number to mint
     * @param _merkleProof The merkle proof to validate on allowlist
     */
    function mintAllowlist(uint256 quantity, bytes32[] calldata _merkleProof) external {
        require(
            allowListSaleActive,
            "Allowlist sale is not active"
        );
        require(
            mintMerkleWalletList[msg.sender] == false,
            "Already minted"
        );
        require(
            quantity <= MAX_ALLOWLIST_MINT,
            "Can't mint that many tokens"
        );
        require(
            _totalMinted() + quantity + (AMOUNT_FOR_OWNER - ownerMinted) <= MAX_MINT_SUPPLY,
            "Max mint supply reached"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, mintMerkleRoot, leaf), "Invalid Merkle Proof");
        mintMerkleWalletList[msg.sender] = true;

        _safeMint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }

    /**
     * @notice The function to call for public minting
     * @param quantity the number of tokens to mint (up to MAX_MINT_PER_TRANSACTION)
     */
    function mintPublic(uint256 quantity) external payable {
        require(
            publicSaleActive,
            "Public sale is not active"
        );
        require(
            quantity <= MAX_MINT_PER_TRANSACTION,
            "Over mint limit"
        );
        require(
            _totalMinted() + quantity + (AMOUNT_FOR_OWNER - ownerMinted) <= MAX_MINT_SUPPLY,
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
    function mintOwner(uint256 quantity) external onlyOwner {
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
    function gift(address to, uint256 quantity) external onlyOwner {
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
     * @notice The function to call for team minting
     * @param quantity The number to mint
     */
    function teamMint(uint256 quantity) external {
        require(
            allowListSaleActive,
            "Allowlist sale is not active"
        );
        require(
            0 < teamMintWalletList[msg.sender] && teamMintWalletList[msg.sender] <= MAX_TEAM_MINT,
            "Not on team or too many requested"
        );
        require(
            _totalMinted() + quantity + (AMOUNT_FOR_OWNER - ownerMinted) <= MAX_MINT_SUPPLY,
            "Max mint supply reached"
        );

        teamMintWalletList[msg.sender] -= quantity;

        _safeMint(msg.sender, quantity);

        emit Minted(msg.sender, quantity);
    }


    /**
    * @notice Initializes team mint wallets
    * @param walletList The list of wallets that will be able to team mint
    */
    function setTeamWallets(address[] memory walletList) external onlyOwner {
        for (uint i; i < walletList.length; i++) {
            teamMintWalletList[walletList[i]] = MAX_TEAM_MINT;
        }
    }

    /**
    * @notice Clears team wallets
    * @param walletList The list of wallets to clear
    */
    function clearTeamWallets(address[] memory walletList) external onlyOwner {
        for (uint i; i < walletList.length; i++) {
            delete teamMintWalletList[walletList[i]];
        }
    }


    /**
     * @notice Withdraws owner funds from the contract after the refund window
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(withdrawalAddress), balance);
        emit Withdrawal(withdrawalAddress, balance);
    }

    /**
    * @notice Sets the address to withdraw to
    * @param _withdrawalAddress The Address to use for future withdrawals
    */
    function setWithdrawalAddress(address _withdrawalAddress) external onlyOwner {
        withdrawalAddress = _withdrawalAddress;
        emit SetWithdrawalAddress(_withdrawalAddress);
    }

//    /**
//     * @notice Gets the baseURI to be used to build a token URI
//     * @return the baseURI string
//     */
//    function _baseURI() internal view override returns (string memory) {
//        if (!revealed) {
//            return notRevealedURI;
//        } else {
//            return baseURI;
//        }
//    }

    /**
     * @notice Returns the token URI, taking into account reveal
     * @param tokenId The id of the token
     * @return The token URI string
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (!revealed) {
            return bytes(notRevealedURI).length != 0 ? string(
                abi.encodePacked(notRevealedURI)) : "";
        } else {
            if(hasUnclaimedReward[tokenId]){
                return bytes(rareRewardBaseURI).length != 0 ? string(
                    abi.encodePacked(rareRewardBaseURI, tokenId.toString(), baseExtension)) : "";
            } else {
            return bytes(baseURI).length != 0 ? string(
                abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
            }
        }
    }

    /**
     * @notice Change the rare reward URI
     * @param rareRewardURI_ The new string to be used
     */
    function setRareRewardBaseURI(string memory rareRewardURI_) external onlyOwner {
        rareRewardBaseURI = rareRewardURI_;
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
     * @notice Toggle the allow list sale status
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
     * @notice Set the mint price
     * @param newPrice The price to use for mint
     */
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    /**
     * @notice Sets Merkle Root for allowlist mint
     * @param _merkleRoot The merkle root for allowlist
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        mintMerkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets Merkle Root for free mint
     * @param _merkleRoot The merkle root for free mint
     */
    function setFreeMintMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        freeMintMerkleRoot = _merkleRoot;
    }

    /**
     * @notice Useful to reset a list of addresses to be able to allowlist mint again.
     * @param walletList A list of addresses to reset
     */
    function initMintMerkleWalletList(address[] memory walletList) external onlyOwner {
        for (uint i; i < walletList.length; i++) {
            mintMerkleWalletList[walletList[i]] = false;
        }
    }

    /**
     * @notice Sets a list of tokens to have their rare rewards claimed
     */
    function markRewardAsClaimed(uint256[] memory tokenList) external onlyOwner {
        for (uint i; i < tokenList.length; i++) {
            hasUnclaimedReward[tokenList[i]] = false;
        }
    }

    /**
     * @notice Sets a list of tokens to have their rare rewards unclaimed
     */
    function markRewardAsUnclaimed(uint256[] memory tokenList) external onlyOwner {
        for (uint i; i < tokenList.length; i++) {
            hasUnclaimedReward[tokenList[i]] = true;
        }
    }

}