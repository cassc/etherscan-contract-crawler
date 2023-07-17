// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./Z3roOwnership.sol";
import "./Z3roUtility.sol";

contract Z3roIdentity is Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;

    address public immutable genesisZ3ro;
    address private immutable multiSig;
    uint256 public STAGE_MAX_SUPPLY_1;
    uint256 public STAGE_MAX_SUPPLY_2;
    uint256 public STAGE_MAX_SUPPLY_3;

    uint256 public cteam_sets = 111;

    string private baseTokenURI;

    bytes32 public whitelist;
    bytes32 public freelist;

    bool public genesisCleared = false;
    bool public revealed = false;

    struct Configs {
        bool onlyWhitelist;
        bool allowFl;
        uint8 stage;
        uint8 max_wallet_sets;
        uint8 max_wallet_sets_2;
        uint8 max_wallet_sets_3;
        uint8 max_fl_sets;
        uint16 max_wl_supply;
        uint256 mint_cost;
    }

    Configs public configs;

    Z3roOwnership public z3roOwnership;
    Z3roUtility public z3roUtility;

    constructor(
        uint256 stageSupply,
        uint8 maxWalletSets,
        address _genesisZ3ro,
        address _multiSig
    ) ERC721A("z3rocollective", "Z3RO") {
        STAGE_MAX_SUPPLY_1 = stageSupply;

        genesisZ3ro = _genesisZ3ro;

        multiSig = _multiSig;

        z3roOwnership = new Z3roOwnership(address(this), multiSig);
        z3roUtility = new Z3roUtility(address(this), multiSig);

        configs = Configs(
            true, // onlyWhitelist
            true, // allowFl
            1, // stage
            maxWalletSets, // max_wallet_sets
            0, // max_wallet_sets_2
            0, // max_wallet_sets_3
            1, // max_fl_sets
            1111, // max_wl_supply
            0.03 ether // mint_cost
        );
    }

    /* EVENTS & MODIFIERS*/
    event minted(address to, uint256 qty);

    modifier isUser() {
        require(
            tx.origin == _msgSenderERC721A(),
            "The caller is another contract, must be user."
        );
        _;
    }

    function stage1Owned() internal view returns (uint256 counter) {
        for (uint256 i = 0; i < STAGE_MAX_SUPPLY_1; i++) {
            if (ownerOf(i) == _msgSenderERC721A()) {
                counter++;
            }
        }
    }

    function stage1and2Owned() internal view returns (uint256 counter) {
        for (uint256 i = 0; i < STAGE_MAX_SUPPLY_1 + STAGE_MAX_SUPPLY_2; i++) {
            if (ownerOf(i) == _msgSenderERC721A()) {
                counter++;
            }
        }
    }

    modifier isEligibleMint(uint256 batchQty, bool teamMint) {
        require(revealed, "Not revealed yet.");

        /* Configs sanity check */
        if (!teamMint) {
            require(configs.stage > 0, "Minting not started yet.");
            require(configs.mint_cost > 0, "Awkward...");
            require(
                configs.max_wallet_sets > 0,
                "Max wallet sets not defined."
            );
            require(
                configs.max_wl_supply > 0,
                "Max Whitelist supply not defined."
            );
        }

        if (configs.stage == 1) {
            // there is a limit to the supply
            require(
                _totalMinted() + batchQty <= STAGE_MAX_SUPPLY_1,
                "Stage 1 sold out"
            );
        } else if (configs.stage == 2) {
            require(
                _totalMinted() + batchQty <=
                    STAGE_MAX_SUPPLY_1 + STAGE_MAX_SUPPLY_2,
                "Stage 2 sold out"
            );
        } else if (configs.stage == 3) {
            require(
                _totalMinted() + batchQty <=
                    STAGE_MAX_SUPPLY_1 +
                        STAGE_MAX_SUPPLY_2 +
                        STAGE_MAX_SUPPLY_3,
                "Stage 3 sold out"
            );
        }
        _;
    }

    modifier isOnList(
        uint256 batchQty,
        bytes32[] calldata proof,
        bytes32 leaf,
        bool teamMint
    ) {
        if (!teamMint) {
            if (configs.onlyWhitelist) {
                require(whitelist != "", "wl root not set");
                require(
                    _totalMinted() + batchQty <= configs.max_wl_supply,
                    "You tried to mint more than the currently available supply."
                );

                require(
                    MerkleProof.verify(proof, whitelist, leaf),
                    "You are not on the whitelist"
                );
            } else {
                require(
                    _totalMinted() + batchQty <= configs.max_wl_supply,
                    "You tried to mint more than the currently available supply."
                );
            }
        } else {
            require(configs.allowFl, "Fl not allowed");
            require(freelist != "", "fl root not set");
            require(
                MerkleProof.verify(proof, freelist, leaf),
                "You are not on the fl"
            );
        }
        _;
    }

    modifier isUnderWalletLimit(uint256 batchQty) {
        if (configs.stage == 1) {
            // user cannot go over max mints per wallet
            require(
                batchQty + _numberMinted(_msgSenderERC721A()) <=
                    configs.max_wallet_sets,
                "Tried to mint more than permited per wallet"
            );
        } else if (configs.stage == 2) {
            // check amout of tokens between 0 <= STAGE_MAX_SUPPLY_1
            uint256 previousMints = stage1Owned();
            require(
                (batchQty + _numberMinted(_msgSenderERC721A())) -
                    previousMints <=
                    configs.max_wallet_sets_2,
                "Tried to mint more than permited per wallet"
            );
        } else if (configs.stage == 3) {
            // check amout of tokens between 0 <= STAGE_MAX_SUPPLY_1 + STAGE_MAX_SUPPLY_2
            uint256 previousMints = stage1and2Owned();
            require(
                (batchQty + _numberMinted(_msgSenderERC721A())) -
                    previousMints <=
                    configs.max_wallet_sets_3,
                "Tried to mint more than permited per wallet"
            );
        }
        _;
    }

    function isOnTeam(
        uint256 batchQty,
        bytes32[] calldata proof,
        bytes32 leaf
    ) private view returns (bool) {
        require(configs.allowFl, "Allow fl not set");
        require(freelist != "", "fl root not set");
        require(
            _numberMinted(_msgSenderERC721A()) + batchQty <=
                configs.max_fl_sets,
            "Cannot fl mint more than permited"
        );
        require(
            MerkleProof.verify(proof, freelist, leaf),
            "You are not on the fl"
        );

        return true;
    }

    /* FUNCTIONS */

    function Z3roGenesis(address[] calldata genesisAddresses)
        external
        onlyOwner
    {
        require(!genesisCleared, "Genesis fix is concluded");

        for (uint256 i = 0; i < genesisAddresses.length; i++) {
            uint256 mintsDone = IERC721A(genesisZ3ro).balanceOf(
                genesisAddresses[i]
            );
            if (mintsDone < 1) {
                continue;
            }

            uint256 airdropMints = (mintsDone * 2) + mintsDone;

            //mint Identity
            _safeMint(genesisAddresses[i], airdropMints);
            //mint Ownership
            Z3roOwnership(z3roOwnership).genesisMint(
                genesisAddresses[i],
                airdropMints
            );
            //mint Utility
            Z3roUtility(z3roUtility).genesisMint(
                genesisAddresses[i],
                airdropMints
            );
        }
    }

    /* external */
    function enterZ3ro(
        uint256 qty,
        bytes32[] calldata proof,
        bytes32 leaf,
        bool _teamMint
    )
        external
        payable
        nonReentrant
        isUser
        isEligibleMint(qty, false)
        isUnderWalletLimit(qty)
        isOnList(qty, proof, leaf, _teamMint)
    {
        if (_teamMint && isOnTeam(qty, proof, leaf)) {
            // continue
        } else {
            require(msg.value >= configs.mint_cost, "Not enough eth sent");
        }

        //mint Identity
        _safeMint(_msgSenderERC721A(), qty);
        //mint Ownership
        Z3roOwnership(z3roOwnership).identifyZ3ro(qty);
        //mint Utility
        Z3roUtility(z3roUtility).useZ3ro(qty);

        emit minted(_msgSenderERC721A(), qty);
    }

    function cteamMint(uint256 qty) external onlyOwner {
        require(_numberMinted(_msgSenderERC721A()) + qty <= cteam_sets);
        if (configs.stage == 1) {
            require(_totalMinted() + qty <= STAGE_MAX_SUPPLY_1);
        } else if (configs.stage == 2) {
            require(_totalMinted() + qty <= STAGE_MAX_SUPPLY_2);
        } else if (configs.stage == 3) {
            require(_totalMinted() + qty <= STAGE_MAX_SUPPLY_3);
        }

        //mint Identity
        _safeMint(_msgSenderERC721A(), qty);
        //mint Ownership
        Z3roOwnership(z3roOwnership).identifyZ3ro(qty);
        //mint Utility
        Z3roUtility(z3roUtility).useZ3ro(qty);

        emit minted(_msgSenderERC721A(), qty);
    }

    /* GETTERS AND SETTERS */

    function clearGenesis() external onlyOwner {
        genesisCleared = true;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setRevealed(bool isRevealed) external onlyOwner {
        revealed = isRevealed;
    }

    function setOnlyWhitelist(bool isOnlyWl) external onlyOwner {
        configs.onlyWhitelist = isOnlyWl;
    }

    function setStage(uint8 stage) external onlyOwner {
        configs.stage = stage;
    }

    function setStageSupply1(uint256 supply) external onlyOwner {
        require(configs.stage == 1);
        STAGE_MAX_SUPPLY_1 = supply;
    }

    function setStageSupply2(uint256 supply) external onlyOwner {
        require(configs.stage == 2);
        STAGE_MAX_SUPPLY_2 = supply;
    }

    function setStageSupply3(uint256 supply) external onlyOwner {
        require(configs.stage == 3);
        STAGE_MAX_SUPPLY_3 = supply;
    }

    function setMaxWalletSets(uint8 max) external onlyOwner {
        configs.max_wallet_sets = max;
    }

    function setMaxWalletSets2(uint8 max) external onlyOwner {
        configs.max_wallet_sets_2 = max;
    }

    function setMaxWalletSets3(uint8 max) external onlyOwner {
        configs.max_wallet_sets_3 = max;
    }

    function setMaxWlSupply(uint16 max) external onlyOwner {
        configs.max_wl_supply = max;
    }

    function setTeamSets(uint256 sets) external onlyOwner {
        cteam_sets = sets;
    }

    function setMintCost(uint256 cost) external onlyOwner {
        configs.mint_cost = cost;
    }

    function setWhitelistMerkleRoot(bytes32 root) external onlyOwner {
        whitelist = root;
    }

    function setFlMerkleRoot(bytes32 root) external onlyOwner {
        freelist = root;
    }

    function setAllowFl(bool allow) external onlyOwner {
        configs.allowFl = allow;
    }

    function withdrawFunds() external nonReentrant onlyOwner {
        (bool success, ) = payable(multiSig).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function getTotalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /* internal */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}