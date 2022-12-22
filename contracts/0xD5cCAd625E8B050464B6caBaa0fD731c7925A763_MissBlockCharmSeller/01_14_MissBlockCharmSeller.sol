//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/IMissBlockCharmBox.sol";


contract MissBlockCharmSeller is EIP712, AccessControl {
    using SafeERC20 for IERC20;

    modifier onlyNotPaused() {
        require(!paused, "Paused");
        _;
    }

    IMissBlockCharmBox public nftContract = IMissBlockCharmBox(0x5736C9Bfdd5cA782f7b963573B43d4131163b479);

    bytes32 public constant SERVER_ROLE = keccak256("SERVER_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    string private constant SIGNING_DOMAIN = "LazySeller-MissBlockCharm";
    string private constant SIGNATURE_VERSION = "1";
    address public receiver;
    bool public paused;

    struct Buyer {
        uint256 amount;
        address buyerAddress;
        uint256 totalPrice;
        address tokenAddress;
    }

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _setupRole(
            DEFAULT_ADMIN_ROLE,
            msg.sender
        );

        receiver = 0x78571B9cEd2D2BC9741960A5b08069125d96e483;
    }

    function togglePause() external onlyRole(CONTROLLER_ROLE) {
        paused = !paused;
    }

    function setAddressReceiver(address _receiver) external onlyRole(CONTROLLER_ROLE) {
        require(_receiver != address(0));
        receiver = _receiver;
    }

    function setNFTContract(IMissBlockCharmBox _nftContract) external onlyRole(CONTROLLER_ROLE) {
        nftContract = _nftContract;
    }

    function buy(Buyer calldata buyer, bytes memory signature)  external payable onlyNotPaused {
        address signer = _verify(buyer, signature);
        bool isNativeToken = buyer.tokenAddress == address(0);
        IERC20 token = IERC20(buyer.tokenAddress);

        uint256 amount = buyer.amount;
        uint256 totalPrice = buyer.totalPrice;

        require(buyer.buyerAddress == msg.sender, "invalid signature");
        require(
            hasRole(SERVER_ROLE, signer),
            "Signature invalid or unauthorized"
        );
        if(isNativeToken) {
            require(msg.value == totalPrice, "not enough fee");
            (bool isSuccess, ) = address(receiver).call{value: totalPrice}("");
            require(isSuccess);
        } else {
            token.safeTransferFrom(msg.sender, receiver, totalPrice);
        }

        nftContract.mint(amount, buyer.buyerAddress);
    }

    function _hash(Buyer calldata buyer)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Buyer(uint256 amount,address buyerAddress,uint256 totalPrice,address tokenAddress)"
                        ),
                        buyer.amount,
                        buyer.buyerAddress,
                        buyer.totalPrice,
                        buyer.tokenAddress
                    )
                )
            );
    }

    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _verify(Buyer calldata buyer, bytes memory signature)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(buyer);
        return ECDSA.recover(digest, signature);
    }
}