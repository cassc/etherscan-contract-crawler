// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

import "./Errors.sol";
import "./IAddressProvider.sol";
import "./IMetadataProvider.sol";
import "./IPaymentTokenRegistry.sol";

contract Replican is ERC721EnumerableUpgradeable {
    event ReplicanMinted(address indexed by, address indexed to, uint256 indexed tokenId);
    event ReplicanValidated(address indexed from, address indexed to, uint256 indexed tokenId);

    IERC721 private masterContract;
    mapping(uint256 => address) private masterTokenOperators;

    IAddressProvider private addressProvider;

    function initialize(address _masterContract, string memory _name, string memory _symbol, address addressProvider_) initializer external
    {
        __ERC721_init(_name, _symbol);
        masterContract = IERC721(_masterContract);
        addressProvider = IAddressProvider(addressProvider_);
    }

    function secure(address to, address vault, uint256 tokenId) external payable {
        if (msg.sender != masterContract.ownerOf(tokenId)) revert Errors.Unauthorized();
        IPaymentTokenRegistry paymentRegistry = IPaymentTokenRegistry(addressProvider.paymentTokenRegistry());
        PaymentConfig memory paymentConfig = paymentRegistry.costConfig(address(this));
        if (paymentConfig.cost > 0) {
            address payoutAddress = paymentConfig.payout;
            if (payoutAddress == address(0)) {
                payoutAddress = addressProvider.treasury();
            }
            if (paymentConfig.token == address(0) && msg.value < paymentConfig.cost) {
                revert Errors.InvalidSecurePayment();
            }
            if (paymentConfig.token != address(0)) {
                IERC20 tokenContract = IERC20(paymentConfig.token);
                bool success = tokenContract.transferFrom(msg.sender, payoutAddress, paymentConfig.cost);
                if (!success) revert Errors.TransferERC20Failed();
            } else {
                (bool success, ) = payable(payoutAddress).call{value: msg.value}("");
                if (!success) revert Errors.TransferFailed();
            }
        }

        if (!_exists(tokenId)) {
            _mint(to, tokenId);
            emit ReplicanMinted(msg.sender, to, tokenId);
        } else {
            _transfer(ownerOf(tokenId), to, tokenId);
        }

        address oldMasterTokenOperator = masterTokenOperators[tokenId];
        masterTokenOperators[tokenId] = vault;
        emit ReplicanValidated(oldMasterTokenOperator, to, tokenId);
    }

    function invalidate(uint256 tokenId) external {
        if (msg.sender != masterContract.ownerOf(tokenId) && msg.sender != ownerOf(tokenId)) {
            revert Errors.Unauthorized();
        }
        delete masterTokenOperators[tokenId];
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return
            IMetadataProvider(addressProvider.metadataProvider()).tokenURI(tokenId, address(this), isValid(tokenId), "");
    }

    function isValid(uint256 tokenId) public view returns (bool) {
        return masterContract.ownerOf(tokenId) == masterTokenOperators[tokenId];
    }
}