// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface INFT {
    function mint(address, uint256, uint256, bytes memory) external;

    function addNFT(uint256, uint256, bool) external;

    function totalSupply(uint256) external returns (uint256);

    function supplyLeft(uint256) external returns (uint256);

    function burn(address, uint256, uint256) external;

    function setApprovalForAll(address, bool) external;
}

contract RedeemSinglePayment is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    INFT public nftContract;
    address public treasury;

    mapping(uint256 => Nft) public nftDetail;

    struct Nft {
        IERC20 erc20Token;
        uint256 price;
        uint256 quantity;
        uint256 totalPaid;
        uint256 counter;
    }

    constructor(INFT _nftAddress, address _treasury) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        nftContract = _nftAddress;
        treasury = _treasury;
    }

    function redeem(uint256 _tokenId, uint256 _amount) external {
        Nft memory _nftDetail = nftDetail[_tokenId];
        require(_nftDetail.quantity >= _nftDetail.counter + _amount);
        uint256 value = _amount * _nftDetail.price;

        // burn nft
        nftContract.burn(msg.sender, _tokenId, _amount);

        //pay user
        _nftDetail.erc20Token.safeTransferFrom(treasury, msg.sender, value);

        //update nft details
        _nftDetail.counter += _amount;
        _nftDetail.totalPaid += value;
        nftDetail[_tokenId] = _nftDetail;
    }

    function setupPayment(
        uint256 _tokenId,
        IERC20 _erc20Token,
        uint256 _price,
        uint256 _quantityToPay
    ) public onlyRole(ADMIN_ROLE) {
        require(_erc20Token.totalSupply() > 0, "Redeem: bad erc20 address");
        _updatePayment(
            _tokenId,
            _erc20Token,
            _price,
            _quantityToPay,
            nftDetail[_tokenId].totalPaid,
            nftDetail[_tokenId].counter
        );
    }

    function adjustPayment(
        uint256 _tokenId,
        IERC20 _erc20Token,
        uint256 _price,
        uint256 _quantityToPay
    ) public onlyRole(ADMIN_ROLE) {
        require(_erc20Token.totalSupply() > 0, "Redeem: bad erc20 address");
        _updatePayment(
            _tokenId,
            _erc20Token,
            _price,
            _quantityToPay,
            nftDetail[_tokenId].totalPaid,
            nftDetail[_tokenId].counter
        );
    }

    function _updatePayment(
        uint256 _tokenId,
        IERC20 _erc20Token,
        uint256 _price,
        uint256 _quantityToPay,
        uint256 _counter,
        uint256 _totalPaid
    ) internal {
        nftDetail[_tokenId] = Nft(
            _erc20Token,
            _price,
            _quantityToPay,
            _counter,
            _totalPaid
        );
    }

    // function paymentDetail(
    //     uint256 _tokenId
    // ) external view returns (Nft memory) {
    //     // ) external view returns (IERC20, uint256, uint256, uint256, uint256) {
    //     return nftDetail[_tokenId];
    //     // return (
    //     //     nftDetail[_tokenId].erc20Token,
    //     //     nftDetail[_tokenId].price,
    //     //     nftDetail[_tokenId].totalPaid,
    //     //     nftDetail[_tokenId].counter,
    //     //     nftDetail[_tokenId].quantity
    //     // );
    // }
}