// SPDX-License-Identifier: MIT
// Creator: 0xforehead

//       ██████╗░░█████╗░██████╗░██╗░░██╗░█████╗░██╗░░██╗░█████╗░███╗░░░███╗██████╗░░██████╗
//       ██╔══██╗██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║░░██║██╔══██╗████╗░████║██╔══██╗██╔════╝
//       ██████╔╝██║░░██║██████╔╝█████═╝░██║░░╚═╝███████║███████║██╔████╔██║██████╔╝╚█████╗░
//       ██╔═══╝░██║░░██║██╔══██╗██╔═██╗░██║░░██╗██╔══██║██╔══██║██║╚██╔╝██║██╔═══╝░░╚═══██╗
//       ██║░░░░░╚█████╔╝██║░░██║██║░╚██╗╚█████╔╝██║░░██║██║░░██║██║░╚═╝░██║██║░░░░░██████╔╝
//       ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═╝░░░░░╚═════╝░

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

// TODO: Add royalties to the contract
/**
 * @title Porkchamps contract
 * @dev Extends ERC721A Non-Fungible Token Standard basic implementation
 */
contract Porkchamps is ERC721A, Ownable, PaymentSplitter {
    string private _baseTokenURI;
    address private adminSigner = address(1);

    uint256 public collectionSize = 10000;
    uint256 public teamReserve = 1111;
    string public provenanceHash = "0x1";

    struct Prices {
        uint128 allowlistPriceWei;
        uint128 publicPriceWei;
    }

    struct SaleConfig {
        bool allowlistMintEnabled;
        bool publicMintEnabled;
    }

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    Prices public prices = Prices(0.02 ether, 0.03 ether);
    SaleConfig public saleConfig = SaleConfig(false, false);

    constructor(address[] memory _payees, uint256[] memory _shares)
        payable
        ERC721A("Porkchamps", "PKC")
        PaymentSplitter(_payees, _shares)
    {}

    // ======================================================== Modifiers

    /// @dev caller is not another contract
    modifier callerIsUser() {
        require(
            tx.origin == msg.sender,
            "The caller cannot be another contract"
        );
        _;
    }

    // ======================================================== Internal Functions

    /// @dev check that the coupon sent was signed by the admin signer
    function _verify(bytes32 digest, Coupon memory coupon)
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer == adminSigner;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // ======================================================== Sale Methods

    // To mint the team avatars
    // The team reserves the first 17 avatar nfts (#0-16)
    function avatarMint(address[] calldata addresses) external onlyOwner {
        require(
            totalSupply() + addresses.length == 17,
            "Too many already minted before avatar mint"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    // The next 160 mints (#17-176) will be reserved for the team members for future utility
    function teamMint(address[] calldata addresses) external onlyOwner {
        require(
            totalSupply() + addresses.length * 20 < 178,
            "Too many already minted before team mint"
        );
        require(addresses.length == 8, "Only 160 mints allowed for the team");

        for (uint256 i = 0; i < addresses.length; i++) {
            for (uint256 j = 0; j < 4; j++) {
                _safeMint(addresses[i], 5);
            }
        }
    }

    function allowlistMint(
        uint256 quantity,
        uint256 allowance,
        Coupon memory coupon
    ) external payable callerIsUser {
        require(
            saleConfig.allowlistMintEnabled == true,
            "Allowlist event is not active"
        );
        require(
            numberMinted(msg.sender) + quantity <= allowance,
            "Reached max allowance"
        );
        require(
            totalSupply() + quantity <= collectionSize - teamReserve,
            "Reached max supply"
        );
        require(
            msg.value == prices.allowlistPriceWei * quantity,
            "Need to send the correct amount of eth"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(msg.sender, allowance))
            )
        );

        require(_verify(digest, coupon), "Invalid coupon");

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(saleConfig.publicMintEnabled, "Public sale is not active");
        require(
            totalSupply() + quantity <= collectionSize - teamReserve,
            "Reached max supply"
        );
        require(
            msg.value == prices.publicPriceWei * quantity,
            "Need to send the correct amount of eth"
        );
        require(quantity < 21, "Can only mint a max of 20 at a time");
        _safeMint(msg.sender, quantity);
    }

    // The last batch of nfts (max of 1111) are reserved for project marketing etc.
    function teamReserveMint(uint256 quantity) external onlyOwner {
        // Cannot mint the reserve until the public collection has sold out
        require(
            totalSupply() >= collectionSize - teamReserve,
            "Can only mint the remaining NFTs"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "Cannot exceed collectionSize"
        );
        uint256 numChunks = quantity / 5;
        uint256 remainder = quantity % 5;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, 5);
        }
        _safeMint(msg.sender, remainder);
    }

    // ======================================================== Admin Methods

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setAdminSigner(address _address) external onlyOwner {
        require(_address != address(0), "Cannot be zero address");
        adminSigner = _address;
    }

    function setPrices(Prices memory prices_) external onlyOwner {
        prices = prices_;
    }

    function setTeamReserve(uint256 teamReserve_) external onlyOwner {
        require(teamReserve_ <= teamReserve, "Can only decrease teamReserve");
        teamReserve = teamReserve_;
    }

    function setSaleConfig(SaleConfig memory saleConfig_) external onlyOwner {
        saleConfig = saleConfig_;
    }

    // To decrease total supply
    function setCollectionSize(uint256 collectionSize_) external onlyOwner {
        require(
            collectionSize_ <= collectionSize,
            "Can only decrease collectionSize"
        );
        collectionSize = collectionSize_;
    }

    // To have an on-chain record of the order of images prior to minting
    function setProvenanceHash(string memory provenanceHash_)
        external
        onlyOwner
    {
        provenanceHash = provenanceHash_;
    }

    // ======================================================== Team Methods

    function release(address payable account) public override {
        require(
            msg.sender == account,
            "PaymentSplitter: can only release own funds"
        );
        require(
            shares(msg.sender) > 0,
            "PaymentSplitter: account has no shares"
        );
        return super.release(account);
    }
} // End of Contract