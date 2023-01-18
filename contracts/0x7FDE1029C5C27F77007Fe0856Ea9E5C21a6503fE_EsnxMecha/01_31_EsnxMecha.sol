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
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "closedsea/src/OperatorFilterer.sol";

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

interface IRenameToken {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

interface IEsnxComponent {}

contract EsnxMecha is
    Initializable,
    UUPSUpgradeable,
    ERC721AQueryableUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    OperatorFilterer
{
    uint256 public constant NUM_PARTS = 5;

    IEsnxComponent public immutable esnxComponent;

    string private _baseTokenURI;

    mapping(uint256 => string) private _tokenName;
    mapping(uint256 => uint256) public numRenames;
    uint256 public renameFee;

    IRenameToken public renameToken;

    error NotEsnxComponent();
    error InvalidPart();
    error NotEnoughPayment();
    error RenameNotEnabled();
    error NotTokenOwner();

    event Assemble(uint256 indexed tokenId, uint256[] esnxComponentIds);
    event Rename(uint256 indexed tokenId, string newName);

    modifier onlyEsnxComponent() {
        if (msg.sender != address(esnxComponent)) {
            revert NotEsnxComponent();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address esnxComponent_) {
        _disableInitializers();

        esnxComponent = IEsnxComponent(esnxComponent_);
    }

    function initialize() external initializer initializerERC721A {
        __ERC721A_init("ESNX Mecha", "ESNXM");

        __Ownable_init();

        _setDefaultRoyalty(
            address(0xd188Db484A78C147dCb14EC8F12b5ca1fcBC17f5),
            750
        );
        _registerForOperatorFiltering();

        _baseTokenURI = "https://api.elysiumshell.xyz/esnxm/";

        renameFee = 0.01 ether;

        _mint(msg.sender, 19);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenName(uint256 tokenId) public view returns (string memory) {
        if (bytes(_tokenName[tokenId]).length == 0) {
            return
                string.concat(
                    "ESNX Mecha #",
                    StringsUpgradeable.toString(tokenId)
                );
        } else {
            return _tokenName[tokenId];
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC721AUpgradeable, ERC2981Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            ERC721AUpgradeable.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
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

    function setRenameFee(uint256 newFee) external onlyOwner {
        renameFee = newFee;
    }

    function setRenameToken(IRenameToken newToken) external onlyOwner {
        renameToken = newToken;
    }

    function setName(
        uint256 tokenId,
        string calldata newName,
        bool useToken
    ) external payable {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

        if (numRenames[tokenId] != 0) {
            if (useToken) {
                renameToken.burn(msg.sender, 1, 1); // Assuming the token ID of rename token is 1
            } else {
                if (msg.value != renameFee) revert NotEnoughPayment();
            }
        }

        ++numRenames[tokenId];
        _tokenName[tokenId] = newName;

        emit Rename(tokenId, newName);
    }

    function validateTokenId(uint256[] calldata esnxComponentIds) public pure {
        for (uint256 i = 0; i < NUM_PARTS; ++i) {
            uint256 esnxComponentId = esnxComponentIds[i];
            uint256 part = esnxComponentId % NUM_PARTS;
            if (part != i) {
                revert InvalidPart();
            }
        }
    }

    function mint(address to, uint256[] calldata esnxComponentIds)
        external
        onlyEsnxComponent
    {
        validateTokenId(esnxComponentIds);

        emit Assemble(_nextTokenId(), esnxComponentIds);

        _mint(to, 1);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }
}