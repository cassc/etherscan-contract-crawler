// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import "./lib/OnlyDevMultiSigUpgradeable.sol";

error SetDevMultiSigToZeroAddress();
error InvalidQueryRange();
error NotTokenOwner();
error FreeMintNotEnabled();

//   .--,-``-.                                   ,-.----.
//  /   /     '.           ,--,     ,--,         \    /  \
// / ../        ;          |'. \   / .`|         |   :    \
// \ ``\  .`-    '         ; \ `\ /' / ;         |   |  .\ :
//  \___\/   \   :         `. \  /  / .'         .   :  |: |
//       \   :   |          \  \/  / ./          |   |   \ :
//       /  /   /            \  \.'  /           |   : .   /
//       \  \   \             \  ;  ;            ;   | |`-'
//   ___ /   :   |           / \  \  \           |   | ;
//  /   /\   /   :          ;  /\  \  \          :   ' |
// / ,,/  ',-    .        ./__;  \  ;  \         :   : :
// \ ''\        ;         |   : / \  \  ;        |   | :
//  \   \     .'          ;   |/   \  ' |        `---'.|
//   `--`-,,-'            `---'     `--`           `---`
// 3XP - https://3XP.art

contract HoppiCarrot is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    OnlyDevMultiSigUpgradeable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC2981Upgradeable
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    event NFTMinted(address _owner, uint256 typeId, uint256 amount);
    event SaleStatusChange(
        uint256 typeId,
        uint256 indexed saleId,
        bool enabled
    );

    address internal _devMultiSigWallet;
    address private hoppiContract;
    address private freeMintSignerAddress;
    uint256 constant PUBLIC_SALE_ID = 0; // public sale

    string private baseURI;
    string public name;
    string public symbol;

    mapping(uint256 => bool) public isFreeMintEnabled;
    mapping(uint256 => mapping(uint256 => SaleConfig)) private _saleConfig;
    mapping(uint256 => MintInfo) public mintInfo;

    mapping(uint256 => mapping(address => HoppiLoverMintInfo))
        public hoppiLoverMintInfo;

    mapping(string => address) public referralAddresses;

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

    struct MintInfo {
        uint256 devReserveAmounts;
        uint256 maxSupplyAmounts;
        bool carrotTypes;
    }

    struct HoppiLoverMintInfo {
        uint256 bonusMintAmount;
        bool freeClaimed;
        uint256 totalMintedAmount;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address devMultiSigWallet_,
        uint96 royalty_,
        PuclicSaleConfigCreate calldata publicSaleConfig,
        address _freeMintSignerAddress
    ) public initializer {
        __OnlyDevMultiSig_init(devMultiSigWallet_);
        __ERC1155_init("");
        __ERC2981_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();

        name = _name;
        symbol = _symbol;
        _devMultiSigWallet = devMultiSigWallet_;
        baseURI = _initBaseURI;
        _setDefaultRoyalty(devMultiSigWallet_, royalty_);
        setFreeMintValidator(_freeMintSignerAddress);

        mintInfo[0].devReserveAmounts = 1000;
        mintInfo[0].maxSupplyAmounts = 100000;
        mintInfo[0].carrotTypes = true;

        setPublicSaleConfig(
            0,
            publicSaleConfig.maxPerTransaction,
            publicSaleConfig.unitPrice
        );
    }

    /* 
        interface
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /* 
        uri
    */
    function uri(uint256 typeId) public view override returns (string memory) {
        require(
            mintInfo[typeId].carrotTypes,
            "URI requested for invalid carrot type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /* 
        BACK OFFICE
    */
    function setDevMultiSigAddress(address payable _address)
        external
        onlyDevMultiSig
    {
        if (_address == address(0)) revert SetDevMultiSigToZeroAddress();
        _devMultiSigWallet = _address;
        updateDevMultiSigWallet(_address);
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyDevMultiSig
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function withdrawTokensToDev(IERC20Upgradeable token)
        public
        onlyDevMultiSig
    {
        uint256 funds = token.balanceOf(address(this));
        require(funds > 0, "No token left");
        token.transfer(address(_devMultiSigWallet), funds);
    }

    function withdrawETHBalanceToDev() public onlyDevMultiSig {
        require(address(this).balance > 0, "No ETH left");

        (bool success, ) = address(_devMultiSigWallet).call{
            value: address(this).balance
        }("");

        require(success, "Transfer failed.");
    }

    /* 
        MINT
    */
    modifier canMint(
        uint256 typeId,
        uint256 saleId,
        address to,
        uint256 amount
    ) {
        _guardMint(to, typeId, amount);

        unchecked {
            SaleConfig memory saleConfig = _saleConfig[typeId][saleId];
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

    function _guardMint(
        address,
        uint256 typeId,
        uint256 quantity
    ) internal view virtual {
        unchecked {
            require(tx.origin == _msgSender(), "Can't mint from contract");
            require(mintInfo[typeId].carrotTypes, "Invalid Carrot Type");
            require(
                totalSupply(typeId) + quantity <=
                    mintInfo[typeId].maxSupplyAmounts,
                "Exceeds max supply"
            );
        }
    }

    function updateMintInfo(uint256 typeId, MintInfo memory mintInfo_)
        external
        onlyOwner
    {
        mintInfo[typeId] = mintInfo_;
    }

    function addNewCarrotType(uint256 typeId, uint256 amount)
        external
        onlyOwner
    {
        mintInfo[typeId].carrotTypes = true;
        mintInfo[typeId].maxSupplyAmounts = amount;
    }

    function updateCarrotTypes(uint256 typeId, bool isAvailable)
        external
        onlyOwner
    {
        require(mintInfo[typeId].carrotTypes, "Invalid Carrot Type");
        mintInfo[typeId].carrotTypes = isAvailable;
    }

    function updateMaxSupply(uint256 typeId, uint256 amount)
        external
        onlyOwner
    {
        require(mintInfo[typeId].carrotTypes, "Invalid Carrot Type");
        mintInfo[typeId].maxSupplyAmounts = amount;
    }

    /* 
        DEV MINT
    */
    function devMint(uint256[] memory typeIds, uint256[] memory amounts)
        external
        onlyOwner
    {
        _devMintTo(_devMultiSigWallet, typeIds, amounts);
    }

    function devMintTo(
        address to,
        uint256[] memory typeIds,
        uint256[] memory amounts
    ) external onlyOwner {
        _devMintTo(to, typeIds, amounts);
    }

    function _devMintTo(
        address to,
        uint256[] memory typeIds,
        uint256[] memory amounts
    ) internal onlyOwner {
        uint256 n = typeIds.length;
        require(n == amounts.length, "Invalid input");

        for (uint256 i = 0; i < n; ++i) {
            require(
                amounts[i] <= mintInfo[typeIds[i]].devReserveAmounts,
                "The quantity exceeds the reserve."
            );
            mintInfo[typeIds[i]].devReserveAmounts -= amounts[i];
        }

        _mintBatch(to, typeIds, amounts, "");
    }

    /* 
        PUBLIC MINT
    */
    function publicMint(uint256 typeId, uint256 amount)
        external
        payable
        canMint(typeId, PUBLIC_SALE_ID, _msgSender(), amount)
    {
        _mint(_msgSender(), typeId, amount, "");

        emit NFTMinted(_msgSender(), typeId, amount);
    }

    function getPublicSaleConfig(uint256 typeId)
        external
        view
        returns (SaleConfig memory)
    {
        return _saleConfig[typeId][PUBLIC_SALE_ID];
    }

    function setPublicSaleConfig(
        uint256 typeId,
        uint256 maxPerTransaction,
        uint256 unitPrice
    ) public onlyOwner {
        _saleConfig[typeId][PUBLIC_SALE_ID].maxPerTransaction = uint8(
            maxPerTransaction
        );
        _saleConfig[typeId][PUBLIC_SALE_ID].unitPrice = uint64(unitPrice);
    }

    function setPublicSaleStatus(uint256 typeId, bool enabled)
        external
        onlyOwner
    {
        if (_saleConfig[typeId][PUBLIC_SALE_ID].enabled != enabled) {
            _saleConfig[typeId][PUBLIC_SALE_ID].enabled = enabled;
            emit SaleStatusChange(typeId, PUBLIC_SALE_ID, enabled);
        }
    }

    /* 
        FREE CLAIM
    */
    function freeMint(
        uint256 typeId,
        uint256 amount,
        address referralWalletAddress,
        bytes memory signature
    ) external {
        if (!isFreeMintEnabled[typeId]) {
            revert FreeMintNotEnabled();
        }

        bool freeClaimed = hoppiLoverMintInfo[typeId][_msgSender()].freeClaimed;

        hoppiLoverMintInfo[typeId][_msgSender()].freeClaimed = true;
        hoppiLoverMintInfo[typeId][_msgSender()].totalMintedAmount += amount;

        require(freeClaimed == false, "You already claimed your free mint");
        _guardMint(_msgSender(), typeId, amount);

        require(
            _verifyFreeMint(
                _hashFreeMint(
                    _msgSender(),
                    typeId,
                    amount,
                    referralWalletAddress
                ),
                signature
            ),
            "Invalid signature"
        );

        _mint(_msgSender(), typeId, amount, "");

        emit NFTMinted(_msgSender(), typeId, amount);

        if (referralWalletAddress != address(0)) {
            hoppiLoverMintInfo[typeId][referralWalletAddress]
                .bonusMintAmount += 1;
            hoppiLoverMintInfo[typeId][_msgSender()].bonusMintAmount += 1;
        }
    }

    function _hashFreeMint(
        address account,
        uint256 typeId,
        uint256 amount,
        address referralWalletAddress
    ) internal pure returns (bytes32) {
        return
            ECDSAUpgradeable.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        account,
                        typeId,
                        amount,
                        referralWalletAddress
                    )
                )
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

    function toggleFreeMintEnabled(uint256 typeId) external onlyOwner {
        isFreeMintEnabled[typeId] = !isFreeMintEnabled[typeId];
    }

    function toggleFreeMintAndPublicSale(uint256 typeId, bool enabled)
        external
        onlyOwner
    {
        isFreeMintEnabled[typeId] = enabled;

        if (_saleConfig[typeId][PUBLIC_SALE_ID].enabled != enabled) {
            _saleConfig[typeId][PUBLIC_SALE_ID].enabled = enabled;
            emit SaleStatusChange(typeId, PUBLIC_SALE_ID, enabled);
        }
    }

    /* 
        BONUS MINT CLAIM
    */
    function bonusMint(uint256 typeId) external {
        if (!isFreeMintEnabled[typeId]) {
            revert FreeMintNotEnabled();
        }

        uint256 amount = hoppiLoverMintInfo[typeId][_msgSender()]
            .bonusMintAmount;

        hoppiLoverMintInfo[typeId][_msgSender()].bonusMintAmount = 0;
        hoppiLoverMintInfo[typeId][_msgSender()].totalMintedAmount += amount;

        require(amount > 0, "You already claimed all of your bonus mint");
        _guardMint(_msgSender(), typeId, amount);

        _mint(_msgSender(), typeId, amount, "");

        emit NFTMinted(_msgSender(), typeId, amount);
    }

    /*  
        |￣￣￣￣￣￣￣|
        | Something |
        |  REALLY   |
        |   FUN     |
        |＿＿＿＿＿___|
        (\__/) ||
        (•ㅅ•) ||
        / 　 づ
    */
    modifier onlyHoppiContract() {
        require(
            _msgSender() == hoppiContract,
            "Invalid Hoppi Contract Address"
        );
        _;
    }

    function setHoppiContractAddress(address hoppiContractAddress)
        external
        onlyOwner
    {
        hoppiContract = hoppiContractAddress;
    }

    function feedCarrots(
        address walletAddress,
        uint256 typeId,
        uint256 amount
    ) external nonReentrant onlyHoppiContract {
        _burn(walletAddress, typeId, amount);
    }

    function feedCarrotsBatch(
        address walletAddress,
        uint256[] memory typeIds,
        uint256[] memory amounts
    ) external nonReentrant onlyHoppiContract {
        _burnBatch(walletAddress, typeIds, amounts);
    }

    function burnCarrots(uint256 typeId, uint256 amount) public nonReentrant {
        _burn(_msgSender(), typeId, amount);
    }

    function burnCarrotsBatch(
        uint256[] memory typeIds,
        uint256[] memory amounts
    ) public nonReentrant {
        _burnBatch(_msgSender(), typeIds, amounts);
    }
}