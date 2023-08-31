//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./JoyridePartImports.sol";

//              _   ____ __     __ _____   _____  _____   ______   _____
//             | | / __ \\ \   / /|  __ \ |_   _||  __ \ |  ____| / ____|
//             | || |  | |\ \_/ / | |__) |  | |  | |  | || |__   | (___
//         _   | || |  | | \   /  |  _  /   | |  | |  | ||  __|   \___ \
//        | |__| || |__| |  | |   | | \ \  _| |_ | |__| || |____  ____) |
//         \____/  \____/   |_|   |_|  \_\|_____||_____/ |______||_____/
//
contract JoyrideParts is
    ERC721A,
    Ownable,
    Pausable,
    WithSaleStart,
    WithPresaleStart,
    WithERC721AMetadata
{
    /**
    @notice The IPFS CID of all Joyride parts. These will be randomised during token reveal
    with the `RANDOMISATION_SCRIPT`. It will be published when all tokens are minted.
    */
    string constant public PROVENANCE_HASH = "QmPNromyewqCEguDWmnaaD8S17ZAQpyeb5cZ7mwsQCXfZE";

    /**
    @notice The IPFS CID of the script with which all items in the `PROVENANCE_HASH` will be
    randomly assigned to their respective token IDs.
     */
    string constant public RANDOMISATION_SCRIPT = "QmcqXiimpsRpKg2XeTkNLxeociR4qWtFzrTu2mRThn3Tv1";

    /// @notice There will only be 3000 Joyride cars (3000 tops and bases).
    uint256 constant public MAX_TOKENS = 6000;

    /// @dev 999 Blobs get a free car part each.
    uint256 constant private TOKENS_FOR_CLAIM = 999;

    /// @dev During public mint you can purchase 10 parts per transaction.
    uint256 constant private MAX_TOKENS_PER_PURCHASE = 10;

    /// @notice The price of each Joyride car part.
    uint256 public tokenPrice = 0.08 ether;

    /// @dev Used to check Blobs ownership of Blobs for the Bloblist.
    Blobs public blobs;

    /// @dev Used to know who is allowed to assemble the cars.
    address private joyrideAddress;

    /// @dev Used to know who is allowed to assemble the cars.
    address private signerAddress;

    /// @dev Used to check whether Blobs have been used to claim free parts.
    mapping(uint256 => bool) private _claimedTokens;

    /// @dev Used to limit the number of items bought during presale.
    mapping(address => uint8) private _purchasedDuringPresale;

    /// @dev Keeps track of the total number of Blobs that claimed their free parts.
    uint256 private _reservedTokensClaimed = 0;

    event FreePartClaimedFor(uint256 indexed blobId);

    constructor (
        address _blobAddress,
        uint256 _saleStart,
        uint256 _presaleStart,
        string memory baseURI_,
        address _signerAddress
    )
        ERC721A("Joyride Parts", "PART")
        WithSaleStart(_saleStart)
        WithPresaleStart(_presaleStart)
        WithERC721AMetadata(baseURI_)
    {
        blobs = Blobs(_blobAddress);
        signerAddress = _signerAddress;
    }

    /// @notice Check if a blob claimed the free car part
    function isClaimed(uint256 blobId) public view returns(bool) {
        return _claimedTokens[blobId];
    }

    /// @notice Check if token is a top car part
    function isTop(uint256 tokenId) external view returns(bool) {
        require(_exists(tokenId), "Token doesn't exist");

        return tokenId % 2 == 1;
    }

    /// @notice Check if token is a base car part
    function isBase(uint256 tokenId) external view returns(bool) {
        require(_exists(tokenId), "Token doesn't exist");

        return tokenId % 2 == 0;
    }

    /// @notice Claim free car parts
    /// @param blobIds uint256[] A list of Blob IDs for which to claim free parts.
    function mint(uint256[] calldata blobIds) public {
        claimForBlobs(blobIds);

        _safeMint(msg.sender, blobIds.length);
    }

    /// @notice Mint car parts
    /// @param blobIds uint256[] A list of Blob IDs for which to claim free parts.
    /// @param amount uint256 The number of Joyride parts to purchase (in addition to free mints).
    /// @param signature bytes A signature to verify addresses during presale (whitelist).
    function mint(uint256[] calldata blobIds, uint256 amount, bytes memory signature)
        public payable ensureAvailabilityFor(amount) whenNotPaused
    {
        // Free Blob Claims
        claimForBlobs(blobIds);

        // Sale
        if (amount > 0) {
            require(tokenPrice * amount <= msg.value, "Insufficient ether value.");

            if (saleStarted()) {
                require(amount <= MAX_TOKENS_PER_PURCHASE, "Exceeded max token purchase.");
            } else if (presaleStarted()) {
                uint256 presaleMaxAmount = blobIds.length * 3;

                // If the user is on the whitelist, they can mint 4
                bytes32 signedData = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender)));
                if (ECDSA.recover(signedData, signature) == signerAddress) {
                    presaleMaxAmount += 4;
                }

                require(_purchasedDuringPresale[msg.sender] + amount <= presaleMaxAmount, "Exceeded presale limit.");
                _purchasedDuringPresale[msg.sender] += uint8(amount);
            } else {
                revert("Sale not started");
            }
        }

        _safeMint(msg.sender, blobIds.length + amount);
    }

    /// @notice Let the owner mint parts
    function ownerMint(uint256 amount, address to) public onlyOwner ensureAvailabilityFor(amount) {
        _safeMint(to, amount);
    }

    /// @dev Get the tokenURI for a specific token
    function tokenURI(uint256 tokenId)
        public view override(WithERC721AMetadata, ERC721A)
        returns (string memory)
    {
        return WithERC721AMetadata.tokenURI(tokenId);
    }

    /// @notice Allows the Joyride Contract to assemble parts (and burn them in the process).
    function useInAssembly(uint256 tokenId) external {
        require(msg.sender == joyrideAddress, "Not the assembler.");

        _burn(tokenId, false);
    }

    /// @notice Set the address of the Joyride contract that will assemble the cars.
    function setJoyrideAddress(address _joyrideAddress) public onlyOwner {
        joyrideAddress = _joyrideAddress;
    }

    /// @notice Set the address that is allowed to approve whitelist spots.
    function setSigner(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    /// @notice Set the price of each car part in WEI.
    function setPrice (uint256 _price) external onlyOwner {
        tokenPrice = _price;
    }

    /// @notice Allows the owner to withdraw funds stored in the contract.
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 devCut = balance / 10;
        payable(0x6603418703e027019d6E8060542E6193509077B0).transfer(devCut);
        payable(0xC09252422a1BDeB0bde16d12C9a5880BC7Fb3F53).transfer(devCut);
        payable(0xf21f1195456c90Ce20410cADd5c0C51F8af3fBFA).transfer(devCut);
        payable(0x9a8265D7100895Ef6c3832c599dCB05E73c47111).transfer(devCut);

        payable(owner()).transfer(address(this).balance);
    }

    /// @dev Configure the baseURI for the tokenURI method
    function _baseURI()
        internal view override(WithERC721AMetadata, ERC721A)
        returns (string memory)
    {
        return WithERC721AMetadata._baseURI();
    }

    /// @dev Check whether tokens are still available are still available for sale.
    modifier ensureAvailabilityFor(uint256 amount) {
        uint256 amount_reserved = TOKENS_FOR_CLAIM - _reservedTokensClaimed;
        require(
            MAX_TOKENS - (_currentIndex - 1) >= amount + amount_reserved,
            "Requested number of tokens not available"
        );

        _;
    }

    /// @dev Check if blobs have free parts available and set them as claimed.
    function claimForBlobs(uint256[] calldata blobIds) private {
        if (blobIds.length > 0) {
            for (uint256 idx = 0; idx < blobIds.length; idx++) {
                uint256 blobId = blobIds[idx];
                require(!isClaimed(blobId), "Token already claimed");
                require(blobs.ownerOf(blobId) == msg.sender, "Not owner");
                _claimedTokens[blobId] = true;

                emit FreePartClaimedFor(blobId);
            }

            _reservedTokensClaimed += blobIds.length;
        }
    }

    /// @dev The first Joyride part should have the token ID #1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}