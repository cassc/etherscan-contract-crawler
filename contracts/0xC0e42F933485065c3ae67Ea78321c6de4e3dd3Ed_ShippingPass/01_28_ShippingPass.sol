// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC1155Burnable.sol";
import "./default_operator_contracts/DefaultOperatorFilterer.sol";
import "./PriceConverter.sol";
import "./Tag.sol";
import "./BBTag.sol";

/// @title Shipping Pass
/// @author Atlas C.O.R.P.
contract ShippingPass is
    ERC721Enumerable,
    AccessControlEnumerable,
    DefaultOperatorFilterer,
    Ownable
{
    using PriceConverter for uint256;

    struct Order {
        uint256[] tokenIds;
        uint256[] quantities;
    }

    bytes32 public constant SALES_MANAGER = keccak256("SALES_MANAGER");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    IERC1155Burnable public immutable boringBrewBagsContract;

    string public baseURI;
    bool public passActive;
    uint256 public counter;
    uint256 public shippingCost1 = 8 ether;
    uint256 public shippingCost2 = 16 ether;
    uint256 public shippingCost3 = 24 ether;

    mapping(uint256 shippingPassId => Order orderDetails) private orders;

    event Withdraw(uint256 _amount);
    event Claimed(address indexed _caller);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        IERC1155Burnable _boringBrewBagsContract
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SALES_MANAGER, msg.sender);
        boringBrewBagsContract = _boringBrewBagsContract;
        baseURI = _uri;
    }

    /// @notice caller has to pay Ethereum for shipping pass
    /// @param order is a struct containing 2 arrays. TokenId array and quantity array
    function buyShippingPass(Order calldata order) external payable {
        uint256 quantitiesLength = order.quantities.length;

        require(passActive, "buyShippingPass: contract is not active");
        require(
            order.tokenIds.length == quantitiesLength,
            "buyShippingPass: length of ids & amounts array mismatch"
        );

        uint256 i = 0;
        uint256 bagsBurned;
        for (; i < quantitiesLength; ) {
            bagsBurned += order.quantities[i];

            unchecked {
                ++i;
            }
        }
        if (bagsBurned == 1) {
            require(
                msg.value.getConversionRate() >= shippingCost1,
                "buyShippingPass: SEND MORE ETHEREUM"
            );
        } else if (bagsBurned == 2) {
            require(
                msg.value.getConversionRate() >= shippingCost2,
                "buyShippingPass: SEND MORE ETHEREUM"
            );
        } else {
            require(
                msg.value.getConversionRate() >= shippingCost3,
                "buyShippingPass: SEND MORE ETHEREUM"
            );
        }

        ++counter;

        orders[counter] = order;

        boringBrewBagsContract.burnBatch(
            msg.sender,
            order.tokenIds,
            order.quantities
        );

        _safeMint(msg.sender, counter);

        emit Claimed(msg.sender);
    }

    function getOrder(
        uint256 _orderNumber
    ) public view returns (uint256[] memory, uint256[] memory) {
        return (orders[_orderNumber].tokenIds, orders[_orderNumber].quantities);
    }

    /// @param _tokenId is the NFT ID that the caller wants to burn
    function burn(uint256 _tokenId) external onlyRole(BURN_ROLE) {
        require(
            msg.sender == ERC721.ownerOf(_tokenId),
            "burn: not owner of token ID"
        );
        _burn(_tokenId);
    }

    /// @notice withdraws tokens here
    /// @param _destination is the address the SALES_MANAGER wants to send funds to
    function withdraw(address _destination) external onlyOwner {
        uint256 balance = address(this).balance;

        require(payable(_destination).send(balance));
        emit Withdraw(balance);
    }

    /// @notice enables the contract to be used
    /// @param _passActive true is active false is inactive
    function toggleActive(bool _passActive) external onlyOwner {
        passActive = _passActive;
    }

    /// @notice to change the URI if needed
    /// @param _URI new IPFS link to change to a new one
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    /// @notice to view the URI
    /// @return baseURI returns the IPFS link being used
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    /// @param _newPrice is the new price of shippingCost1 in wei
    function setPrice1(uint256 _newPrice) external onlyOwner {
        shippingCost1 = _newPrice;
    }

    /// @param _newPrice is the new price of shippingCost2 in wei
    function setPrice2(uint256 _newPrice) external onlyOwner {
        shippingCost2 = _newPrice;
    }

    /// @param _newPrice is the new price of shippingCost3 in wei
    function setPrice3(uint256 _newPrice) external onlyOwner {
        shippingCost3 = _newPrice;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return (ERC721Enumerable.supportsInterface(interfaceId) ||
            AccessControlEnumerable.supportsInterface(interfaceId));
    }

    function setApprovalForAll(
        address operator,
        bool _approved
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, _approved);
    }

    function approve(
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(to) {
        super.approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokensInWallet(
        address _owner
    ) external view returns (Order[] memory _orders, uint256[] memory _tokens) {
        uint256 tokenCount = balanceOf(_owner);

        _orders = new Order[](tokenCount);
        _tokens = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; ) {
            uint256 token = tokenOfOwnerByIndex(_owner, i);
            _orders[i] = orders[token];
            _tokens[i] = token;
            unchecked {
                i++;
            }
        }
    }
}