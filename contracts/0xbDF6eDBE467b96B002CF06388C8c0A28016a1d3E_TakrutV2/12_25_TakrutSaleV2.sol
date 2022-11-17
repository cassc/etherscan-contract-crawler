// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../lib/erc721-operator-filter/ERC721AOperatorFilterUpgradeable.sol";
import "../lib/OnlyDevMultiSigUpgradeable.sol";
import "../lib/Refund.sol";

contract TakrutSaleV2 is
    ReentrancyGuardUpgradeable,
    OnlyDevMultiSigUpgradeable,
    ERC721AOperatorFilterUpgradeable,
    Refund
{
    error FreeMintNotEnabled();
    using ECDSAUpgradeable for bytes32;

    event NFTMinted(address _owner, uint256 amount, uint256 startTokenId);
    event SaleStatusChange(uint256 indexed saleId, bool enabled);

    address internal _devMultiSigWallet;
    address private freeMintSignerAddress;

    uint256 public MAX_SUPPLY; // total supply
    uint256 public DEV_RESERVE; // total dev will reserve
    uint256 public MAX_FREE_SUPPLY; // total dev will reserve
    uint256 constant PUBLIC_SALE_ID = 0; // public sale

    bool public isFreeMintEnabled;

    struct SaleConfigCreate {
        uint256 saleId;
        uint8 maxPerWallet;
        uint8 maxPerTransaction;
        uint64 unitPrice;
        address signerAddress;
        uint256 maxPerRound;
    }

    struct PuclicSaleConfigCreate {
        uint8 maxPerTransaction;
        uint64 unitPrice;
    }

    struct SaleConfig {
        bool enabled;
        uint8 maxPerWallet;
        uint8 maxPerTransaction;
        uint64 unitPrice;
        address signerAddress;
        uint256 maxPerRound;
    }

    struct WhitelistedUser {
        address walletAddress;
        uint256 mintAmount;
    }

    mapping(uint256 => SaleConfig) private _saleConfig;
    mapping(uint256 => mapping(address => WhitelistedUser)) public whitelisted;
    mapping(uint256 => mapping(address => bool)) public _addressExist;
    mapping(bytes32 => address) public usedCodes;

    modifier canMint(
        uint256 saleId,
        address to,
        uint256 amount
    ) {
        _guardMint(to, amount);
        unchecked {
            SaleConfig memory saleConfig = _saleConfig[saleId];
            require(saleConfig.enabled, "Sale not enabled");
            require(
                amount <= saleConfig.maxPerTransaction,
                "Exceeds max per transaction"
            );
            require(
                msg.value >= (amount * saleConfig.unitPrice),
                "ETH amount is not sufficient"
            );
            if (saleId > 0) {
                require(
                    saleConfig.maxPerRound - amount >= 0,
                    "Exceeds max per round"
                );
            }
        }
        _;
    }

    function _guardMint(address, uint256 quantity) internal view virtual {
        unchecked {
            require(
                tx.origin == _msgSenderERC721A(),
                "Can't mint from contract"
            );
            require(
                totalSupply() + quantity <= MAX_SUPPLY,
                "Exceeds max supply"
            );
        }
    }

    function allowlistMint(
        uint256 saleId,
        uint256 amount,
        // uint256 _type,
        bytes calldata signature
    ) external payable canMint(saleId, _msgSenderERC721A(), amount) {
        require(
            _verify(saleId, _hash(_msgSenderERC721A(), saleId), signature),
            "Invalid signature"
        ); // check if this is a correct WL address
        if (!_addressExist[saleId][_msgSenderERC721A()]) {
            // After verify the signature - check if address is already exist yet then create one
            setWhitelistUser(
                saleId,
                _msgSenderERC721A(),
                _saleConfig[saleId].maxPerWallet
            );
        }
        require(
            amount > 0 &&
                amount <= whitelisted[saleId][_msgSenderERC721A()].mintAmount,
            "Exceeds maximum tokens you can purchase in a single transaction"
        );
        require(
            whitelisted[saleId][_msgSenderERC721A()].mintAmount > 0,
            "There's no more you can mint, please wait for the public sale to mint more!"
        );
        require(
            amount <= whitelisted[saleId][_msgSenderERC721A()].mintAmount,
            "You cannot mint more than that!"
        );
        whitelisted[saleId][_msgSenderERC721A()].mintAmount -= amount;
        _saleConfig[saleId].maxPerRound -= amount;

        uint256 startTokenId = _nextTokenId();
        _safeMint(_msgSenderERC721A(), amount);
        uint256 endTokenId = _nextTokenId() - 1;

        recordMint(saleId, startTokenId, endTokenId);

        emit NFTMinted(_msgSenderERC721A(), amount, startTokenId);
    }

    function publicMint(uint256 amount)
        external
        payable
        canMint(PUBLIC_SALE_ID, _msgSenderERC721A(), amount)
    {
        uint256 startTokenId = _nextTokenId();
        _safeMint(_msgSenderERC721A(), amount);
        uint256 endTokenId = _nextTokenId() - 1;

        recordMint(PUBLIC_SALE_ID, startTokenId, endTokenId);

        emit NFTMinted(_msgSenderERC721A(), amount, startTokenId);
    }

    function devMint(uint256 amount) external onlyOwner {
        require(amount <= DEV_RESERVE, "The quantity exceeds the reserve.");
        uint256 startTokenId = _nextTokenId();
        DEV_RESERVE -= amount;

        _guardMint(_msgSenderERC721A(), amount);
        _safeMint(_devMultiSigWallet, amount);

        emit NFTMinted(_devMultiSigWallet, amount, startTokenId);
    }

    function toggleFreeMintEnabled() external onlyOwner {
        isFreeMintEnabled = !isFreeMintEnabled;
    }

    function freeMint(bytes32 secretCode, bytes memory signature) external {
        uint256 amount = 1;

        if (!isFreeMintEnabled) {
            revert FreeMintNotEnabled();
        }
        _guardMint(_msgSenderERC721A(), amount);

        require(
            usedCodes[secretCode] == address(0),
            "Secret Code already used"
        );
        require(balanceOf(_msgSenderERC721A()) == 0, "Only one nft per wallet");
        require(MAX_FREE_SUPPLY > 0, "All free mint has been claimed!");
        require(
            _verifyFreeMint(
                _hashFreeMint(_msgSenderERC721A(), secretCode),
                signature
            ),
            "Invalid signature"
        );

        usedCodes[secretCode] = _msgSenderERC721A();

        MAX_FREE_SUPPLY -= amount;

        uint256 startTokenId = _nextTokenId();
        _safeMint(_msgSenderERC721A(), amount);

        emit NFTMinted(_msgSenderERC721A(), amount, startTokenId);
    }

    function recordMint(
        uint256 saleId,
        uint256 startTokenId,
        uint256 endTokenId
    ) private {
        for (uint256 i = startTokenId; i <= endTokenId; i++) {
            _mintedToken[i] = MintedToken({
                minter: _msgSenderERC721A(),
                mintPrice: uint64(_saleConfig[saleId].unitPrice)
            });
        }
    }

    function getPublicSaleConfig() external view returns (SaleConfig memory) {
        return _saleConfig[PUBLIC_SALE_ID];
    }

    function getSaleConfig(uint256 saleId)
        external
        view
        returns (SaleConfig memory)
    {
        return _saleConfig[saleId];
    }

    function setPublicSaleConfig(uint256 maxPerTransaction, uint256 unitPrice)
        public
        onlyOwner
    {
        _saleConfig[PUBLIC_SALE_ID].maxPerTransaction = uint8(
            maxPerTransaction
        );
        _saleConfig[PUBLIC_SALE_ID].unitPrice = uint64(unitPrice);
    }

    function setSaleConfig(
        uint256 saleId,
        uint256 maxPerWallet,
        uint256 maxPerTransaction,
        uint256 unitPrice,
        address signerAddress,
        uint256 maxPerRound
    ) public onlyOwner {
        _saleConfig[saleId].maxPerWallet = uint8(maxPerWallet);
        _saleConfig[saleId].maxPerTransaction = uint8(maxPerTransaction);
        _saleConfig[saleId].unitPrice = uint64(unitPrice);
        _saleConfig[saleId].signerAddress = signerAddress;
        _saleConfig[saleId].maxPerRound = maxPerRound;
    }

    function setPublicSaleStatus(bool enabled) external onlyOwner {
        if (_saleConfig[PUBLIC_SALE_ID].enabled != enabled) {
            _saleConfig[PUBLIC_SALE_ID].enabled = enabled;
            emit SaleStatusChange(PUBLIC_SALE_ID, enabled);
        }
    }

    function setSaleStatus(uint256 saleId, bool enabled) external onlyOwner {
        if (_saleConfig[saleId].enabled != enabled) {
            _saleConfig[saleId].enabled = enabled;
            emit SaleStatusChange(saleId, enabled);
        }
    }

    function isWhitelisted(uint256 saleId, bytes calldata signature)
        public
        view
        returns (bool, uint256)
    {
        // check if this address is whitelisted or not
        uint256 mintAmount = 0;
        bool isWhitelistedBool;

        if (_verify(saleId, _hash(_msgSenderERC721A(), saleId), signature)) {
            isWhitelistedBool = true;
            if (!_addressExist[saleId][_msgSenderERC721A()]) {
                // After verify the signature - check if address is already exist yet then create one
                mintAmount = _saleConfig[saleId].maxPerWallet;
            } else {
                mintAmount = whitelisted[saleId][_msgSenderERC721A()]
                    .mintAmount;
            }
        } else {
            isWhitelistedBool = false;
        }
        return (isWhitelistedBool, mintAmount);
    }

    function _hash(address account, uint256 saleId)
        internal
        pure
        returns (bytes32)
    {
        return
            ECDSAUpgradeable.toEthSignedMessageHash(
                keccak256(abi.encodePacked(account, saleId))
            );
    }

    function _verify(
        uint256 saleId,
        bytes32 digest,
        bytes memory signature
    ) internal view returns (bool) {
        return
            _saleConfig[saleId].signerAddress ==
            ECDSAUpgradeable.recover(digest, signature);
    }

    function _hashFreeMint(address account, bytes32 secretCode)
        internal
        pure
        returns (bytes32)
    {
        return
            ECDSAUpgradeable.toEthSignedMessageHash(
                keccak256(abi.encodePacked(account, secretCode))
            );
    }

    function _verifyFreeMint(bytes32 digest, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return
            freeMintSignerAddress ==
            ECDSAUpgradeable.recover(digest, signature);
    }

    function setFreeMintValidator(address freeMintSignerAddress_)
        public
        onlyOwner
    {
        require(
            freeMintSignerAddress_ != address(0),
            "validator cannot be 0x0"
        );
        freeMintSignerAddress = freeMintSignerAddress_;
    }

    function setWhitelistUser(
        uint256 saleId,
        address _walletAddress,
        uint256 _mintAmount
    ) private {
        whitelisted[saleId][_walletAddress].walletAddress = _walletAddress;
        whitelisted[saleId][_walletAddress].mintAmount = _mintAmount;
        _addressExist[saleId][_walletAddress] = true; // winner address;
    }

    function removeWhitelistUser(uint256 saleId, address _user)
        public
        onlyDevMultiSig
    {
        console.log("removeWhitelistUser");
        delete whitelisted[saleId][_user];
        delete _addressExist[saleId][_user];
    }
}