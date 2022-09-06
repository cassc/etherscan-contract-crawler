/*

██████╗░██╗██╗░░░░░██╗░░░░░░█████╗░░██████╗░█████╗░██████╗░██╗░░██╗███████╗██████╗░░██████╗
██╔══██╗██║██║░░░░░██║░░░░░██╔══██╗██╔════╝██╔══██╗██╔══██╗██║░░██║██╔════╝██╔══██╗██╔════╝
██████╔╝██║██║░░░░░██║░░░░░██║░░██║╚█████╗░██║░░██║██████╔╝███████║█████╗░░██████╔╝╚█████╗░
██╔═══╝░██║██║░░░░░██║░░░░░██║░░██║░╚═══██╗██║░░██║██╔═══╝░██╔══██║██╔══╝░░██╔══██╗░╚═══██╗
██║░░░░░██║███████╗███████╗╚█████╔╝██████╔╝╚█████╔╝██║░░░░░██║░░██║███████╗██║░░██║██████╔╝
╚═╝░░░░░╚═╝╚══════╝╚══════╝░╚════╝░╚═════╝░░╚════╝░╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═════╝░


 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "Address.sol";
import "Strings.sol";
import "ERC721AQueryable.sol";
import "ReentrancyGuard.sol";
import "MerkleProof.sol";

enum State {
    NotStarted,
    AlphaWave,
    BetaWave,
    PublicSale,
    Frozen,
    SoldOut
}

contract PillHub is ERC721AQueryable, Ownable, ReentrancyGuard {
    // Base URI before for metadata
    string public baseURI;
    // Blind URI before reveal
    string public blindURI;

    uint256 public constant COLLECTION_SIZE = 5555;
    uint256 public tokenPrice = 0.12 ether;

    uint256 public ALPHA_MINT_LIMIT = 2;
    uint256 public BETA_MINT_LIMIT = 1;
    uint256 public PUBLIC_MINT_LIMIT = 5; //TODO add change logic

    uint256 public ALPHA_WAVE_SIZE = 1500;
    uint256 public BETA_WAVE_SIZE = 1500;
    uint256 public PUBLIC_WAVE_SIZE = 2555;

    // Reveal enable/disable
    bool public reveal;

    //MERKLE
    //TODO check the roots!
    bytes32 public ALPHA_merkleRoot =
        0x1c8dc6cbe055292959a9c0e98c505bc6f65d81b793ab5e303d335df7280cd24f;
    bytes32 public BETA_merkleRoot =
        0x69429f80186ed564d5f3bd0a9515ed002872cae4cf9756b52f7c0dbc404398dd;

    // Current Contract state
    State public state = State.NotStarted;
    mapping(address => bool) public whitelistClaimed;

    //todo: constructor

    constructor(string memory _blindURI) ERC721A("TESTERSSSS", "TEST") {
        blindURI = _blindURI;
    }

    /********************/
    /**    MODIFIERS   **/
    /********************/
    // This means that if the smart contract is frozen by the owner, the
    // function is executed an exception is thrown
    modifier notFrozen() {
        require(state != State.Frozen, "Pillosophers: frozen!");
        _;
    }
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract!");
        _;
    }

    /******************************/
    /**    ONLYOWNER Functions   **/
    /******************************/
    /// @notice reveal now, called only by owner
    /// @dev reveal metadata for NFTs
    function revealNow() external onlyOwner {
        reveal = true;
    }

    /// @notice setBaseURI, called only by owner
    /// @dev set Base URI
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function setBlindURI(string memory _URI) external onlyOwner {
        blindURI = _URI;
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setPublicMintLimitSize(uint256 _newSize) external onlyOwner {
        PUBLIC_MINT_LIMIT = _newSize;
    }

    /// @notice freeze now, called only by owner
    /// @dev freeze minting !! only an emergency function!!
    function freezeNow() external onlyOwner notFrozen {
        state = State.Frozen;
    }

    function startAlphaWave() external onlyOwner {
        state = State.AlphaWave;
    }

    function startBetaWave() external onlyOwner {
        state = State.BetaWave;
    }

    function startPublicSale(uint256 _newPrice) external onlyOwner {
        state = State.PublicSale;
        tokenPrice = _newPrice;
    }

    function soldOut() external onlyOwner notFrozen {
        require(totalSupply() == COLLECTION_SIZE, "Sale is still on!");
        state = State.SoldOut;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /******************************/
    /**      Public Functions    **/
    /******************************/

    function tokenMint(uint256 _quantity, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser
        notFrozen
    {
        require(
            (state == State.AlphaWave ||
                state == State.BetaWave ||
                state == State.PublicSale),
            "Sale has not started yet."
        );

        if (state == State.AlphaWave) {
            require(
                totalSupply() + _quantity <= ALPHA_WAVE_SIZE,
                "reached max supply"
            );
            require(!whitelistClaimed[msg.sender], "Address already claimed");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(_merkleProof, ALPHA_merkleRoot, leaf),
                "Invalid Merkle Proof."
            );
            require(
                _quantity <= ALPHA_MINT_LIMIT,
                "you will exceed the max whitelist limit"
            );
            whitelistClaimed[msg.sender] = true;
            _safeMint(msg.sender, _quantity);
        } else if (state == State.BetaWave) {
            require(
                totalSupply() + _quantity <= ALPHA_WAVE_SIZE + BETA_WAVE_SIZE,
                "reached max supply"
            );
            require(!whitelistClaimed[msg.sender], "Address already claimed");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(_merkleProof, BETA_merkleRoot, leaf),
                "Invalid Merkle Proof."
            );
            require(
                _quantity <= BETA_MINT_LIMIT,
                "you will exceed the max whitelist limit"
            );
            whitelistClaimed[msg.sender] = true;
            _safeMint(msg.sender, _quantity);
        } else if (state == State.PublicSale) {
            require(
                totalSupply() + _quantity <= COLLECTION_SIZE,
                "reached max supply"
            );
            require(msg.value >= _quantity * tokenPrice, "Insufficient funds.");
            require(
                numberMinted(msg.sender) + _quantity <= PUBLIC_MINT_LIMIT,
                "can not mint this many"
            );
            _safeMint(msg.sender, _quantity);
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");
        if (!reveal) {
            return
                string(
                    abi.encodePacked(
                        blindURI,
                        "/",
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /******************************/
    /**     Internal Functions   **/
    /******************************/
}