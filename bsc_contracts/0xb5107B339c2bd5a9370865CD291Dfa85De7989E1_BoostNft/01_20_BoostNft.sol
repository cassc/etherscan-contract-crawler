// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
// pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// Interfaces
import "../utils/Interfaces/IFarm.sol";

contract BoostNft is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StringsUpgradeable for uint256;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    string public _baseURI;
    address public DAO;
    address public farm;
    address public busd;
    uint256 public maxBoost;

    struct NFTInfo {
        string name;
        uint256 price;
        uint256 totalSupply;
        uint256 boostAmount;
        bool active;
    }

    mapping(uint256 => NFTInfo) public nftInfo;

    mapping(address => mapping(uint256 => uint256)) public userInfo;

    uint256 public maxStackable;

    event ItemMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount
    );
    event ItemsBatchMinted(
        address indexed to,
        uint256[] indexed tokenId,
        uint256[] indexed amounts
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC1155_init("Rocket Fuel");
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        maxBoost = 71500;
        maxStackable = 1;
        setBaseURI("https://backend.celestialfinance.app/nft/json/");
    }

    function bigBang(
        address _farm,
        address _DAO,
        address _busd
    ) public onlyRole(OPERATOR_ROLE) {
        farm = _farm;
        DAO = _DAO;
        busd = _busd;
    }

    function setBaseURI(string memory newuri) public onlyRole(OPERATOR_ROLE) {
        _baseURI = newuri;
    }

    function uri(uint256 _tokenID)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, _tokenID.toString()))
                : "";
    }

    // function contractURI() public view returns (string memory) {

    // return bytes(_baseURI).length > 0
    //     ? string(abi.encodePacked(_baseURI, "_contract_metadata", baseExtension))
    //     : "";
    // }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        require(
            amount + totalSupply(id) <= nftInfo[id].totalSupply,
            "Trying to mint too many"
        );
        require(nftInfo[id].active == true, "Inactive NFT");
        require(
            IERC20Upgradeable(busd).balanceOf(msg.sender) >=
                nftInfo[id].price * amount,
            "Not enough Funds"
        );

        IERC20Upgradeable(busd).transferFrom(
            msg.sender,
            DAO,
            amount * nftInfo[id].price
        );

        _mint(account, id, amount, data);

        emit ItemMinted(account, id, amount);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        for (uint i = 0; i < ids.length; i++) {
            require(
                amounts[i] + totalSupply(ids[i]) <= nftInfo[ids[i]].totalSupply,
                "Trying to mint too many"
            );
            require(nftInfo[ids[i]].active == true, "Inactive NFT");
            require(
                IERC20Upgradeable(busd).balanceOf(msg.sender) >=
                    nftInfo[ids[i]].price * amounts[i],
                "Not enough Funds"
            );

            IERC20Upgradeable(busd).transferFrom(
                msg.sender,
                DAO,
                amounts[i] * nftInfo[ids[i]].price
            );
        }

        _mintBatch(to, ids, amounts, data);

        emit ItemsBatchMinted(to, ids, amounts);
    }

    function setNFT(
        string memory _name,
        uint256 _price,
        uint256 _tokenId,
        uint256 _totalSupply,
        uint256 _boostAmount,
        bool _active
    ) public onlyRole(OPERATOR_ROLE) {
        require(_boostAmount < maxBoost, "Boost too high");

        nftInfo[_tokenId].name = _name;
        nftInfo[_tokenId].price = _price;
        nftInfo[_tokenId].totalSupply = _totalSupply;
        nftInfo[_tokenId].boostAmount = _boostAmount;
        nftInfo[_tokenId].active = _active;

        IFarm(farm).setNFT(address(this), _tokenId, _boostAmount);
    }

    function changeMaxBoost(uint256 _newBoost) public onlyRole(OPERATOR_ROLE) {
        maxBoost = _newBoost;
    }

    function changeMaxStackable(uint256 _newAmount)
        public
        onlyRole(OPERATOR_ROLE)
    {
        maxStackable = _newAmount;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        for (uint i = 0; i < ids.length; i++) {
            if (from != address(0)) {
                if (
                    userInfo[from][ids[i]] > 0 &&
                    (userInfo[from][ids[i]] - amounts[i]) == 0 &&
                    IFarm(farm).nftDepositedAmount(
                        address(this),
                        ids[i],
                        from
                    ) >
                    0
                ) {
                    IFarm(farm).withdrawNFT(from, address(this), ids[i], 1);
                }
                userInfo[from][ids[i]] -= amounts[i];
            }
            if (to != address(0)) {
                if (
                    IFarm(farm).nftDepositedAmount(address(this), ids[i], to) ==
                    0
                ) {
                    IFarm(farm).depositNFT(to, address(this), ids[i], 1);
                }
                userInfo[to][ids[i]] += amounts[i];
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}