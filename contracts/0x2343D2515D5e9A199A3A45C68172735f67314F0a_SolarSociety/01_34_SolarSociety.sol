// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC721AUpgradeable, IERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract SolarSociety is
    UUPSUpgradeable,
    ERC721AUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721AQueryableUpgradeable,
    ERC2981Upgradeable,
    PausableUpgradeable
{
    uint256 public constant MAX_TOTAL_SUPPLY = 10000;
    uint256 public constant FREE_SUPPLY = 2500;
    bytes32 public constant OPERATOR_ROLE = keccak256(bytes("OPERATOR"));

    uint256 public publicPrice;
    uint256 public maxTokenPerAddress;
    bool public revealed;
    string private _baseTokenURI;

    mapping(address => uint256) public tokensMinted;

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event EtherWithdrawn(address _to, uint256 _amount);
    event MaxTokenPerAddressUqdated(uint256 _maxTokenPerAddress);
    event TokenPriceUpdated(uint256 _tokenPrice);

    /// @dev Initializer to set up the initial contract parameters.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize contract parameters.
     * @param _name Name of the token.
     * @param _symbol Symbol of the token.
     * @param _owner The address of the contract owner.
     * @param _royaltyReciver The address to receive royalties.
     * @param _royaltyValue The value of royalties.
     * @param _initBaseURI The initial base URI of the token.
     * @param _maxTokenPerAddress The maximum number of tokens per address.
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _royaltyReciver,
        uint96 _royaltyValue,
        string memory _initBaseURI,
        uint256 _maxTokenPerAddress
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __ERC721AQueryable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(OPERATOR_ROLE, _msgSender());
        _setDefaultRoyalty(_royaltyReciver, _royaltyValue);
        _safeMint(_owner, 1); //set up listing
        _pause();

        //mintSetter
        publicPrice = 0.0069 ether;
        _baseTokenURI = _initBaseURI;
        maxTokenPerAddress = _maxTokenPerAddress;
    }

    /**
     * @dev Mint tokens.
     * @param quantity The quantity of tokens to mint.
     */
    function mint(uint256 quantity) external payable whenNotPaused {
        require(
            totalSupply() + quantity <= MAX_TOTAL_SUPPLY,
            "Exceeds MAX_SUPPLY"
        );
        require(
            tokensMinted[_msgSender()] + quantity <= maxTokenPerAddress,
            "Exceeds MAX_PURCHASE_PER_ADDRESS"
        );

        if (totalSupply() < FREE_SUPPLY) {
            uint256 remainingFreeSupply = FREE_SUPPLY - totalSupply();

            if (quantity <= remainingFreeSupply) {
                _mintFree(quantity);
            } else {
                _mintFree(remainingFreeSupply);
                _mintPaid(quantity - remainingFreeSupply);
            }
        } else {
            _mintPaid(quantity);
        }
    }

    /**
     * @dev Mint free tokens.
     * @param quantity The quantity of tokens to mint.
     */
    function _mintFree(uint256 quantity) internal {
        _safeMint(_msgSender(), quantity);

        tokensMinted[_msgSender()] += quantity;
    }

    /**
     * @dev Mint paid tokens.
     * @param quantity The quantity of tokens to mint.
     */
    function _mintPaid(uint256 quantity) internal {
        uint256 totalCost = publicPrice * quantity;
        require(msg.value >= totalCost, "Need to send more ETH.");

        _safeMint(_msgSender(), quantity);

        tokensMinted[_msgSender()] += quantity;

        if (msg.value > totalCost) {
            payable(_msgSender()).transfer(msg.value - totalCost);
        }
    }

    /**
     * @dev Returns the contract owner address.
     * @return owner address.
     */
    function owner() public view virtual returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
     * @dev Adds an operator to the contract.
     * @param operator The address of the operator to be added.
     */
    function addOperator(address operator) public onlyRole(OPERATOR_ROLE) {
        require(operator != address(0), "Invalid operator address");
        _grantRole(OPERATOR_ROLE, operator);
    }

    /**
     * @dev Sets the royalty information for the contract.
     * @param receiver The address of the royalty receiver.
     * @param value The royalty value.
     */
    function setRoyaltyInfo(
        address receiver,
        uint96 value
    ) public onlyRole(OPERATOR_ROLE) {
        require(receiver != address(0), "Invalid receiver address");
        _setDefaultRoyalty(receiver, value);
    }

    /**
     * @dev Sets new mint price.
     * @param newPrice new price per token.
     */
    function setMintPrice(uint256 newPrice) public onlyRole(OPERATOR_ROLE) {
        publicPrice = newPrice;
        emit TokenPriceUpdated(newPrice);
    }

    /**
     * @dev Pause the contract.
     */
    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    /**
     * @dev Set the maximum number of tokens per address.
     * @param _maxTokenPerAddress The maximum number of tokens per address.
     */
    function setMaxTokenPerAddress(
        uint256 _maxTokenPerAddress
    ) external onlyRole(OPERATOR_ROLE) {
        require(maxTokenPerAddress > 0, "Invalid maxTokenPerAddress");
        maxTokenPerAddress = _maxTokenPerAddress;
        emit MaxTokenPerAddressUqdated(_maxTokenPerAddress);
    }

    /**
     * @dev Reveal the tokens.
     */
    function reveal() external onlyRole(OPERATOR_ROLE) {
        require(revealed == false, "Already revealed");
        revealed = true;
        emit BatchMetadataUpdate(0, totalSupply());
    }

    /**
     * @dev Set the base URI of the tokens.
     * @param baseURI The base URI of the tokens.
     */
    function setBaseURI(
        string calldata baseURI
    ) external onlyRole(OPERATOR_ROLE) {
        _baseTokenURI = baseURI;
        emit BatchMetadataUpdate(0, totalSupply());
    }

    /**
     * @dev Withdraws Ether from the contract to the owner.
     */
    function withdrawEther(uint256 amount) external onlyRole(OPERATOR_ROLE) {
        if (amount == 0) amount = address(this).balance;

        require(
            amount <= address(this).balance,
            "Amount to withdraw is greater than the contract balance"
        );
        (bool success, ) = _msgSender().call{value: amount}("");
        require(success, "Transfer failed.");
        emit EtherWithdrawn(_msgSender(), amount);
    }

    /**
     * @dev Authorizes an upgrade for the contract UUPS.
     * @param newImplementation The address of the new implementation to be authorized.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(OPERATOR_ROLE) {}

    /**
     * @dev Checks if the contract supports a specific interface.
     * @param interfaceId The interface identifier to check for support.
     * @return boolean value indicating whether the contract supports the specified interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            IERC721AUpgradeable,
            ERC721AUpgradeable,
            AccessControlEnumerableUpgradeable,
            ERC2981Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IERC721AUpgradeable).interfaceId ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId) ||
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the base URI of the tokens.
     * @return base URI.
     */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721AUpgradeable)
        returns (string memory)
    {
        return _baseTokenURI;
    }

    /**
     * @dev Returns the token URI for the specified token ID.
     * @param tokenId The token ID.
     * @return URI for the specified token ID.
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        string memory result;

        if (revealed) {
            string memory metadataPointerId = _toString(tokenId);
            result = string(
                abi.encodePacked(baseURI, metadataPointerId, ".json")
            );
        } else {
            result = baseURI;
        }

        return bytes(baseURI).length != 0 ? result : "";
    }
}