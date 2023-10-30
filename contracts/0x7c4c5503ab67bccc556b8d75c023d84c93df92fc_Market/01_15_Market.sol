// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface INFT {
    function mint(address, uint256, uint256, bytes memory) external;

    function addNFT(uint256, uint256, bool) external;

    function totalSupply(uint256) external returns (uint256);

    function supplyLeft(uint256) external returns (uint256);

    function burn(address, uint256, uint256) external;

    function setApprovalForAll(address, bool) external;

    function balanceOf(address, uint256) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract Market is AccessControl, ERC1155Holder {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC20 public stablecoin;

    INFT public nftContract;
    address public treasury;

    uint256 public offerCounter;

    struct SalesOffer {
        uint256 nftId;
        uint256 price;
        uint256 quantity;
        string customId;
    }

    mapping(uint256 => SalesOffer) public saleOffers;

    event Redeem(bytes customId, uint256 indexed tokenId );
    event Buy(SalesOffer offer, uint256  amount );

    constructor(INFT _nftAddress, address _treasury, IERC20 _stable) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        nftContract = _nftAddress;
        treasury = _treasury;
        stablecoin = _stable;
    }

    function redeemAndBurn(uint256 _tokenId, uint256 _amount, address _user,uint256 _value, string memory _customId) external onlyRole(ADMIN_ROLE){
        // burn nft
        nftContract.burn(_user, _tokenId, _amount);

        //pay user
        stablecoin.safeTransferFrom(treasury,_user, _value * _amount);

        emit Redeem(abi.encode(_customId), _tokenId);
    }

    function redeemAndSell(uint256 _tokenId, uint256 _amount, address _user,uint256 _value, uint256 _salesValue, string memory _customId) external onlyRole(ADMIN_ROLE){
        // transfer nft
        nftContract.safeTransferFrom(_user,address(this), _tokenId, _amount, "");

        //add sale offer
        saleOffers[offerCounter] = SalesOffer(_tokenId,_salesValue, _amount, _customId);
        offerCounter++;

        //pay user
        stablecoin.safeTransferFrom(treasury, _user, _value * _amount);

        emit Redeem(abi.encode(_customId), _tokenId);
    }

    function buy(uint256 _offerId, uint256 _amount) public {
        SalesOffer storage offer = saleOffers[_offerId];
        require(offer.quantity >= _amount, "T2SMarker: bad quantity");

        // transfer stablecoin
        stablecoin.safeTransferFrom(msg.sender, treasury, offer.price * _amount);

        // transfer nft
        nftContract.safeTransferFrom(address(this), msg.sender, offer.nftId, _amount, "");

        //update left quantity
        saleOffers[_offerId].quantity -= _amount;

        emit Buy(offer, _amount);
    }

    function updatePrice(uint256 _offerId, uint256 _value) public onlyRole(ADMIN_ROLE) {
        SalesOffer storage offer = saleOffers[_offerId];
        offer.price = _value;
    }

    function transferToken(address _tokenAddress) public onlyRole(ADMIN_ROLE) {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).safeTransfer(treasury,balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155Receiver) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}