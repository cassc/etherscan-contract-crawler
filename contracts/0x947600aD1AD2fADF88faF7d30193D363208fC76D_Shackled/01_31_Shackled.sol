// // SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledUtils.sol";
import "./ShackledStructs.sol";
import "./ShackledRenderer.sol";
import "./ShackledGenesis.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Shackled is ERC721Enumerable, Ownable {
    /// minting parameters for the Genesis collection
    bytes32 public mintState;
    bytes32 public publicMintState = keccak256(abi.encodePacked("public_mint"));
    bytes32 public presaleMintState = keccak256(abi.encodePacked("presale"));
    uint256 public maxSupply = 1024;
    uint256 public mintPrice = 0.15 ether;
    uint256 public reservedTokens = 20;
    uint256 public txnQtyLimit = 5;
    mapping(uint256 => bytes32) public tokenSeedHashes;

    /// rendering engine parameters
    int256 public canvasDim = 128;
    uint256 public outputHeight = 512;
    uint256 public outputWidth = 512;
    bool public returnSVG = true;

    event Received(address, uint256);

    constructor() ERC721("Shackled", "SHACKLED") {}

    /** @dev Mint allocated token IDs assigned to active Dawn Key holders.
     * @param quantity The amount to mint
     * @param allowlistMintIds The allocated ids to mint at mintPrice
     * @param dawnKeyMintIds The allocated ids to mint free
     * @param signature The signature to verify
     */
    function presaleMint(
        uint256 quantity,
        uint256[] calldata allowlistMintIds,
        uint256[] calldata dawnKeyMintIds,
        bytes calldata signature
    ) public payable {
        require(presaleMintState == mintState, "Presale mint is not active");

        /// verify the signature to confirm valid paramaters have been sent
        require(
            checkSignature(signature, allowlistMintIds, dawnKeyMintIds),
            "Invalid signature"
        );

        uint256 nMintableIds = allowlistMintIds.length + dawnKeyMintIds.length;

        /// check that the current balance indicates tokens are still mintable
        /// to raise an error and stop the transaction that wont lead to any mints
        /// note that this doesnt guarantee tokens haven't been minted
        /// as they may have been transfered out of the holder's wallet
        require(
            quantity + balanceOf(msg.sender) <= nMintableIds,
            "Quantity requested is too high"
        );

        /// determine how many allowlistMints are being made
        /// and that sufficient value has been sent to cover this
        uint256 dawnKeyMintsRequested;
        for (uint256 i = 0; i < dawnKeyMintIds.length; i++) {
            if (!_exists(dawnKeyMintIds[i])) {
                if (dawnKeyMintsRequested < quantity) {
                    dawnKeyMintsRequested++;
                } else {
                    break;
                }
            }
        }

        uint256 allowListMintsRequested = quantity - dawnKeyMintsRequested;

        require(
            msg.value >= mintPrice * allowListMintsRequested,
            "Insufficient value to mint"
        );

        /// iterate through all mintable ids (dawn key mints first)
        /// and mint up to the requested quantity
        uint16 numMinted;
        for (uint256 i = 0; i < nMintableIds; ++i) {
            if (numMinted == quantity) {
                break;
            }

            bool dawnKeyMint = i < dawnKeyMintIds.length;

            uint256 tokenId = dawnKeyMint
                ? dawnKeyMintIds[i]
                : allowlistMintIds[i - dawnKeyMintIds.length];

            /// check that this specific token is mintable
            /// prevents minting, transfering out of the wallet, and minting again
            if (_exists(tokenId)) {
                continue;
            }

            _safeMint(msg.sender, tokenId);
            storeSeedHash(tokenId);
            ++numMinted;
        }
        require(numMinted == quantity, "Requested quantity not minted");
    }

    /** @dev Mints a token during the public mint phase
     * @param quantity The quantity of tokens to mint
     */
    function publicMint(uint256 quantity) public payable {
        require(mintState == publicMintState, "Public mint is not active");
        require(quantity <= txnQtyLimit, "Quantity exceeds txn limit");

        // check the txn value
        require(
            msg.value >= mintPrice * quantity,
            "Insufficient value to mint"
        );

        /// Disallow transactions that would exceed the maxSupply
        require(
            totalSupply() + quantity <= maxSupply,
            "Insufficient supply remaining"
        );

        /// mint the requested quantity
        /// go through the whole supply to find tokens
        /// as some may not have been minted in presale
        uint256 minted;
        for (uint256 tokenId = 0; tokenId < maxSupply; tokenId++) {
            if (!_exists(tokenId)) {
                _safeMint(msg.sender, tokenId);
                storeSeedHash(tokenId);
                minted++;
            }
            if (minted == quantity) {
                break;
            }
        }
    }

    /** @dev Store the seedhash for a tokenId */
    function storeSeedHash(uint256 tokenId) internal {
        require(_exists(tokenId), "TokenId does not exist");
        require(tokenSeedHashes[tokenId] == 0, "Seed hash already set");
        /// create a hash that will be used to seed each Genesis piece
        /// use a range of parameters to reduce predictability and gamification
        tokenSeedHashes[tokenId] = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.difficulty,
                msg.sender,
                tokenId
            )
        );
    }

    /** @dev Set the contract's mint state
     */
    function setMintState(string memory newMintState) public onlyOwner {
        mintState = keccak256(abi.encodePacked(newMintState));
    }

    /** @dev validate a signature
     */
    function checkSignature(
        bytes memory signature,
        uint256[] calldata allowlistMintIds,
        uint256[] calldata dawnKeyMintIds
    ) public view returns (bool) {
        bytes32 payloadHash = keccak256(
            abi.encode(this, msg.sender, allowlistMintIds, dawnKeyMintIds)
        );
        address actualSigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(payloadHash),
            signature
        );
        address owner = owner();
        return (owner == actualSigner);
    }

    /**
     * @dev Set some tokens aside for the team
     */
    function reserveTokens() public onlyOwner {
        for (uint256 i = 0; i < reservedTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
            storeSeedHash(tokenId);
        }
    }

    /**
     * @dev Withdraw ether to owner's wallet
     */
    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdraw failed");
    }

    /** @dev run the rendering engine on any given renderParams */
    function render(
        ShackledStructs.RenderParams memory renderParams,
        int256 canvasDim_,
        bool returnSVG
    ) public view returns (string memory) {
        return ShackledRenderer.render(renderParams, canvasDim_, returnSVG);
    }

    /** generate a genesis piece from a given tokenHash */
    function generateGenesisPiece(bytes32 tokenHash)
        public
        view
        returns (
            ShackledStructs.RenderParams memory,
            ShackledStructs.Metadata memory
        )
    {
        return ShackledGenesis.generateGenesisPiece(tokenHash);
    }

    /** @dev render the art for a Shackled Genesis NFT and get the 'raw' metadata
     */
    function renderGenesis(uint256 tokenId, int256 canvasDim_)
        public
        view
        returns (
            string memory,
            ShackledStructs.RenderParams memory,
            ShackledStructs.Metadata memory
        )
    {
        /// get the hash created when this token was minted
        bytes32 tokenHash = tokenSeedHashes[tokenId];

        /// generate the geometry and color of this genesis piece
        (
            ShackledStructs.RenderParams memory renderParams,
            ShackledStructs.Metadata memory metadata
        ) = ShackledGenesis.generateGenesisPiece(tokenHash);

        // run the rendering engine and return an encoded image
        string memory image = ShackledRenderer.render(
            renderParams,
            canvasDim_,
            returnSVG
        );

        return (image, renderParams, metadata);
    }

    /** @dev run the rendering engine and return a token's final metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        (
            string memory image,
            ShackledStructs.RenderParams memory renderParams,
            ShackledStructs.Metadata memory metadata
        ) = renderGenesis(tokenId, canvasDim);

        // construct and encode the metadata json
        return ShackledUtils.getEncodedMetadata(image, metadata, tokenId);
    }

    /** @dev change the canvas size to render on
     */
    function updateCanvasDim(int256 _canvasDim) public onlyOwner {
        canvasDim = _canvasDim;
    }

    /** @dev change the desired output width to interpolate to in the svg container
     */
    function updateOutputWidth(uint256 _outputWidth) public onlyOwner {
        outputWidth = _outputWidth;
    }

    /** @dev change the desired output height to interpolate to in the svg container
     */
    function updateOutputHeight(uint256 _outputHeight) public onlyOwner {
        outputHeight = _outputHeight;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}