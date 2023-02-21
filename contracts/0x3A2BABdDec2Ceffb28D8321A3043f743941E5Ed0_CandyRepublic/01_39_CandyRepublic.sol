// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./ERC721SeaDrop.sol";
import { IERC721 } from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC2981 } from "lib/openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import { MerkleProof } from "./lib/MerkleProof.sol";

interface IERC5639 {
    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault)
        external
        view
        returns (bool);
}

contract CandyRepublic is ERC721SeaDrop {
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // The Genesis NFT Collection smart contract address
    address private constant _GENESIS_COLLECTION_ADDRESS =
        0x1Be6f6BAc65573b68FEfBdf89c5c1FA7f3A5805b;

    // The CandyRepublic address
    address private constant _CANDY =
        0xa0e091347827eC3fFC0E85389b8f0014E2895f15;

    // The CandyRepublic secondary address
    address private constant _CANDY_2 =
        0x4C90a5584aBfe69462b6Dec304A78a59FE18b2b4;

    // The Delegeate cash address
    address private constant _DELEGATE_CASH_ADDRESS =
        0x00000000000076A84feF008CDAbe6409d2FE638B;

    // The OpenSea Registry smart contract address
    address private constant _PROXY_REGISTRY_ADDRESS =
        0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    // NFT total supply
    uint256 private constant _TOTAL_SUPPLY = 6250;

    // NFT sale window
    uint256 private constant _MINT_START = 1677175200;

    // Genesis + Derivative = OG_WINDOW
    uint256 private constant _OG_WINDOW_START = _MINT_START;
    uint256 private constant _OG_WINDOW_END = _OG_WINDOW_START + 6 hours;

    // Prospects + Whitelist A = WHITELIST_WINDOW
    uint256 private constant _WHITELIST_WINDOW_START = _MINT_START + 2 hours;
    uint256 private constant _WHITELIST_WINDOW_END =
        _WHITELIST_WINDOW_START + 4 hours;

    // Whitelist B = FINAL_WINDOW
    uint256 private constant _FINAL_WINDOW_START = _MINT_START + 6 hours;
    uint256 private constant _FINAL_WINDOW_END = _FINAL_WINDOW_START + 2 hours;

    // Public mint
    uint256 private constant _PUBLIC_WINDOW_START = _FINAL_WINDOW_END;
    uint256 private constant _PUBLIC_WINDOW_END =
        _PUBLIC_WINDOW_START + 1 hours;

    // The maxmimum mint/wallet
    uint256 private constant _MINT_PRICE = 0.08 ether;
    uint256 private constant _MINT_PRICE_PROSPECT = 0.07 ether;
    uint256 private constant _MINT_CAP = 2;
    uint256 private constant _DERIVATIVES_FREE_MINT_CAP = 1;
    uint256 private constant _PUBLIC_MINT_CAP = 1;
    uint256 private constant _GENESIS_BITMAP_LENGTH = 2;

    // =============================================================
    //                         STORAGE
    // =============================================================

    // The merkle tree root hash for the genesis addresses.
    bytes32 private _DERIVATIVES_WHITELIST_ROOT =
        0x126095171d42ac1451766cfb60a5782db96c342ec125d1ddf9daaeeedfe0e090;

    // The merkle tree root hash for the prospects addresses.
    bytes32 private _WHITELIST_PROSPECT_ROOT =
        0xc488b8656c7c3ee37169e932772c4b8660d18a09978030f7ffb9d1f52f31104c;

    // The merkle tree root hash for the whitelistA addresses.
    bytes32 private _WHITELIST_A_ROOT =
        0x35746d68b4141332427ac8a6e1041112f988c94ea29d33762060fbefedcd7d2d;

    // The merkle tree root hash for the whitelistB addresses.
    bytes32 private _WHITELIST_B_ROOT =
        0x7c8f4d87b09d246b54c0f44eff5435b58ec9c9d71282d07d197516c2771497a5;

    // Bitmap representing used genesis token ids
    uint256 private GenesisBitmap = 0;
    bool private didReserve = false;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address[] memory seaDropAllowlist
    ) ERC721SeaDrop(name_, symbol_, seaDropAllowlist) {}

    function reserveTeam() external onlyOwner {
        // Ensure the sender can call it once.
        require(!didReserve);
        didReserve = true;

        _mint(_CANDY, 250);
    }

    function configureWhitelists(
        bytes32 derivatives,
        bytes32 prospects,
        bytes32 whitelistA,
        bytes32 whitelistB
    ) external onlyOwner {
        _DERIVATIVES_WHITELIST_ROOT = derivatives;
        _WHITELIST_PROSPECT_ROOT = prospects;
        _WHITELIST_A_ROOT = whitelistA;
        _WHITELIST_B_ROOT = whitelistB;
    }

    function isWhitelist(
        bytes32[] calldata proof,
        bytes32 leaf,
        bytes32 root
    ) internal pure returns (bool) {
        return MerkleProof.verifyCalldata(proof, root, leaf);
    }

    function inOGPeriod() internal view returns (bool) {
        return
            block.timestamp >= _OG_WINDOW_START &&
            block.timestamp <= _OG_WINDOW_END;
    }

    function inWhitelistPeriod() internal view returns (bool) {
        return
            block.timestamp >= _WHITELIST_WINDOW_START &&
            block.timestamp <= _WHITELIST_WINDOW_END;
    }

    function inFinalPeriod() internal view returns (bool) {
        return
            block.timestamp >= _FINAL_WINDOW_START &&
            block.timestamp <= _FINAL_WINDOW_START;
    }

    function inPublicPeriod() internal view returns (bool) {
        return
            block.timestamp >= _PUBLIC_WINDOW_START &&
            block.timestamp <= _PUBLIC_WINDOW_START;
    }

    function getGenesisBitmap() external view returns (uint256) {
        return GenesisBitmap;
    }

    function getPrice(
        address wallet,
        uint256 mintType,
        uint256 quantity
    ) public view returns (uint256) {
        // 1: Derivatives
        if (mintType == 1) {
            uint256 numberMinted = _numberMinted(wallet);
            if (quantity == 2 || numberMinted == 1) {
                return _MINT_PRICE;
            }
            return 0;
        }

        // 2: Prospects
        if (mintType == 2) {
            return quantity * _MINT_PRICE_PROSPECT;
        }

        // Other: WhitelistA/B
        return quantity * _MINT_PRICE;
    }

    function genesisMint(uint256[] calldata genesisTokenID, address vault)
        external
    {
        require(tx.origin == msg.sender, "Caller is Smart Contract");
        require(inOGPeriod(), "Not in mint window!");
        uint256[] memory genesisTokenIDMemory = genesisTokenID;
        uint256 genesisLength = genesisTokenIDMemory.length;
        uint256 currentSupply = totalSupply();
        require(
            genesisLength + currentSupply <= _TOTAL_SUPPLY,
            "Exceeding Limit!"
        );

        uint256 mintQuantity;
        uint256 mintedFromThatNFT;
        uint256 finalOring;
        uint256 memoryGenesis = GenesisBitmap;
        uint256 shifting;

        IERC721 GenesisSmartContract = IERC721(_GENESIS_COLLECTION_ADDRESS);

        address requester = msg.sender;
        if (vault != address(0)) {
            IERC5639 DelegateRegistry = IERC5639(_DELEGATE_CASH_ADDRESS);
            require(
                DelegateRegistry.checkDelegateForAll(msg.sender, vault),
                "Not delegate!"
            );
            requester = vault;
        }

        for (uint256 index; index < genesisLength; ) {
            require(
                GenesisSmartContract.ownerOf(genesisTokenIDMemory[index]) ==
                    requester,
                "Not owner of tokenID!"
            );
            shifting = 2 * (genesisTokenIDMemory[index] - 1);
            mintedFromThatNFT = (memoryGenesis & (3 << shifting)) >> shifting;

            if (mintedFromThatNFT == 0) {
                mintQuantity += _GENESIS_BITMAP_LENGTH;
                finalOring = finalOring ^ (3 << shifting);
            }

            unchecked {
                ++index;
            }
        }
        require(mintQuantity > 0, "Can't mint anymore!");

        // Set genesis bitmap
        GenesisBitmap = (memoryGenesis ^ finalOring);

        _mint(msg.sender, mintQuantity);
    }

    function derivativeMint(
        bytes32[] calldata derivativeProof,
        uint256 quantity
    ) external payable {
        require(tx.origin == msg.sender, "Caller is Smart Contract");
        // Check for correct window period
        require(inWhitelistPeriod(), "Not in mint window!");

        // Check total supply
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + quantity <= _TOTAL_SUPPLY,
            "Exceeding 6250 NFTs!"
        );

        // Check mint cap
        uint256 numberMinted = _numberMinted(msg.sender);
        require(
            numberMinted + quantity <= _MINT_CAP,
            "Can't mint more than 2!"
        );

        // Check if whitelisted
        require(
            isWhitelist(
                derivativeProof,
                keccak256(abi.encodePacked(msg.sender)),
                _DERIVATIVES_WHITELIST_ROOT
            ),
            "Not whitelisted!"
        );
        // Check if paid the correct ammount of ETH
        require(
            msg.value == getPrice(msg.sender, 1, quantity),
            "Incorrect payment value!"
        );
        _mint(msg.sender, quantity);
    }

    function whitelistProspectMint(
        bytes32[] calldata whitelistProof,
        uint256 quantity
    ) external payable {
        require(tx.origin == msg.sender, "Caller is Smart Contract");
        // Check for correct window period
        require(inWhitelistPeriod(), "Not in mint window!");

        // Check total supply
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + quantity <= _TOTAL_SUPPLY,
            "Exceeding 6250 NFTs!"
        );

        // Check mint cap
        uint256 numberMinted = _numberMinted(msg.sender);
        require(
            numberMinted + quantity <= _MINT_CAP,
            "Can't mint more than 2!"
        );

        // Check if whitelisted
        require(
            isWhitelist(
                whitelistProof,
                keccak256(abi.encodePacked(msg.sender)),
                _WHITELIST_PROSPECT_ROOT
            ),
            "Not whitelisted!"
        );
        // Check if paid the correct ammount of ETH
        require(
            msg.value == getPrice(msg.sender, 2, quantity),
            "Incorrect Payment Value!"
        );
        _mint(msg.sender, quantity);
    }

    function whitelistAMint(bytes32[] calldata whitelistProof, uint256 quantity)
        external
        payable
    {
        require(tx.origin == msg.sender, "Caller is Smart Contract");
        // Check for correct window period
        require(inWhitelistPeriod(), "Not in mint window!");

        // Check total supply
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + quantity <= _TOTAL_SUPPLY,
            "Exceeding 6250 NFTs!"
        );

        // Check mint cap
        uint256 numberMinted = _numberMinted(msg.sender);
        require(
            numberMinted + quantity <= _MINT_CAP,
            "Can't mint more than 2!"
        );

        // Check if whitelisted
        require(
            isWhitelist(
                whitelistProof,
                keccak256(abi.encodePacked(msg.sender)),
                _WHITELIST_A_ROOT
            ),
            "Not whitelisted!"
        );

        // Check if paid the correct ammount of ETH
        require(
            msg.value == getPrice(msg.sender, 3, quantity),
            "Incorrect Payment Value!"
        );
        _mint(msg.sender, quantity);
    }

    function whitelistBMint(bytes32[] calldata whitelistProof, uint256 quantity)
        external
        payable
    {
        require(tx.origin == msg.sender, "Caller is Smart Contract");
        // Check for correct window period
        require(inFinalPeriod(), "Not in mint window!");

        // Check total supply
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + quantity <= _TOTAL_SUPPLY,
            "Exceeding 6250 NFTs!"
        );

        // Check mint cap
        uint256 numberMinted = _numberMinted(msg.sender);
        require(
            numberMinted + quantity <= _MINT_CAP,
            "Can't mint more than 2!"
        );

        // Check if whitelisted
        require(
            isWhitelist(
                whitelistProof,
                keccak256(abi.encodePacked(msg.sender)),
                _WHITELIST_B_ROOT
            ),
            "Not whitelisted!"
        );

        // Check if paid the correct ammount of ETH
        require(
            msg.value == getPrice(msg.sender, 3, quantity),
            "Incorrect Payment Value!"
        );
        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(tx.origin == msg.sender, "Caller is Smart Contract");
        // Check for correct window period
        require(inPublicPeriod(), "Not in mint window!");

        // Check total supply
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + quantity <= _TOTAL_SUPPLY,
            "Exceeding 6250 NFTs!"
        );
        require(quantity == _PUBLIC_MINT_CAP, "Can't mint more than 1!");

        // Check if paid the correct ammount of ETH
        require(
            msg.value == getPrice(msg.sender, 3, quantity),
            "Incorrect Payment Value!"
        );
        _mint(msg.sender, quantity);
    }

    // Withdraw ETH Funds
    function withdrawETHFunds() external onlyOwner {
        (bool success, ) = _CANDY.call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

    function getNumberMinted(address _address) external view returns (uint256) {
        return _numberMinted(_address);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     *
     * @ param  _tokenId     The NFT asset queried for royalty information.
     * @param  _salePrice    The sale price of the NFT asset specified by
     *                       _tokenId.
     *
     * @return receiver      Address of who should be sent the royalty payment.
     * @return royaltyAmount The royalty payment amount for _salePrice.
     */
    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    )
        external
        pure
        override(ERC721ContractMetadata, IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        // Set the royalty amount to the sale price times the royalty basis
        // points divided by 10_000.
        royaltyAmount = (_salePrice * 300) / 10_000;

        // Set the receiver of the royalty.
        receiver = _CANDY_2;
    }
}