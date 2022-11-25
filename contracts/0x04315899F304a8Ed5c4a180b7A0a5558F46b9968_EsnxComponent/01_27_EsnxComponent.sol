//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/**

`7MM"""YMM   .M"""bgd `7MN.   `7MF'`YMM'   `MP'
  MM    `7  ,MI    "Y   MMN.    M    VMb.  ,P
  MM   d    `MMb.       M YMb   M     `MM.M'
  MMmmMM      `YMMNq.   M  `MN. M       MMb
  MM   Y  , .     `MM   M   `MM.M     ,M'`Mb.
  MM     ,M Mb     dM   M     YMM    ,P   `MM.
.JMMmmmmMMM P"Ybmmd"  .JML.    YM  .MM:.  .:MMa.

powered by ctor.xyz

 */

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "closedsea/src/OperatorFilterer.sol";
import "erc1155delta/contracts/extensions/ERC1155DeltaQueryableUpgradeable.sol";
import "ctorlab-solidity/contracts/supply-control/DeflationSupplyCapLinear.sol";

interface IEsnxMecha {
    function mint(address to, uint256[] calldata ids) external;
}

contract EsnxComponent is
    Initializable,
    UUPSUpgradeable,
    ERC1155DeltaQueryableUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    OperatorFilterer
{
    using DeflationSupplyCapLinear for DeflationSupplyCapLinear.DeflationSupplyCapLinearParameter;

    uint256 public constant HEAD_TOKEN_ID = 0;
    uint256 public constant BODY_TOKEN_ID = 1;
    uint256 public constant ARMS_TOKEN_ID = 2;
    uint256 public constant LEGS_TOKEN_ID = 3;
    uint256 public constant EQUIPMENT_TOKEN_ID = 4;
    uint256 public constant NUM_PARTS = 5;

    address public immutable recoder;

    IEsnxMecha public esnxMecha;

    uint256 public assemblingStartTime;
    uint256 public assemblingEndTime;

    DeflationSupplyCapLinear.DeflationSupplyCapLinearParameter
        public supplyCapParam;

    error NotRecoder();
    error NotEOA();
    error NotStarted();
    error Ended();
    error InvalidTime();
    error InvalidLength();
    error InvalidPart();

    modifier onlyRecoder() {
        if (msg.sender != recoder) {
            revert NotRecoder();
        }
        _;
    }

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert NotEOA();
        }
        _;
    }

    modifier onlyDuring(uint256 startTime, uint256 endTime) {
        uint256 blockTime = block.timestamp;
        if (blockTime < startTime) {
            revert NotStarted();
        }
        if (blockTime >= endTime) {
            revert Ended();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address recoder_) {
        _disableInitializers();

        recoder = recoder_;
    }

    function initialize() external initializer {
        __ERC1155Delta_init("https://api.elysiumshell.xyz/esnxc/{id}");
        __Ownable_init();

        _setDefaultRoyalty(
            address(0xd188Db484A78C147dCb14EC8F12b5ca1fcBC17f5),
            750
        );
        _registerForOperatorFiltering();

        assemblingStartTime = type(uint256).max;
        assemblingEndTime = type(uint256).max;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155DeltaUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setUri(string calldata uri_) external onlyOwner {
        _setURI(uri_);
    }

    function setEsnxMecha(address esnxMecha_) external onlyOwner {
        esnxMecha = IEsnxMecha(esnxMecha_);
    }

    function setAssemblingTime(uint256 start, uint256 end) external onlyOwner {
        if (end <= start) {
            revert InvalidTime();
        }
        assemblingStartTime = start;
        assemblingEndTime = end;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function mint(address to) external onlyRecoder {
        supplyCapParam.checkMintingAndUpdate(_totalMinted(), NUM_PARTS);
        _mint(to, NUM_PARTS);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function assemble(uint256[] calldata ids)
        external
        onlyDuring(assemblingStartTime, assemblingEndTime)
        onlyEOA
    {
        if (ids.length != NUM_PARTS) {
            revert InvalidLength();
        }

        _burnBatch(msg.sender, ids);
        esnxMecha.mint(msg.sender, ids);
    }

    function currentSupplyCap() external view returns (uint256) {
        return supplyCapParam.currentSupplyCap();
    }

    function availableForRecoding() external view returns (uint256) {
        return supplyCapParam.availableToMint(_totalMinted()) / NUM_PARTS;
    }

    function initializeSupplyCap(
        uint64 decayStart,
        uint64 decayPeriod,
        uint32 initialSupply,
        uint32 supplyDecay
    ) external onlyOwner {
        supplyCapParam.initializeParam(
            decayStart,
            decayPeriod,
            initialSupply,
            supplyDecay
        );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}